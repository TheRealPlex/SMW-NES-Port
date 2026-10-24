#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,struct
r=Path('build/smw-nes-physics-v0.2.nes').read_bytes()
assert r[:4]==b'NES\x1a'
prg,chr=r[4]*16384,r[5]*8192
assert len(r)==16+prg+chr==73744
mapper=(r[6]>>4)|(r[7]&0xf0)
assert mapper==4 and r[6]&3==3 and r[8]==1
assert r[6]&4==0 and r[7]&12==0
vectors=struct.unpack('<HHH',r[16+prg-6:16+prg]);assert all(0xc000<=v<=0xfff9 for v in vectors)
labels={line.split()[2][1:]:int(line.split()[1],16) for line in Path('build/labels.txt').read_text().splitlines() if len(line.split())==3}
assert vectors==(labels['NMI'],labels['Reset'],labels['IRQ'])
assert r[16+prg-16384+(vectors[1]-0xc000)]==0x78 # SEI
assert set(r[16:16+49152])=={255}
assert len(set(r[-8192:]))>4
assert labels['__BSS_RUN__']+labels['__BSS_SIZE__']<=0x800
assert len(Path('build/world.bin').read_bytes())==128*15
result={'status':'passed','mapper':mapper,'PRG_bytes':prg,'CHR_bytes':chr,'WRAM_bytes':8192,'battery':True,'mirroring':'vertical','vectors':[f'{v:04X}' for v in vectors],'sha256':hashlib.sha256(r).hexdigest(),'file_bytes':len(r)}
Path('build/static-results.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
