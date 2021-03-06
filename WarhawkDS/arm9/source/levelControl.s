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
	.global checkLevelControl
	.global showBossJump
	.global showLevelStart
	.global showLevelBack
	.global showLevelNext
	.global showGetReady
	.global updateGetReady
	.global showBossDie
	.global updateBossDie

checkLevelControl:

	stmfd sp!, {r0-r2, lr}

	ldr r1,=REG_KEYINPUT
	ldr r2,[r1]
	tst r2,#BUTTON_SELECT
	bleq showBossJump
	tst r2,#BUTTON_L
	bleq showLevelBack
	beq checkLevelControlDone
	tst r2,#BUTTON_R
	bleq showLevelNext
	beq checkLevelControlDone				@ still skips to end of level!
	tst r2,#BUTTON_START
	bleq initLevel
	bne checkLevelControlDone
	
	checkLevelControlDone:
	
	ldmfd sp!, {r0-r2, pc}
	
	@ ------------------------------------

showBossJump:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =vofsMain
	ldr r1, =256+32
	str r1, [r0]

	ldr r0, =vofsSub
	ldr r1, =256+32
	str r1, [r0]
	
	ldr r0, =yposMain
	ldr r1, =256+192
	str r1, [r0]

	ldr r0, =yposSub
	ldr r1, =256+192
	str r1, [r0]
	
	ldr r0, =pixelOffsetMain
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =pixelOffsetSub
	mov r1, #0
	str r1, [r0]
	
	bl drawMapScreenMain
	bl drawMapScreenSub
	
	ldmfd sp!, {r0-r1, pc}
	
	@ ===========================================================
	@ LEVEL START
	@ ===========================================================
	
showLevelStart:

	stmfd sp!, {r0, lr}
	
	bl fxOff
	bl fxFadeBlackInit
	bl fxFadeMax
	bl stopSound
	bl stopAudioStream
	bl initVideoMain
	bl initMainTiles
	bl initLevelScrollRegisters				@ Reset the scroll registers
	bl clearOAM
	bl initSprites
	bl initLevelSprites
	bl clearBG0
	bl clearBG1
	bl clearBG2
	bl clearBG3
	
	bl checkGameContinue
	
	bl drawMapScreenMain
	bl drawMapScreenSub
	bl drawSFMapScreenMain
	bl drawSFMapScreenSub
	bl drawSBMapScreenMain
	bl drawSBMapScreenSub
	bl levelDrift
	bl drawSprite
		
	@ Fade in
	
	@bl fxSpotlightIn
	bl fxFadeIn
	bl fxMosaicIn
	@bl fxScanline
	@bl fxWipeInLeft
	@bl fxCrossWipe
	@bl fxSineWobbleOn

	ldr r0, =inGameRawText					@ Read the path to the file
	bl playAudioStream						@ Play the audio stream
	
	bl showGetReady

	ldmfd sp!, {r0, pc}

	@ ------------------------------------
	
showLevelBack:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0,=levelNum
	ldr r1,[r0]
	sub r1,#1
	cmp r1,#0
	moveq r1,#LEVEL_COUNT
	str r1,[r0]
	
	bl initLevel
	
	ldmfd sp!, {r0-r1, pc}

	@ ------------------------------------

showLevelNext:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =levelNum
	ldr r1, [r0]
	add r1, #1
	cmp r1, #LEVEL_COUNT + 1
	moveq r1, #1
	beq showLevelNextEndOfGame
	str r1,[r0]
	
	bl initLevel

	b showLevelNextDone
	
showLevelNextEndOfGame:

	ldr r0, =optionGameModeCurrent
	ldr r0, [r0]
	
	ldr r1, =optionGameModeComplete
	ldr r2, [r1]
	
	cmp r0, #OPTION_GAMEMODECURRENT_NORMAL
	orreq r2, #OPTION_GAMEMODECOMPLETE_NORMAL
	cmp r0, #OPTION_GAMEMODECURRENT_MENTAL
	orreq r2, #OPTION_GAMEMODECOMPLETE_MENTAL
	
	str r2, [r1]

	bl writeOptions	
	bl showEndOfGame
	
showLevelNextDone:
	
	ldmfd sp!, {r0-r2, pc}

	@ ------------------------------------
	
showGetReady:

	stmfd sp!, {r0-r11, lr}
	
	ldr r0, =gameMode
	ldr r1, =GAMEMODE_GETREADY
	str r1, [r0]
	
	ldr r0, =getReadyText			@ Load out text pointer
	ldr r1, =11						@ x pos
	ldr r2, =10						@ y pos
	ldr r3, =0						@ Draw on sub screen
	bl drawText
	
	ldr r0, =levelText				@ Load out text pointer
	ldr r1, =12						@ x pos
	ldr r2, =10						@ y pos
	ldr r3, =1						@ Draw on main screen
	bl drawText
	
	ldr r10, =levelNum				@ Pointer to data
	ldr r10, [r10]					@ Read value
	mov r8, #10						@ y pos
	mov r9, #2						@ Number of digits
	mov r11, #18					@ x pos
	bl drawDigits					@ Draw

	bl fxCopperTextOn
	
	ldr r0, =3000								@ 3 seconds
	ldr r1, =timerDoneGetReady					@ Callback function address
	
	bl startTimer
	
	ldmfd sp!, {r0-r11, pc}
	
	@ ------------------------------------
	
