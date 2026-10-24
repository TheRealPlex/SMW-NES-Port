.proc TickAbilities
 lda invulnerable
 beq :+
 dec invulnerable
:
 lda action_cooldown
 beq :+
 dec action_cooldown
:
 lda cape_spin
 beq :+
 dec cape_spin
:
 lda tongue_timer
 beq :+
 dec tongue_timer
:
 lda frame
 and #1
 bne @done
 lda star_timer
 beq :+
 dec star_timer
 lda #1
 sta palette_dirty
:
 lda balloon_timer
 beq @done
 dec balloon_timer
@done:rts
.endproc
.proc ApplyCapeFlight
 lda balloon_timer
 beq @cape
 lda #$F8
 sta vy
 lda buttons
 and #$04
 beq @done
 lda #8
 sta vy
 rts
@cape:
 lda power
 cmp #3
 bne @cancel
 lda yoshi_mounted
 bne @cancel
 lda grounded
 bne @cancel
 lda pressed
 and #BTN_A
 beq @flight
 lda air_state
 cmp #12
 bne @flight
 lda #180
 sta flight_timer
 lda #0
 sta flight_phase
@flight:
 lda flight_timer
 beq @glide
 dec flight_timer
 inc flight_phase
 lda flight_phase
 cmp #16
 bcc @done
 lda buttons
 and #$04
 bne @dive
 lda buttons
 and #$08
 bne @rise
 lda buttons
 and #BTN_A
 beq @glide
 lda flight_phase
 and #32
 beq @lift
 lda #8
 sta vy
 rts
@lift:lda #$F8
 sta vy
 rts
@rise:lda #$E8
 sta vy
 rts
@dive:lda #48
 sta vy
 rts
@glide:
 lda buttons
 and #BTN_A
 beq @done
 lda vy
 bmi @done
 cmp #12
 bcc @done
 lda #12
 sta vy
@done:rts
@cancel:
 lda #0
 sta flight_timer
 rts
.endproc
.proc UpdateAbilities
 lda pressed
 and #BTN_SELECT
 beq @mount
 lda yoshi_mounted
 beq @reserve
 lda #0
 sta yoshi_mounted
 sta tongue_timer
 lda #$C0
 sta vy
 lda #0
 sta grounded
 jmp @mount
@reserve:
 lda reserve_item
 beq @mount
 sec
 sbc #1
 sta temp4
 jsr FindItemSlot
 bcs @mount
 jsr ItemAtPlayer
 lda #0
 sta reserve_item
 lda #1
 sta hud_dirty
@mount:
 lda yoshi_active
 beq @action
 cmp #2
 beq @flee
 lda yoshi_mounted
 beq @tryMount
 lda px
 sta yoshi_x
 lda px+1
 sta yoshi_x+1
 lda py
 sta yoshi_y
 lda facing
 sta yoshi_facing
 jmp @action
@tryMount:
 jsr NearYoshi
 bcc @action
 lda yoshi_active
 cmp #3
 bne @up
 lda #1
 sta yoshi_active
 jsr SoundPower
@up:
 lda pressed
 and #$08
 beq @action
 lda #1
 sta yoshi_mounted
 lda #0
 sta flight_timer
 jsr SoundPower
 jmp @action
@flee:
 lda frame
 and #1
 bne @recover
 inc yoshi_x
 bne @recover
 inc yoshi_x+1
@recover:
 jsr NearYoshi
 bcc @action
 lda pressed
 and #$08
 beq @action
 lda #1
 sta yoshi_mounted
 sta yoshi_active
@action:
 lda pressed
 and #BTN_B
 beq @coins
 lda action_cooldown
 bne @coins
 lda #16
 sta action_cooldown
 lda yoshi_mounted
 beq @power
 lda yoshi_shell
 beq :+
 lda #0
 sta yoshi_shell
 jsr ShootFireball
 jmp @coins
