org #1200

hblnk = 0xe008
vblnk = 0xe002

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

;DITHER = 0x5a5a ; [jp]
DITHER = 0xefef ; [eu]

PLASMA_DURATION = 50

main:
    di
    im 1

    ld hl, histogram.red
    ld (fill_color), hl
    call fill_screen

PRESS_SPACE_OFFSET = 12*SCREEN_WIDTH + SCREEN_WIDTH/2 - 11
    ld hl, press_space
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 22
    ldir
    
    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0x72
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 21
    ldir

    wait_key:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key

    ld (@sp_save), sp
    
	ld hl, 0xd000+40*25
    ld sp, hl
    ld de, DITHER
    ld b, 25
plasma_fill:
    repeat 20
    push de
    rend
    dec b
    jp nz, plasma_fill

@sp_save equ $+1
    ld sp, 0x0000

    ld hl, song
    xor a
    
    call PLY_LW_Init

    ld hl, _irq_vector
    ld (0x1039),hl

	ld hl, 0xe007               ;Counter 2.
	ld (hl), 0xb0
	dec hl
	ld (hl),1
	ld (hl),0

	ld hl, 0xe007               ;100 Hz (plays the music at 50hz).
	ld (hl), 0x74
	ld hl, 0xe005
    ld (hl), 156
	ld (hl), 0

	ld hl, 0xe008 ;sound on
	ld (hl), 0x01

    ei


    ld hl, vblnk
    ld a, 0x7f
.wait0:
    cp (hl)
    jp nc, .wait0
.wait1:
    cp (hl)
    jp c, .wait1


    ld iy, up
start:
    di
    ld ix, 0xd800 + 40*25
    call border8_fill
    
    push iy
    
    call PLY_LW_Play
    
    pop iy
    
    ld ix, 0xd000 + 40*25    
    call border8_fill
    ei
    
frame_loop:
    ld a, (frame)
    add a, a
    ld (@t0), a
    ld (@t1), a
    ld (@t2), a
    ld (@t3), a
    ld (@t4), a
    
    ld hl, 0xd800
    
    ld e, 25
plasma_y:
    ld a, e             ; ay  = j
    add a, a            ; ay += ay
    add a, e            ; ay += j
    ld (@ay), a
    ld b, a
@t0 equ $+1
    ld a, 0x00
    add a, b            ; a1 = t + ay
    ld (@a10), a
    ld (@a11), a

    ld d, 32
plasma_x:
    ld a, d             ; ax = i
    add a, a            ; ax += ax
    adc a, a            ; ax += ax
    adc a, d            ; ax += i
    ld (@ax), a
    ld  b, a
@t1 equ $+1
    ld a, 0x00
    ld c, a
    add b               ; a0 = t + ax
    ld (@a00), a    

    ld  a, c
    sub b               ; a2 = t - ax
    ld (@a20), a    

@a00 equ $+1
    ld a, (sin_table)   ; s0 = sn[a0]
    ld b, a
@a10 equ $+1    
    ld a, (cos_table)   ; c0 = cs[a1]
    add a, b            ; c0 = c0 + s0
    rla                 ; c0 >>= 1
@ax equ $+1
    ld b, 0x00
    add a, b            ; c0 += ax
@ay equ $+1
    ld b, 0x00    
    sub b               ; c0 -= ay
    ld b, a
@t2 equ $+1
    ld a, 0x00
    add a, b            ; c0 += t
    ld (@c0), a
    
@a11 equ $+1
    ld a, (sin_table)   ; s1 = sn[a1]
    ld b, a
@a20 equ $+1    
    ld a, (cos_table)   ; c1 = cs[a2]
    sub b               ; s1 = c1 - s1
    ccf
    rr a                ; s1 >>= 1
    ld a, (@ax)
    add a, b            ; s1 += ax
    ld b, a
    ld a, (@ay)
    add a, b            ; s1 += ay
    ld c, a
@t3 equ $+1
    ld a, 0x00
    ld b, a
    ld a, c
    sub b               ; s1 -= t
    ld (@s1), a
    
@c0 equ $+1
    ld a, (sin_table)
    ld b, a             ; c1 = sn[c0]
@s1 equ $+1
    ld a, (cos_table)
    add a, b            ; c1 += cs[s1]
    sub 64              ; c1 -= 64
    ld b, a
@t4 equ $+1
    ld a, 0x00
    add a, b            ; c1 += t 
    srl a
    srl a
    srl a
    srl a               ; c1 >>= 4 
    
    ld (@col), a
