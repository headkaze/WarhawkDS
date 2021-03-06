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
#include "sprite.h"
#include "ipc.h"

	.arm
	.align
	.text
	.global showGameStart
	.global showGameStop
	.global showGamePause
	.global checkGamePause
	.global updateGameUnPause
	.global checkGameOver
	
showGameStart:

	stmfd sp!, {lr}
	
	ldr r0, =fxFadeOutBusy
	ldr r0, [r0]
	cmp r0, #FADE_BUSY
	beq showGameStartDone

	bl initData									@ setup actual game data

	bl fxFadeBlackInit
	
	ldr r0, =fxFadeCallbackAddress
	ldr r1, =initLevel
	str r1, [r0]
	
	bl fxFadeOut
	
showGameStartDone:
	
	ldmfd sp!, {pc}
	
	@ ------------------------------------
	
showGameStop:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =gameMode
	ldr r1, =GAMEMODE_STOPPED
	str r1, [r0]
		
	ldmfd sp!, {r0-r1, pc}

	@ ------------------------------------
	
checkGamePause:

	stmfd sp!, {r0-r1, lr}

	ldr r0, =REG_KEYINPUT						@ Read Key Input
	ldr r1, [r0]
	tst r1, #BUTTON_START						@ Start button pressed?
	bleq showGamePause
		
	ldmfd sp!, {r0-r1, pc}
	
	@ ------------------------------------

showGamePause:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =gameMode
	ldr r1,[r0]						@ load current mode
	ldr r2,=gameModeBackup
	str r1,[r2]						@ and store a backup
	ldr r1, =GAMEMODE_PAUSED
	str r1, [r0]
	
@	ldr r0, =pausedText				@ Load out text pointer
@	ldr r1, =13						@ x pos
@	ldr r2, =10						@ y pos
@	ldr r3, =0						@ Draw on sub screen
@	bl drawText
	
	ldr r0, =pausedText				@ Load out text pointer
	ldr r1, =13						@ x pos
	ldr r2, =10						@ y pos
	ldr r3, =1						@ Draw on main screen
	bl drawText

	ldr r0, =pausedOptionText				@ Load out text pointer
	ldr r1, =5						@ x pos
	ldr r2, =10						@ y pos
	ldr r3, =0						@ Draw on main screen
	bl drawText
	
	bl fxCopperTextOn
	
	ldr r0, =buttonWaitPress
	mov r1,#1
	str r1,[r0]						@ set the button to active
	mov r1,#0
	ldr r0, =pauseStartHeld
	str r1,[r0]
		
	ldmfd sp!, {r0-r2, pc}
	
	@ ------------------------------------
	
updateGameUnPause:								@ SORRY about messing with this HK!! :)

	stmfd sp!, {r0-r2, lr}

	ldr r0,=pauseStartHeld
	ldr r1,[r0]
	cmp r1,#1
	beq showGameUnPause

	mov r1,#BUTTON_START						@ set keyWait to check for START as an option
	bl keyWait									@ ANY BL from here crashes?
	cmp r1,#1
	beq updateGameUnPauseWait

		ldr r0, =buttonWaitPress	
		mov r1,#1
		str r1,[r0]								@ set the button to active, we need this clear for release
		ldr r0, =pauseStartHeld
		str r1,[r0]								@ tell the code we are waiting for release to continue

	updateGameUnPauseWait:	

	ldr r2, =REG_KEYINPUT						@ Read key input register
	ldr r3, [r2]								@ Read key value
	tst r3,#BUTTON_SELECT
	
	beq showGameUnPauseQuit

	ldmfd sp!, {r0-r2, pc}

showGameUnPause:

	mov r1,#BUTTON_START						@ set keyWait to check for START as an option
	bl keyWait									@ ANY BL from here crashes?
	ldr r1,=buttonWaitPress
	ldr r0,[r1]
	cmp r0,#0
	bne showGameUnPauseWait

		ldr r0, =gameMode
		ldr r2, =gameModeBackup
		ldr r1,[r2]
		str r1, [r0]
		bl fxCopperTextOff
		bl clearBG0Partial

	showGameUnPauseWait:
	ldmfd sp!, {r0-r2, pc}
	
showGameUnPauseQuit:

	bl showTitleScreen

	ldmfd sp!, {r0-r2, pc}
		
	@ ------------------------------------
	
checkGameOver:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =energy
	ldr r1, [r0]
	cmp r1, #0
	beq activatePlayerDeath
	
	b checkGameOverDone

activatePlayerDeath:

	ldr r0,=deathMode
	ldr r1,[r0]
	cmp r1,#DEATHMODE_STILL_ACTIVE
	moveq r1,#1
	str r1,[r0]
	
checkGameOverDone:
		
	ldmfd sp!, {r0-r1, pc}
	
	@ ------------------------------------

pauseStartHeld:
	.word 0
gameModeBackup:
	.word 0
	
	.pool
	.end
