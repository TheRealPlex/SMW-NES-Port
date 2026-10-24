; Original pulse-channel test effects. No Nintendo audio data.
.proc SoundJump
 lda #$01
 sta $4015
 lda #$9A
 sta $4000
 lda #$B0
 sta $4002
 lda #$08
 sta $4003
 lda #10
 sta sfx_timer
 rts
.endproc
.proc SoundStomp
 lda #1
 sta $4015
 lda #$96
 sta $4000
 lda #$40
 sta $4002
 lda #$09
 sta $4003
 lda #6
 sta sfx_timer
 rts
.endproc
.proc SoundHurt
 lda #1
 sta $4015
 lda #$9B
 sta $4000
 lda #$F0
 sta $4002
 lda #$0B
 sta $4003
 lda #16
 sta sfx_timer
 rts
.endproc
.proc SoundGoal
 lda #1
 sta $4015
 lda #$9A
 sta $4000
 lda #$60
 sta $4002
 lda #$08
 sta $4003
 lda #30
 sta sfx_timer
 rts
.endproc
.proc AudioTick
 lda sfx_timer
 beq @done
 dec sfx_timer
 bne @done
 lda #0
 sta $4015
@done: rts
.endproc
