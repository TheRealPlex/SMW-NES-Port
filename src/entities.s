.proc InitEntities
 ldx #7
@init:
 lda EnemyStartX,x
 sta enemy_x,x
 lda EnemyStartHi,x
 sta enemy_hi,x
 txa
 and #1
 sta enemy_kind,x
 lda #0
 sta enemy_dir,x
 sta enemy_vy,x
 lda level_index
 beq @hide
 lda #0
 sta enemy_dead,x
 stx entity_index
 lda enemy_x,x
 clc
 adc #8
 sta probe_x
 lda enemy_hi,x
 adc #0
 sta probe_x+1
 lda #1
 sta slope_mode
 lda #64
 sta probe_y
@floor:
 jsr ProbeSolid
 bne @place
 lda probe_y
 clc
 adc #8
 sta probe_y
 cmp #232
 bcc @floor
 ldx entity_index
@hide:
 lda #1
 sta enemy_dead,x
 jmp @next
@place:
 ldx entity_index
 lda contact_surface
 sec
 sbc #16
 sta enemy_y,x
@next:
 dex
 jpl @init
 rts
.endproc
EnemyStartX: .byte <224,<512,<864,<1216,<1632,<2208,<2816,<3360
EnemyStartHi: .byte >224,>512,>864,>1216,>1632,>2208,>2816,>3360
.proc UpdateEntities
 lda #0
 sta entity_index
@next:
 ldx entity_index
 lda enemy_dead,x
 jne @continue
 lda enemy_x,x
 sec
 sbc camera
 sta temp2
 lda enemy_hi,x
 sbc camera+1
 beq @active
 cmp #1
 bne @behind
 lda temp2
 cmp #64
 jcs @continue
 jmp @active
@behind:
 cmp #$FF
 jne @continue
 lda temp2
 cmp #192
 jcc @continue
@active:
 jsr EnemyProjectileHit
 ldx entity_index
 lda enemy_dead,x
 jne @continue
 lda enemy_kind,x
 cmp #3
 jeq @interaction
 lda frame
 and #1
 beq @step
 lda enemy_kind,x
 cmp #4
 jne @ground
@step:
 lda enemy_dir,x
 bne @right
 lda enemy_x,x
 bne :+
 lda enemy_hi,x
 bne @borrow
 lda #1
 sta enemy_dir,x
 jmp @ground
@borrow:dec enemy_hi,x
:
 dec enemy_x,x
 jmp @ground
@right:
 inc enemy_x,x
 bne @ground
 inc enemy_hi,x
@ground:
 lda enemy_x,x
 clc
 adc #8
 sta probe_x
 lda enemy_hi,x
 adc #0
 sta probe_x+1
 lda enemy_y,x
 clc
 adc #18
 sta probe_y
 lda #1
 sta slope_mode
 jsr ProbeSolid
 beq @fall
 ldx entity_index
 lda contact_surface
 sec
 sbc #16
 sta enemy_y,x
 jmp @side
@fall:
 ldx entity_index
 inc enemy_y,x
 inc enemy_y,x
 lda enemy_y,x
 cmp #224
 bcc @side
 lda #1
 sta enemy_dead,x
 jmp @continue
@side:
 ldx entity_index
 lda enemy_x,x
 clc
 adc #1
 sta probe_x
 lda enemy_hi,x
 adc #0
 sta probe_x+1
 lda enemy_dir,x
 beq :+
 lda probe_x
 clc
 adc #13
 sta probe_x
 lda probe_x+1
 adc #0
 sta probe_x+1
:
 lda enemy_y,x
 clc
 adc #7
 sta probe_y
 lda #0
 sta slope_mode
 jsr ProbeSolid
 beq @interaction
 ldx entity_index
 lda enemy_dir,x
 eor #1
 sta enemy_dir,x
@interaction:
 ldx entity_index
 lda enemy_x,x
 sec
 sbc px
 sta temp2
 lda enemy_hi,x
 sbc px+1
 beq @rightNear
 cmp #$FF
 jne @continue
 lda temp2
 cmp #$C0
 jcc @continue
 jmp @inRange
@rightNear:
 lda temp2
 cmp #65
 jcs @continue
@inRange:
 lda enemy_y,x
 sec
 sbc py
 clc
 adc #24
 cmp #49
 jcs @continue
 lda tongue_timer
 beq @spin
 lda yoshi_mounted
 beq @spin
 lda temp2
 bmi @tongueLeft
 lda facing
 bne @spin
 jmp @eat
@tongueLeft:
 lda facing
 beq @spin
@eat:
 lda enemy_kind,x
 cmp #1
 beq :+
 cmp #3
 bne @eatKill
:
 lda #1
 sta yoshi_shell
@eatKill:
 lda #1
 sta enemy_dead,x
 jsr AddCoin
 jmp @continue
@spin:
 lda cape_spin
 beq @touch
 lda temp2
 clc
 adc #28
 cmp #57
 bcs @touch
 jsr KillEnemy
 jmp @continue
@touch:
 lda temp2
 clc
 adc #13
 cmp #27
 jcs @continue
 lda star_timer
 beq @stomp
 jsr KillEnemy
 jmp @continue
@stomp:
 lda vy
 bmi @hurt
 lda saved_y
 clc
 adc #12
 cmp enemy_y,x
 bcc @bounce
 beq @bounce
 lda enemy_kind,x
 cmp #3
 bne @hurt
 lda pressed
 and #BTN_B
 beq @safeShell
 lda #4
 sta enemy_kind,x
 lda facing
 eor #1
 sta enemy_dir,x
 lda #12
 sta action_cooldown
 lda #30
 sta invulnerable
 jmp @continue
@safeShell:
 jmp @continue
@hurt:
 jsr HurtPlayer
 jmp @continue
@bounce:
 lda #$D0
 sta vy
 lda #0
 sta grounded
 lda enemy_kind,x
 beq @rex
 cmp #1
 beq @shell
 cmp #3
 beq @shellMove
 cmp #4
 beq @shellStop
 jsr KillEnemy
 jmp @continue
@rex:
 lda #5
 sta enemy_kind,x
 jmp @sound
@shell:
 lda #3
 sta enemy_kind,x
 jmp @sound
@shellMove:
 lda #4
 sta enemy_kind,x
 lda facing
 eor #1
 sta enemy_dir,x
 jmp @sound
@shellStop:
 lda #3
 sta enemy_kind,x
@sound:jsr SoundStomp
@continue:
 inc entity_index
 lda entity_index
 cmp #8
 jcc @next
 rts
.endproc
.proc KillEnemy
 ldx entity_index
 lda #1
 sta enemy_dead,x
 jmp SoundStomp
.endproc
.proc EnemyProjectileHit
 ldy #0
@next:
 lda bullet_active,y
 beq @skip
 lda bullet_x,y
 sec
 sbc enemy_x,x
 sta temp3
 lda bullet_hi,y
 sbc enemy_hi,x
 beq @positive
 cmp #$FF
 bne @skip
 lda temp3
 cmp #$F0
 bcc @skip
 jmp @height
@positive:
 lda temp3
 cmp #17
 bcs @skip
@height:
 lda bullet_y,y
 sec
 sbc enemy_y,x
 clc
 adc #16
 cmp #33
 bcs @skip
 lda #0
 sta bullet_active,y
 lda #1
 sta enemy_dead,x
 jsr SoundStomp
 rts
@skip:
 iny
 cpy #2
 bne @next
 rts
.endproc
