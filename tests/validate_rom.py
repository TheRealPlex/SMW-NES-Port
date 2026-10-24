#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,struct
r=Path('build/smw-nes-adventure-v0.3.nes').read_bytes()
assert r[:4]==b'NES\x1a';prg,chr=r[4]*16384,r[5]*8192
assert len(r)==16+prg+chr==73744
mapper=(r[6]>>4)|(r[7]&0xf0);assert mapper==4 and r[6]&3==3 and r[8]==1
assert r[6]&4==0 and r[7]&12==0
vectors=struct.unpack('<HHH',r[16+prg-6:16+prg]);assert all(0xc000<=v<=0xfff9 for v in vectors)
labels={line.split()[2][1:]:int(line.split()[1],16) for line in Path('build/labels.txt').read_text().splitlines() if len(line.split())==3}
assert vectors==(labels['NMI'],labels['Reset'],labels['IRQ'])
assert r[16+6*8192+(vectors[1]-0xc000)]==0x78
for stage in range(4):
 assert max(r[16+stage*8192:16+stage*8192+3840])<44
 assert len(Path(f'build/world{stage}.bin').read_bytes())==4864
assert set(r[16+5*8192:16+6*8192])=={255}
assert labels['__BSS_RUN__']+labels['__BSS_SIZE__']<=0x800
assert labels['loop_index']<256
manifest=json.loads(Path('build/art-manifest.json').read_text());assert manifest['sprite_tiles']<=256
result={'status':'passed','mapper':mapper,'PRG_bytes':prg,'CHR_bytes':chr,'WRAM_bytes':8192,'battery':True,'mirroring':'vertical','world_banks':4,'sprite_tiles':manifest['sprite_tiles'],'vectors':[f'{v:04X}' for v in vectors],'sha256':hashlib.sha256(r).hexdigest(),'file_bytes':len(r)}
Path('build/static-results.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
