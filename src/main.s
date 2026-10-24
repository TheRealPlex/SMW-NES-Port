.setcpu "6502"
.macpack longbranch
.include "hardware.inc"
.include "state.inc"
.segment "HEADER"
.byte "NES",$1A,4,1,$43,0,1,0,0,0,0,0,0,0
.segment "CODE"
.export Reset,NMI,IRQ
.proc Reset
 sei
 cld
 ldx #$40
 stx $4017
 ldx #$FF
 txs
 inx
 stx PPUCTRL
 stx PPUMASK
 stx $4010
 stx $4015
 bit PPUSTATUS
@v1: bit PPUSTATUS
 bpl @v1
 lda #0
 tax
@clear:
 sta $0000,x
 sta $0100,x
 sta $0300,x
 sta $0400,x
 sta $0500,x
 sta $0600,x
 sta $0700,x
 inx
 bne @clear
@v2: bit PPUSTATUS
 bpl @v2
 lda #0
 sta $E000
 sta $A000
 lda #$80
 sta $A001
 ldx #0
@banks:
 txa
 sta $8000
 lda BankInit,x
 sta $8001
 inx
 cpx #8
 bne @banks
 lda #5
 sta lives
 jsr LoadProgress
 lda #1
 sta rebuild
 jsr RebuildScreen
 jsr DrawSprites
 lda #$88
 sta PPUCTRL
 lda #$1E
 sta PPUMASK
 cli
 lda #1
 sta frame_ready
@loop:
 lda frame_ready
 bne @loop
 jsr ReadController
 lda game_mode
 beq @world
 cmp #2
 beq @goal
 lda pressed
 and #BTN_START
 beq @notpause
 lda paused
 eor #1
 sta paused
 lda #1
 sta hud_dirty
@notpause:
 lda paused
 beq @stage
 lda pressed
 and #BTN_SELECT
 beq @draw
 jsr ReturnToMap
 jmp @draw
@stage:
 jsr TickAbilities
 jsr UpdatePlatforms
 jsr UpdatePlayer
 jsr UpdateAbilities
 jsr UpdateEntities
 jsr UpdateItems
 jsr UpdateBullets
 jsr UpdateCamera
 jsr UpdateProgress
 jmp @draw
@world:
 jsr UpdateWorld
 jmp @draw
@goal:
 lda end_timer
 beq @return
 dec end_timer
 jmp @draw
@return:
 jsr ReturnToMap
@draw:
 lda rebuild
 beq @normal
 jsr RebuildScreen
@normal:
 jsr DrawSprites
 lda #1
 sta frame_ready
 jmp @loop
.endproc
BankInit: .byte 0,2,4,5,6,7,0,4

.proc NMI
 pha
 txa
 pha
 tya
 pha
 inc frame
 lda rebuild
 beq @normalNmi
 lda #0
 sta frame_ready
 jmp @noirq
@normalNmi:
 lda #0
 sta $E000
 lda frame_ready
 jeq @sound
 lda column_pending
 beq :+
 jsr UploadColumn
 lda #0
 sta column_pending
:
 lda dirty_pending
 beq :+
 jsr UploadDirtyTile
 lda #0
 sta dirty_pending
:
 lda palette_dirty
 beq :+
 jsr UpdateHeroPalette
 lda #0
 sta palette_dirty
:
 lda hud_dirty
 beq :+
 jsr UploadHudCounters
 lda #0
 sta hud_dirty
:
 lda #0
 sta OAMADDR
 lda #2
 sta OAMDMA
 lda #0
 sta frame_ready
@sound:
 bit PPUSTATUS
 lda #0
 sta PPUSCROLL
 sta PPUSCROLL
 lda #$88
 sta PPUCTRL
 lda game_mode
 beq @noirq
 lda #30
 sta $C000
 lda #0
 sta $C001
 sta $E001
@noirq:
 jsr AudioTick
 pla
 tay
 pla
 tax
 pla
.endproc
NMI_Return: rti
.proc IRQ
 pha
 lda #0
 sta $E000
 bit PPUSTATUS
 lda camera+1
 and #1
 ora #$88
 sta PPUCTRL
 lda camera
 sta PPUSCROLL
 lda #0
 sta PPUSCROLL
 pla
 rti
.endproc
.proc ReadController
 lda buttons
 sta previous
 lda #1
 sta JOY1
 lda #0
 sta JOY1
 sta buttons
 ldx #8
@read:
 lda JOY1
 lsr a
 rol buttons
 dex
 bne @read
 lda previous
 eor #$FF
 and buttons
 sta pressed
 rts
.endproc
.proc LoadPalette
 bit PPUSTATUS
 lda #$3F
 sta PPUADDR
 lda #0
 sta PPUADDR
 ldx #0
@copy:
 lda Palette,x
 sta PPUDATA
 inx
 cpx #32
 bne @copy
 lda level_index
 cmp #3
 bne @normal
 lda game_mode
 beq @normal
 bit PPUSTATUS
 lda #$3F
 sta PPUADDR
 lda #0
 sta PPUADDR
 ldx #0
@castle:
 lda CastlePalette,x
 sta PPUDATA
 inx
 cpx #16
 bne @castle
@normal:
 lda #1
 sta palette_dirty
 rts
.endproc
CastlePalette: .byte $0F,$0F,$00,$10, $0F,$0F,$00,$10, $0F,$0F,$00,$10, $0F,$0F,$30,$16
Palette:
.byte $21,$0F,$2A,$27, $21,$11,$31,$30, $21,$0F,$28,$30, $21,$0F,$30,$16
.byte $21,$0F,$27,$16, $21,$0F,$12,$30, $21,$0F,$2A,$30, $21,$0F,$28,$17
.include "level.s"
.include "world.s"
.include "physics.s"
.include "abilities.s"
.include "entities.s"
.include "render.s"
.include "audio.s"
.segment "RODATA"
.include "build/sprites.inc"
.segment "LEVEL0"
.incbin "build/world0.bin"
.segment "LEVEL1"
.incbin "build/world1.bin"
.segment "LEVEL2"
.incbin "build/world2.bin"
.segment "LEVEL3"
.incbin "build/world3.bin"
.segment "STATIC"
.include "build/level.inc"
.segment "VECTORS"
.word NMI,Reset,IRQ
.segment "CHARS"
.incbin "build/original.chr"
