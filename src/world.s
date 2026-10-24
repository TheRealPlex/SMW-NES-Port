.proc LoadProgress
 lda #1
 sta world_cursor
 lda $6000
 cmp #$50
 bne @new
 lda $6001
 cmp #$33
 bne @new
 lda $6002
 eor $6003
 cmp #$FF
 bne @new
 lda $6002
 sta cleared_levels
 lda $6004
 cmp #4
 bcs @new
 sta world_cursor
 rts
@new:
 lda #0
 sta cleared_levels
 jmp SaveProgress
.endproc
.proc SaveProgress
 lda #$50
 sta $6000
 lda #$33
 sta $6001
 lda cleared_levels
 sta $6002
 eor #$FF
 sta $6003
 lda world_cursor
 sta $6004
 rts
.endproc
.proc UpdateWorld
 lda pressed
 and #(BTN_LEFT|$08)
 beq @right
 lda world_cursor
 beq @action
 dec world_cursor
 jmp @changed
@right:
 lda pressed
 and #(BTN_RIGHT|$04)
 beq @action
 lda world_cursor
 cmp #3
 bcs @action
 inc world_cursor
@changed:
 lda #1
 sta rebuild
 jsr SoundCoin
@action:
 lda pressed
 and #(BTN_A|BTN_START)
 beq @done
 ldx world_cursor
 lda StagePrerequisite,x
 and cleared_levels
 cmp StagePrerequisite,x
 bne @done
 jsr StartStage
@done:rts
.endproc
StagePrerequisite: .byte 0,0,2,4
StageBits: .byte 1,2,4,8
StageMaxHi: .byte 0,15,15,7
MapNodeX: .byte 64,112,160,176
MapNodeY: .byte 160,160,128,96
.proc StartStage
 lda world_cursor
 sta level_index
 tax
 lda StageMaxHi,x
 sta world_max_hi
 lda #6
 sta $8000
 txa
 sta $8001
 lda #0
 sta checkpoint
 sta completed
 sta paused
 sta cape_spin
 sta flight_timer
 sta yoshi_mounted
 sta balloon_timer
 sta standing_platform
 lda #1
 sta game_mode
 ; Current native map -> live mutable WRAM. Other PRG bank remains static.
 lda #0
 sta ptr
 sta ptr2
 lda #$80
 sta ptr+1
 lda #$68
 sta ptr2+1
 ldx #15
 ldy #0
@copy:
 lda (ptr),y
 sta (ptr2),y
 iny
 bne @copy
 inc ptr+1
 inc ptr2+1
 dex
 bne @copy
 jsr InitEntities
 jsr InitItems
 jsr InitPlatforms
 jsr Respawn
 lda carry_yoshi
 beq @timerInit
 lda level_index
 cmp #3
 beq @timerInit
 lda #1
 sta yoshi_active
 sta yoshi_mounted
 lda px
 sta yoshi_x
 lda px+1
 sta yoshi_x+1
 lda py
 sta yoshi_y
@timerInit:
 lda #3
 sta timer_hundreds
 lda #0
 sta timer_tens
 sta timer_units
 sta timer_tick
 jsr SaveProgress
 rts
.endproc
.proc ReturnToMap
 lda level_index
 cmp #3
 beq :+
 lda yoshi_mounted
 sta carry_yoshi
:
 lda #0
 sta game_mode
 sta camera
 sta camera+1
 sta paused
 sta yoshi_mounted
 sta tongue_timer
 sta column_pending
 sta dirty_pending
 lda #1
 sta rebuild
 jsr SaveProgress
 rts
.endproc
.proc RebuildScreen
 sei
 lda #0
 sta $E000
 sta PPUMASK
 sta PPUCTRL
 sta dirty_pending
 sta column_pending
 jsr LoadPalette
 lda game_mode
 bne @stage
 jsr DrawWorldMap
 jmp @done
@stage:
 jsr BuildInitialScreen
@done:
 bit PPUSTATUS
 lda #0
 sta PPUADDR
 sta PPUADDR
 sta PPUSCROLL
 sta PPUSCROLL
 lda #$88
 sta PPUCTRL
 lda #$1E
 sta PPUMASK
 lda #0
 sta rebuild
 cli
 rts
