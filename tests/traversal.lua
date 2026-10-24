-- Controller-only traversal: reads level/player state, never writes game RAM.
local root=assert(os.getenv('SMW_ROOT'));local symbols={}
for line in io.lines(root..'/build/labels.txt') do local a,n=line:match('^al (%x+) %.([%w_]+)$');if a then symbols[n]=tonumber(a,16) end end
local w=assert(io.open(root..'/build/world.bin','rb'));local world=w:read('*a');w:close()
local function rd(n) return memory.readbyte(symbols[n]) end
local function x() return memory.readword(symbols.px) end
local solidtypes={[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true}
local function solid(wx,wy)
 if wx<0 or wx>=2048 or wy<0 or wy>=240 then return false end
 return solidtypes[string.byte(world,math.floor(wx/16)*15+math.floor(wy/16)+1)] or false
end
emu.speedmode('maximum');emu.poweron()
for i=1,120 do joypad.set(1,{});emu.frameadvance() end
local hold=0;local success=false;local maxx=0;local trace=assert(io.open(root..'/build/traversal.csv','w'));trace:write('frame,x,y,deaths,A\n')
for i=1,4000 do
 local px=x();local py=rd('py');maxx=math.max(maxx,px)
 local floor_ahead=false
 for ground_y=py+18,239,8 do if solid(px+30,ground_y) then floor_ahead=true end end
 local danger=solid(px+30,py+8) or not floor_ahead
 for e=0,3 do
  if memory.readbyte(symbols.enemy_dead+e)==0 then
   local ex=memory.readword(symbols.enemy_x+e,symbols.enemy_hi+e)
   if ex>=px+10 and ex<px+48 then danger=true end
  end
 end
 if rd('grounded')==1 and hold==0 and danger then hold=32 end
 local press=hold>0;if hold>0 then hold=hold-1 end
 joypad.set(1,{right=true,B=true,A=press});emu.frameadvance()
 trace:write(string.format('%d,%d,%d,%d,%d\n',i,x(),rd('py'),rd('deaths'),press and 1 or 0))
 maxx=math.max(maxx,x())
 if x()>=1968 then success=true;break end
end
local f=assert(io.open(root..'/build/traversal-results.txt','w'))
f:write((success and 'PASS ' or 'FAIL ')..'controller_only_full_course max_x='..maxx..' deaths='..rd('deaths')..'\n');f:close();trace:close()
gui.savescreenshotas(root..'/build/traversal.png');emu.exit()
