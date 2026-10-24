; All active collision/render tiles are native NES metatiles in live WRAM.
.proc GetProbeTile
 lda probe_y
 cmp #240
 bcs @air
 lsr a
 lsr a
 lsr a
 lsr a
 sta hit_row
 tay
 lda probe_x+1
 cmp #16
 bcs @air
 asl a
 asl a
 asl a
 asl a
 sta temp
 lda probe_x
 lsr a
 lsr a
 lsr a
 lsr a
 ora temp
 sta hit_col
 tax
 lda LiveColLo,x
 sta ptr
 lda LiveColHi,x
 sta ptr+1
 lda (ptr),y
 rts
@air: lda #0
 rts
.endproc
.proc ProbeSolid
 jsr GetProbeTile
 tax
 lda hit_row
 asl a
 asl a
 asl a
 asl a
 sta contact_surface
 lda MetaSolid,x
 beq @air
 cmp #1
 beq @solid
 lda slope_mode
 beq @air
 lda MetaSolid,x
 cmp #4
 beq @platform
 cmp #2
 bne @down
 lda probe_x
 and #15
 eor #15
 jmp @surface
@down:
 lda probe_x
 and #15
@surface:
 clc
 adc contact_surface
 sta contact_surface
 lda probe_y
 cmp contact_surface
 bcc @air
@solid: lda #1
 rts
@platform:
 lda saved_y
 clc
 adc #16
 cmp contact_surface
 bcc @solid
 beq @solid
@air: lda #0
 rts
.endproc
.proc PrepareColumn
 lda column_index
 and #31
 ora #$80
 sta column_addr
 lda column_index
 and #32
 lsr a
 lsr a
 lsr a
 ora #$20
 sta column_addr+1
 lda column_index+1
 lsr a
 lda column_index
 ror a
 tax
 lda LiveColLo,x
 sta ptr
 lda LiveColHi,x
 sta ptr+1
 lda column_index
 and #1
 sta temp2
 ldy #0
 ldx #0
@row:
 lda (ptr),y
 asl a
 asl a
 ora temp2
 sta column_buffer,x
 ora #2
 sta column_buffer+1,x
 inx
 inx
 iny
 cpy #15
 bne @row
 lda column_index+1
 and #1
 lsr a
 lda column_index
 ror a
 lsr a
 tax
 lda AttrColLo,x
 sta ptr
 lda AttrColHi,x
 sta ptr+1
 ldy #7
@attr:
 lda (ptr),y
 sta attribute_buffer,y
 dey
 bpl @attr
 lda column_index
 and #31
 lsr a
 lsr a
 tax
 lda HudAttributes,x
 sta attribute_buffer
 txa
 ora #$C0
 sta attr_addr
 lda column_addr+1
 ora #3
 sta attr_addr+1
 lda #1
 sta column_pending
 rts
.endproc
.proc UploadColumn
 lda #$8C
 sta PPUCTRL
 bit PPUSTATUS
 lda column_addr+1
 sta PPUADDR
 lda column_addr
 sta PPUADDR
 ldx #4
@loop:
 lda column_buffer,x
 sta PPUDATA
 inx
 cpx #30
 bne @loop
 lda #$88
 sta PPUCTRL
 ldx #0
 lda attr_addr
 sta temp3
@attr:
 lda attr_addr+1
 sta PPUADDR
 lda temp3
 sta PPUADDR
 lda attribute_buffer,x
 sta PPUDATA
 lda temp3
 clc
 adc #8
 sta temp3
 inx
 cpx #8
 bne @attr
 rts
.endproc
.proc BuildInitialScreen
 bit PPUSTATUS
 lda #0
 sta PPUCTRL
 lda #$20
 sta PPUADDR
 lda #0
 sta PPUADDR
 ldx #8
 ldy #0
@clear:
 sta PPUDATA
 iny
 bne @clear
 dex
 bne @clear
 jsr CameraTileColumn
 sta old_coarse
 sta column_index
 stx old_coarse+1
 stx column_index+1
 lda #64
 sta loop_index
@columns:
 jsr PrepareColumn
 jsr UploadColumn
 inc column_index
 bne :+
 inc column_index+1
