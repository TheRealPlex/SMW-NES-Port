; Original pulse-channel test effects. No Nintendo audio data.
.proc SoundJump
 lda #$03
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
 lda #3
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
 lda #3
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
 lda #3
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
.proc SoundCoin
 lda #3
 sta $4015
 lda #$9A
 sta $4000
 lda #$50
 sta $4002
 lda #$08
 sta $4003
 lda #8
 sta sfx_timer
 rts
.endproc
.proc SoundPower
 lda #3
 sta $4015
 lda #$9A
 sta $4000
 lda #$D0
 sta $4002
 lda #$08
 sta $4003
 lda #24
 sta sfx_timer
 rts
.endproc
.proc AudioTick
 lda sfx_timer
 beq @music
 dec sfx_timer
 bne @music
 lda #2
 sta $4015
@music:
 inc music_tick
 lda music_tick
 cmp #10
 bcc @done
 lda #0
 sta music_tick
 ldx music_step
 lda MelodyLo,x
 sta $4006
 lda MelodyHi,x
 ora #$08
 sta $4007
 lda #$B6
 sta $4004
 lda #0
 sta $4005
 lda sfx_timer
 beq :+
 lda #3
 bne @enable
:
 lda #2
@enable:
 sta $4015
 inc music_step
 lda music_step
 and #31
 sta music_step
@done:rts
.endproc
; Original short composition, not Nintendo music.
MelodyLo: .byte $AB,$53,$1F,$53,$AB,$FD,$AB,$53,$3F,$1F,$53,$FD,$AB,$53,$1F,$FD,$1F,$53,$AB,$1F,$53,$FD,$AB,$53,$AB,$FD,$53,$1F,$AB,$53,$FD,$AB
MelodyHi: .byte 1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,0,1
