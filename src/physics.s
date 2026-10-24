; Signed speed is Q4.4; acceleration includes an extra fractional byte.
; Differentially checked against the supplied ROM in Snes9x.
; Flat-ground/normal-jump subset: docs/physics.md; tests/fixtures/.
.proc Respawn
 lda #0
 sta px_frac
 sta py_frac
 sta vx_frac
 sta vx
 sta p_meter
 sta air_state
 sta grounded
 sta facing
 sta paused
 sta cape_spin
 sta flight_timer
 sta balloon_timer
 sta yoshi_mounted
 sta tongue_timer
 sta standing_platform
 sta invulnerable
 sta camera
 sta camera+1
 lda checkpoint
 beq @start
 lda checkpoint_x
 sta px
 lda checkpoint_x+1
 sta px+1
 lda checkpoint_y
 sta py
 jsr UpdateCamera
 jmp @finish
@start:
 lda #40
 sta px
 lda #0
 sta px+1
 lda #192
 sta py
@finish:
 lda #6
 sta vy
 lda #1
 sta rebuild
 sta hud_dirty
 rts
.endproc
.proc Die
 inc deaths
 lda #0
 sta power
 sta star_timer
 sta reserve_item
 lda lives
 beq :+
 dec lives
:
 lda lives
 bne @again
 lda #5
 sta lives
 jsr ReturnToMap
 rts
@again:
 jsr SoundHurt
 jsr Respawn
 lda #90
 sta invulnerable
 lda #1
 sta palette_dirty
 rts
.endproc
.proc UpdatePlayer
 lda px
 sta saved_x
 lda px+1
 sta saved_x+1
 lda py
 sta saved_y
 lda grounded
 sta was_grounded
 lda #0
 sta head_offset
 sta slope_mode
 lda power
 ora yoshi_mounted
 beq :+
 lda #16
 sta head_offset
:
 ; SMW integrates last frame's speeds before calculating the next speeds.
 jsr IntegrateX
 ; World boundary clamp.
 lda px+1
 bmi @clampleft
 cmp world_max_hi
 bcc @collideX
 bne @rightEdge
 lda px
 cmp #$E1
 bcc @collideX
@rightEdge:
 lda #$E0
 sta px
 lda world_max_hi
 sta px+1
 jmp @collideX
@clampleft:
 lda #0
 sta px
 sta px+1
 sta px_frac
@collideX:
 lda vx
 beq @verticalStart
 lda px
 clc
 adc #2
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 lda vx
 bmi @probeSide
 lda px
 clc
 adc #13
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
@probeSide:
 lda py
 sec
 sbc head_offset
 clc
 adc #2
 sta probe_y
 jsr ProbeSolid
 bne @wall
 lda py
 clc
 adc #14
 sta probe_y
 jsr ProbeSolid
 beq @verticalStart
@wall:
 lda saved_x
 sta px
 lda saved_x+1
 sta px+1
 lda #0
 sta vx
 sta vx_frac
 sta px_frac
@verticalStart:
 jsr IntegrateY
 lda vy
 bpl @vertical
 lda #32
 clc
 adc head_offset
 sta temp
 lda py
 cmp temp
 bcs @vertical
 lda temp
 sta py
 lda #0
 sta vy
@vertical:
 lda #0
 sta grounded
 lda px
 clc
 adc #3
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 lda vy
 bmi @ceiling
 lda #1
 sta slope_mode
 lda py
 clc
 adc #16
 jcs @fell
 sta probe_y
 lda was_grounded
 beq :+
 lda probe_y
 clc
 adc #4
 sta probe_y
:
 jsr ProbeSolid
 bne @land
 lda px
 clc
 adc #12
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 jsr ProbeSolid
 bne @land
 lda py
 cmp #224
 jcs @fell
 jmp @motionEnd
@land:
 lda contact_surface
 sec
 sbc #16
 sta py
 lda #0
 sta vy
 sta air_state
 lda #1
 sta grounded
 jmp @motionEnd
@ceiling:
 lda #0
 sta slope_mode
 lda py
 sec
 sbc head_offset
 sta probe_y
 jsr ProbeSolid
 bne @headhit
 lda px
 clc
 adc #12
 sta probe_x
 lda px+1
 adc #0
 sta probe_x+1
 jsr ProbeSolid
 beq @motionEnd
@headhit:
 jsr TryBumpBlock
 lda hit_row
 clc
 adc #1
 asl a
 asl a
 asl a
 asl a
 clc
 adc head_offset
 sta py
 lda #0
 sta vy
 sta air_state
@motionEnd:
 jsr CheckPlatforms
 lda pressed
 and #BTN_A
 beq @nextVelocity
 lda grounded
 beq @nextVelocity
 lda vx
 bpl :+
 eor #$FF
 clc
 adc #1
:
 lsr a
 lsr a
 lsr a
 tax
 cpx #8
 bcc :+
 ldx #7
:
 lda JumpSpeed,x
 sta vy
 lda #11
 ldx p_meter
 cpx #112
 bcc :+
 lda #12
