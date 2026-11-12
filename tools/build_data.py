#!/usr/bin/env python3
"""Genera Data.lua a partir de lo que /tui export guardó en SavedVariables.

Uso:
    1. En el juego: /tui export y después /reload (o salir), para que se escriba en disco.
    2. python tools/build_data.py "<WoW>/_forever_/WTF/Account/<CUENTA>/SavedVariables/TomasUI.lua"

Escribe Data.lua en la raíz del repo (o donde indique --out).
"""
import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from tomasui_lib import lua_long_string, lua_number, lua_string, parse_lua_assignments  # noqa: E402

HEADER = ('-- TomasUI · Data.lua\n'
          '-- GENERADO por /tui export (o tools/build_data.py). No editar a mano: la configuración va en Config.lua.\n'
          'local _, ns = ...\n\n')


def render(d):
    r = d['ref']
    layouts = '\n'.join('\t\t[%s] = %s,' % (lua_string(k), lua_long_string(v))
                        for k, v in sorted((d.get('editModeLayouts') or {}).items()))
    return HEADER + (
        'ns.Data = {\n'
        '\tversion = %d,\n'
        '\tref = {\n'
        '\t\tphysW = %s, physH = %s,\n'
        '\t\tuiScale = %s,\n'
        '\t\tuiW = %s, uiH = %s,\n'
        '\t\telvW = %s, elvH = %s,\n'
        '\t\tultrawide = %s, eyefinity = %s,\n'
        '\t},\n'
        '\teditModeLayouts = {\n%s\n\t},\n'
        '\telvProfile = %s,\n'
        '\telvPrivate = %s,\n'
        '\tplater = %s,\n'
        '}\n'
    ) % (int(d['version']),
         lua_number(r['physW']), lua_number(r['physH']), lua_number(r['uiScale']),
         lua_number(r['uiW']), lua_number(r['uiH']), lua_number(r['elvW']), lua_number(r['elvH']),
         lua_number(bool(r.get('ultrawide'))), lua_number(bool(r.get('eyefinity'))),
         layouts, lua_long_string(d['elvProfile']), lua_long_string(d.get('elvPrivate') or ''),
         lua_long_string(d.get('plater') or ''))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('savedvariables', help='Ruta a WTF/Account/<CUENTA>/SavedVariables/TomasUI.lua')
    ap.add_argument('--out', default=str(pathlib.Path(__file__).resolve().parent.parent / 'Data.lua'))
    args = ap.parse_args()

    sv = parse_lua_assignments(pathlib.Path(args.savedvariables).read_text(encoding='utf-8'))
    export = (sv.get('TomasUIDB') or {}).get('export')
    if not export:
        sys.exit('No hay exportación en ese fichero. En el juego: /tui export y luego /reload.')

    pathlib.Path(args.out).write_text(render(export), encoding='utf-8')
    print('Data.lua generado: versión %s -> %s' % (int(export['version']), args.out))


if __name__ == '__main__':
    main()
