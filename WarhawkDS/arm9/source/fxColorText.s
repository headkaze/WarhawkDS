@ Copyright (c) 2009 Proteus Developments / Headsoft
@ 
@ Permission is hereby granted, free of charge, to any person obtaining
@ a copy of this software and associated documentation files (the
@ "Software"), to deal in the Software without restriction, including
@ without limitation the rights to use, copy, modify, merge, publish,
@ distribute, sublicense, and/or sell copies of the Software, and to
@ permit persons to whom the Software is furnished to do so, subject to
@ the following conditions:
@ 
@ The above copyright notice and this permission notice shall be included
@ in all copies or substantial portions of the Software.
@ 
@ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
@ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
@ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
@ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
@ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
@ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
@ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include "warhawk.h"
#include "system.h"
#include "video.h"
#include "background.h"
#include "dma.h"
#include "interrupts.h"
#include "windows.h"

	#define FONT_COLOR_OFFSET				255
	#define COLOR_HILIGHT					COLOR_YELLOW

	.arm
	.align
	.text
	.global fxCopperTextOn
	.global fxCopperTextOff
	.global fxCopperTextVBlank
	.global fxColorCycleTextOn
	.global fxColorCycleTextOff
	.global fxColorCycleTextHBlank
	.global colorNoScrollMain
	.global colorNoScrollSub
	.global colorHilightMain
	.global colorHilightSub
	.global colorPalMain
	.global colorPalSub
	.global colorPal1
	.global colorPal2

fxCopperTextOn:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =fxMode
	ldr r1, [r0]
	orr r1, #FX_COPPER_TEXT
	str r1, [r0]
	
	ldr r0, =colorPal1
	ldr r1, =colorPalMain
	ldr r2, =(256 * 2)
	bl dmaCopy
	
	ldr r0, =colorPal1
	ldr r1, =colorPalSub
	ldr r2, =(256 * 2)
	bl dmaCopy
	
	ldr r0, =colorNoScrollMain
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =colorNoScrollSub
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =colorHilightMain
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =colorHilightSub
	mov r1, #0
	str r1, [r0]
	
	ldmfd sp!, {r0-r2, pc}

	@ ---------------------------------------
	
fxCopperTextOff:

	stmfd sp!, {r0-r4, lr}
	
	ldr r0, =fxMode
	ldr r1, [r0]
	bic r1, #FX_COPPER_TEXT
	str r1, [r0]
	
	ldr r0, =BG_PALETTE
	ldr r1, =BG_PALETTE_SUB
	ldr r2, =COLOR_WHITE
	ldr r3, =(FONT_COLOR_OFFSET * 2)
	strh r2, [r0, r3]
	strh r2, [r1, r3]
	
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0
	
	bl dmaTransfer
	
	mov r0, #1
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0
	
	bl dmaTransfer
	
	ldmfd sp!, {r0-r4, pc}

	@ ---------------------------------------
	
fxColorCycleTextOn:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =fxMode
	ldr r1, [r0]
	orr r1, #FX_COLOR_CYCLE_TEXT
	str r1, [r0]
	
	ldmfd sp!, {r0-r1, pc}

	@ ---------------------------------------
	
fxColorCycleTextOff:

	stmfd sp!, {r0-r3, lr}
	
	ldr r0, =fxMode
	ldr r1, [r0]
	bic r1, #FX_COLOR_CYCLE_TEXT
	str r1, [r0]
	
	ldr r0, =BG_PALETTE
	ldr r1, =BG_PALETTE_SUB
	ldr r2, =COLOR_WHITE
	ldr r3, =(FONT_COLOR_OFFSET * 2)
	strh r2, [r0, r3]
	strh r2, [r1, r3]
	
	ldmfd sp!, {r0-r3, pc}

	@ ---------------------------------------
	