.endproc
.proc DrawWorldMap
 lda #$88
 sta PPUCTRL
 bit PPUSTATUS
 lda #$20
 sta PPUADDR
 lda #0
 sta PPUADDR
 lda #<WorldMapData
 sta ptr
 lda #>WorldMapData
 sta ptr+1
 ldx #4
 ldy #0
@copy:
 lda (ptr),y
 sta PPUDATA
 iny
 bne @copy
 inc ptr+1
 dex
 bne @copy
 lda #$23
 sta PPUADDR
 lda #$20
 sta PPUADDR
 ldx world_cursor
 lda LevelNameLo,x
 sta ptr
 lda LevelNameHi,x
 sta ptr+1
 ldy #0
@name:
 lda (ptr),y
 sta PPUDATA
 iny
 cpy #24
 bne @name
 ; Readable map title and footer use the white/red palette.
 ldx #0
@attr:
 lda #$23
 sta PPUADDR
 txa
 ora #$C0
 sta PPUADDR
 lda #$FF
 sta PPUDATA
 inx
 cpx #8
 bne @attr
 lda #$23
 sta PPUADDR
 lda #$F0
 sta PPUADDR
 ldx #16
 lda #$FF
@footer:sta PPUDATA
 dex
 bne @footer
 lda #$3F
 sta PPUADDR
 lda #9
 sta PPUADDR
 lda #$12
 sta PPUDATA
 lda #$28
 sta PPUDATA
 lda #$30
 sta PPUDATA
 lda #0
 sta hud_dirty
 rts
.endproc
.proc UpdateProgress
 lda game_mode
 cmp #1
 jne @done
 lda level_index
 bne @checkpoint
 lda px
 cmp #216
 jcc @done
 jmp ReturnToMap
@checkpoint:
 lda checkpoint
 bne @timer
 lda px+1
 cmp #4
 bcc @timer
 lda grounded
 beq @timer
 lda #1
 sta checkpoint
 lda px
 sta checkpoint_x
 lda px+1
 sta checkpoint_x+1
 lda py
 sta checkpoint_y
 jsr SoundPower
@timer:
 inc timer_tick
 lda timer_tick
 cmp #60
 bcc @goal
 lda #0
 sta timer_tick
 lda timer_units
 bne @units
 lda #9
 sta timer_units
 lda timer_tens
 bne @tens
 lda #9
 sta timer_tens
 lda timer_hundreds
 beq @die
 dec timer_hundreds
 jmp @hud
@tens: dec timer_tens
 jmp @hud
@units:dec timer_units
@hud:
 lda #1
 sta hud_dirty
@goal:
 lda world_max_hi
 clc
 adc #0
 sta temp
 lda px+1
 cmp temp
 bcc @done
 lda px
 cmp #$80
 bcc @done
 ldx level_index
 lda StageBits,x
 ora cleared_levels
 sta cleared_levels
 lda #1
 sta completed
 lda #2
 sta game_mode
 lda #100
 sta end_timer
 lda #0
 sta vx
 sta vx_frac
 jsr SaveProgress
 jsr SoundGoal
@done:rts
@die:jmp Die
.endproc
.proc UploadHudCounters
 lda game_mode
 beq @done
 lda #$88
 sta PPUCTRL
 bit PPUSTATUS
 lda #$20
 sta PPUADDR
 lda #$42
 sta PPUADDR
 lda lives
 jsr DigitPair
 lda #$20
 sta PPUADDR
 lda #$48
 sta PPUADDR
 lda coins
 jsr DigitPair
 lda #$20
 sta PPUADDR
 lda #$59
 sta PPUADDR
 lda timer_hundreds
 clc
 adc #202
 sta PPUDATA
 lda timer_tens
 clc
 adc #202
 sta PPUDATA
 lda timer_units
 clc
 adc #202
 sta PPUDATA
 lda #$20
 sta PPUADDR
 lda #$51
 sta PPUADDR
 lda p_meter
 cmp #112
 lda #0
 bcc :+
 lda #198
:
 sta PPUDATA
@done:rts
.endproc
ReserveLetters: .byte 0,188,181,178
.proc DigitPair
 ldx #0
@tens:
 cmp #10
 bcc @done
 sec
 sbc #10
 inx
 bne @tens
@done:
 pha
 txa
 clc
 adc #202
 sta PPUDATA
 pla
 clc
 adc #202
 sta PPUDATA
 rts
.endproc
