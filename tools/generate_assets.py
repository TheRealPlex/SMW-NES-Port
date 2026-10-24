#!/usr/bin/env python3
"""Hand-redrawn NES pixel art + native level/world data. No ROM assets copied."""
from pathlib import Path
import json,runpy
R=Path(__file__).resolve().parents[1];O=R/'build';O.mkdir(exist_ok=True)
font=runpy.run_path(str(R/'assets/font.py'))['font']
font.update(dict(zip('0123456789',[
['01110','10001','10011','10101','11001','10001','01110'],['00100','01100','00100','00100','00100','00100','01110'],['01110','10001','00001','00110','01000','10000','11111'],['11110','00001','00001','01110','00001','00001','11110'],['00010','00110','01010','10010','11111','00010','00010'],['11111','10000','10000','11110','00001','00001','11110'],['01110','10000','10000','11110','10001','10001','01110'],['11111','00001','00010','00100','01000','01000','01000'],['01110','10001','10001','01110','10001','10001','01110'],['01110','10001','10001','01111','00001','00001','01110']
])))
class Art:
 def __init__(self,w=16,h=16):self.w=w;self.h=h;self.p=[[0]*w for _ in range(h)]
 def dot(self,x,y,c):
  if 0<=x<self.w and 0<=y<self.h:self.p[y][x]=c
 def rect(self,x,y,w,h,c):
  for yy in range(y,y+h):
   for xx in range(x,x+w):self.dot(xx,yy,c)
 def ellipse(self,x,y,w,h,c):
  for yy in range(y,y+h):
   for xx in range(x,x+w):
    if ((xx-x+.5-w/2)/(w/2))**2+((yy-y+.5-h/2)/(h/2))**2<=1:self.dot(xx,yy,c)
 def line(self,x,y,xx,yy,c):
  n=max(abs(xx-x),abs(yy-y),1)
  for i in range(n+1):self.dot(round(x+(xx-x)*i/n),round(y+(yy-y)*i/n),c)
 def clone(self):
  a=Art(self.w,self.h);a.p=[r[:] for r in self.p];return a

def tile(p):
 return bytes(sum(((p[y][x]>>bit)&1)<<(7-x) for x in range(8)) for bit in range(2) for y in range(8))
def split(a):return [tile([r[x:x+8] for r in a.p[y:y+8]]) for y in range(0,a.h,8) for x in range(0,a.w,8)]
# Metatiles: palette 0=earth/grass; 1=distant greens; 2=yellow objects;
# palette 3=red/white HUD and roofs. Attributes select real NES 16px quadrants.
arts=[];pals=[];solids=[]
def meta(a,p=0,s=0):arts.append(a);pals.append(p);solids.append(s)
meta(Art())
def dirt(top=False):
 a=Art();a.rect(0,0,16,16,3)
 for x,y in [(3,7),(11,10),(6,14)]:a.dot(x,y,1);a.dot(x+1,y,1)
 if top:
  a.rect(0,0,16,1,1);a.rect(0,1,16,3,2)
  for x in range(1,16,4):a.line(x,3,x+1,5,2);a.dot(x+1,6,1)
 return a
meta(dirt(True),0,1);meta(dirt(),0,1)
a=Art();a.rect(0,0,16,16,1);a.rect(1,1,14,6,3);a.rect(1,9,14,6,3);a.line(8,1,8,6,1);a.line(4,9,4,14,1);a.line(12,9,12,14,1);meta(a,2,1)
a=Art();a.rect(1,0,14,16,1);a.rect(0,1,16,14,1);a.rect(2,2,12,12,2);a.line(3,2,12,2,3);a.rect(6,4,4,2,1);a.dot(10,6,1);a.rect(7,7,3,2,1);a.dot(7,11,1);a.dot(7,12,3);meta(a,2,1)
# Pipe: separate left/right top and shaft metatiles, bright rim and outline.
for right,cap in [(False,True),(True,True),(False,False),(True,False)]:
 a=Art();a.rect(0,0,16,16,2)
 a.rect(15 if right else 0,0,1,16,1);a.rect(13 if right else 2,0,2,16,3)
 if cap:a.rect(0,0,16,1,1);a.rect(1,1,14,2,3);a.rect(0,6,16,1,1)
 else:a.rect(0 if right else 14,0,2,16,1)
 meta(a,0,1)