:
 lda #22
 sta tongue_timer
 jsr SoundStomp
 jmp @coins
@power:
 lda power
 cmp #2
 bne @spin
 jsr ShootFireball
 jmp @coins
@spin:
 cmp #3
 bne @coins
 lda #16
 sta cape_spin
 jsr SoundStomp
@coins:
 lda dirty_pending
 bne @hazard
 lda px
 clc
 adc #8
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 lda py
 clc
 adc #6
 sta probe_y
 jsr GetProbeTile
 cmp #17
 bne @hazard
 lda #0
 jsr MarkTileDirty
 jsr AddCoin
@hazard:
 lda px
 clc
 adc #8
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 lda py
 clc
 adc #16
 sta probe_y
 jsr GetProbeTile
 cmp #25
 bne @done
 jmp Die
@done:rts
.endproc
.proc NearYoshi
 lda yoshi_x
 sec
 sbc px
 sta temp
 lda yoshi_x+1
 sbc px+1
 beq @positive
 cmp #$FF
 bne @far
 lda temp
 cmp #$E8
 bcc @far
 jmp @height
@positive:
 lda temp
 cmp #25
 bcs @far
@height:
 lda yoshi_y
 sec
 sbc py
 clc
 adc #24
 cmp #49
 bcs @far
 sec
 rts
@far:clc
 rts
.endproc
.proc HurtPlayer
 lda invulnerable
 ora star_timer
 bne @done
 lda yoshi_mounted
 beq @shrink
 lda #0
 sta yoshi_mounted
 sta tongue_timer
 lda #2
 sta yoshi_active
 lda #100
 sta invulnerable
 jsr SoundHurt
 rts
@shrink:
 lda power
 beq @die
 lda #0
 sta power
 sta cape_spin
 sta flight_timer
 lda #120
 sta invulnerable
 lda #1
 sta palette_dirty
 jsr SoundHurt
@done:rts
@die:jmp Die
.endproc
.proc AddCoin
 inc coins
 lda coins
 cmp #100
 bcc @hud
 lda #0
 sta coins
 inc lives
@hud:
 lda #1
 sta hud_dirty
 jmp SoundCoin
.endproc
.proc FindItemSlot
 ldx #0
@find:
 lda item_active,x
 beq @free
 inx
 cpx #8
 bne @find
 sec
 rts
@free:clc
 rts
.endproc
.proc ItemAtPlayer
 lda temp4
 sta item_kind,x
 lda px
 sta item_x,x
 lda px+1
 sta item_hi,x
 lda py
 sec
 sbc #40
 sta item_y,x
 lda #1
 sta item_active,x
 rts
.endproc
.proc TryBumpBlock
 ldx hit_col
 lda LiveColLo,x
 sta ptr
 lda LiveColHi,x
 sta ptr+1
 ldy hit_row
 lda (ptr),y
 cmp #4
 bne @done
 lda dirty_pending
 bne @done
 lda #18
 jsr MarkTileDirty
 jsr FindItemSlot
 bcs @done
 lda hit_col
 asl a
 asl a
 asl a
 asl a
 sta item_x,x
 lda hit_col
 lsr a
 lsr a
 lsr a
 lsr a
 sta item_hi,x
 lda hit_row
 sec
 sbc #1
 asl a
 asl a
 asl a
 asl a
 sta item_y,x
 lda #1
 sta item_active,x
 lda #0
 sta item_kind,x
 lda hit_col
 cmp #23
 bne :+
 lda #1
 sta item_kind,x
:
 lda hit_col
 cmp #36
 bne :+
 lda #2
 sta item_kind,x
:
 lda hit_col
 cmp #60
 bne :+
 lda #3
 sta item_kind,x
:
 lda hit_col
 cmp #88
 bne :+
 lda #4
 sta item_kind,x
:
 lda hit_col
 cmp #104
 bne :+
 lda #6
 sta item_kind,x
