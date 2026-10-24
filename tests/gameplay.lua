-- Real emulation tests; RAM fixtures isolate mechanics, and are identified below.
local root=assert(os.getenv('SMW_ROOT'))
local symbols={}
for line in io.lines(root..'/build/labels.txt') do
 local addr,name=line:match('^al (%x+) %.([%w_]+)$')
 if addr then symbols[name]=tonumber(addr,16) end
end
local log=assert(io.open(root..'/build/emulator-results.txt','w'))
local failures=0
local function check(name,yes,detail)
 log:write((yes and 'PASS ' or 'FAIL ')..name..' '..(detail or '')..'\n');log:flush()
 if not yes then failures=failures+1 end
end
local function rd(n) return memory.readbyte(assert(symbols[n],n)) end
local function wr(n,v) memory.writebyte(assert(symbols[n],n),v) end
local function word(n) return memory.readword(symbols[n]) end
local function s8(n) local v=rd(n);if v>=128 then return v-256 end;return v end
local trace=assert(io.open(root..'/build/movement.csv','w'))
trace:write('emulator_frame,x,y,vx,vy,camera,grounded\n')
local function frames(n,b)
 for i=1,n do
  joypad.set(1,b or {});emu.frameadvance()
  trace:write(string.format('%d,%d,%d,%d,%d,%d,%d\n',emu.framecount(),word('px'),rd('py'),s8('vx'),s8('vy'),word('camera'),rd('grounded')))
 end
end
local capture=dofile(root..'/tests/capture.lua')
local function shot(n) capture(root..'/build/'..n..'.ppm') end
local worldfile=assert(io.open(root..'/build/world.bin','rb'))
local world=worldfile:read('*a');worldfile:close()
local function check_vram(name)
 local camera=word('camera');local first=math.floor(camera/8)
 local last=first+31+(camera%8>0 and 1 or 0);local mismatches=0
 for col=first,last do
  for row=5,29 do
   local metacol=math.floor(col/2);local metarow=math.floor(row/2)
   local expected=string.byte(world,metacol*15+metarow+1)*4+(col%2)+(row%2)*2
   local address=0x2000+(math.floor(col/32)%2)*0x400+(col%32)+row*32
   if ppu.readbyte(address)~=expected then mismatches=mismatches+1 end
  end
 end
 check(name,mismatches==0,'camera='..camera..' mismatched_tiles='..mismatches)
end
local function enemies_off()
 for i=0,3 do memory.writebyte(symbols.enemy_dead+i,1) end
end
local function place(x,y,cam)
 wr('px',x%256);memory.writebyte(symbols.px+1,math.floor(x/256));wr('py',y)
 wr('px_frac',0);wr('py_frac',0);wr('vx',0);wr('vx_frac',0);wr('vy',0);wr('grounded',0)
 wr('camera',(cam or 0)%256);memory.writebyte(symbols.camera+1,math.floor((cam or 0)/256))
 wr('rebuild',1);wr('invulnerable',0);frames(3)