fxCopperTextVBlank:

	stmfd sp!, {r0-r4, lr}
	
	bl DC_FlushAll
	
	ldr r0, =colorNoScrollMain
	ldr r0, [r0]
	cmp r0, #1
	beq fxCopperTextVBlankScrollSkipMain
	
	ldr r0, =colorPalMain
	mov r1, r0
	add r0, #2
	ldr r2, =(255 * 2)
	bl dmaCopy
	
	ldr r0, =colorPalMain
	ldrh r1, [r0]
	ldr r2, =(255 * 2)
	strh r1, [r0, r2]
	
fxCopperTextVBlankScrollSkipMain:
	
	ldr r0, =colorNoScrollSub
	ldr r0, [r0]
	cmp r0, #1
	beq fxCopperTextVBlankScrollSkipSub
	
	ldr r0, =colorPalSub
	mov r1, r0
	add r0, #2
	ldr r2, =(255 * 2)
	bl dmaCopy
	
	ldr r0, =colorPalSub
	ldrh r1, [r0]
	ldr r2, =(255 * 2)
	strh r1, [r0, r2]

fxCopperTextVBlankScrollSkipSub:

	ldr r0, =colorPalMain
	ldr r1, =colorBufferMain
	ldr r2, =(256 * 2)
	bl dmaCopy
	
	ldr r0, =colorPalSub
	ldr r1, =colorBufferSub
	ldr r2, =(256 * 2)
	bl dmaCopy
	
	ldr r0, =colorHilightMain
	ldr r0, [r0]
	cmp r0, #0
	beq fxCopperTextVBlankContinueMain
	
	ldr r1, =colorBufferMain
	add r1, r0, lsl #4
	sub r1, #1
	ldr r2, =(8 * 2)
	ldr r0, =COLOR_HILIGHT
	bl dmaFillHalfWords
	
fxCopperTextVBlankContinueMain:

	ldr r0, =colorHilightSub
	ldr r0, [r0]
	cmp r0, #0
	beq fxCopperTextVBlankContinueSub
	
	ldr r1, =colorBufferSub
	add r1, r0, lsl #4
	sub r1, #1
	ldr r2, =(8 * 2)
	ldr r0, =COLOR_HILIGHT
	bl dmaFillHalfWords
	
fxCopperTextVBlankContinueSub:

	mov r0, #0								@ Dma channel
	ldr r1, =colorBufferMain				@ Source
	ldr r2, =BG_PALETTE						@ Dest
	ldr r3, =(FONT_COLOR_OFFSET * 2)
	add r2, r3
	mov r3, #1								@ Count
	ldr r4, =(DMA_ENABLE | DMA_REPEAT | DMA_START_HBL | DMA_DST_RESET)
	
	bl dmaTransfer
	
	mov r0, #1								@ Dma channel
	ldr r1, =colorBufferSub					@ Source
	ldr r2, =BG_PALETTE_SUB					@ Dest
	ldr r3, =(FONT_COLOR_OFFSET * 2)
	add r2, r3
	mov r3, #1								@ Count
	ldr r4, =(DMA_ENABLE | DMA_REPEAT | DMA_START_HBL | DMA_DST_RESET)
	
	bl dmaTransfer
	
	ldmfd sp!, {r0-r4, pc}

	@ ---------------------------------------
	
fxColorCycleTextHBlank:

	stmfd sp!, {r0-r6, lr}
	
	bl getRandom
	
	ldr r0, =BG_PALETTE
	ldr r1, =BG_PALETTE_SUB
	ldr r2, =colorOffset
	ldr r2, [r2]
	ldr r3, =(FONT_COLOR_OFFSET * 2)
	
	ldrh r5, [r0, r2]
	ldrh r6, [r1, r2]
	
	strh r5, [r0, r3]
	strh r6, [r1, r3]
	
	ldr r0, =colorWait
	ldr r1, [r0]
	ldr r2, =colorOffset
	ldr r3, [r2]
	add r1, #1
	cmp r1, #4
	moveq r1, #0
	moveq r3, r8
	andeq r3, #0xF
	str r1, [r0]
	str r3, [r2]
	
	ldmfd sp!, {r0-r6, pc}

	@ ---------------------------------------
	
	.data
	.align

