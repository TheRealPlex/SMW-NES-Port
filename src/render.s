; Variable-sized native metasprites. Mario's head/body use distinct palettes.
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
 sta hud_sprite
 lda game_mode
 bne @hero
 ldx world_cursor
 lda MapNodeX,x
 sta sprite_x
 lda MapNodeY,x
 sec
 sbc #24
 sta sprite_y
 lda #SPR_SMALL_0
 sta sprite_id
 lda #0
 sta sprite_flip
 jmp DrawMeta
@hero:
 lda reserve_item
 beq @bodyStart
 sec
 sbc #1
 clc
 adc #SPR_MUSHROOM
 sta sprite_id
 lda #116
 sta sprite_x
 lda #4
 sta sprite_y
 lda #0
 sta sprite_flip
 lda #1
 sta hud_sprite
 jsr DrawMeta
 lda #0
 sta hud_sprite
@bodyStart:
 lda py
 sec
 sbc #8
 sta hero_top
 lda power
 beq :+
 lda py
 sec
 sbc #16
 sta hero_top
:
 lda yoshi_mounted
 beq :+
 lda hero_top
 sec
 sbc #18
 sta hero_top
:
 lda invulnerable
 beq @drawHero
 and #4
 bne @cape
@drawHero:
 lda px
 sec
 sbc camera
 sta sprite_x
 lda hero_top
 sta sprite_y
 lda facing
 sta sprite_flip
 lda #SPR_SMALL_0
 ldx power
 beq :+
 lda #SPR_BIG_0
:
 sta sprite_id
 lda yoshi_mounted
 beq @pose
 lda sprite_id
 clc
 adc #3
 sta sprite_id
 jmp @render
@pose:
 lda cape_spin
 beq @ground
 lda sprite_id
 clc
 adc #4
 sta sprite_id
 jmp @render
@ground:
 lda grounded
 bne @walk
 lda sprite_id
 clc
 adc #2
 sta sprite_id
 jmp @render
@walk:
 lda vx
 beq @render
 lda frame
 and #8
 beq @render
 inc sprite_id
@render:
 jsr DrawMeta
@cape:
 lda power
 cmp #3
 bne @yoshi
 lda px
 sec
 sbc camera
 sec
 sbc #10
 sta sprite_x
 lda facing
 sta sprite_flip
 beq :+
 lda sprite_x
 clc
 adc #20
 sta sprite_x
:
 lda hero_top
 clc
 adc #8
 sta sprite_y
 lda frame
 lsr a
 lsr a
 lsr a
 and #1
 clc
 adc #SPR_CAPE_0
 sta sprite_id
 jsr DrawMeta
@yoshi:
 lda yoshi_active
 jeq @platforms
 lda yoshi_x
 sec
 sbc camera
 sta sprite_x
 lda yoshi_x+1
 sbc camera+1
 bne @platforms
 lda sprite_x
 cmp #233
 bcs @platforms
 lda yoshi_facing
 sta sprite_flip
 lda yoshi_y
 sec
 sbc #8
 sta sprite_y
 lda yoshi_active
 cmp #3
 bne @body
 lda #SPR_EGG
 sta sprite_id
 jsr DrawMeta
 jmp @platforms
@body:
 lda frame
 lsr a
 lsr a
 lsr a
 and #1
 clc
 adc #SPR_YOSHI_0
 sta sprite_id
 lda tongue_timer
 beq :+
 lda #SPR_YOSHI_2
 sta sprite_id
:
 jsr DrawMeta
 lda tongue_timer
 beq @platforms
 lda yoshi_mounted
 beq @platforms
 lda yoshi_x
 sec
 sbc camera
 sta sprite_x
 lda facing
 bne @tongueLeft
 lda sprite_x
 clc
 adc #24
 sta sprite_x
 jmp @tongueY
@tongueLeft:
 lda sprite_x
 sec
 sbc #24
 sta sprite_x
@tongueY:
 lda yoshi_y
 clc
 adc #2
 sta sprite_y
 lda #SPR_TONGUE
 sta sprite_id
 jsr DrawMeta
 lda sprite_x
 clc
 adc #8
 sta sprite_x
 jsr DrawMeta
 lda sprite_x
 clc
 adc #8
 sta sprite_x
 jsr DrawMeta
@platforms:
 lda #0
 sta loop_index