a=Art();a.rect(0,0,16,16,1);a.rect(1,1,14,14,3);a.line(2,2,13,2,2);a.line(2,2,2,13,2);a.dot(13,13,1);meta(a,2,1)
# 10-15: backdrop hills (left, middle, right, eye/bottom), bush, clouds.
for kind in range(6):
 a=Art()
 if kind<3:
  if kind==0:
   for y in range(16):a.rect(15-y//2,y,y//2+1,1,2);a.dot(14-y//2,y,1)
  elif kind==2:
   for y in range(16):a.rect(0,y,y//2+1,1,2);a.dot(y//2+1,y,1)
  else:a.rect(0,0,16,16,2);a.line(4,2,4,15,3)
 elif kind==3:a.rect(0,0,16,16,2);a.ellipse(3,4,3,7,1);a.ellipse(10,4,3,7,1);a.dot(3,4,3);a.dot(10,4,3)
 elif kind==4:a.ellipse(0,5,16,15,1);a.ellipse(1,5,14,12,2);a.line(3,8,5,6,3);a.line(10,7,12,9,3)
 else:a.ellipse(0,6,12,8,3);a.ellipse(6,3,10,11,3)
 meta(a,1 if kind<5 else 2,0)
# 16: midpoint sign, 17: coin, 18: used block, 19/20: slope.
a=Art();a.rect(2,0,2,16,1);a.rect(12,0,2,16,1);a.rect(4,4,8,3,3);a.rect(4,7,8,2,2);meta(a,2)
a=Art();a.ellipse(4,1,8,14,1);a.ellipse(5,2,6,12,2);a.line(7,3,7,11,3);a.line(8,3,8,11,1);meta(a,2)
a=Art();a.rect(1,0,14,16,1);a.rect(0,1,16,14,1);a.rect(2,2,12,12,2);a.dot(3,3,1);a.dot(12,3,1);a.dot(3,12,1);a.dot(12,12,1);meta(a,2,1)
for down in (False,True):
 a=dirt()
 for y in range(16):
  for x in range(16):
   surface=x if down else 15-x
   if y<surface:a.dot(x,y,0)
   elif y==surface:a.dot(x,y,1)
   elif y<surface+4:a.dot(x,y,2)
 meta(a,0,2 if not down else 3)
# 21 map water; 22 path; 23 red roof; 24 checkpoint/goal pole; 25 lava.
a=Art();a.rect(0,0,16,16,1);a.line(1,4,6,4,3);a.line(9,11,14,11,3);a.dot(7,3,3);meta(a,2)
a=Art();a.rect(0,0,16,16,2);a.rect(6,0,4,16,3);a.rect(0,6,16,4,3);meta(a,0)
a=Art()
for y in range(16):a.rect(max(0,7-y),y,min(16,2*y+2),1,3)
a.line(1,14,14,14,1);meta(a,3)
a=Art();a.rect(7,0,2,16,1);a.rect(9,1,6,7,3);a.rect(9,7,5,1,2);meta(a,2)
a=Art();a.rect(0,3,16,13,3)
for x in range(16):a.dot(x,1+(x%4)//2,2);a.dot(x,3,1)
meta(a,3)
# 26 castle stone; 27 castle window; 28 mushroom platform; 29 trunk.
a=Art();a.rect(0,0,16,16,1);a.rect(1,1,14,6,3);a.rect(1,9,14,6,3);a.line(8,1,8,6,1);a.line(4,9,4,14,1);a.line(12,9,12,14,1);meta(a,2,1)
a=arts[26].clone();a.ellipse(4,1,8,14,1);a.rect(4,7,8,9,1);a.line(8,4,8,14,2);meta(a,2,1)
a=Art();a.ellipse(0,0,16,16,3);a.rect(0,8,16,7,3);a.line(0,15,15,15,1);a.rect(3,3,3,4,2);a.rect(11,5,3,4,2);meta(a,3,4)
a=Art();a.rect(5,0,6,16,3);a.line(5,0,5,15,1);a.line(10,0,10,15,1);meta(a,2)
# Background-only wood walls and doorway, with collision-free house frontage.
a=Art();a.rect(0,0,16,16,3)
for y in range(0,16,4):a.line(0,y,15,y,1)
a.rect(5,3,6,10,1);a.rect(6,4,4,8,2);meta(a,0)
a=Art();a.rect(0,0,16,16,3);a.rect(2,0,12,16,1);a.line(3,0,3,15,2);meta(a,0)
assert len(arts)==32
# Thirteen reusable metatiles form a single smooth, round SMW-style hill.
hill=Art(64,112)
for y in range(112):
 for x in range(64):
  inside=y>=32 or (x-31.5)**2+(y-31.5)**2<=32**2
  if not inside:continue
  border=x==0 or x==63 or (y<32 and (x-31.5)**2+(y-31.5)**2>30.5**2)
  hill.dot(x,y,1 if border else 3 if x in (10,11) and y>=24 else 2)
for x in (26,38):hill.rect(x,51,3,8,1);hill.dot(x,51,3)
patterns={};hillgrid=[];available=[10,11,12,13]+list(range(32,41))
for yy in range(7):
 row=[]
 for xx in range(4):
  a=Art();a.p=[r[xx*16:xx*16+16] for r in hill.p[yy*16:yy*16+16]]
  key=tuple(tuple(r) for r in a.p)
  if key not in patterns:
   idx=available[len(patterns)];patterns[key]=idx
   if idx<len(arts):arts[idx]=a;pals[idx]=1;solids[idx]=0
   else:
    while len(arts)<idx:meta(Art(),1)
    meta(a,1)
  row.append(patterns[key])
 hillgrid.append(row)
while len(arts)<41:meta(Art(),1)
a=Art();a.rect(0,0,16,16,2);meta(a,0)
meta(dirt(),0,0)
meta(arts[20].clone(),0,0)
arts[3]=dirt(True);pals[3]=0;solids[3]=0
pals[14]=0
assert len(arts)==44
bg=b''.join(b''.join(split(a)) for a in arts)
# Font tiles 128..163 white; 176..201 red. A..Z,0..9.
bg=bg.ljust(176*16,b'\0')
def letter(ch,color):
 a=Art(8,8)
 for y,row in enumerate(font[ch]):
  for x,v in enumerate(row):
   if v=='1':a.dot(x+2,y+1,1);a.dot(x+1,y,color)
 return tile(a.p)
for ch in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789':bg+=letter(ch,2)
# Blue reserve-item frame, eight native 8x8 tiles at 212..219.
for part in range(8):
 a=Art(8,8)
 if part in (0,1,2):a.line(0,1,7,1,1);a.line(0,2,7,2,2)
 if part in (5,6,7):a.line(0,6,7,6,1);a.line(0,5,7,5,2)
 if part in (0,3,5):a.line(1,0,1,7,1);a.line(2,0,2,7,2)
 if part in (2,4,7):a.line(6,0,6,7,1);a.line(5,0,5,7,2)
 bg+=tile(a.p)
bg=bg.ljust(224*16,b'\0')
for ch in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':bg+=letter(ch,3)
bg=bg.ljust(4096,b'\0')
# Sprites are new, hand-authored pixel drawings. Palette 0 head/red, 1 body.
head=[
'0000011111100000','0000133333310000','0001333233331000','0013333233333100',
'0111111111111110','0011122222111000','0011222221210000','0012222221222100',
'0012222222222210','0011222211122210','0001222111111100','0000122222221000',
'0000012222110000','0000111111100000','0001331113310000','0013331113331000']
body=[
'0011121121111000','0111121121111100','1331122221133310','1331122221133310',
'1331122221133310','0111222222111100','0001222222100000','0001222222100000',
'0001222222100000','0001221122100000','0001221122100000','0001221122100000',
'0011110011110000','0111110011111000','0111110011111000','0011100001110000']
smallbody=['0001331113310000','0013331113331000','0133112211331000','1333122221333100','1331222222133100','0111222222111000','0001221222100000','0001221122100000','0011110011110000','0111110011111000','0111100001111000','0011000000110000']
def ascii_art(rows):
 a=Art(len(rows[0]),len(rows));a.p=[[int(c) for c in r] for r in rows];return a
sprites=[bytes(16)];metas=[];names={}
def sprite(name,a,pal=0,rowpals=None):
 idx=len(metas);names[name]=idx;records=[]
 for yy in range(0,a.h,8):
  for xx in range(0,a.w,8):
   p=[r[xx:xx+8] for r in a.p[yy:yy+8]]
   if not any(any(r) for r in p):continue
   t=len(sprites);sprites.append(tile(p));records.extend((xx,yy,t,rowpals[yy//8] if rowpals else pal))
 metas.append(bytes((a.w,len(records)//4,*records)))
 return idx
for big in (False,True):
 for pose in range(5):
  if big:rows=head+body;rowpals=[0,0,1,1]
  else:rows=head[:12]+smallbody;rowpals=[0,0,1]
  a=ascii_art(rows)
  if pose==1:
   for y in range(a.h-8,a.h):a.p[y]=([0,0]+a.p[y][:-2]) if y<a.h-3 else a.p[y][2:]+[0,0]
  if pose==2:
   for y in range(a.h-8,a.h):a.p[y]=a.p[y][2:]+[0,0]
   a.rect(0,a.h-4,5,3,1);a.rect(11,a.h-8,5,3,1)
  if pose==3: # riding: knees to the sides, no crouched standing legs
   a.rect(0,a.h-9,16,9,0);a.rect(2,a.h-9,12,4,2);a.rect(0,a.h-6,6,3,2);a.rect(10,a.h-6,6,3,2);a.rect(0,a.h-3,6,3,1);a.rect(10,a.h-3,6,3,1)
  if pose==4: # spin / cape attack arms extended
   a.rect(0,16 if big else 12,4,6,3);a.rect(12,16 if big else 12,4,6,3)
  sprite(('BIG_' if big else 'SMALL_')+str(pose),a,rowpals=rowpals)
for pose in range(2):
 a=Art(16,24)
 for y in range(24):
  width=max(4,14-(y//5) + (pose*2 if y>12 else 0))
  a.rect(16-width,y,width,1,1);a.rect(17-width,y,max(1,width-2),1,2)
 a.line(12,1,7,19,3);sprite('CAPE_'+str(pose),a,3)
# Yoshi: bulbous snout, two white eyes, saddle ridge, small arms and orange-like feet.
for pose in range(3):
 a=Art(24,24);a.ellipse(10,0,10,12,1);a.ellipse(11,1,8,10,2)
 a.ellipse(14,0,4,8,3);a.ellipse(18,1,4,7,3);a.rect(16,2,1,4,1);a.rect(20,3,1,3,1)
 a.ellipse(13,7,11,9,1);a.ellipse(14,7,10,7,2);a.dot(21,8,1);a.line(16,13,22,13,1)
 a.ellipse(4,8,13,14,1);a.ellipse(5,9,11,11,2);a.ellipse(9,13,7,8,3)
 a.line(1,14,5,12,1);a.line(0,15,5,15,2);a.rect(5,7,7,3,1);a.rect(6,7,5,2,3)
 a.rect(5 if pose!=1 else 2,20,6,4,1);a.rect(13 if pose!=1 else 15,19,7,4,1)
 a.rect(6 if pose!=1 else 3,20,4,2,3);a.rect(14 if pose!=1 else 16,19,5,2,3)
 if pose==2:a.line(22,12,23,12,3)
 sprite('YOSHI_'+str(pose),a,2)
# Rex / Koopa / Goomba drawn in native 8-bit silhouettes.
for kind in range(3):
 for pose in range(2):
  a=Art(16,24 if kind!=2 else 16)
  if kind==0:
   a.ellipse(3,0,12,14,1);a.ellipse(4,1,10,12,2);a.ellipse(8,1,5,6,3);a.rect(11,2,1,3,1);a.ellipse(7,8,9,6,3)
   a.ellipse(2,11,12,11,1);a.ellipse(3,12,10,9,2);a.ellipse(7,13,6,7,3);a.rect(1+pose*2,21,5,3,1);a.rect(10-pose*2,21,6,3,1)
  elif kind==1:
   a.ellipse(4,0,9,10,1);a.ellipse(5,1,7,8,3);a.rect(9,2,1,4,1);a.ellipse(1,8,14,13,1);a.ellipse(2,9,12,11,2);a.line(7,10,7,18,1);a.line(3,15,12,15,1);a.rect(1+pose,21,6,3,3);a.rect(9-pose,20,6,3,3)
  else:
   a.ellipse(1,1,14,13,1);a.ellipse(2,2,12,10,2);a.rect(3,5,3,4,3);a.rect(10,5,3,4,3);a.dot(5,6,1);a.dot(10,6,1);a.line(4,4,6,5,1);a.line(9,5,12,4,1);a.rect(0+pose,12,7,4,1);a.rect(9-pose,12,7,4,1)
  sprite(['REX','KOOPA','GOOMBA'][kind]+'_'+str(pose),a,2 if kind==1 else 1 if kind==0 else 3)
a=Art();a.ellipse(1,3,14,12,1);a.ellipse(2,4,12,10,2);a.line(7,5,7,11,1);a.line(3,10,12,10,1);a.rect(3,13,10,2,3);sprite('SHELL',a,2)
# Main SMW items, all new native drawings.
for kind in range(7):
 a=Art()
 if kind in (0,4):
  a.ellipse(1,0,14,11,1);a.ellipse(2,1,12,9,2 if kind==4 else 3);a.ellipse(3,2,4,4,3 if kind==4 else 2);a.ellipse(10,3,3,3,3 if kind==4 else 2);a.rect(4,9,8,7,1);a.rect(5,10,6,5,2);a.dot(6,11,1);a.dot(9,11,1)
 elif kind==1:
  a.ellipse(1,0,14,11,1);a.ellipse(2,1,12,9,3);a.ellipse(4,2,8,7,2);a.rect(6,4,1,3,1);a.rect(9,4,1,3,1);a.rect(7,10,2,6,1);a.line(7,13,3,11,2);a.line(8,14,13,11,2)
 elif kind==2:
  a.ellipse(6,0,8,13,1);a.ellipse(7,1,6,11,2);a.line(4,15,11,3,1);a.line(8,7,12,5,3);a.line(7,10,11,8,3)
 elif kind==3:
  for y in range(14):
   width=[2,4,6,16,14,12,10,10,12,12,6,4,2,0][y];a.rect((16-width)//2,y,width,1,1)
  for y in range(2,10):
   w=[2,12,10,8,6,6,8,6][y-2];a.rect((16-w)//2,y,w,1,2)
  a.rect(6,5,1,4,1);a.rect(9,5,1,4,1)
 elif kind==5:
  a.ellipse(2,0,12,16,1);a.ellipse(3,1,10,14,3);a.ellipse(4,3,4,4,2);a.ellipse(9,8,3,4,2)
 else:
  a.ellipse(1,0,14,16,1);a.ellipse(2,1,12,14,2);a.rect(6,3,5,2,1);a.rect(6,5,2,7,1);a.rect(8,6,3,2,1);a.rect(10,4,1,3,1)
 sprite(['MUSHROOM','FLOWER','FEATHER','STAR','ONEUP','EGG','BALLOON'][kind],a,2 if kind in (4,5) else 0 if kind in (0,1) else 3)
a=Art(8,8);a.ellipse(0,0,8,8,1);a.ellipse(1,1,6,6,3);a.ellipse(2,2,4,4,2);sprite('FIREBALL',a,0)
a=Art(8,8);a.rect(0,3,8,2,3);sprite('TONGUE',a,0)
a=Art(32,8);a.rect(0,0,32,8,1);a.rect(1,1,30,5,3)
for x in range(1,31,4):a.rect(x,2,2,3,2)
sprite('PLATFORM',a,0)
assert len(sprites)<=256, len(sprites)
(O/'original.chr').write_bytes(bg+b''.join(sprites).ljust(4096,b'\0'))
# Sprite definitions stay in fixed PRG, art in actual 2bpp CHR ROM.
inc=['; Hand-redrawn metasprites, generated; all pixels are original drawings.']
for k,v in names.items():inc.append(f'SPR_{k} = {v}')
inc+=['MetaSpriteLo: .byte '+','.join('<MS'+str(i) for i in range(len(metas))),'MetaSpriteHi: .byte '+','.join('>MS'+str(i) for i in range(len(metas)))]
for i,b in enumerate(metas):inc.append('MS'+str(i)+': .byte '+','.join(map(str,b)))
(O/'sprites.inc').write_text('\n'.join(inc)+'\n')
# Native regions. The measured geometry is extended with explicit NES mechanics.
ref=json.loads((R/'levels/island1_geometry.json').read_text())['columns']
worlds=[]
for stage in range(4):
 world=[[0]*15 for _ in range(256)]
 for x in range(256):world[x][13:]=[1,2]
 if stage==1:world=[c[:] for c in ref]
 if stage==2:
  for a,b in [(24,28),(61,65),(98,104),(139,144),(183,189),(218,223)]:
   for x in range(a,b):world[x][13:]=[0,0]
  for x,y,w in [(12,10,6),(33,9,6),(49,8,7),(70,10,5),(90,9,7),(112,8,6),(146,10,7),(171,8,6),(198,10,7),(230,9,8)]:
   for xx in range(x,x+w):world[xx][y]=28
   for yy in range(y+1,13):world[x+w//2][yy]=29
 if stage==3:
  for x in range(128):
   world[x][4]=26;world[x][13:]=[26,26]
   if x%12 in (4,5):world[x][5:9]=[27]*4
  for a,b in [(24,30),(58,65),(92,98)]:
   for x in range(a,b):world[x][13:]=[25,25]
  for x,y,w in [(14,10,3),(38,9,3),(72,10,4),(105,9,4)]:
   for xx in range(x,x+w):world[xx][y]=26
 if stage==0:
  for x in range(7,13):world[x][10:13]=[30,30,30]
  for x in range(6,14):world[x][9]=23
  world[9][12]=31;world[10][12]=31
 else:
  for x,t in [(6,0),(23,1),(36,2),(60,3),(88,4),(104,6)]:
   world[x][9]=4
  # Goal is the explicit NES end of this region, not all 20 SNES screens.
  goal=248 if stage in (1,2) else 120
  for y in range(7,13):world[goal][y]=24;world[goal+2][y]=24
  world[goal+1][10]=16
  world[64][12]=16
 # Distant round hills and clouds, using native palette 1.
 if stage!=3:
  for start in range(1,252,10):
   for xx in range(4):
    for yy in range(7):
     x=start+xx;y=6+yy
     if world[x][y]==0:world[x][y]=hillgrid[yy][xx]
  for x in range(4,254,13):
   for xx in range(x,x+2):
    if world[xx][5]==0:world[xx][5]=15
 for x in range(10,248,11):
  for xx in range(x,x+3):
   if world[xx][8]==0:world[xx][8]=17
 worlds.append(world)
# Native level data each lives in a genuine MMC3 8K bank.
for stage,world in enumerate(worlds):
 data=bytes(t for c in world for t in c)
 attr=bytearray()
 for ax in range(128):
  for ay in range(8):
   v=0
   for dy in range(2):
    for dx in range(2):
     y=ay*2+dy;x=ax*2+dx
     p=pals[world[x][y]] if y<15 else 0
     v|=p<<((dy*2+dx)*2)
   attr.append(v)
 (O/f'world{stage}.bin').write_bytes(data+attr)
(O/'world.bin').write_bytes(bytes(t for c in worlds[1] for t in c))
# Generic RAM and ROM attribute pointers; no proprietary level tables.
inc=['LiveColLo:',' .byte '+','.join(f'<(${0x6800+x*15:04X})' for x in range(256)), 'LiveColHi:', ' .byte '+','.join(f'>(${0x6800+x*15:04X})' for x in range(256)), 'AttrColLo:', '.byte '+','.join(f'<(${0x8f00+x*8:04X})' for x in range(128)), 'AttrColHi:', '.byte '+','.join(f'>(${0x8f00+x*8:04X})' for x in range(128)), 'MetaSolid: .byte '+','.join(map(str,solids)), 'MetaPalette: .byte '+','.join(map(str,pals))]
# Map of a small island: sea, grass coast, paths, house, stages and fortress.
mp=[[21]*15 for _ in range(16)]
for y in range(3,13):
 for x in range(2,14):
  if ((x-7.5)/6.5)**2+((y-7.5)/5.5)**2<1:mp[x][y]=41
for x,y in [(4,10),(5,10),(6,10),(7,10),(8,10),(8,9),(8,8),(9,8),(10,8),(11,8),(11,7),(11,6)]:mp[x][y]=22
mp[4][9]=23;mp[4][10]=9;mp[7][10]=17;mp[10][8]=17;mp[11][5]=26;mp[11][6]=27
for x,y in [(4,5),(6,4),(7,6),(10,11),(5,7),(12,9)]:mp[x][y]=14
maptiles=[]
for y in range(30):
 for x in range(32):maptiles.append(mp[x//2][y//2]*4+x%2+(y%2)*2)
mapattr=[]
for ay in range(8):
 for ax in range(8):
  v=0
  for dy in range(2):
   for dx in range(2):
    x=ax*2+dx;y=ay*2+dy;p=pals[mp[x][y]] if y<15 else 0;v|=p<<((dy*2+dx)*2)
  mapattr.append(v)
def texttiles(text,color=False):return [0 if c==' ' else (224 if color else 176)+ord(c)-65 if c.isalpha() else 202+int(c) for c in text]
# Native map title and selected level label, not an in-level lab banner.
for y in list(range(4))+list(range(25,30)):
 for x in range(32):maptiles[y*32+x]=0
for y,text in [(1,'SUPER MARIO WORLD'),(2,'DINOSAUR LAND'),(27,'A ENTER   SELECT ITEM')]:
 ts=texttiles(text);x=(32-len(ts))//2;maptiles[y*32+x:y*32+x+len(ts)]=ts
(O/'map.bin').write_bytes(bytes(maptiles+mapattr))
inc+=['WorldMapData: .incbin "build/map.bin"']
# HUD uses real background tiles, fixed by the MMC3 IRQ split.
hud=[0]*128
for y,x,text,color in [(1,1,'MARIO',True),(1,24,'TIME',False),(2,1,'L05',False),(2,7,'C00',False),(2,16,'P',False),(2,25,'300',False)]:
 ts=texttiles(text,color);hud[y*32+x:y*32+x+len(ts)]=ts
hud[14:17]=[212,213,214]
hud[32+14:32+17]=[215,0,216]
hud[64+14:64+17]=[217,218,219]
inc+=['HudData: .byte '+','.join(map(str,hud))]
inc+=['HudAttributes: .byte $FF,$FF,$FF,$55,$55,$FF,$FF,$FF']
for i,name in enumerate(['YOSHIS HOUSE','YOSHIS ISLAND 1','YOSHIS ISLAND 2','IGGYS CASTLE']):
 ts=texttiles(name);ts=(ts+[0]*24)[:24];inc.append('LevelName'+str(i)+': .byte '+','.join(map(str,ts)))
inc+=['LevelNameLo: .byte '+','.join('<LevelName'+str(i) for i in range(4)), 'LevelNameHi: .byte '+','.join('>LevelName'+str(i) for i in range(4))]
(O/'level.inc').write_text('\n'.join(inc)+'\n')
(O/'art-manifest.json').write_text(json.dumps({'sprite_tiles':len(sprites),'metasprites':names,'background_metatiles':len(arts),'levels':4,'native_world_columns':256},indent=2)+'\n')
print(f'Original pixel art: {len(sprites)}/256 sprite tiles, {len(metas)} metasprites; four MMC3 level banks')
