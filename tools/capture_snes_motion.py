#!/usr/bin/env python3
from libretro_reference import Snes
from pathlib import Path
import json,hashlib
import argparse
p=argparse.ArgumentParser();p.add_argument('--core',type=Path,required=True);p.add_argument('--rom',type=Path,required=True);p.add_argument('--output',type=Path,default=Path('tests/fixtures/smw-motion-reference.json'));a=p.parse_args()
root=Path(__file__).resolve().parents[1]
core=a.core;rom=a.rom
s=Snes(core,rom)
# Deterministic controller sequence from power-on to Yoshi's Island 1.
for n,keys in [(600,0),(2,8),(120,0),(2,256),(120,0),(2,256),(600,0),(2,1),(240,0),(80,64),(10,0),(2,1),(240,0),(60,64),(10,0),(2,1),(240,0)]:s.run(n,keys)
assert s.byte(0x100)==20 and s.word(0x94)==16 and s.word(0x96)==352, s.state()
state=s.save()
# Abstract buttons use NES-compatible bit layout, mapped to SNES B/Y/D-pad.
cases={
 'walk_right':[[100,1]],'walk_left':[[100,2]],
 'run_right':[[150,65]],'run_left':[[150,66]],
 'brake_run':[[100,65],[60,0]],'reverse_run':[[100,65],[60,66]],
 'release_run_button':[[100,65],[55,1]],
 'jump_tap':[[2,128],[70,0]],'jump_hold':[[32,128],[50,0]],
 'run_jump':[[100,65],[32,193],[55,65]],
 'air_reverse':[[18,129],[20,130],[50,0]],
 'release_air_control':[[35,65],[10,193],[65,0]]}
result={
 'provenance':{'rom_sha256':hashlib.sha256(rom.read_bytes()).hexdigest(),'emulator':'Snes9x libretro 1.61 (Ubuntu 1.61+dfsg-1)','core_sha256':hashlib.sha256(core.read_bytes()).hexdigest(),'fixture':'Yoshis Island 1 start, X held at 48 each frame; native ground Y=352, vanilla small Mario; sprites disabled, no ROM patches; WRAM fixtures reset velocity, fractions and P-meter. Numeric telemetry only.', 'snes_input':'NES A -> SNES B (normal jump); NES B -> SNES Y (run)'},
 'fields':['x_accum','y_relative','x_fraction','y_fraction','vx_fraction','vx','vy','p_meter','air_state'],
 'cases':[]}
for name,segments in cases.items():
 s.load(state)
 for addr,val in {0x94:48,0x95:0,0xd1:48,0xd2:0,0x96:96,0x97:1,0xd3:96,0xd4:1,0x13da:0,0x13dc:0,0x7a:0,0x7b:0,0x7c:0,0x7d:6,0x72:0,0x73:0,0x76:1,0x13e4:0,0x13e1:0,0x86:0,0x14a0:0,0x14a1:0,0x19:0}.items():s.ram[addr]=val
 rows=[];accum=0
 for count,b in segments:
  keys=((b&1)!=0)<<7|((b&2)!=0)<<6|((b&64)!=0)<<1|((b&128)!=0)
  for _ in range(count):
   for addr in (0x94,0xd1):s.ram[addr]=48;s.ram[addr+1]=0
   for addr in range(0x14c8,0x14d4):s.ram[addr]=0
   s.run(keys=keys)
   accum+=s.word(0x94)-48
   rows.append([accum,s.word(0x96)-352,s.byte(0x13da),s.byte(0x13dc),s.byte(0x7a),s.state()['vx'],s.state()['vy'],s.byte(0x13e4),s.byte(0x72)])
 result['cases'].append({'name':name,'segments':segments,'rows':rows})
 print(name,len(rows),rows[-1])
a.output.write_text(json.dumps(result,separators=(',',':'))+'\n')
