local root=assert(os.getenv('SMW_ROOT'));local s={}
for line in io.lines(root..'/build/labels.txt')do local a,n=line:match('^al (%x+) %.([%w_]+)$');if a then s[n]=tonumber(a,16)end end
local function rd(n)return memory.readbyte(assert(s[n],n))end
local function wr(n,v)memory.writebyte(assert(s[n],n),v)end
local function word(n)return memory.readword(s[n])end
local function ww(n,v)wr(n,v%256);memory.writebyte(s[n]+1,math.floor(v/256))end
local results={};local failed=0
local function check(n,v,detail)results[#results+1]=(v and 'PASS 'or'FAIL ')..n..' '..(detail or'');if not v then failed=failed+1 end end
local function f(n,b)for i=1,n do local a={up=false,down=false,left=false,right=false,A=false,B=false,start=false,select=false};for k,v in pairs(b or{})do a[k]=v end;joypad.set(1,a);emu.frameadvance()end end
local capture=dofile(root..'/tests/capture_frontend.lua')
local function shot(n,b)capture(root..'/build/adventure-'..n..'.png',b)end
local function quiet()
 for i=0,7 do memory.writebyte(s.enemy_dead+i,1);memory.writebyte(s.item_active+i,0)end
 wr('star_timer',0);wr('balloon_timer',0);wr('tongue_timer',0);wr('cape_spin',0);wr('flight_timer',0);wr('yoshi_mounted',0);wr('yoshi_active',0);wr('standing_platform',0);wr('action_cooldown',0)
 wr('bullet_active',0);memory.writebyte(s.bullet_active+1,0);wr('invulnerable',0);wr('lives',50)
end
local function place(x,y,cam)
 ww('px',x);wr('py',y);ww('camera',cam or math.max(0,x-144));wr('px_frac',0);wr('py_frac',0);wr('vx',0);wr('vx_frac',0);wr('vy',0);wr('grounded',0);wr('p_meter',0);wr('air_state',0);wr('rebuild',1);f(4)
end
local function item(kind)
 memory.writebyte(s.item_x,rd('px'));memory.writebyte(s.item_hi,memory.readbyte(s.px+1));memory.writebyte(s.item_y,rd('py'));memory.writebyte(s.item_kind,kind);memory.writebyte(s.item_active,1);f(3)
end
local function vram(name)
 local cam=word('camera');local first=math.floor(cam/8);local last=first+31+(cam%8>0 and 1 or 0);local wrong=0
 for col=first,last do for row=4,29 do
  local mc=math.floor(col/2);local mr=math.floor(row/2)
  local expected=memory.readbyte(0x6800+mc*15+mr)*4+col%2+row%2*2
  local addr=0x2000+math.floor(col/32)%2*0x400+col%32+row*32
  if ppu.readbyte(addr)~=expected then wrong=wrong+1;if wrong<8 then print('VRAMDIFF '..name..' col='..col..' row='..row..' expected='..expected..' got='..ppu.readbyte(addr))end end
 end end
 check(name,wrong==0,'mismatched_tiles='..wrong..' camera='..cam)
end
local max_nmi,start_nmi=0,0
memory.registerexec(s.NMI,function()start_nmi=debugger.getcyclescount()end)
memory.registerexec(s.NMI_Return,function()max_nmi=math.max(max_nmi,debugger.getcyclescount()-start_nmi)end)
emu.speedmode('maximum');f(120)
check('overworld_boot',rd('game_mode')==0)
wr('cleared_levels',0);wr('world_cursor',2);wr('rebuild',1);f(4);f(2,{A=true});f(4)
check('locked_path',rd('game_mode')==0)
wr('world_cursor',1);wr('rebuild',1);f(4);shot('map')
f(2,{A=true});f(90)
check('enter_reference_region',rd('game_mode')==1 and rd('level_index')==1)
check('banked_level_loaded',memory.readbyte(0x6800+13)==1 and memory.readbyte(0x6800+256*15-1)<43)
shot('small')
quiet();place(48,192,0);wr('power',0);item(0)
check('mushroom_transformation',rd('power')==1)
shot('super')
item(1);check('fire_transformation',rd('power')==2 and rd('reserve_item')==1)
f(2,{B=true});f(3)
check('fireball_created',rd('bullet_active')>0 or memory.readbyte(s.bullet_active+1)>0)
shot('fire')
f(2,{select=true});f(2);check('reserve_item_released',rd('reserve_item')==0)
quiet();place(48,192,0);wr('power',1);item(2)
check('feather_transformation',rd('power')==3)
f(2,{B=true});check('cape_spin',rd('cape_spin')>0)
f(20);wr('power',3);f(100,{right=true,B=true})
check('p_meter_real_run',rd('p_meter')==112,'meter='..rd('p_meter')..' x='..word('px'))
f(22,{right=true,B=true,A=true})
check('cape_takeoff',rd('flight_timer')>0 and rd('grounded')==0,'y='..rd('py'))
shot('cape-flight',{right=true,B=true,A=true})
f(8,{A=true,up=true});local up=rd('vy');f(4,{A=true,down=true})
check('cape_pitch_controls',up>=128 and rd('vy')==48,'up='..up..' dive='..rd('vy'))
wr('flight_timer',0);wr('vy',40);f(2,{A=true})
check('cape_glide',rd('vy')<=12)
quiet();place(48,192,0);wr('power',1);wr('yoshi_active',1);ww('yoshi_x',48);wr('yoshi_y',192)
f(2,{up=true});f(2)
check('yoshi_mount',rd('yoshi_mounted')==1)
shot('yoshi')
memory.writebyte(s.enemy_x,90);memory.writebyte(s.enemy_hi,0);memory.writebyte(s.enemy_y,192);memory.writebyte(s.enemy_kind,2);memory.writebyte(s.enemy_dead,0)
f(2,{B=true});f(3)
check('yoshi_tongue_eats',memory.readbyte(s.enemy_dead)==1 and rd('tongue_timer')>0)
shot('tongue')
f(24);f(2,{select=true});f(2)
check('yoshi_dismount',rd('yoshi_mounted')==0 and rd('yoshi_active')==1)
quiet();place(48,192,0);wr('power',1);wr('yoshi_active',1);ww('yoshi_x',48);wr('yoshi_y',192);wr('yoshi_mounted',1)
memory.writebyte(s.enemy_x,49);memory.writebyte(s.enemy_hi,0);memory.writebyte(s.enemy_y,192);memory.writebyte(s.enemy_kind,2);memory.writebyte(s.enemy_dead,0);f(3)
check('yoshi_flees_on_damage',rd('yoshi_mounted')==0 and rd('yoshi_active')==2)
quiet();place(48,192,0);wr('power',0);item(3)
check('star_invincibility',rd('star_timer')>0)
memory.writebyte(s.enemy_x,49);memory.writebyte(s.enemy_hi,0);memory.writebyte(s.enemy_y,192);memory.writebyte(s.enemy_kind,2);memory.writebyte(s.enemy_dead,0);f(3)
check('star_defeats_enemy',memory.readbyte(s.enemy_dead)==1)
local lives=rd('lives');item(4);check('one_up',rd('lives')==lives+1)
item(6);check('p_balloon_lift',rd('balloon_timer')>0 and rd('vy')>=128)
quiet();place(96,192,0);wr('power',0)
-- The first added question block must be hit through the normal jump routine.
local addr=0x6800+6*15+9;memory.writebyte(addr,4);wr('rebuild',1);f(4);f(32,{A=true})
check('interactive_question_block',memory.readbyte(addr)==18)
local active=0;for i=0,7 do if memory.readbyte(s.item_active+i)>0 then active=active+1 end end
check('question_spawns_item',active>0)
quiet();place(2600,96,2456);f(20,{right=true,B=true})
vram('streaming_above_2048_pixels');shot('scroll')
f(70,{left=true,B=true});vram('backtracking_bank_ring')
quiet();wr('power',1);place(128,130,0)
-- Place the moving platform below the feet and let the collision routine land.
memory.writebyte(s.platform_x,128);memory.writebyte(s.platform_hi,0);memory.writebyte(s.platform_y,160);wr('vy',24);f(8)
check('moving_platform_landing',rd('standing_platform')==1)
local before=word('px');f(12);check('moving_platform_carries',word('px')~=before)
quiet();place(1056,192,912);f(10)
check('checkpoint_activates',rd('checkpoint')==1)
local deaths=rd('deaths');place(48,224,0);wr('vy',40);f(8)
check('checkpoint_respawn',rd('deaths')==deaths+1 and rd('checkpoint')==1)
-- Finish the region through actual game code, using only position as fixture.
quiet();place(3984,192,3840);wr('yoshi_active',1);wr('yoshi_mounted',1);ww('yoshi_x',3984);wr('yoshi_y',192);f(4)
check('normal_exit_unlocks_path',rd('game_mode')==2 and rd('cleared_levels')%4>=2)
f(110);check('return_to_overworld',rd('game_mode')==0)
check('yoshi_carried_on_map',rd('carry_yoshi')==1)
f(2,{right=true});f(2);f(2,{A=true});f(40)
check('enter_second_region',rd('level_index')==2 and rd('game_mode')==1)
check('yoshi_carried_into_next_stage',rd('yoshi_mounted')==1)
shot('island2')
quiet();place(3984,192,3840);f(4);f(110);f(2,{right=true});f(2);f(2,{A=true});f(40)
check('enter_castle',rd('level_index')==3 and rd('game_mode')==1)
shot('castle')
quiet();place(1936,192,1792);f(5);f(110)
check('world_progress_saved',rd('cleared_levels')==14 and memory.readbyte(0x6002)==14)
check('vblank_budget',max_nmi<2200 and max_nmi>500,'max_cycles='..max_nmi)
results[#results+1]='FAILURES '..failed
local out=assert(io.open(root..'/build/adventure-results.txt','w'));out:write(table.concat(results,'\n')..'\n');out:close();emu.exit()
