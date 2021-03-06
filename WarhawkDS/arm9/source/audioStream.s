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
#include "audio.h"
#include "video.h"
#include "background.h"
#include "dma.h"
#include "interrupts.h"
#include "ipc.h"
#include "timers.h"

	#define MUSIC_CHANNEL	0

	#define STOP_SOUND		-1
	#define BUFFER_SIZE		4096
	#define AUDIO_FREQ		32000

	.arm
	.align
	.text
	.global playAudioStream
	.global stopAudioStream	
	.global audioStreamTimer1
	
initAudioStream:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =TIMER0_DATA
	ldr r1, =SOUND_FREQ(AUDIO_FREQ) * 2
	strh r1, [r0]
	
	ldr r0, =TIMER0_CR
	ldr r1, =(TIMER_ENABLE | TIMER_DIV_1)
	strh r1, [r0]
	
	ldr r0, =TIMER1_DATA
	ldr r1, =(0x10000 - (BUFFER_SIZE / 2))
	strh r1, [r0]

	ldr r0, =TIMER1_CR
	ldr r1, =(TIMER_ENABLE | TIMER_IRQ_REQ | TIMER_CASCADE)
	strh r1, [r0]
	
	ldmfd sp!, {r0-r1, pc}								@ Return
	
	@ ---------------------------------------------
	
playAudioStream:

	stmfd sp!, {r0-r2, lr}

	@ r0 = string pointer to music
	
	@bl stopAudioStream
	
	ldr r1, =backBuffer
	mov r2, #0
	str r2, [r1]
	
	ldr r1, =bufferPos
	mov r2, #0
	str r2, [r1]
	
	mov r1, r0											@ Move string pointer
	ldr r0, =fileName									@ Read address of fileName
	ldr r2, =256										@ Size == 256
	bl memcpy											@ Copy filename to fileName
		
	ldr r0, =fileName
	
	bl initFileStream									@ Initialize the file stream
	
	ldr r1, =fileSize									@ Read fileSize address
	str r0, [r1]										@ Write the filesize to it
	
	ldr r0, =buffer										@ Buffer address
	ldr r1, =(BUFFER_SIZE / 2)							@ Read the bufferSize address
	
	bl readFileStream									@ Read the next buffer of audio file
	bl playBuffer
	bl initAudioStream
	
	@ldr r0, =419000									@ Wait for ARM7 to "ketchup"
	@bl swiDelay
	
	bl swiWaitForVBlank
	
	ldmfd sp!, {r0-r2, pc}								@ restore registers and return

	@ ---------------------------------------------
	
stopAudioStream:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =buffer
	mov r1, #0
	ldr r2, =BUFFER_SIZE
	bl memset 
	
	ldr r0, =TIMER0_CR
	ldrh r1, [r0]
	bic r1, #TIMER_ENABLE
	strh r1, [r0]

	ldr r0, =TIMER1_CR
	ldrh r1, [r0]
	bic r1, #TIMER_ENABLE
	strh r1, [r0]
	
	ldr r0, =IPC_SOUND_DATA(MUSIC_CHANNEL)				@ Get the IPC sound data address
	mov r1, #STOP_SOUND									@ Get the sample address
	str r1, [r0]
	
	@ldr r0, =REG_IPC_SYNC
	@ldr r1, =IPC_SEND_SYNC(0)
	@strh r1, [r0]
	
	@ldr r0, =419000									@ Wait for ARM7 to "ketchup"
	@bl swiDelay
	
	bl swiWaitForVBlank
	
	ldmfd sp!, {r0-r1, pc}								@ restore registers and return

	@ ---------------------------------------------

playBuffer:

	stmfd sp!, {r0-r1, lr}

	ldr r0, =IPC_SOUND_LEN(MUSIC_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =BUFFER_SIZE								@ buffer size
	str r1, [r0]										@ Write the buffer size
	
	ldr r0, =IPC_SOUND_DATA(MUSIC_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =buffer										@ Get the sample address
	str r1, [r0]										@ Write the value
	
	@ldr r0, =REG_IPC_SYNC
	@ldr r1, =IPC_SEND_SYNC(0)
	@strh r1, [r0]
	
	ldmfd sp!, {r0-r1, pc}								@ restore registers and return
	
	@ ---------------------------------------------
	
audioStreamTimer1:

	stmfd sp!, {r0-r5, lr}
	
	ldr r0, =REG_IME									@ Turn off interrupts
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =buffer										@ Buffer address
	ldr r1, =(BUFFER_SIZE / 2)							@ Read the buffer size
	
	ldr r4, =backBuffer
	ldr r5, [r4]
	cmp r5, #0
	moveq r5, #1
	addeq r0, r1
	movne r5, #0
	str r5, [r4]
	
	bl readFileStream									@ Read the next BUFFER_SIZE of audio file
	
	bl DC_FlushAll										@ Clear cache
	
	ldr r0, =bufferPos									@ Read the bufferPos address
	ldr r1, [r0]										@ Read the bufferPos value
	ldr r2, =fileSize									@ Read the fileSize address
	ldr r2, [r2]										@ Read the fileSize value
	cmp r1, r2											@ Compare bufferPos to fileSize
	movgt r1, #0										@ if greater than reset bufferPos
	
	push { r0-r2 }
	
	blgt resetFileStream
	
	pop { r0-r2 }
	
	ldr r3, =(BUFFER_SIZE / 2)							@ Read the buffer size
	add r1, r3											@ Add buffer size to bufferPos
	str r1, [r0]										@ Write value back to bufferPos
	
	ldr r0, =REG_IME									@ Turn interrupts back on
	mov r1, #1
	str r1, [r0]
		
	ldmfd sp!, {r0-r5, pc}								@ Return
	
	@ ---------------------------------------------

	.data
	.align
	
backBuffer:
	.word 0
	
bufferPos:
	.word 0
	
fileSize:
	.word 0
	
fileName:
	.space 256
	
buffer:
	.space BUFFER_SIZE
	
	.pool
	.end