updateGetReady:
	
	stmfd sp!, {r0-r2, lr}
	
	bl scrollStars								@ update scroll stars
	
	bl readInput								@ read the input
	
	cmp r0, #1									@ if it is 1, keep pressed (from no-key pressed)
	bne updareGetReadyDone
	
	ldr r1, =REG_KEYINPUT
	ldr r2, [r1]
	tst r2, #BUTTON_A
	bleq stopTimer
	bleq timerDoneGetReady
	
updareGetReadyDone:
	
	ldmfd sp!, {r0-r2, pc}
	
	@ ------------------------------------
	
timerDoneGetReady:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =gameMode
	ldr r1, =GAMEMODE_RUNNING
	str r1, [r0]
	
	bl clearBG0
	
	bl fxCopperTextOff
	
	ldmfd sp!, {r0-r1, pc} 					@ restore registers and return
	
	@---------------------------------

showBossDie:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =gameMode
	ldr r1, =GAMEMODE_BOSSDIE
	str r1, [r0]

	@ Anything to set up???
	
	@ Well we need a way to init a big boss explode, we can generate a random number
	@ from 0-95 and use that for the x and y of explosions and also file them from
	@ start to end, overwriting active number 128 (boss sprites)
	@ this may look ok???
	@ well, we need to set variables for bossExploder to use
	@ explodeSpriteBoss = current number of the sprite to use
	@ explodeSpriteBossCount = count the times through the loop
	@ when this has been done enough, we will need to set a little delay
	@ to wait for all explosions to have finished, then set levelEnd to 3
	@ That should be easy, will keep the exploding stuff in bosscode.s
	
	ldr r0,=explodeSpriteBoss
	mov r1,#17
	str r1,[r0]									@ set current sprite number
	ldr r0,=explodeSpriteBossCount
	mov r1,#0
	str r1,[r0]
	
	bl stopAudioStream
	bl stopSound
	@ PLAY A "LARGE" EXPLOSION SOUND HERE!!	
	bl playBossExplode2Sound
	
	ldmfd sp!, {r0-r1, pc}

	@ ------------------------------------

updateBossDie:

	stmfd sp!, {r0-r1, lr}
	
	bl moveShip									@ check and move your ship
	bl alienFireMove							@ check and move alien bullets
	bl fireCheck								@ check for your wish to shoot!
	bl drawScore								@ update the score with any changes
	bl moveAliens								@ move the aliens and detect colisions with you
	bl levelDrift								@ update level with the horizontal drift
	bl moveBullets								@ check and then moves bullets
	bl scrollStars								@ Scroll Stars (BG2,BG3)		
	bl drawSprite								@ drawsprites and do update bloom effect
	bl animateAliens
	bl checkBossInit							@ so we can still move him as he DIES	
	bl bossExploder

	ldr r0,=levelEnd
	ldr r1,[r0]
	cmp r1,#LEVELENDMODE_BOSSEXPLODE			@ if levelEnd=3, just wait for explosions to finish	
	bne updateBossDieDone
	cmp r1, #LEVELENDMODE_FADE_OUT
	beq updateBossDieDone
	
	ldr r0,=explodeSpriteBossCount				@ use this as a little delay to let explosions settle
	ldr r1,[r0]
	cmp r1,#127									@ delay for explosions
	beq updateBossDieEndOfLevel
	add r1,#1
	str r1,[r0]
	
	b updateBossDieDone
		
updateBossDieEndOfLevel:

	str r1,[r0]

@	ldr r2,=levelEnd
@	mov r1,#LEVELENDMODE_BOSSEXPLODE
@
@	str r1,[r2]
	

	ldr r0, =levelEnd
	ldr r1, =LEVELENDMODE_FADE_OUT
	str r1, [r0]

	ldr r0,=levelNum
	ldr r1,[r0]
	cmp r1,#16
	bne BigBossComethNo
		
		@ we are definatley gonna need some kind of transitions!!
		@ and perhaps big letters saying "WARNING" with a siren sound?

		ldr r0,=bossMan
		mov r1,#0							
		str r1,[r0]
	
		bl fxFadeBlackInit
		
		ldr r0, =fxFadeCallbackAddress
		ldr r1, =bigBossInit
		str r1, [r0]
		
		bl fxFadeOut
		
		b updateBossDieDone

	BigBossComethNo:
	
	bl fxFadeBlackInit
	
	ldr r0, =fxFadeCallbackAddress
	ldr r1, =showEndOfLevel
	str r1, [r0]
	
	bl fxFadeOut
		
updateBossDieDone:
	
	ldmfd sp!, {r0-r1, pc}

	@ ------------------------------------
	
	.pool
	.end
