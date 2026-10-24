-- Controller-only playthrough. Reads state for steering; never writes game RAM.
local root=assert(os.getenv('SMW_ROOT'));local s={}
for line in io.lines(root..'/build/labels.txt')do local a,n=line:match('^al (%x+) %.([%w_]+)$');if a then s[n]=tonumber(a,16)end end
local function rd(n)return memory.readbyte(s[n])end
local function x()return memory.readword(s.px)end
local function step(b)local keys={up=false,down=false,left=false,right=false,A=false,B=false,start=false,select=false};for k,v in pairs(b or{})do keys[k]=v end;joypad.set(1,keys);emu.frameadvance()end
local function tile(wx,wy)
 if wx<0 or wx>=4096 or wy<0 or wy>=240 then return 0 end
 return memory.readbyte(0x6800+math.floor(wx/16)*15+math.floor(wy/16))
end
local function solid(wx,wy)
 local t=tile(wx,wy)
 return t==1 or t==2 or t==4 or (t>=5 and t<=9) or t==18 or t==19 or t==20 or t==26 or t==28
end
emu.speedmode('maximum');emu.poweron()
for i=1,120 do step()end
-- Last test saved cursor=3. Move to the first stage through the actual menu.
for i=1,4 do step({left=true});step()end
-- Collect the house supplies and mount Yoshi using buttons only.
step({A=true});for i=1,40 do step()end
for i=1,220 do if x()>=180 then break end;step({right=true})end
step({up=true});step({up=true});step()
for i=1,160 do if rd('game_mode')==0 then break end;step({right=true})end
step();step({right=true});step();step({A=true});for i=1,80 do step()end
step({select=true});step() -- Dismount; this run uses the collected cape.
local lines={'frame,x,y,deaths,A'};local hold=0;local release=0;local stuck=0;local retreat=0;local lastx=-1;local maxx=0;local success=false
for i=1,6000 do
 local px,py=x(),rd('py');maxx=math.max(maxx,px)
 local floor=false
 for y=py+18,math.min(239,py+56),8 do if solid(px+56,y)then floor=true end end
 local danger=solid(px+32,py+7) or solid(px+64,py-12) or not floor
 for e=0,7 do
  if memory.readbyte(s.enemy_dead+e)==0 then
   local ex=memory.readbyte(s.enemy_x+e)+256*memory.readbyte(s.enemy_hi+e)
   if ex>px+4 and ex<px+72 then danger=true end
  end
 end
 if px==lastx then stuck=stuck+1 else stuck=0 end;lastx=px
 if stuck>45 then retreat=24;stuck=0;hold=0 end
 if release>0 then release=release-1 end
 if rd('grounded')==1 and hold==0 and release==0 and danger and retreat==0 then hold=38 end
 local jump=hold>0 or (rd('power')==3 and rd('grounded')==0);if hold>0 then hold=hold-1;if hold==0 then release=3 end end
 if retreat>0 then retreat=retreat-1;step({left=true,B=true}) else step({right=true,B=true,A=jump})end
 lines[#lines+1]=string.format('%d,%d,%d,%d,%d',i,x(),rd('py'),rd('deaths'),jump and 1 or 0)
 if rd('game_mode')==2 then success=true;break end
 if rd('game_mode')==0 then break end
end
local trace=assert(io.open(root..'/build/adventure-traversal.csv','w'));trace:write(table.concat(lines,'\n')..'\n');trace:close()
local out=assert(io.open(root..'/build/traversal-results.txt','w'));out:write((success and 'PASS 'or'FAIL ')..'controller_only_first_stage max_x='..maxx..' deaths='..rd('deaths')..' power='..rd('power')..' mounted='..rd('yoshi_mounted')..'\n');out:close();emu.exit()
