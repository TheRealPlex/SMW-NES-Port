#!/usr/bin/env python3
"""Lossless RGB framebuffer PPM -> PNG; standard library only, no redrawing."""
from pathlib import Path
import struct,zlib

def chunk(kind,data):
 return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
for p in sorted(Path('build').glob('*.ppm')):
 magic,size,maximum,pixels=p.read_bytes().split(b'\n',3)
 assert magic==b'P6' and maximum==b'255'
 w,h=map(int,size.split());assert len(pixels)==w*h*3
 colors=len({pixels[i:i+3] for i in range(0,len(pixels),3)})
 assert colors>=4,(p,'blank screenshot',colors)
 scan=b''.join(b'\0'+pixels[y*w*3:(y+1)*w*3] for y in range(h))
 data=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(scan,9))+chunk(b'IEND',b'')
 p.with_suffix('.png').write_bytes(data)
 print(f'Framebuffer capture: {p.stem}, {w}x{h}, {colors} colors')
