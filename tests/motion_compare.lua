-- Executes the actual NES 6502 routine in FCEUX. Positions/inputs are explicit
-- fixtures; expected numeric traces came from the commercial ROM in Snes9x.
local root=assert(os.getenv('SMW_ROOT'));local sym={}
for line in io.lines(root..'/build/labels.txt') do local a,n=line:match('^al (%x+) %.([%w_]+)$');if a then sym[n]=tonumber(a,16) end end
local cases=dofile(root..'/build/motion-reference.lua')
local function rd(n)return memory.readbyte(assert(sym[n],n)) end
local function wr(n,v)memory.writebyte(assert(sym[n],n),v) end
local function s8(n)local v=rd(n);return v>=128 and v-256 or v end
local current,step,segment,remaining,previous,accum=1,0,1,0,0,0
local pending=false;local done=false;local differences=0;local total=0;local checked=0
local first={};local counts={};local result=assert(io.open(root..'/build/motion-results.txt','w'))
local trace=assert(io.open(root..'/build/nes-motion.csv','w'));trace:write('case,frame,x_accum,y_relative,x_fraction,y_fraction,vx_fraction,vx,vy,p_meter,air_state\n')
local function init()
 wr('px',48);memory.writebyte(sym.px+1,0);wr('py',192);wr('px_frac',0);wr('py_frac',0);wr('vx_frac',0);wr('vx',0);wr('vy',6);wr('grounded',1);wr('facing',0)
 if sym.p_meter then wr('p_meter',0) end;if sym.air_state then wr('air_state',0) end
 wr('invulnerable',255);wr('camera',0);memory.writebyte(sym.camera+1,0)
 for i=0,7 do memory.writebyte(sym.enemy_dead+i,1);memory.writebyte(sym.item_active+i,0) end
 wr('power',0);wr('yoshi_active',0);wr('yoshi_mounted',0);wr('flight_timer',0);wr('balloon_timer',0);wr('star_timer',0)
end
memory.registerexec(sym.UpdatePlayer,function()
 if done then return end
 if pending then
  accum=accum+memory.readword(sym.px)-48
  local air=sym.air_state and rd('air_state') or (rd('grounded')==1 and 0 or (s8('vy')<0 and 11 or 36))
  local row={accum,rd('py')-192,rd('px_frac'),rd('py_frac'),rd('vx_frac'),s8('vx'),s8('vy'),sym.p_meter and rd('p_meter') or 0,air}
  local want=cases[current].rows[step]
  local mismatch=false
  for i=1,#want do checked=checked+1;if row[i]~=want[i] then mismatch=true;differences=differences+1;if not first[current] then first[current]='frame='..step..' field='..i..' expected='..want[i]..' actual='..row[i] end end end
  counts[current]=(counts[current] or 0)+(mismatch and 1 or 0);total=total+1
  trace:write(cases[current].name..','..step..','..table.concat(row,',')..'\n')
  if step==#cases[current].rows then
   result:write((counts[current]==0 and 'PASS ' or 'FAIL ')..cases[current].name..' mismatched_frames='..counts[current]..'/'..step..' '..(first[current] or '')..'\n');result:flush()
   current=current+1;step=0;segment=1;remaining=0;previous=0;accum=0;pending=false
   if current>#cases then done=true;wr('paused',1);return end
  end
 end
 if not pending then init();pending=true end
 if remaining==0 then remaining=cases[current].segments[segment][1];segment=segment+1 end
 local buttons=cases[current].segments[segment-1][2]
 wr('px',48);memory.writebyte(sym.px+1,0)
 wr('buttons',buttons);wr('pressed',(buttons>=128 and previous<128) and 128 or 0)
 previous=buttons;remaining=remaining-1;step=step+1
end)
emu.speedmode('maximum')
for i=1,4000 do
 if done then break end
 if rd('game_mode')==0 then wr('world_cursor',1) end
 joypad.set(1,{A=(i==60 or i==61),B=false,right=false,left=false,start=false,select=false,up=false,down=false})
 emu.frameadvance()
end
memory.registerexec(sym.UpdatePlayer,nil)
result:write('TOTAL frames='..total..' compared_values='..checked..' differing_values='..differences..' complete='..tostring(done)..'\n');result:close();trace:close();emu.exit()