:
 dec loop_index
 bne @columns
 lda #0
 sta column_pending
 jsr DrawHud
 rts
.endproc
.proc DrawHud
 lda #$88
 sta PPUCTRL
 ldx #0
@table:
 txa
 pha
 asl a
 asl a
 ora #$20
 sta PPUADDR
 lda #0
 sta PPUADDR
 ldy #0
@hud:
 lda HudData,y
 sta PPUDATA
 iny
 cpy #128
 bne @hud
 pla
 pha
 asl a
 asl a
 ora #$23
 sta PPUADDR
 lda #$C0
 sta PPUADDR
 ldy #0
@attr:
 lda HudAttributes,y
 sta PPUDATA
 iny
 cpy #8
 bne @attr
 pla
 tax
 inx
 cpx #2
 bne @table
 lda #1
 sta hud_dirty
 rts
.endproc
.proc UploadDirtyTile
 lda #$88
 sta PPUCTRL
 lda dirty_col
 and #15
 asl a
 sta dirty_addr
 lda dirty_row
 and #3
 asl a
 asl a
 asl a
 asl a
 asl a
 asl a
 clc
 adc dirty_addr
 sta dirty_addr
 lda dirty_col
 and #16
 lsr a
 lsr a
 ora #$20
 sta dirty_addr+1
 lda dirty_row
 lsr a
 lsr a
 clc
 adc dirty_addr+1
 sta dirty_addr+1
 lda dirty_tile
 asl a
 asl a
 sta temp3
 bit PPUSTATUS
 lda dirty_addr+1
 sta PPUADDR
 lda dirty_addr
 sta PPUADDR
 lda temp3
 sta PPUDATA
 ora #1
 sta PPUDATA
 lda dirty_addr
 clc
 adc #32
 sta dirty_addr
 lda dirty_addr+1
 adc #0
 sta PPUADDR
 lda dirty_addr
 sta PPUADDR
 lda temp3
 ora #2
 sta PPUDATA
 ora #1
 sta PPUDATA
 rts
.endproc
.proc MarkTileDirty
 ; Caller gives A = new native tile, hit_col/row identify live map cell.
 sta dirty_tile
 sta temp4
 ldx hit_col
 lda LiveColLo,x
 sta ptr
 lda LiveColHi,x
 sta ptr+1
 ldy hit_row
 lda temp4
 sta (ptr),y
 lda hit_col
 sta dirty_col
 lda hit_row
 sta dirty_row
 lda #1
 sta dirty_pending
 rts
.endproc
.proc UpdateCamera
 lda px
 sec
 sbc camera
 sta temp
 lda px+1
 sbc camera+1
 bne @right
 lda temp
 cmp #145
 bcs @right
 cmp #96
 bcc @left
 jmp @stream
@right:
 lda px
 sec
 sbc #144
 sta camera
 lda px+1
 sbc #0
 sta camera+1
 jmp @clamp
@left:
 lda px
 sec
 sbc #96
 sta camera
 lda px+1
 sbc #0
 sta camera+1
 bcs @clamp
 lda #0
 sta camera
 sta camera+1
@clamp:
 lda camera+1
 cmp world_max_hi
 bcc @stream
 bne @end
 lda camera
 beq @stream
@end:
 lda world_max_hi
 sta camera+1
 lda #0
 sta camera
@stream:
 jsr CameraTileColumn
 sta temp4
 stx temp3
 cmp old_coarse
 bne @changed
 cpx old_coarse+1
 beq @done
@changed:
 lda temp4
 sta column_index
 lda temp3
 sta column_index+1
 lda temp4
 sec
 sbc old_coarse
 lda temp3
 sbc old_coarse+1
 bmi @back
 lda column_index
 clc
 adc #32
 sta column_index
 lda column_index+1
 adc #0
 sta column_index+1
@back:
 lda temp4
 sta old_coarse
 lda temp3
 sta old_coarse+1
 jsr PrepareColumn
@done:rts
.endproc
.proc CameraTileColumn
 lda camera+1
 lsr a
 lsr a
 lsr a
 tax
 lda camera+1
 and #7
 asl a
 asl a
 asl a
 asl a
 asl a
 sta temp
 lda camera
 lsr a
 lsr a
 lsr a
 ora temp
 rts
.endproc
