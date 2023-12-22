; 64tass -D TARGET_C64:=1 snes_userport.asm -o snes-c64.prg
; 64tass -D TARGET_C64:=1 -D WAIT_FOR_VBLANK:=1 snes_userport.asm -o snes-c64-vblank.prg
; 64tass -D TARGET_C128:=1 snes_userport.asm -o snes-c128.prg
; 64tass -D TARGET_C128:=1 -D WAIT_FOR_VBLANK:=1 snes_userport.asm -o snes-c128-vblank.prg
; 64tass -D TARGET_VIC20:=1 snes_userport.asm -o snes-vic20.prg
; 64tass -D TARGET_VIC20:=1 -D WAIT_FOR_VBLANK:=1 snes_userport.asm -o snes-vic20-vblank.prg
; 64tass -D TARGET_PET:=1 snes_userport.asm -o snes-pet.prg
; 64tass -D TARGET_PLUS4:=1 snes_userport.asm -o snes-plus4.prg

TARGET_C64 :?= 0
TARGET_C128 :?= 0
TARGET_VIC20 :?= 0
TARGET_PET :?= 0
TARGET_PLUS4 :?= 0

WAIT_FOR_VBLANK :?= 0

.if TARGET_C64 || TARGET_C128

; C64 CIA#2 PB
snes_data = $dd01
snes_ddr  = $dd03

bit_latch = $20 ; PB5 (user port pin J)
bit_data  = $40 ; PB6 (user port pin K)
bit_clock = $08 ; PB3 (user port pin F)

.if TARGET_C64
basic_start = $0801
.endif

.if TARGET_C128
basic_start = $1c01
.endif

snes_state = $fb
counter = $fd

CHROUT = $ffd2

raster_low = $d012
raster_high = $d011

.endif

.if TARGET_VIC20

; VIC-20 VIA#1 PB
snes_data = $9110
snes_ddr  = $9112

bit_latch = $20 ; PB5 (user port pin J)
bit_data  = $40 ; PB6 (user port pin K)
bit_clock = $08 ; PB3 (user port pin F)

basic_start = $1001 ; (Unexpanded)
; basic_start = $0401 ; (3K Expanded)
; basic_start = $1201 ; (8K and more Expansion)

snes_state = $fb
counter = $fd

CHROUT = $ffd2

raster_low = $9004
raster_high = $9003

.endif

.if TARGET_PET

; PET VIA PA
snes_data = $e841
snes_ddr  = $e843

bit_latch = $20 ; PA5 (user port pin J)
bit_data  = $40 ; PA6 (user port pin K)
bit_clock = $08 ; PA3 (user port pin F)

basic_start = $0401

snes_state = $5e
counter = $60
CHROUT = $ffd2

.endif

.if TARGET_PLUS4

; PLUS/4 PIO 6529B #1
snes_data = $fd10
snes_ddr  = 0

bit_latch = $40 ; P6 (user port pin J)
bit_data  = $02 ; P1 (user port pin K)
bit_clock = $80 ; P7 (user port pin F)

basic_start = $1001

snes_state = $61
counter = $63
CHROUT = $ffd2

.endif

* = basic_start

		.word (+), 1 ; pointer, line number
		.null $9e, format("%4d", start) ;  sys xxx
+		.word 0 ; basic line end

start
		lda #<labels
		ldy #>labels
		jsr print

		; initialize
.if snes_ddr
		lda #$ff - bit_data ; bit_latch|bit_clock
		sta snes_ddr
.endif
		lda #0
		sta snes_data

		; main loop
main_loop
		jsr read_snes

		lda #8
		sta counter
		ldy #1
		ldx #0
-		lda #'0'
		rol snes_state,x
		bcs +
		lda #'1'
+		sta state,y
		iny
		iny
		dec counter
		bne -
		lda #4
		sta counter
		inx
		cpx #2
		bne -

		lda #<state
		ldy #>state
		jsr print

.if WAIT_FOR_VBLANK
-		lda raster_low
		bne -
		lda raster_high
		bpl -
.endif

		jmp main_loop

; A - low byte of address
; Y - high byte of address
print
		sta snes_state
		sty snes_state + 1
		ldy #0
-		lda (snes_state),y
		beq +
		jsr CHROUT
		iny
		jmp -
+		rts

read_snes
		; pulse latch
		lda #bit_latch|bit_data
		sta snes_data
		lda #bit_data
		sta snes_data

		ldx #0
		ldy #8

		; read one bit
-		lda snes_data
.if TARGET_PET
		and #bit_data
.endif
		cmp #bit_data
		rol snes_state,x

		; pulse clock
		lda #bit_clock|bit_data
		sta snes_data
		lda #bit_data
		sta snes_data

		; loop for 8 bits
		dey
		bne -
		ldy #4

		; loop for 2 bytes
		inx
		cpx #2
		bne -

		rol snes_state + 1
		rol snes_state + 1
		rol snes_state + 1
		rol snes_state + 1

		rts

labels
		.null $93,"0 B BUTTON",$0d,"0 Y BUTTON",$0d,"0 SELECT",$0d,"0 START",$0d,"0 DPAD UP",$0d,"0 DPAD DOWN",$0d,"0 DPAD LEFT",$0d,"0 DPAD RIGHT",$0d,"0 A BUTTON",$0d,"0 X BUTTON",$0d,"0 LEFT SHOULDER",$0d,"0 RIGHT SHOULDER",$0d
state
		.null $13,"A",$0d,"B",$0d,"C",$0d,"D",$0d,"E",$0d,"F",$0d,"G",$0d,"H",$0d,"I",$0d,"J",$0d,"K",$0d,"L",$0d