:
 jsr SoundPower
@done:rts
.endproc
.proc InitItems
 ldx #7
 lda #0
@clear:
 sta item_active,x
 dex
 bpl @clear
 lda level_index
 cmp #3
 beq @noYoshi
 lda #3
 sta yoshi_active
 lda #$C0
 sta yoshi_x
 lda #2
 sta yoshi_x+1
 lda #192
 sta yoshi_y
 lda level_index
 bne @done
 lda #1
 sta yoshi_active
 lda #192
 sta yoshi_x
 lda #0
 sta yoshi_x+1
 ldx #5
@house:
 lda HouseItemX,x
 sta item_x,x
 lda #0
 sta item_hi,x
 lda #176
 sta item_y,x
 lda HouseItemKind,x
 sta item_kind,x
 lda #1
 sta item_active,x
 dex
 bpl @house
 rts
@noYoshi:lda #0
 sta yoshi_active
@done:rts
.endproc
HouseItemX: .byte 40,72,104,136,168,208
HouseItemKind: .byte 0,1,2,3,4,6
.proc UpdateItems
 lda #0
 sta item_index
@next:
 ldx item_index
 lda item_active,x
 beq @continue
 lda item_x,x
 sec
 sbc px
 sta temp2
 lda item_hi,x
 sbc px+1
 beq @positive
 cmp #$FF
 bne @continue
 lda temp2
 cmp #$F0
 bcc @continue
 jmp @vertical
@positive:
 lda temp2
 cmp #17
 bcs @continue
@vertical:
 lda item_y,x
 sec
 sbc py
 clc
 adc #24
 cmp #49
 bcs @continue
 lda item_kind,x
 sta temp4
 lda #0
 sta item_active,x
 jsr GiveItem
@continue:
 inc item_index
 lda item_index
 cmp #8
 bne @next
 rts
.endproc
.proc GiveItem
 ; A value in temp4 identifies mushroom/flower/feather/star/1-up/egg/balloon.
 lda temp4
 cmp #3
 bcs @special
 lda power
 beq @new
 cmp #1
 bne @store
 lda temp4
 beq @store
@store:
 lda power
 sta reserve_item
@new:
 lda temp4
 clc
 adc #1
 cmp #1
 bne :+
 ldx power
 bne @hud
:
 sta power
@hud:
 lda #1
 sta hud_dirty
 sta palette_dirty
 jsr SoundPower
 rts
@special:
 cmp #3
 bne @oneup
 lda #255
 sta star_timer
 lda #1
 sta palette_dirty
 jmp SoundPower
@oneup:
 cmp #4
 bne @egg
 inc lives
 lda #1
 sta hud_dirty
 jmp SoundPower
@egg:
 cmp #5
 bne @balloon
 lda #1
 sta yoshi_active
 jmp SoundPower
@balloon:
 lda #200
 sta balloon_timer
 jmp SoundPower
.endproc
.proc ShootFireball
 ldx #0
 lda bullet_active
 beq @free
 inx
 lda bullet_active+1
 bne @done
@free:
 lda #60
 sta bullet_active,x
 lda px
 clc
 adc #8
 sta bullet_x,x
 lda px+1
 adc #0
 sta bullet_hi,x
 lda py
 sta bullet_y,x
 lda facing
 sta bullet_dir,x
 lda #0
 sta bullet_vy,x
 jsr SoundJump
@done:rts
.endproc
.proc UpdateBullets
 lda #0
 sta bullet_index
@next:
 ldx bullet_index
 lda bullet_active,x
 beq @continue
 dec bullet_active,x
 lda bullet_dir,x
 bne @left
 lda bullet_x,x
 clc
 adc #4
 sta bullet_x,x
 lda bullet_hi,x
 adc #0
 sta bullet_hi,x
 jmp @down
@left:
 lda bullet_x,x
 sec
 sbc #4
 sta bullet_x,x
 lda bullet_hi,x
 sbc #0
 sta bullet_hi,x