end
local nmi_start=0;local max_nmi=0
memory.registerexec(symbols.NMI,function() nmi_start=debugger.getcyclescount() end)
memory.registerexec(symbols.NMI_Return,function() max_nmi=math.max(max_nmi,debugger.getcyclescount()-nmi_start) end)
emu.speedmode('maximum')
frames(120)
-- Clear the test save state in RAM so this run must generate a fresh 0->1 save.
wr('completed',0);memory.writebyte(0x6002,0);memory.writebyte(0x6003,255)
check('boot_grounded',rd('grounded')==1 and rd('py')==192,'x='..word('px')..' y='..rd('py'))
local colors={}
for y=0,223,8 do for x=0,255,8 do local r,g,b=emu.getscreenpixel(x,y,true);colors[tostring(r)..','..tostring(g)..','..tostring(b)]=true end end
local count=0;for _ in pairs(colors) do count=count+1 end
check('visible_picture',count>=4,'sampled_colors='..count)
check('early_enemy_present',memory.readbyte(symbols.enemy_dead)==0 and memory.readword(symbols.enemy_x,symbols.enemy_hi)<256)
shot('boot')
-- Physics fixtures: remove enemies, preserve normal controller and game code.
enemies_off();place(40,192,0)
local x0=word('px');frames(45,{right=true})
check('walk_input_speed',word('px')>x0+30 and rd('vx')==20,'x='..word('px')..' vx='..s8('vx'))
local walkx=word('px');frames(25)
check('ground_friction',rd('vx')==0,'vx='..s8('vx')..' drift='..(word('px')-walkx))
place(40,192,0);frames(40,{right=true,B=true})
check('run_faster_than_walk',rd('vx')==36,'vx='..s8('vx'))
frames(30,{left=true,B=true})
check('reverse_acceleration',s8('vx')<0,'vx='..s8('vx'))
place(40,192,0)
local minshort=192
frames(2,{A=true})
for i=1,55 do frames(1);minshort=math.min(minshort,rd('py')) end
check('jump_lands',rd('grounded')==1 and rd('py')==192)
place(40,192,0)
local minlong=192
for i=1,65 do frames(1,i<32 and {A=true} or {});minlong=math.min(minlong,rd('py')) end
check('variable_jump',minlong<minshort-20,'short_apex='..minshort..' held_apex='..minlong)
shot('jump-landing')
-- Brick undersides at world x=160..207, y=160. Head stops below y=176.
place(176,192,0);local minhead=192
for i=1,28 do frames(2,{A=true});minhead=math.min(minhead,rd('py')) end
check('ceiling_collision',minhead>=176,'minimum_y='..minhead)
-- Pipe side x=368..399, top y=176.
place(336,192,224);frames(40,{right=true,B=true})
check('solid_wall',word('px')<=354,'x='..word('px'))
-- Jump lands on pipe top (a 32px obstacle).
place(376,130,224);frames(30)
check('platform_landing',rd('py')==160 and rd('grounded')==1,'x='..word('px')..' y='..rd('py'))
-- Safe level segment 800..975. Cross nametable boundary and then backtrack.
place(800,192,656);frames(40,{right=true,B=true})
local ahead=word('camera');shot('scroll-right');check_vram('vram_after_forward_scroll')
frames(90,{left=true,B=true})
check('bidirectional_camera',ahead>656 and word('camera')<ahead,'ahead='..ahead..' back='..word('camera'))
shot('scroll-left');check_vram('vram_after_backward_scroll')
-- Pause via real button edge.
local before=word('px');frames(1,{start=true});frames(12,{right=true})
check('pause',rd('paused')==1 and word('px')==before)
frames(1,{start=true});frames(1)
check('unpause',rd('paused')==0)
-- Checkpoint and fall use a RAM positioning fixture; respawn is actual game code.
place(1056,192,912);frames(2)
check('checkpoint_activates',rd('checkpoint')==1)
place(1456,220,1320);local deaths=rd('deaths');frames(20)
check('checkpoint_respawn',rd('deaths')==deaths+1 and word('px')==1024 and word('camera')==880 and rd('py')==192)
frames(30,{left=true,B=true,A=true});frames(25,{left=true,B=true})
check('reverse_after_checkpoint',word('px')<1024 and word('camera')<880,'x='..word('px')..' camera='..word('camera'))
shot('checkpoint');check_vram('vram_after_checkpoint_return')
-- Entity stomp, side damage and offscreen persistence fixtures.
enemies_off();place(640,169,496)
memory.writebyte(symbols.enemy_dead+1,0);memory.writebyte(symbols.enemy_x+1,128);memory.writebyte(symbols.enemy_hi+1,2)
wr('vy',32);frames(8)
check('enemy_stomp',memory.readbyte(symbols.enemy_dead+1)==1)
enemies_off();place(640,192,496)
memory.writebyte(symbols.enemy_dead+1,0);memory.writebyte(symbols.enemy_x+1,130);memory.writebyte(symbols.enemy_hi+1,2)
wr('invulnerable',0);deaths=rd('deaths');frames(3)
check('enemy_side_damage',rd('deaths')==deaths+1)
frames(2);enemies_off();place(40,192,0)
memory.writebyte(symbols.enemy_dead+3,0);memory.writebyte(symbols.enemy_x+3,112);memory.writebyte(symbols.enemy_hi+3,6)
frames(10)
check('offscreen_entity_not_destroyed',memory.readbyte(symbols.enemy_dead+3)==0)
place(1600,192,1456);frames(10)
check('entity_reappears_on_return',memory.readbyte(symbols.enemy_dead+3)==0 and memory.readbyte(0x0211)==12)
-- World edges must reverse walkers rather than wrap unsigned positions.
enemies_off();place(100,192,0)
memory.writebyte(symbols.enemy_dead,0);memory.writebyte(symbols.enemy_x,0);memory.writebyte(symbols.enemy_hi,0);memory.writebyte(symbols.enemy_dir,0)
frames(8)
check('enemy_left_world_boundary',memory.readbyte(symbols.enemy_hi)==0 and memory.readbyte(symbols.enemy_x)<16 and memory.readbyte(symbols.enemy_dir)==1)
enemies_off();place(1900,192,1756)
memory.writebyte(symbols.enemy_dead,0);memory.writebyte(symbols.enemy_x,240);memory.writebyte(symbols.enemy_hi,7);memory.writebyte(symbols.enemy_dir,1)
frames(8)
check('enemy_right_world_boundary',memory.readbyte(symbols.enemy_hi)==7 and memory.readbyte(symbols.enemy_x)<=240 and memory.readbyte(symbols.enemy_dir)==0)
-- Goal sets a persistent completion byte; second emulator process verifies it.
enemies_off();wr('completed',0);place(1968,192,1792);frames(5)
check('goal_sets_progress',rd('completed')==1 and memory.readbyte(0x6002)==1 and memory.readbyte(0x6003)==254)
shot('goal');check_vram('vram_final_screen')
-- Long idle soak (on safe end area, completion state persists).
local startframe=rd('frame');frames(3600)
check('soak_3600_frames',rd('grounded')==1 and rd('py')==192 and rd('frame')~=startframe)
check('nmi_cycle_budget',max_nmi>500 and max_nmi<2000,'max_cycles_to_RTI='..max_nmi)
log:write('FAILURES '..failures..'\n');trace:close();log:close();emu.exit()
