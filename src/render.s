; 16x16 metasprites, 8x8 hardware sprites. Four sprites per actor.
.proc DrawSprites
 lda #$F8
 ldx #0
@hide:
 sta $0200,x
 inx
 inx
 inx
 inx
 bne @hide
 lda #0
 sta oam_index
 lda invulnerable
 beq @hero
 and #4
 bne @enemies
@hero:
 lda px
 sec
 sbc camera
 sta sprite_x
 lda py
 sta sprite_y
 lda #0
 sta sprite_tile
 lda grounded
 beq @jump
 lda vx
 beq @pose
 lda frame
 and #8
 beq @pose
 lda #4
 sta sprite_tile
 jmp @pose
@jump:
 lda #8
 sta sprite_tile
@pose:
 lda #0
 sta sprite_attr
 lda facing
 beq :+
 lda #$40
 sta sprite_attr
:
 lda completed
 beq :+
 inc sprite_attr
 inc sprite_attr
:
 jsr DrawActor
@enemies:
 lda #0
 sta entity_index
@loop:
 ldx entity_index
 lda enemy_dead,x
 bne @skip
 lda enemy_x,x
 sec
 sbc camera
 sta sprite_x
 lda enemy_hi,x
 sbc camera+1
 bne @skip
 lda sprite_x
 cmp #241
 bcs @skip
 lda enemy_y,x
 sta sprite_y
 lda #12
 sta sprite_tile
 lda #1
 sta sprite_attr
 jsr DrawActor
@skip:
 inc entity_index
 lda entity_index
 cmp #4
 bne @loop
 rts
.endproc
.proc DrawActor
 ldx oam_index
 lda sprite_y
 sec
 sbc #1
 sta $0200,x
 sta $0204,x
 clc
 adc #8
 sta $0208,x
 sta $020C,x
 lda sprite_x
 sta $0203,x
 sta $020B,x
 clc
 adc #8
 sta $0207,x
 sta $020F,x
 lda sprite_attr
 sta $0202,x
 sta $0206,x
 sta $020A,x
 sta $020E,x
 and #$40
 beq @normal
 lda sprite_tile
 ora #1
 sta $0201,x
 lda sprite_tile
 sta $0205,x
 ora #3
 sta $0209,x
 lda sprite_tile
 ora #2
 sta $020D,x
 jmp @done
@normal:
 lda sprite_tile
 sta $0201,x
 ora #1
 sta $0205,x
 lda sprite_tile
 ora #2
 sta $0209,x
 ora #1
 sta $020D,x
@done:
 txa
 clc
 adc #16
 sta oam_index
 rts
.endproc
