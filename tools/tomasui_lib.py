"""Utilidades compartidas de las herramientas de TomasUI.

- decode_elvui / decode_plater: cadenas de exportación (!E2! / !PLATER:2!) -> tablas Python
- lua_value: tablas Python -> texto Lua (para Data.lua)
- parse_lua_assignments: lee un fichero SavedVariables de WoW sin necesitar Lua
"""
import base64
import re
import zlib


# ---------------------------------------------------------------- decodificar
def _cbor():
    try:
        import cbor2
    except ImportError as exc:  # pragma: no cover
        raise SystemExit('Falta cbor2: pip install cbor2') from exc
    return cbor2


def _norm(o):
    """bytes -> str en claves y valores; listas CBOR -> dict con índices Lua (1..n)."""
    if isinstance(o, dict):
        return {(k.decode() if isinstance(k, bytes) else k): _norm(v) for k, v in o.items()}
    if isinstance(o, list):
        return {i + 1: _norm(v) for i, v in enumerate(o)}
    if isinstance(o, bytes):
        return o.decode('utf-8')
    return o


def decode_elvui(s):
    """!E2!... -> (tipo, clave, datos). Formato: base64 -> deflate -> 'CBOR::tipo[::clave]'."""
    raw = zlib.decompress(base64.b64decode(s.strip()[4:]), -15)
    parts = raw.split(b'::')
    if len(parts) >= 3 and parts[-2] == b'profile':
        payload, kind, key = b'::'.join(parts[:-2]), 'profile', parts[-1].decode()
    else:
        payload, kind, key = b'::'.join(parts[:-1]), parts[-1].decode(), None
    return kind, key, _norm(_cbor().loads(payload))


def decode_plater(s):
    raw = zlib.decompress(base64.b64decode(s.strip()[len('!PLATER:2!'):]), -15)
    return _norm(_cbor().loads(raw))


# ---------------------------------------------------------------- escribir Lua
def lua_string(v):
    out = ['"']
    for ch in v:
        o = ord(ch)
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif ch == '\n':
            out.append('\\n')
        elif o < 32:
            out.append('\\%03d' % o)
        else:
            out.append(ch)
    out.append('"')
    return ''.join(out)


def lua_number(n):
    if isinstance(n, bool):
        return 'true' if n else 'false'
    if isinstance(n, int):
        return str(n)
    if n == int(n) and abs(n) < 1e15:
        return str(int(n))
    return repr(n)


def lua_value(v, indent=1):
    if isinstance(v, dict):
        if not v:
            return '{}'
        pad = '\t' * indent
        rows = []
        for k in sorted(v, key=lambda k: (isinstance(k, str), str(k))):
            key = '[%s]' % (lua_string(k) if isinstance(k, str) else lua_number(k))
            rows.append('%s%s = %s,' % (pad, key, lua_value(v[k], indent + 1)))
        return '{\n' + '\n'.join(rows) + '\n' + '\t' * (indent - 1) + '}'
    if isinstance(v, str):
        return lua_string(v)
    if v is None:
        return 'nil'
    return lua_number(v)


def lua_long_string(s):
    level = 1
    while (']' + '=' * level + ']') in s:
        level += 1
    eq = '=' * level
    return '[%s[%s]%s]' % (eq, s, eq)


# ---------------------------------------------------------------- leer SavedVariables
_TOKEN = re.compile(r'''
    (?P<ws>\s+|--[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<num>-?(?:\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+))
  | (?P<kw>true|false|nil)
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<sym>[{}\[\]=,;])
''', re.S | re.X)

_ESC = {'n': '\n', 't': '\t', 'r': '\r', '\\': '\\', '"': '"', "'": "'", 'a': '\a', 'b': '\b', 'f': '\f', 'v': '\v'}


def _unescape(body):
    out, i = [], 0
    while i < len(body):
        c = body[i]
        if c == '\\' and i + 1 < len(body):
            n = body[i + 1]
            if n.isdigit():
                j = i + 1
                while j < len(body) and j < i + 4 and body[j].isdigit():
                    j += 1
                out.append(chr(int(body[i + 1:j])))
                i = j
                continue
            if n == '\n':
                out.append('\n')
            else:
                out.append(_ESC.get(n, n))
            i += 2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def _tokens(text):
    pos = 0
    while pos < len(text):
        m = _TOKEN.match(text, pos)
        if not m:
            raise ValueError('No entiendo el fichero en la posición %d: %r' % (pos, text[pos:pos + 30]))
        pos = m.end()
        kind = m.lastgroup
        if kind == 'ws':
            continue
        yield kind, m.group(kind)


def parse_lua_assignments(text):
    """Lee 'Nombre = valor' (formato SavedVariables) y devuelve un dict."""
    toks = list(_tokens(text))
    i = 0

    def value():
        nonlocal i
        kind, tok = toks[i]
        i += 1
        if kind == 'str':
            return _unescape(tok[1:-1])
        if kind == 'num':
            return float(tok) if any(c in tok for c in '.eE') else int(tok)
        if kind == 'kw':
            return {'true': True, 'false': False, 'nil': None}[tok]
        if tok == '{':
            t, n = {}, 1
            while toks[i][1] != '}':
                if toks[i][1] == '[':
                    i += 1
                    k = value()
                    i += 2  # ] =
                    t[k] = value()
                elif toks[i][0] == 'name' and i + 1 < len(toks) and toks[i + 1][1] == '=':
                    k = toks[i][1]
                    i += 2
                    t[k] = value()
                else:
                    t[n] = value()
                    n += 1
                if toks[i][1] in (',', ';'):
                    i += 1
            i += 1
            return t
        raise ValueError('Valor inesperado: %r' % tok)

    out = {}
    while i < len(toks):
        name = toks[i][1]
        i += 2  # nombre =
        out[name] = value()
    return out
