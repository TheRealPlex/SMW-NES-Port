; Collision queries and rendering read the same original level data.
.proc ProbeSolid
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
 cmp #8
 bcs @solid
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
 lda WorldColLo,x
 sta ptr
 lda WorldColHi,x
 sta ptr+1
 lda (ptr),y
 tax
 lda MetaSolid,x
 rts
@air: lda #0
 rts
@solid: lda #1
 rts
.endproc

; Input column_index is a world tile column (8px). 512px nametable ring.
.proc PrepareColumn
 lda column_index
 and #31
 sta column_addr
 lda column_index
 and #32
 lsr a
 lsr a
 lsr a
 ora #$20
 sta column_addr+1
 lda column_index
 lsr a
 tax
 lda WorldColLo,x
 sta ptr
 lda WorldColHi,x
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
 ; In-world signs scroll naturally and regenerate when backtracking.
 lda column_index
 sec
 sbc #2
 bcc @done
 tax
 cpx #26
 bcs @done
 lda TitleText,x
 sta column_buffer+1
 lda HintText,x
 sta column_buffer+2
@done:
 lda #1
 sta column_pending
 rts
.endproc
TitleText: .byte 82,76,86,0,79,71,88,82,72,66,82,0,75,64,65,0,0,0,0,0,0,0,0,0,0,0
HintText: .byte 64,0,73,84,76,79,0,65,0,81,84,77,0,82,83,64,81,83,0,79,64,84,82,68,0,0

.proc UploadColumn
 ; 30 bytes * ~14 cycles, plus addressing. Only called in VBlank/forced blank.
 lda #$8C
 sta PPUCTRL
 bit PPUSTATUS
 lda column_addr+1
 sta PPUADDR
 lda column_addr
 sta PPUADDR
 ldx #0
@loop:
 lda column_buffer,x
 sta PPUDATA
 inx
 cpx #30
 bne @loop
 rts
.endproc
.proc BuildInitialScreen
 ; Rendering off: initialize both nametables, including attributes.
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
 ; Align first streamed tile to the left edge. Populate 64 tile columns.
 jsr CameraTileColumn
 sta old_coarse
 sta column_index
 lda #64
 sta saved_y
@columns:
 jsr PrepareColumn
 jsr UploadColumn
 inc column_index
 dec saved_y
 bne @columns
 lda #0
 sta column_pending
 rts
.endproc

.proc UpdateCamera
 ; Dead zone: right edge x=144, left edge x=96. Never locks reverse scroll.
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
 cmp #7
 bcc @stream
 lda #7
 sta camera+1
 lda #0
 sta camera
@stream:
 jsr CameraTileColumn
 cmp old_coarse
 beq @done
 sta column_index
 ; If coarse moved right, stream right offscreen edge; else left edge.
 sec
 sbc old_coarse
 bmi @back
 lda column_index
 clc
 adc #32
 sta column_index
@back:
 ; Clamp source at last tile. Prevent wrap at the end of the world.
 lda column_index
 pha
 jsr CameraTileColumn
 sta old_coarse
 pla
 sta column_index
 jsr PrepareColumn
@done: rts
.endproc

; Minimal test-course completion save, not a Dinosaur Land progression system.
.proc LoadProgress
 lda $6000
 cmp #$50
 bne @new
 lda $6001
 cmp #$31
 bne @new
 lda $6002
 eor $6003
 cmp #$FF
 bne @new
 lda $6002
 cmp #2
 bcs @new
 sta completed
 rts
@new:
 lda #0
 sta completed
 jmp SaveProgress
.endproc
.proc SaveProgress
 lda #$50
 sta $6000
 lda #$31
 sta $6001
 lda completed
 sta $6002
 eor #$FF
 sta $6003
 rts
.endproc

; Full world coordinate /8, not just the 512px nametable-ring coordinate.
.proc CameraTileColumn
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
