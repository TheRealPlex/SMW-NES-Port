#!/usr/bin/env python3
"""Generate original NES 2bpp art and column-major level data. No SNES inputs."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build'; OUT.mkdir(exist_ok=True)
level=json.loads((ROOT/'levels/test_level.json').read_text())
W,H=level['width'],level['height']
world=[[0]*H for _ in range(W)]
for x in range(W):
    if not any(a<=x<b for a,b in level['gaps']):
        world[x][13:]=[1,2]
for x,y,w,h,t in level['rectangles']:
    for a in range(x,x+w):
        for b in range(y,y+h): world[a][b]=t if b==y else (6 if t==5 else t)
for x in range(3,W-2,9):
    for a in range(2): world[x+a][3+(x%3)]=8
# Scenic bushes occupy air only; no collision.
for x in range(5,W-2,7):
    if world[x][12]==0: world[x][12]=9
world[64][12]=11
for y in range(7,13): world[123][y]=10

def tile(rows):
    a=[int(c) for row in rows for c in row]
    assert len(a)==64
    return bytes([sum(((a[y*8+x]>>bit)&1)<<(7-x) for x in range(8)) for bit in range(2) for y in range(8)])
def split16(rows):
    assert len(rows)==16 and all(len(r)==16 for r in rows)
    return b''.join(tile([r[x:x+8] for r in rows[y:y+8]]) for y,x in [(0,0),(0,8),(8,0),(8,8)])
blank=['0'*16]*16
art=[blank]
art += [[('2222222222222222' if y==0 else '1212121212121212' if y==1 else '3333333333333333' if y<4 else ''.join('1' if (x*3+y*5)%23==0 else '3' for x in range(16))) for y in range(16)]]
art += [[ ''.join('1' if (x*3+y*5)%23==0 else '3' for x in range(16)) for y in range(16)]]
art += [[ ''.join('1' if y%8==0 or (x+(8 if y>=8 else 0))%8==0 else '3' for x in range(16)) for y in range(16)]]
art += [[ '1111111111111111' if y in (0,15) else '1333333333333331' if y not in (3,4,7,8,11) else '1333331133333331' for y in range(16)]]
art += [[ '1111111111111111' if y in (0,3,15) else '1222222222222231' for y in range(16)]]
art += [[ '0122222222222310' for _ in range(16)]]
art += [[ '1111111111111111' if y in (0,15) else '1333333333333331' if y in (1,14) else '1311111111111131' for y in range(16)]]
art += [[ ''.join('3' if ((x-5)**2+(y-9)**2<34 or (x-10)**2+(y-9)**2<22) else '0' for x in range(16)) for y in range(16)]]
art += [[ ''.join('2' if (x-8)**2+(y-15)**2<85 else '0' for x in range(16)) for y in range(16)]]
art += [[ '0000000110000000' if y>6 else '0000000122222200' for y in range(16)]]
art += [[ '0000111111110000' if y in (2,10) else '0000133333310000' if 2<y<10 else '0000000110000000' for y in range(16)]]
bg=b''.join(split16(a) for a in art)
# A small handcrafted 5x7 alphabet. Foreground 3 on sky 0.
font={
'A':['01110','10001','10001','11111','10001','10001','10001'],
'B':['11110','10001','10001','11110','10001','10001','11110'],
'C':['01111','10000','10000','10000','10000','10000','01111'],
'D':['11110','10001','10001','10001','10001','10001','11110'],
'E':['11111','10000','10000','11110','10000','10000','11111'],
'F':['11111','10000','10000','11110','10000','10000','10000'],
'G':['01111','10000','10000','10111','10001','10001','01110'],
'H':['10001','10001','10001','11111','10001','10001','10001'],
'I':['11111','00100','00100','00100','00100','00100','11111'],
'J':['00111','00010','00010','00010','10010','10010','01100'],
'K':['10001','10010','10100','11000','10100','10010','10001'],
'L':['10000','10000','10000','10000','10000','10000','11111'],
'M':['10001','11011','10101','10101','10001','10001','10001'],
'N':['10001','11001','11001','10101','10011','10011','10001'],
'O':['01110','10001','10001','10001','10001','10001','01110'],
'P':['11110','10001','10001','11110','10000','10000','10000'],
'Q':['01110','10001','10001','10001','10101','10010','01101'],
'R':['11110','10001','10001','11110','10100','10010','10001'],
'S':['01111','10000','10000','01110','00001','00001','11110'],
'T':['11111','00100','00100','00100','00100','00100','00100'],
'U':['10001','10001','10001','10001','10001','10001','01110'],
'V':['10001','10001','10001','10001','10001','01010','00100'],
'W':['10001','10001','10001','10101','10101','11011','10001'],
'X':['10001','10001','01010','00100','01010','10001','10001'],
'Y':['10001','10001','01010','00100','00100','00100','00100'],
'Z':['11111','00001','00010','00100','01000','10000','11111']}
bg=bg.ljust(64*16,b'\0')
for i in range(26): bg+=tile(['0'+r.replace('1','3')+'00' for r in font[chr(65+i)]]+['00000000'])
bg=bg.ljust(4096,b'\0')
# Original 16x16 hero, idle / step / airborne. Palette 1=red,2=skin,3=blue.
hero=['0000111111000000','0001111111110000','0003332223200000','0032222223220000','0032222222223000','0002222222330000','0000011111000000','0001131131100000','0011131131110000','0221133331122000','0220333333022000','0000333333000000','0000330033000000','0000330033000000','0003330033300000','0003330033300000']
step=hero[:12]+['0000333333000000','0000333333300000','0003330000330000','0033300000330000']
jump=hero[:7]+['0001131131122000','0221131131122000','0221133331100000','0000333333000000','0003333333300000','0033300033300000','0033000003300000','0000000000000000','0000000000000000']
enemy=['0000000000000000','0000000000000000','0000011111000000','0001111111110000','0011111111111000','0111221112211100','0111231112311100','0111111111111100','0111111111111100','0011111111111000','0001111111110000','0000333333300000','0003333333330000','0003330033330000','0033300003333000','0033300003333000']
sprites=b''.join(split16(a) for a in [hero,step,jump,enemy]).ljust(4096,b'\0')
(OUT/'original.chr').write_bytes(bg+sprites)
(OUT/'world.bin').write_bytes(bytes(t for col in world for t in col))
text=['; Generated from levels/test_level.json. Original data.','WorldData: .incbin "build/world.bin"','WorldColLo:']
text+=['.byte '+','.join(f'<(WorldData+{x*15})' for x in range(a,min(a+16,W))) for a in range(0,W,16)]
text+=['WorldColHi:']
text+=['.byte '+','.join(f'>(WorldData+{x*15})' for x in range(a,min(a+16,W))) for a in range(0,W,16)]
text+=['MetaSolid: .byte '+','.join(str(int(i in (1,2,3,4,5,6,7))) for i in range(12))]
(OUT/'level.inc').write_text('\n'.join(text)+'\n')
print('Original CHR: 8192 bytes; level: 1920 bytes')