@pnext:
 ldx loop_index
 lda platform_x,x
 sec
 sbc camera
 sta sprite_x
 lda platform_hi,x
 sbc camera+1
 bne @pskip
 lda sprite_x
 cmp #225
 bcs @pskip
 lda platform_y,x
 sta sprite_y
 lda #0
 sta sprite_flip
 lda #SPR_PLATFORM
 sta sprite_id
 jsr DrawMeta
@pskip:
 inc loop_index
 lda loop_index
 cmp #2
 bne @pnext
 lda #0
 sta entity_index
@enemies:
 ldx entity_index
 lda enemy_dead,x
 jne @eskip
 lda enemy_x,x
 sec
 sbc camera
 sta sprite_x
 lda enemy_hi,x
 sbc camera+1
 jne @eskip
 lda sprite_x
 cmp #241
 jcs @eskip
 lda enemy_y,x
 sta sprite_y
 lda enemy_dir,x
 eor #1
 and #1
 sta sprite_flip
 lda enemy_kind,x
 cmp #3
 beq @shell
 cmp #4
 beq @shell
 cmp #5
 beq @goomba
 cmp #2
 beq @goomba
 pha
 lda sprite_y
 sec
 sbc #8
 sta sprite_y
 pla
 cmp #1
 beq @koopa
 lda #SPR_REX_0
 jmp @anim
@koopa:lda #SPR_KOOPA_0
 jmp @anim
@goomba:lda #SPR_GOOMBA_0
@anim:
 sta sprite_id
 lda frame
 and #16
 beq @edraw
 inc sprite_id
 jmp @edraw
@shell:
 lda #SPR_SHELL
 sta sprite_id
@edraw:
 jsr DrawMeta
@eskip:
 inc entity_index
 lda entity_index
 cmp #8
 jcc @enemies
 lda #0
 sta item_index
@items:
 ldx item_index
 lda item_active,x
 beq @iskip
 lda item_x,x
 sec
 sbc camera
 sta sprite_x
 lda item_hi,x
 sbc camera+1
 bne @iskip
 lda sprite_x
 cmp #241
 bcs @iskip
 lda item_y,x
 sta sprite_y
 lda #0
 sta sprite_flip
 lda item_kind,x
 clc
 adc #SPR_MUSHROOM
 sta sprite_id
 jsr DrawMeta
@iskip:
 inc item_index
 lda item_index
 cmp #8
 bne @items
 lda #0
 sta bullet_index
@bullets:
 ldx bullet_index
 lda bullet_active,x
 beq @bskip
 lda bullet_x,x
 sec
 sbc camera
 sta sprite_x
 lda bullet_hi,x
 sbc camera+1
 bne @bskip
 lda bullet_y,x
 sta sprite_y
 lda #SPR_FIREBALL
 sta sprite_id
 jsr DrawMeta
@bskip:
 inc bullet_index
 lda bullet_index
 cmp #2
 bne @bullets
 rts
.endproc
.proc DrawMeta
 ldx sprite_id
 lda MetaSpriteLo,x
 sta ptr
 lda MetaSpriteHi,x
 sta ptr+1
 ldy #0
 lda (ptr),y
 sta meta_width
 iny
 lda (ptr),y
 sta meta_count
 lda #2
 sta meta_offset
@tile:
 lda oam_index
 cmp #252
 jcs @done
 ldy meta_offset
 lda (ptr),y
 sta temp3
 iny
 lda (ptr),y
 clc
 adc sprite_y
 sta temp4
 iny
 lda (ptr),y
 sta sprite_tile
 iny
 lda (ptr),y
 sta meta_pal
 lda temp4
 cmp #240
 bcs @skip
 lda game_mode
 beq @x
 lda hud_sprite
 bne @x
 lda temp4
 cmp #32
 bcc @skip
@x:
 lda sprite_flip
 beq @normal
 lda meta_width
 sec
 sbc #8
 sec
 sbc temp3
 sta temp3
 lda meta_pal
 ora #$40
 sta meta_pal
@normal:
 lda sprite_x
 clc
 adc temp3
 bcs @skip
 ldx oam_index
 sta $0203,x
 lda temp4
 sec
 sbc #1
 sta $0200,x
 lda sprite_tile
 sta $0201,x
 lda meta_pal
 sta $0202,x
 txa
 clc
 adc #4
 sta oam_index
@skip:
 lda meta_offset
 clc
 adc #4
 sta meta_offset
 dec meta_count
 jne @tile
@done:rts
.endproc
