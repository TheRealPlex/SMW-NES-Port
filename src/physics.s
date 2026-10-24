; Signed speed is Q4.4; acceleration includes an extra fractional byte.
; Verified SMW NTSC scale: CODE_00DC4F. Limited constants: docs/physics.md.
.proc Respawn
 lda #0
 sta px_frac
 sta py_frac
 sta vx_frac
 sta vx
 sta vy
 sta grounded
 sta facing
 sta paused
 sta camera
 sta camera+1
 lda checkpoint
 beq @start
 lda #4
 sta px+1
 lda #0
 sta px
 lda #3
 sta camera+1
 lda #112
 sta camera
 jmp @y
@start:
 lda #40
 sta px
 lda #0
 sta px+1
@y:
 lda #192
 sta py
 lda #90
 sta invulnerable
 lda #1
 sta rebuild
 rts
.endproc
.proc Die
 inc deaths
 jsr SoundHurt
 jmp Respawn
.endproc
.proc UpdatePlayer
 lda px
 sta saved_x
 lda px+1
 sta saved_x+1
 lda py
 sta saved_y
 lda #$14
 sta maxspeed
 lda buttons
 and #BTN_B
 beq :+
 lda #$24
 sta maxspeed
:
 lda buttons
 and #(BTN_LEFT|BTN_RIGHT)
 cmp #BTN_RIGHT
 beq @right
 cmp #BTN_LEFT
 beq @left
 ; Ground friction. No automatic horizontal drag in air.
 lda grounded
 beq @move
 lda vx
 ora vx_frac
 beq @move
 lda vx
 bmi @dragleft
 lda vx_frac
 sec
 sbc #$00
 sta vx_frac
 lda vx
 sbc #1
 sta vx
 bpl @move
 jmp @stop
@dragleft:
 lda vx_frac
 clc
 adc #$00
 sta vx_frac
 lda vx
 adc #1
 sta vx
 bmi @move
@stop:
 lda #0
 sta vx
 sta vx_frac
 jmp @move
@right:
 lda #0
 sta facing
 lda vx_frac
 clc
 adc #$80
 sta vx_frac
 lda vx
 adc #1
 sta vx
 bmi @move
 cmp maxspeed
 bcc @move
 lda maxspeed
 sta vx
 lda #0
 sta vx_frac
 jmp @move
@left:
 lda #1
 sta facing
 lda vx_frac
 sec
 sbc #$80
 sta vx_frac
 lda vx
 sbc #1
 sta vx
 bpl @move
 eor #$FF
 clc
 adc #1
 cmp maxspeed
 bcc @move
 lda maxspeed
 eor #$FF
 clc
 adc #1
 sta vx
 lda #0
 sta vx_frac
@move:
 jsr IntegrateX
 ; World boundary clamp.
 lda px+1
 bmi @clampleft
 cmp #7
 bcc @collideX
 lda px
 cmp #$E1
 bcc @collideX
 lda #$E0
 sta px
 lda #7
 sta px+1
 jmp @collideX
@clampleft:
 lda #0
 sta px
 sta px+1
 sta px_frac
@collideX:
 lda vx
 beq @jump
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
 beq @jump
@wall:
 lda saved_x
 sta px
 lda saved_x+1
 sta px+1
 lda #0
 sta vx
 sta vx_frac
 sta px_frac
@jump:
 lda pressed
 and #BTN_A
 beq @gravity
 lda grounded
 beq @gravity
 ; Jump speed depends on horizontal speed, using verified normal-jump table.
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
 lda #0
 sta grounded
 jsr SoundJump
@gravity:
 lda #6
 sta temp2
 lda buttons
 and #BTN_A
 beq :+
 lda #3
 sta temp2
:
 lda vy
 clc
 adc temp2
 bmi :+
 cmp #$40
 bcc :+
 lda #$40
:
 sta vy
 jsr IntegrateY
 ; Clamp to ceiling if 8-bit Y underflowed while rising.
 lda vy
 bpl @vertical
 lda saved_y
 cmp #16
 bcs @vertical
 lda py
 cmp #224
 bcc @vertical
 lda #0
 sta py
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
 lda py
 clc
 adc #16
 jcs @fell
 sta probe_y
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
 bcs @fell
 jmp @progress
@land:
 lda hit_row
 asl a
 asl a
 asl a
 asl a
 sec
 sbc #16
 sta py
 lda #0
 sta vy
 sta py_frac
 lda #1
 sta grounded
 jmp @progress
@ceiling:
 lda py
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
 beq @progress
@headhit:
 lda hit_row
 clc
 adc #1
 asl a
 asl a
 asl a
 asl a
 sta py
 lda #0
 sta vy
 sta py_frac
@progress:
 lda px+1
 cmp #4
 bcc @done
 lda #1
 sta checkpoint
 lda px+1
 cmp #7
 bcc @done
 lda px
 cmp #$B0
 bcc @done
 lda completed
 bne @done
 lda #1
 sta completed
 jsr SaveProgress
 jsr SoundGoal
@done: rts
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
