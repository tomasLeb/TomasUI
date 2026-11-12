#!/usr/bin/env python3
"""Genera el perfil pixel perfect de TomasUI a partir del perfil original (base_profile.txt).

Es la "fuente" de la versión inicial del perfil y documenta la rejilla usada. Después de la
versión inicial, el perfil se mantiene en el juego y se publica con /tui export; este script
solo hace falta para rehacer el diseño desde cero.

Reglas de la rejilla (pantalla de referencia 2560x1080, escala 0,711 -> 1 unidad = 1 px;
en 1440p 1 unidad = 1,333 px):
  · Tamaños, huecos y posiciones en múltiplos de 3 (en 1440p caen en píxeles enteros).
  · Lo centrado, en múltiplos de 6 (pares en las dos resoluciones).
  · Bloque central de 1062 de ancho: barras 2 x 498 + hueco 66, grupo 5 x 210 + 4 x 3.
  · Columna derecha de 261: minimapa, microbarra (11 x 21 + 10 x 3), misiones y Details!.

Uso:
    python tools/layout_pp.py [base_profile.txt] > perfil.lua      # tabla Lua del perfil
"""
import copy
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from tomasui_lib import decode_elvui, lua_value  # noqa: E402

W, H = 2560, 1080  # pantalla de referencia en unidades de UI


