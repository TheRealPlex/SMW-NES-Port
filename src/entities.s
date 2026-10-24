; Four persistent walkers. Offscreen activation never marks an entity dead.
.proc InitEntities
 ldx #3
@init:
 lda EnemyStartX,x
 sta enemy_x,x
 lda EnemyStartHi,x
 sta enemy_hi,x
 lda #192
 sta enemy_y,x
 lda #0
 sta enemy_dead,x
 lda #0
 sta enemy_dir,x
 dex
 bpl @init
 rts
.endproc
EnemyStartX: .byte <224,<640,<1184,<1648
EnemyStartHi: .byte >224,>640,>1184,>1648
.proc UpdateEntities
 lda #0
 sta entity_index
@next:
 ldx entity_index
 lda enemy_dead,x
 jne @continue
 ; Activate only the camera's current 256px window plus 128px right margin.
 lda enemy_x,x
 sec
 sbc camera
 sta temp2
 lda enemy_hi,x
 sbc camera+1
 bmi @interaction
 cmp #2
 bcs @interaction
 cmp #1
 bne @active
 lda temp2
 cmp #128
 bcs @interaction
@active:
 lda frame
 and #1
 bne @interaction
 lda enemy_dir,x
 beq @left
 inc enemy_x,x
 bne @probe
 inc enemy_hi,x
 jmp @probe
@left:
 lda enemy_x,x
 bne :+
 dec enemy_hi,x
:
 dec enemy_x,x
@probe:
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
 adc #8
 sta probe_y
 jsr ProbeSolid
 bne @reverse
 ldx entity_index
 lda enemy_y,x
 clc
 adc #17
 sta probe_y
 jsr ProbeSolid
 bne @interaction
@reverse:
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
 beq @positive
 cmp #$FF
 bne @continue
 lda temp2
 cmp #$F3
 bcc @continue
 jmp @vertical
@positive:
 lda temp2
 cmp #14
 bcs @continue
@vertical:
 lda py
 sec
 sbc enemy_y,x
 bpl @below
 cmp #$F1
 bcc @continue
 jmp @touch
@below:
 cmp #14
 bcs @continue
@touch:
 lda vy
 bmi @hurt
 lda saved_y
 clc
 adc #12
 cmp enemy_y,x
 bcc @stomp
 beq @stomp
@hurt:
 lda invulnerable
 bne @continue
 jsr Die
 rts
@stomp:
 lda #1
 sta enemy_dead,x
 lda #$D0
 sta vy
 lda #0
 sta grounded
 jsr SoundStomp
@continue:
 inc entity_index
 lda entity_index
 cmp #4
 jcc @next
 rts
.endproc