colorNoScrollMain:
	.word 0
	
colorNoScrollSub:
	.word 0
	
colorHilightMain:
	.word 0
		
colorHilightSub:
	.word 0

colorOffset:
	.word 0
	
colorWait:
	.word 0
	
	.align
colorPal1:
	.hword 0x0c00,0x1c00,0x2800,0x3400,0x4400,0x5000,0x6000,0x6c00
	.hword 0x7c00,0x7c63,0x7cc6,0x7d4a,0x7dad,0x7e10,0x7e94,0x7ef7
	.hword 0x7ef7,0x7e94,0x7e10,0x7dad,0x7d4a,0x7cc6,0x7c63,0x7c00
	.hword 0x6c00,0x6000,0x5000,0x4400,0x3400,0x2800,0x1c00,0x0c00
	.hword 0x0063,0x00e5,0x0148,0x01ab,0x022d,0x0290,0x0313,0x0376
	.hword 0x03f8,0x0ff9,0x1bfa,0x2bfb,0x37fb,0x43fc,0x53fd,0x5ffd
	.hword 0x5ffd,0x53fd,0x43fc,0x37fb,0x2bfb,0x1bfa,0x0ff9,0x03f8
	.hword 0x0376,0x0313,0x0290,0x022d,0x01ab,0x0148,0x00e5,0x0063
	.hword 0x0003,0x0007,0x000a,0x000d,0x0011,0x0014,0x0018,0x001b
	.hword 0x001f,0x0c7f,0x18df,0x295f,0x35bf,0x421f,0x529f,0x5eff
	.hword 0x5eff,0x529f,0x421f,0x35bf,0x295f,0x18df,0x0c7f,0x001f
	.hword 0x001b,0x0018,0x0014,0x0011,0x000d,0x000a,0x0007,0x0003
	.hword 0x0842,0x0c63,0x14a5,0x1ce7,0x2529,0x294a,0x318c,0x39ce
	.hword 0x3def,0x4631,0x4e73,0x5294,0x5ad6,0x6318,0x6739,0x6f7b
	.hword 0x6f7b,0x6739,0x6318,0x5ad6,0x5294,0x4e73,0x4631,0x3def
	.hword 0x39ce,0x318c,0x294a,0x2529,0x1ce7,0x14a5,0x0c63,0x0842
	.hword 0x0c00,0x1c00,0x2800,0x3400,0x4400,0x5000,0x6000,0x6c00
	.hword 0x7c00,0x7c63,0x7cc6,0x7d4a,0x7dad,0x7e10,0x7e94,0x7ef7
	.hword 0x7ef7,0x7e94,0x7e10,0x7dad,0x7d4a,0x7cc6,0x7c63,0x7c00
	.hword 0x6c00,0x6000,0x5000,0x4400,0x3400,0x2800,0x1c00,0x0c00
	.hword 0x0063,0x00e5,0x0148,0x01ab,0x022d,0x0290,0x0313,0x0376
	.hword 0x03f8,0x0ff9,0x1bfa,0x2bfb,0x37fb,0x43fc,0x53fd,0x5ffd
	.hword 0x5ffd,0x53fd,0x43fc,0x37fb,0x2bfb,0x1bfa,0x0ff9,0x03f8
	.hword 0x0376,0x0313,0x0290,0x022d,0x01ab,0x0148,0x00e5,0x0063
	.hword 0x0003,0x0007,0x000a,0x000d,0x0011,0x0014,0x0018,0x001b
	.hword 0x001f,0x0c7f,0x18df,0x295f,0x35bf,0x421f,0x529f,0x5eff
	.hword 0x5eff,0x529f,0x421f,0x35bf,0x295f,0x18df,0x0c7f,0x001f
	.hword 0x001b,0x0018,0x0014,0x0011,0x000d,0x000a,0x0007,0x0003
	.hword 0x0842,0x0c63,0x14a5,0x1ce7,0x2529,0x294a,0x318c,0x39ce
	.hword 0x3def,0x4631,0x4e73,0x5294,0x5ad6,0x6318,0x6739,0x6f7b
	.hword 0x6f7b,0x6739,0x6318,0x5ad6,0x5294,0x4e73,0x4631,0x3def
	.hword 0x39ce,0x318c,0x294a,0x2529,0x1ce7,0x14a5,0x0c63,0x0842
	
	.align