def build(base):
    X = base
    pp = copy.deepcopy(X)
    log = []

    def setp(path, val):
        t = pp
        ks = path.split('.')
        for k in ks[:-1]:
            t = t.setdefault(k, {})
        t[ks[-1]] = val

    def chg(path, val):
        setp(path, val)
        log.append((path, val))

    def r(v, m):
        return int(m * round(v / m))

    # --- unit frames
    for u in ['player','target','focus','pet']:
        chg(f'unitframe.units.{u}.width',210)
    for u in ['player','target','focus']:
        chg(f'unitframe.units.{u}.height',42)
    for u in ['player','target','focus','pet','targettarget','focustarget']:
        chg(f'unitframe.units.{u}.power.height',21)
    for u in ['player','target','focus']:
        chg(f'unitframe.units.{u}.castbar.width',210)
    for u in ['targettarget','focustarget']:
        chg(f'unitframe.units.{u}.width',78); chg(f'unitframe.units.{u}.height',42)
    chg('unitframe.units.focus.infoPanel.height',21)
    for u in ['player','target']:
        chg(f'unitframe.units.{u}.buffs.height',21); chg(f'unitframe.units.{u}.debuffs.height',21)
    chg('unitframe.units.target.debuffs.height',21)
    # party / raid
    chg('unitframe.units.party.width',210); chg('unitframe.units.party.height',42); chg('unitframe.units.party.power.height',21)
    chg('unitframe.units.party.horizontalSpacing',3); chg('unitframe.units.party.debuffs.height',21); chg('unitframe.units.party.buffs.height',21)
    chg('unitframe.units.party.petsGroup.width',210); chg('unitframe.units.party.petsGroup.height',6)
    for u,(h,pw) in {'raid1':(12,12),'raid2':(6,9)}.items():
        chg(f'unitframe.units.{u}.width',210); chg(f'unitframe.units.{u}.height',h); chg(f'unitframe.units.{u}.power.height',pw); chg(f'unitframe.units.{u}.horizontalSpacing',3); chg(f'unitframe.units.{u}.verticalSpacing',3)
    # auras: 30x21, spacing 6, separadas 6 del marco y entre filas
    for u,per in [('player',10),('target',10),('party',10)]:
        for a in ['buffs','debuffs']:
            for k,v in [('sizeOverride',21),('keepSizeRatio',True),('height',21),('spacing',0),('perrow',per),('numrows',1),('yOffset',0)]:
                chg(f'unitframe.units.{u}.{a}.{k}',v)
    # barras de lanzamiento debajo del marco (no encima del poder), por encima del swing timer
    for u in ['player','target']:
        for k,v in [('overlayOnFrame','None'),('insideInfoPanel',False),('width',210),('height',21),
                    ('strataAndLevel.useCustomStrata',True),('strataAndLevel.frameStrata','MEDIUM')]:
            chg(f'unitframe.units.{u}.castbar.{k}',v)
    # barra de clase activada (necesaria para el poder adicional); combo points separados a la derecha del objetivo
    for k,v in [('enable',True),('detachFromFrame',True),('detachedWidth',57),('height',21),('spacing',3),('autoHide',True)]:
        chg(f'unitframe.units.player.classbar.{k}',v)
    # poder adicional (maná del druida en formas): 57x21 a la izquierda del poder del jugador
    for k,v in [('width',57),('height',21),('autoHide',False)]:
        chg(f'unitframe.units.player.classAdditional.{k}',v)
    # marco del jugador: se atenúa fuera de combate con vida y recurso llenos (fader de ElvUI)
    chg('unitframe.units.player.fader.enable',False)  # marco del jugador siempre visible
    # banda 1: sin texto de vida (se solapa con el indicador de auras)
    chg('unitframe.units.raid1.health.text_format','')
    # --- action bars
    for b in ['bar1','bar2','bar3','bar4']: chg(f'actionbar.{b}.buttonSpacing',6)
    chg('actionbar.stanceBar.buttonSize',30); chg('actionbar.stanceBar.buttonSpacing',6)
    chg('actionbar.barPet.buttonSize',30); chg('actionbar.barPet.buttonSpacing',6)
    chg('actionbar.microbar.buttonSize',21); chg('actionbar.microbar.buttonHeight',24); chg('actionbar.microbar.buttonSpacing',3); chg('actionbar.microbar.buttonsPerRow',12)
    chg('general.totems.spacing',3)
    # hueco central: dos paneles de datos (FPS arriba, durabilidad abajo); panel izquierdo fuera
    chg('datatexts.panels.TomasUI_FPS',{'enable':True,'battleground':False,1:'System'})
    chg('datatexts.panels.TomasUI_Dur',{'enable':True,'battleground':False,1:'Durability'})
    chg('datatexts.panels.LeftChatDataPanel.enable',False)
    chg('chat.editBoxPosition','BELOW_CHAT_INSIDE')
    # beneficios / perjuicios de arriba: iconos 30, separación 6 (vertical 15)
    for a in ['buffs','debuffs']:
        chg(f'auras.{a}.size',30); chg(f'auras.{a}.horizontalSpacing',6); chg(f'auras.{a}.verticalSpacing',15)
    # minimapa: calendario arriba a la izquierda (simétrico al correo) y texto de zona con sombra
    chg('general.minimap.icons.calendar.position','TOPLEFT'); chg('general.minimap.icons.calendar.xOffset',3)
    chg('general.minimap.icons.calendar.yOffset',-3); chg('general.minimap.icons.calendar.scale',1)
    chg('general.minimap.locationFontOutline','SHADOW')
    # --- misc sizes
    chg('databars.experience.width',1062); chg('databars.experience.height',12)
    chg('databars.petExperience.width',210)
    chg('general.altPowerBar.width',48)
    chg('general.minimap.size',261); chg('chat.panelWidth',498)
    chg('bags.bagWidth',630); chg('bags.bankWidth',630); chg('bags.bagBar.size',30); chg('bags.bagBar.spacing',3); chg('bags.bagButtonSpacing',3)
    # --- movers
    def parse(s):
        p,par,rp,x,y=s.split(','); return p,par,rp,float(x),float(y)
    def absxy(par,rp,x,y):
        hf=0 if 'LEFT' in rp else 1 if 'RIGHT' in rp else .5
        vf=0 if 'BOTTOM' in rp else 1 if 'TOP' in rp else .5
        return W*hf+x,H*vf+y
    def norm(s):
        p,par,rp,x,y=parse(s)
        if par not in ('UIParent','ElvUIParent'): return s
        ax,ay=absxy(par,rp,x,y)
        if 400<ax<W-400: h,ho='',ax-W/2
        elif ax<=W/2: h,ho='LEFT',ax
        else: h,ho='RIGHT',ax-W
        if ay>H/2: v,vo='TOP',ay-H
        else: v,vo='BOTTOM',ay
        m=6 if h=='' else 3
        return f'{p},{par},{v+h},{r(ho,m)},{r(vo,3)}'
    mv={k:norm(v) for k,v in X['movers'].items()}
    # center cluster designed by hand
    E='ElvUIParent'; U='UIParent'
    design={
     'ExperienceBarMover':f'BOTTOM,{E},BOTTOM,0,3',
     'ElvAB_1':f'BOTTOM,{E},BOTTOM,-282,18', 'ElvAB_2':f'BOTTOM,{E},BOTTOM,282,18',
     'DTPanelTomasUI_FPSMover':f'BOTTOM,{E},BOTTOM,0,18', 'DTPanelTomasUI_DurMover':f'BOTTOM,{E},BOTTOM,0,60', 'ElvAB_3':f'BOTTOM,{E},BOTTOM,-282,60', 'ElvAB_4':f'BOTTOM,{E},BOTTOM,282,60',
     'PetAB':f'BOTTOMLEFT,{E},BOTTOM,-531,102', 'ShiftAB':f'BOTTOMRIGHT,{U},BOTTOM,531,102',
     'ElvUF_PlayerMover':f'BOTTOM,{E},BOTTOM,-426,267', 'ElvUF_TargetMover':f'BOTTOM,{E},BOTTOM,426,267',
     'ElvUF_PetMover':f'BOTTOM,{E},BOTTOM,-426,369', 'ElvUF_FocusMover':f'BOTTOM,{E},BOTTOM,426,369',
     'ElvUF_TargetTargetMover':'BOTTOMLEFT,ElvUF_TargetMover,BOTTOMRIGHT,3,0',
     'ElvUF_FocusTargetMover':'BOTTOMLEFT,ElvUF_FocusMover,BOTTOMRIGHT,3,0',
     'ElvUF_PartyMover':f'BOTTOM,{E},BOTTOM,0,138','ElvUF_Raid1Mover':f'BOTTOM,{E},BOTTOM,0,138','ElvUF_Raid2Mover':f'BOTTOM,{E},BOTTOM,0,138',
     'AlertFrameMover':f'BOTTOM,{E},BOTTOM,0,267','ElvUIBagMover':f'BOTTOM,{E},BOTTOM,210,267','AltPowerBarMover':f'BOTTOM,{E},BOTTOM,-288,267',
     'LootFrameMover':f'BOTTOM,{E},BOTTOM,0,174',
     'BNETMover':f'TOPLEFT,{E},TOPLEFT,3,-3',
     'GMMover':'TOPLEFT,BNETMover,TOPRIGHT,6,0',
     'ShardTransferMover':'BOTTOMLEFT,BagsMover,TOPLEFT,0,6',
     'MinimapMover':f'TOPRIGHT,{E},TOPRIGHT,-3,-3', 'MicrobarMover':f'TOPRIGHT,{E},TOPRIGHT,-3,-270',
     'BuffsMover':f'TOPRIGHT,{U},TOPRIGHT,-270,-3', 'DebuffsMover':f'TOPRIGHT,{E},TOPRIGHT,-270,-234',
     'QueueStatusMover':'BOTTOMLEFT,Minimap,BOTTOMLEFT,6,6', 'AddonCompartmentMover':'BOTTOMRIGHT,Minimap,BOTTOMRIGHT,-6,6',
     'AdditionalPowerMover':f'BOTTOMRIGHT,{E},BOTTOM,-537,267', 'ClassBarMover':f'BOTTOMRIGHT,{E},BOTTOM,-537,288',
     'ElvUF_PlayerCastbarMover':f'BOTTOM,{E},BOTTOM,-426,240', 'ElvUF_TargetCastbarMover':f'BOTTOM,{E},BOTTOM,426,240',
    }
    for k,v in design.items():
        log.append(('movers.'+k, X['movers'].get(k), v)); mv[k]=v

    pp['movers'] = mv
    return pp, log


def main():
    path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent / 'base_profile.txt')
    kind, _, base = decode_elvui(path.read_text(encoding='utf-8'))
    if kind != 'profile':
        sys.exit('La cadena no es un perfil de ElvUI')
    profile, log = build(base)
    print(lua_value(profile))
    print('-- %d cambios aplicados' % len(log), file=sys.stderr)


if __name__ == '__main__':
    main()