@col equ $+1
    ld a,(gradient)
    ld (hl), a
    
    inc hl

    dec d
    jp nz, plasma_x

    ld bc, 8
    add hl, bc

    dec e
    jp nz, plasma_y
        
    ld hl, vblnk
    ld a, 0x7f
.wait:
    cp (hl)
    jp nc, .wait
    
    ld hl, frame
    inc (hl)
        
    inc hl
    inc (hl)
    
    ld a, PLASMA_DURATION
    cp (hl)
    jp nz, frame_loop
    
    xor a
    ld (hl), a
    
    ld a, (border_index)
    inc a
    cp 11
    jp nz, .go
        xor a
.go:
    ld (border_index), a
    add a, a
    add a, border_table&0xff
    ld l, a
    adc a, border_table>>8
    sub l
    ld h, a
    ld a, (hl)
    inc hl
    ld b, (hl)
    ld iyh, b
    ld iyl, a

    jp start
    
_irq_vector:
    di

    push af
    push hl
    push bc
    push de
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play        
    
    pop de
    pop bc
    pop hl
    pop af

    ei
    reti

border8_fill:
    ld (@b8sp_save), sp
    
    ld a, 25
.loop:
    ld sp, iy
    ld bc, 8
    add iy, bc   

    pop bc
    pop de
    
    exx
    pop bc
    pop de
    
    ld sp, ix
    push de
    push bc
    
    exx
    push de
    push bc

    ld bc, -40
    add ix, bc
    
    dec a
    jp nz, .loop

@b8sp_save equ $+1
    ld sp, 0x0000

    ret

; clear screen animation -------------------------------------------------------
fill_screen:
    ld iy, 25
    ld ix, 0xd000+40

fill_screen.loop
    ld bc, 0
    
fill_line:

    ld hl, vblnk
    ld a, 0x7f
.wait_2:
    cp (hl)
    jp nc, .wait_2
.wait_3:
    cp (hl)
    jp c, .wait_3

    di

    ld (transition_sp_save), sp

    ld sp, ix
    
    ld hl, histogram.attr
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a

    repeat 20
    push hl
    rend
        
    ld hl, 0x828
    add hl, sp
    ld sp, hl
    
fill_color equ $+1
    ld hl, histogram.color
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a
    repeat 20
    push hl
    rend
    
transition_sp_save equ $+1
    ld sp, 0x0000

    ei
        
    inc c
    ld a, 7
    cp c
    jp nz, fill_line

    ld de,0x28
    add ix,de
    
    dec iyl
    jp nz, fill_screen.loop
    
    ret
    
histogram.attr:
    defb 0x70,0x36,0x7a,0x7e,0x3e,0x3c,0x7a
histogram.red:
    defb 0x21,0x21,0x21,0x12,0x12,0x12,0x22
histogram.color:
    defb 0x70,0x70,0x70,0x07,0x07,0x07,0x77
histogram.blue:
    defb 0x01,0x01,0x01,0x10,0x10,0x10,0x00
histogram.black:
    defb 0x07,0x07,0x07,0x70,0x70,0x70,0x00

     
frame:
    defw 0

border_index:
    defb 0
border_table:
    defw up, flush, wish, merry, xmas, year
    defw snowman, rodolph, santa, gift, greets
    
up:         incbin "data/up.bin"
flush:      incbin "data/flush.bin"
wish:       incbin "data/wish.bin"
merry:      incbin "data/merry.bin"
xmas:       incbin "data/xmas.bin" 
year:       incbin "data/2018.bin"
snowman:    incbin "data/snowman.bin" 
rodolph:    incbin "data/rodolph.bin"
santa:      incbin "data/santa.bin"
gift:       incbin "data/gift.bin"
greets:     incbin "data/greets.bin"

