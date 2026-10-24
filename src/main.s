.setcpu "6502"
.macpack longbranch
.include "hardware.inc"
.include "state.inc"
.segment "HEADER"
.byte "NES",$1A,4,1,$43,$00,1,0,0,0,0,0,0,0
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
 ; MMC3: fixed last two 8K banks, vertical mirroring, WRAM enabled.
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
 jsr LoadPalette
 jsr LoadProgress
 jsr InitEntities
 jsr Respawn
 jsr BuildInitialScreen
 jsr DrawSprites
 lda #0
 sta PPUADDR
 sta PPUADDR
 sta PPUSCROLL
 sta PPUSCROLL
 lda #$88
 sta PPUCTRL
 lda #$1E
 sta PPUMASK
 lda #1
 sta frame_ready
@loop:
 lda frame_ready
 bne @loop
 jsr ReadController
 lda pressed
 and #BTN_START
 beq @notpause
 lda paused
 eor #1
 sta paused
@notpause:
 lda paused
 bne @draw
 lda pressed
 and #BTN_SELECT
 beq @play
 jsr Respawn
@play:
 lda invulnerable
 beq :+
 dec invulnerable
:
 jsr UpdatePlayer
 jsr UpdateEntities
 jsr UpdateCamera
@draw:
 lda rebuild
 beq @normal
 ; Forced blank for respawn only. NMI cannot upload a half-built buffer.
 lda #0
 sta PPUMASK
 sta PPUCTRL
 jsr BuildInitialScreen
 lda #0
 sta rebuild
 lda #$88
 sta PPUCTRL
 lda #$1E
 sta PPUMASK
@normal:
 jsr DrawSprites
 lda #1
 sta frame_ready
 jmp @loop
.endproc
BankInit: .byte 0,2,4,5,6,7,0,1

.proc NMI
 pha
 txa
 pha
 tya
 pha
 inc frame
 lda frame_ready
 beq @no_upload
 lda column_pending
 beq :+
 jsr UploadColumn
 lda #0
 sta column_pending
:
 lda #0
 sta OAMADDR
 lda #2
 sta OAMDMA
 bit PPUSTATUS
 lda camera
 sta PPUSCROLL
 lda #0
 sta PPUSCROLL
 lda camera+1
 and #1
 ora #$88
 sta PPUCTRL
 lda #0
 sta frame_ready
@no_upload:
 jsr AudioTick
 pla
 tay
 pla
 tax
 pla
.endproc
NMI_Return:
 rti
.proc IRQ
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
@copy: lda Palette,x
 sta PPUDATA
 inx
 cpx #32
 bne @copy
 rts
.endproc
Palette:
.byte $21,$0B,$2A,$37, $21,$0B,$2A,$37, $21,$0B,$2A,$37, $21,$0B,$2A,$37
.byte $21,$16,$27,$12, $21,$17,$30,$07, $21,$30,$27,$16, $21,$28,$30,$18

.include "level.s"
.include "physics.s"
.include "entities.s"
.include "render.s"
.include "audio.s"
.segment "RODATA"
.include "build/level.inc"
.segment "VECTORS"
.word NMI,Reset,IRQ
.segment "CHARS"
.incbin "build/original.chr"
