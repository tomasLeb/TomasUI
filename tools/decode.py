#!/usr/bin/env python3
"""Decodifica una cadena de exportación de ElvUI (!E2!) o Plater (!PLATER:2!) a JSON legible.

Útil para revisar qué cambió entre dos versiones del perfil:
    python tools/decode.py cadena.txt > perfil.json
    python tools/decode.py Data.lua --data elvProfile > perfil.json
Necesita: pip install cbor2
"""
import argparse
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from tomasui_lib import decode_elvui, decode_plater  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('file', help='Fichero con la cadena, o Data.lua si se usa --data')
    ap.add_argument('--data', metavar='CAMPO', help='Leer el campo (elvProfile, elvPrivate, plater) de un Data.lua')
    args = ap.parse_args()

    text = pathlib.Path(args.file).read_text(encoding='utf-8')
    if args.data:
        m = re.search(r'\t%s = \[(=+)\[(.*?)\]\1\]' % re.escape(args.data), text, re.S)
        if not m:
            sys.exit('El campo %s no es una cadena en ese Data.lua' % args.data)
        text = m.group(2)
    text = text.strip()

    if text.startswith('!PLATER:2!'):
        out = {'type': 'plater', 'data': decode_plater(text)}
    elif text.startswith('!E2!'):
        kind, key, data = decode_elvui(text)
        out = {'type': kind, 'key': key, 'data': data}
    else:
        sys.exit('No reconozco la cadena (debe empezar por !E2! o !PLATER:2!)')
    json.dump(out, sys.stdout, indent=1, ensure_ascii=False, default=str)
    print()


if __name__ == '__main__':
    main()