:
 sta air_state
 lda #0
 sta grounded
 jsr SoundJump
@nextVelocity:
 jsr HorizontalSpeed
 jsr GravitySpeed
 jsr ApplyCapeFlight
@progress:
@done:
 rts
@fell: jmp Die
.endproc
; Values read from bank00 JumpSpeed, not decoded from copied game code.
JumpSpeed: .byte $B0,$AE,$AB,$A9,$A6,$A4,$A1,$9F
.proc IntegrateX
 lda #0
 sta step_sign
 lda vx
 bpl :+
 lda #$FF
 sta step_sign
:
 lda vx
 lsr a
 lsr a
 lsr a
 lsr a
 cmp #8
 bcc :+
 ora #$F0
:
 sta delta
 lda vx
 asl a
 asl a
 asl a
 asl a
 clc
 adc px_frac
 sta px_frac
 lda px
 adc delta
 sta px
 lda px+1
 adc step_sign
 sta px+1
 rts
.endproc
.proc IntegrateY
 lda vy
 lsr a
 lsr a
 lsr a
 lsr a
 cmp #8
 bcc :+
 ora #$F0
:
 sta delta
 lda vy
 asl a
 asl a
 asl a
 asl a
 clc
 adc py_frac
 sta py_frac
 lda py
 adc delta
 sta py
 rts
.endproc

; Flat, non-slippery small-Mario motion. Fractional velocity is intentionally
; preserved when reaching a cap: SMW alternates acceleration and drag there.
.proc HorizontalSpeed
 lda buttons
 and #(BTN_LEFT|BTN_RIGHT)
 bne @direction
 jsr DecPMeter
 lda grounded
 jeq @done
 jmp DragSpeed
@direction:
 ; Right wins when both directions are pressed, matching the original path.
 and #BTN_RIGHT
 eor #1
 sta facing
 ; PMeter increases only at run speed, on the floor or in a P-jump.
 lda buttons
 and #BTN_B
 beq @meterDown
 lda vx
 bpl :+
 eor #$FF
 clc
 adc #1
:
 cmp #35
 bcc @meterDown
 lda grounded
 bne @meterUp
 lda air_state
 cmp #12
 bne @meterDown
@meterUp:
 lda p_meter
 clc
 adc #2
 cmp #112
 bcc :+
 lda #112
:
 sta p_meter
 jmp @limit
@meterDown:
 jsr DecPMeter
@limit:
 lda #20
 sta maxspeed
 lda buttons
 and #BTN_B
 beq @compare
 lda #36
 sta maxspeed
 lda p_meter
 cmp #112
 bcc @compare
 lda #48
 sta maxspeed
@compare:
 lda facing
 bne @negative
 lda vx
 bmi @accel
 cmp maxspeed
 bcs @drag
 jmp @accel
@negative:
 ; Compute the signed negative cap. Do not abs(vx), which loses a fraction
 ; of precision on the negative side of the signed 8.8 representation.
 lda maxspeed
 eor #$FF
 clc
 adc #1
 sta temp
 lda vx
 bpl @accel
 cmp temp
 bcc @drag
 beq @drag
@accel:
 ; Normal acceleration = 1.5 velocity units; skid = 2.5 walking / 5 running.
 lda #$80
 sta temp2
 lda #1
 sta temp
 lda vx
 beq @apply
 ; Facing uses 0=right,1=left; compare signs explicitly.
 lda facing
 beq @turnRight
 lda vx
 bmi @apply
 jmp @skid
@turnRight:
 lda vx
 bpl @apply
@skid:
 lda #2
 sta temp
 lda buttons
 and #BTN_B
 beq @apply
 lda #5
 sta temp
 lda #0
 sta temp2
@apply:
 lda facing
 bne @subtract
 lda vx_frac
 clc
 adc temp2
 sta vx_frac
 lda vx
 adc temp
 sta vx
 rts
@subtract:
 lda vx_frac
 sec
 sbc temp2
 sta vx_frac
 lda vx
 sbc temp
 sta vx
@done: rts
@drag: jmp DragSpeed
.endproc
.proc DecPMeter
 lda p_meter
 beq @done
 dec p_meter
@done: rts
.endproc
.proc DragSpeed
 lda vx
 ora vx_frac
 beq @done
 lda vx
 bmi @negative
 dec vx
 bpl @done
 jmp @stop
@negative:
 inc vx
 bmi @done
 lda #0
 sta vx_frac
@stop:
 lda #0
 sta vx
 sta vx_frac
@done: rts
.endproc
.proc GravitySpeed
 lda #6
 sta temp2
 lda buttons
 and #BTN_A
 beq :+
 lda #3
 sta temp2
:
 lda vy
 bmi @add
 cmp #64
 bcc :+
 lda #64
:
 ldx air_state
 cpx #11
 bne @add
 ldx #36
 stx air_state
@add:
 clc
 adc temp2
 sta vy
 rts
.endproc