@down:
 lda bullet_vy,x
 cmp #3
 bpl :+
 inc bullet_vy,x
:
 lda bullet_y,x
 clc
 adc bullet_vy,x
 sta bullet_y,x
 sta probe_y
 lda bullet_x,x
 sta probe_x
 lda bullet_hi,x
 sta probe_x+1
 lda #1
 sta slope_mode
 jsr ProbeSolid
 beq @continue
 ldx bullet_index
 lda contact_surface
 sec
 sbc #8
 sta bullet_y,x
 lda #$FD
 sta bullet_vy,x
@continue:
 inc bullet_index
 lda bullet_index
 cmp #2
 bne @next
 rts
.endproc
.proc InitPlatforms
 lda #$80
 sta platform_x
 lda #0
 sta platform_hi
 lda #160
 sta platform_y
 lda #0
 sta platform_dir
 lda #$00
 sta platform_x+1
 lda #5
 sta platform_hi+1
 lda #144
 sta platform_y+1
 lda #1
 sta platform_dir+1
 rts
.endproc
.proc UpdatePlatforms
 lda #0
 sta platform_delta
 lda frame
 and #1
 bne @done
 ldx #1
@move:
 lda platform_dir,x
 sta platform_delta
 bne @left
 inc platform_x,x
 bne :+
 inc platform_hi,x
:
 lda platform_x,x
 and #63
 cmp #63
 bne @carry
 lda #1
 sta platform_dir,x
 jmp @carry
@left:
 lda platform_x,x
 bne :+
 dec platform_hi,x
:
 dec platform_x,x
 lda platform_x,x
 and #63
 bne @carry
 lda #0
 sta platform_dir,x
@carry:
 txa
 clc
 adc #1
 cmp standing_platform
 bne @next
 lda platform_delta
 beq @carryRight
 lda px
 bne :+
 dec px+1
:
 dec px
 jmp @next
@carryRight:
 inc px
 bne @next
 inc px+1
@next:
 dex
 bpl @move
@done:rts
.endproc
.proc CheckPlatforms
 lda #0
 sta standing_platform
 lda vy
 bmi @done
 ldx #0
@next:
 lda platform_x,x
 sec
 sbc px
 sta temp2
 lda platform_hi,x
 sbc px+1
 beq @positive
 cmp #$FF
 bne @skip
 lda temp2
 cmp #$E1
 bcc @skip
 jmp @y
@positive:
 lda temp2
 cmp #14
 bcs @skip
@y:
 lda saved_y
 clc
 adc #16
 cmp platform_y,x
 bcc @below
 beq @below
 jmp @skip
@below:
 lda py
 clc
 adc #16
 cmp platform_y,x
 bcc @skip
 lda platform_y,x
 sec
 sbc #16
 sta py
 lda #0
 sta vy
 sta air_state
 lda #1
 sta grounded
 txa
 clc
 adc #1
 sta standing_platform
 rts
@skip:
 inx
 cpx #2
 bne @next
@done:rts
.endproc
.proc UpdateHeroPalette
 bit PPUSTATUS
 lda #$3F
 sta PPUADDR
 lda #$11
 sta PPUADDR
 lda #$0F
 sta PPUDATA
 lda #$27
 sta PPUDATA
 lda power
 cmp #2
 beq @firehat
 lda #$16
 bne @hat
@firehat:lda #$30
@hat:
 ldx star_timer
 beq :+
 lda frame
 and #$30
 ora #6
:
 sta PPUDATA
 lda #$3F
 sta PPUADDR
 lda #$15
 sta PPUADDR
 lda #$0F
 sta PPUDATA
 lda power
 cmp #2
 beq @firebody
 lda #$12
 bne @body
@firebody:lda #$16
@body:
 sta PPUDATA
 lda #$30
 sta PPUDATA
 rts
.endproc