align 256
cos_table:
    defb 0x80,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7e,0x7e,0x7e,0x7d,0x7d,0x7c,0x7c,0x7b
    defb 0x7b,0x7a,0x79,0x79,0x78,0x77,0x76,0x76,0x75,0x74,0x73,0x72,0x71,0x70,0x6f,0x6e
    defb 0x6d,0x6c,0x6a,0x69,0x68,0x67,0x66,0x64,0x63,0x62,0x60,0x5f,0x5e,0x5c,0x5b,0x59
    defb 0x58,0x57,0x55,0x54,0x52,0x51,0x4f,0x4e,0x4c,0x4a,0x49,0x47,0x46,0x44,0x43,0x41
    defb 0x40,0x3e,0x3c,0x3b,0x39,0x38,0x36,0x35,0x33,0x31,0x30,0x2e,0x2d,0x2b,0x2a,0x28
    defb 0x27,0x26,0x24,0x23,0x21,0x20,0x1f,0x1d,0x1c,0x1b,0x19,0x18,0x17,0x16,0x15,0x13
    defb 0x12,0x11,0x10,0x0f,0x0e,0x0d,0x0c,0x0b,0x0a,0x09,0x09,0x08,0x07,0x06,0x06,0x05
    defb 0x04,0x04,0x03,0x03,0x02,0x02,0x01,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    defb 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x02,0x02,0x03,0x03,0x04
    defb 0x04,0x05,0x06,0x06,0x07,0x08,0x09,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11
    defb 0x12,0x13,0x15,0x16,0x17,0x18,0x19,0x1b,0x1c,0x1d,0x1f,0x20,0x21,0x23,0x24,0x26
    defb 0x27,0x28,0x2a,0x2b,0x2d,0x2e,0x30,0x31,0x33,0x35,0x36,0x38,0x39,0x3b,0x3c,0x3e
    defb 0x3f,0x41,0x43,0x44,0x46,0x47,0x49,0x4a,0x4c,0x4e,0x4f,0x51,0x52,0x54,0x55,0x57
    defb 0x58,0x59,0x5b,0x5c,0x5e,0x5f,0x60,0x62,0x63,0x64,0x66,0x67,0x68,0x69,0x6a,0x6c
    defb 0x6d,0x6e,0x6f,0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x76,0x77,0x78,0x79,0x79,0x7a
    defb 0x7b,0x7b,0x7c,0x7c,0x7d,0x7d,0x7e,0x7e,0x7e,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f

sin_table:
    defb 0x40,0x41,0x43,0x44,0x46,0x47,0x49,0x4a,0x4c,0x4e,0x4f,0x51,0x52,0x54,0x55,0x57
    defb 0x58,0x59,0x5b,0x5c,0x5e,0x5f,0x60,0x62,0x63,0x64,0x66,0x67,0x68,0x69,0x6a,0x6c
    defb 0x6d,0x6e,0x6f,0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x76,0x77,0x78,0x79,0x79,0x7a
    defb 0x7b,0x7b,0x7c,0x7c,0x7d,0x7d,0x7e,0x7e,0x7e,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f
    defb 0x80,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7f,0x7e,0x7e,0x7e,0x7d,0x7d,0x7c,0x7c,0x7b
    defb 0x7b,0x7a,0x79,0x79,0x78,0x77,0x76,0x76,0x75,0x74,0x73,0x72,0x71,0x70,0x6f,0x6e
    defb 0x6d,0x6c,0x6a,0x69,0x68,0x67,0x66,0x64,0x63,0x62,0x60,0x5f,0x5e,0x5c,0x5b,0x59
    defb 0x58,0x57,0x55,0x54,0x52,0x51,0x4f,0x4e,0x4c,0x4a,0x49,0x47,0x46,0x44,0x43,0x41
    defb 0x40,0x3e,0x3c,0x3b,0x39,0x38,0x36,0x35,0x33,0x31,0x30,0x2e,0x2d,0x2b,0x2a,0x28
    defb 0x27,0x26,0x24,0x23,0x21,0x20,0x1f,0x1d,0x1c,0x1b,0x19,0x18,0x17,0x16,0x15,0x13
    defb 0x12,0x11,0x10,0x0f,0x0e,0x0d,0x0c,0x0b,0x0a,0x09,0x09,0x08,0x07,0x06,0x06,0x05
    defb 0x04,0x04,0x03,0x03,0x02,0x02,0x01,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    defb 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x02,0x02,0x03,0x03,0x04
    defb 0x04,0x05,0x06,0x06,0x07,0x08,0x09,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11
    defb 0x12,0x13,0x15,0x16,0x17,0x18,0x19,0x1b,0x1c,0x1d,0x1f,0x20,0x21,0x23,0x24,0x26
    defb 0x27,0x28,0x2a,0x2b,0x2d,0x2e,0x30,0x31,0x33,0x35,0x36,0x38,0x39,0x3b,0x3c,0x3e

gradient:
    defb 0x00,0x01,0x11,0x11,0x15,0x55,0x57,0x77,0x77,0x73,0x33,0x32,0x22,0x22,0x20,0x00
    defb 0x00,0x04,0x44,0x44,0x46,0x66,0x67,0x77,0x77,0x76,0x66,0x65,0x55,0x55,0x50,0x00
    
    
press_space:
    defb 0x0f,0x08,0x00,0x0f,0x08,0x00,0x0f,0x08,0x61,0x00,0x00
    defb 0x10,0x12,0x05,0x13,0x13,0x00,0x13,0x10,0x01,0x03,0x05

; music ------------------------------------------------------------------------
player: include "PlayerLightweight_SHARPMZ700.asm"
song: include "music.asm"        