#!/usr/bin/env python3
"""Optional ROM-backed verification against an independently obtained SMWDisX map.
No ROM, disassembly or extracted game assets are copied to the repository.
"""
from pathlib import Path
import argparse,json
p=argparse.ArgumentParser();p.add_argument('rom',type=Path);p.add_argument('symbols',type=Path);a=p.parse_args()
b=a.rom.read_bytes();b=b[512:] if len(b)%32768==512 else b
expected=json.loads(Path('docs/physics-reference-check.json').read_text())['checks']
symbols={name:int(addr,16) for addr,name in (line.split() for line in a.symbols.read_text().splitlines() if len(line.split())==2)}
for item in expected:
 addr=symbols[item['symbol']];off=((addr>>16)&127)*32768+(addr&32767);want=bytes.fromhex(item['bytes'])
 assert b[off:off+len(want)]==want,item['symbol']
 assert addr==int(item['snes_address'],16),item['symbol']
 print(f"PASS {item['symbol']} SNES=${addr:06X}, file=${off:06X}")
