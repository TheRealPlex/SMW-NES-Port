#!/usr/bin/env python3
"""Read documented SNES internal headers; never extract game assets."""
from pathlib import Path
import argparse,hashlib,zlib,json,sys
p=argparse.ArgumentParser();p.add_argument('rom',type=Path);p.add_argument('--output',type=Path);a=p.parse_args()
b=a.rom.read_bytes();extra=512 if len(b)%0x8000==512 else 0;r=b[extra:]
candidates=[]
for name,offset,mode in [('LoROM',0x7fc0,0x20),('HiROM',0xffc0,0x21),('ExHiROM',0x40ffc0,0x25)]:
    h=r[offset:offset+64]
    if len(h)<64:continue
    check=int.from_bytes(h[30:32],'little');complement=int.from_bytes(h[28:30],'little')
    score=int(h[21]&0x2f==mode)*3+int(check^complement==0xffff)*3+int(all(32<=v<127 for v in h[:21]))*2
    candidates.append((score,name,offset,h))
score,name,offset,h=max(candidates)
check=int.from_bytes(h[30:32],'little');complement=int.from_bytes(h[28:30],'little')
power2=len(r)>0 and len(r)&(len(r)-1)==0
out={'source_name':a.rom.name,'file_bytes':len(b),'payload_bytes':len(r),'copier_header_bytes':extra,
'sha256':hashlib.sha256(b).hexdigest(),'crc32':f'{zlib.crc32(b):08X}',
'mapping':name,'internal_header_offset':f'0x{offset:06X}','title':h[:21].decode('ascii',errors='replace').rstrip(),
'map_mode':f'0x{h[21]:02X}','cartridge_type':h[22],'declared_rom_bytes':1024<<h[23],
'declared_sram_bytes':(1024<<h[24]) if h[24] else 0,'destination_code':h[25],
'region':{0:'Japan',1:'North America (USA/Canada)',2:'Europe'}.get(h[25],'Other/unknown'),
'revision_byte':h[27],'revision':f'{h[27]} (internal metadata)',
'checksum':f'{check:04X}','checksum_complement':f'{complement:04X}',
'checksum_pair_valid':check^complement==0xffff,'checksum_calculated':f'{sum(r)&65535:04X}' if power2 else None,
'checksum_matches':check==(sum(r)&65535) if power2 else None,
'declared_size_matches':len(r)==1024<<h[23],
'reset_vector':f'0x{int.from_bytes(h[60:62],"little"):04X}',
'limits':'Header/checksum consistency is not proof of an unmodified dump; no external trusted hash database comparison was performed.',
'sources':['https://snes.nesdev.org/wiki/ROM_header','https://snes.nesdev.org/wiki/ROM_file_formats']}
s=json.dumps(out,indent=2,ensure_ascii=False)+'\n'
if a.output:a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(s)
print(s)
if not(out['checksum_pair_valid'] and out['checksum_matches'] and out['declared_size_matches']):sys.exit(1)
