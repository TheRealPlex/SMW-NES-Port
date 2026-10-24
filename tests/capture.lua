-- Exact RGB readback of the emulated framebuffer, with no drawing/overlays.
-- FCEUX's GUI snapshot cache may retain a forced-blank image in turbo mode.
return function(path)
 local f=assert(io.open(path,'wb'));f:write('P6\n256 240\n255\n')
 for y=0,239 do
  local row={}
  for x=0,255 do
   local r,g,b=emu.getscreenpixel(x,y,true)
   row[#row+1]=string.char(r,g,b)
  end
  f:write(table.concat(row))
 end
 f:close()
end
