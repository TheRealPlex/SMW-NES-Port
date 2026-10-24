-- Real FCEUX frontend snapshot. Settle rendering at normal speed to avoid the
-- turbo snapshot cache. Does not reconstruct pixels or remap sprite palettes.
return function(path,held)
 emu.speedmode('normal')
 local input={up=false,down=false,left=false,right=false,A=false,B=false,start=false,select=false}
 for k,v in pairs(held or {})do input[k]=v end
 for i=1,6 do joypad.set(1,input);emu.frameadvance() end
 gui.savescreenshotas(path)
 for i=1,2 do joypad.set(1,input);emu.frameadvance() end
 emu.speedmode('maximum')
end
