-- New emulator process: no RAM fixtures and no savestate.
local root=assert(os.getenv('SMW_ROOT'));local s={}
for line in io.lines(root..'/build/labels.txt')do local a,n=line:match('^al (%x+) %.([%w_]+)$');if a then s[n]=tonumber(a,16)end end
emu.speedmode('maximum');for i=1,120 do joypad.set(1,{});emu.frameadvance()end
local ok=memory.readbyte(s.cleared_levels)==14 and memory.readbyte(0x6000)==0x50 and memory.readbyte(0x6001)==0x33 and memory.readbyte(0x6002)==14 and memory.readbyte(0x6003)==241
local out=assert(io.open(root..'/build/persistence-results.txt','w'));out:write((ok and 'PASS 'or'FAIL ')..'save_survives_emulator_close_and_reopen\n');out:close();emu.exit()
