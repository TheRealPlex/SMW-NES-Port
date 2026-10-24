local root=assert(os.getenv('SMW_ROOT'))
local symbols={}
for line in io.lines(root..'/build/labels.txt') do
 local addr,name=line:match('^al (%x+) %.([%w_]+)$')
 if addr then symbols[name]=tonumber(addr,16) end
end
emu.speedmode('maximum')
for i=1,120 do emu.frameadvance() end
local ok=memory.readbyte(symbols.completed)==1 and memory.readbyte(0x6002)==1 and memory.readbyte(0x6003)==254
local f=assert(io.open(root..'/build/persistence-results.txt','w'))
f:write((ok and 'PASS ' or 'FAIL ')..'save_survives_emulator_close_and_reopen\n');f:close()
emu.exit()