colorPal2:
	.hword 0x0000,0x0000,0x0421,0x0421,0x0421,0x0842,0x0842,0x0842
	.hword 0x0c63,0x0c63,0x0c63,0x1084,0x1084,0x1084,0x14a5,0x14a5
	.hword 0x14a5,0x18c6,0x18c6,0x18c6,0x1ce7,0x1ce7,0x1ce7,0x2108
	.hword 0x2108,0x2108,0x2529,0x2529,0x2529,0x2529,0x294a,0x294a
	.hword 0x294a,0x2d6b,0x2d6b,0x2d6b,0x318c,0x318c,0x318c,0x35ad
	.hword 0x35ad,0x35ad,0x39ce,0x39ce,0x39ce,0x3def,0x3def,0x3def
	.hword 0x4210,0x4210,0x4210,0x4631,0x4631,0x4631,0x4a52,0x4a52
	.hword 0x4a52,0x4e73,0x4e73,0x4e73,0x5294,0x5294,0x5294,0x56b5
	.hword 0x56b5,0x56b5,0x5ad6,0x5ad6,0x5ad6,0x5ad6,0x5ef7,0x5ef7
	.hword 0x5ef7,0x6318,0x6318,0x6318,0x6739,0x6739,0x6739,0x6b5a
	.hword 0x6b5a,0x6b5a,0x6f7b,0x6f7b,0x6f7b,0x739c,0x739c,0x739c
	.hword 0x77bd,0x77bd,0x77bd,0x7bde,0x7bde,0x7bde,0x7fff,0x7fff
	.hword 0x7fff,0x7fff,0x7bde,0x7bde,0x7bde,0x77bd,0x77bd,0x77bd
	.hword 0x739c,0x739c,0x739c,0x6f7b,0x6f7b,0x6f7b,0x6b5a,0x6b5a
	.hword 0x6b5a,0x6739,0x6739,0x6739,0x6318,0x6318,0x6318,0x5ef7
	.hword 0x5ef7,0x5ef7,0x5ad6,0x5ad6,0x5ad6,0x5ad6,0x56b5,0x56b5
	.hword 0x56b5,0x5294,0x5294,0x5294,0x4e73,0x4e73,0x4e73,0x4a52
	.hword 0x4a52,0x4a52,0x4631,0x4631,0x4631,0x4210,0x4210,0x4210
	.hword 0x3def,0x3def,0x3def,0x39ce,0x39ce,0x39ce,0x35ad,0x35ad
	.hword 0x35ad,0x318c,0x318c,0x318c,0x2d6b,0x2d6b,0x2d6b,0x294a
	.hword 0x294a,0x294a,0x2529,0x2529,0x2529,0x2529,0x2108,0x2108
	.hword 0x2108,0x1ce7,0x1ce7,0x1ce7,0x18c6,0x18c6,0x18c6,0x14a5
	.hword 0x14a5,0x14a5,0x1084,0x1084,0x1084,0x0c63,0x0c63,0x0c63
	.hword 0x0842,0x0842,0x0842,0x0421,0x0421,0x0421,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

	.align
colorPalMain:
	.space (256 * 2)
	
	.align
colorPalSub:
	.space (256 * 2)

	.align
colorBufferMain:
	.space (256 * 2)
	
	.align
colorBufferSub:
	.space (256 * 2)
	
	.pool
	.end
