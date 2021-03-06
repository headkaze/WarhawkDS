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
	.global moveStandardShot
	.global moveTrackerShot
	.global	moveAccelShot
	.global	moveRippleShot
	.global moveMineShot
	.global moveRippleShotSingle
	.global moveDirectShot
	.global moveAngleShot
	.global moveBananaShot
	.global moveGableShot
	.global moveTrackExplodeShot

@
@	Every move in this code should also have a "init" function in firealieninit.s
@
@	Passed to any function used here are:
@
@	r2 		= Offset to our bullet data	(use sptXXXXOffs)
@	r3		= Shot type (this will be needed if several types of shots are combined)
@	r0/r1 	= Players x/y coord
@
@	A check for >768 (base of screen) does not need to be done on a falling bullet
@	as drawSprite.s takes care of that check - thankfully

@
@ "MOVE" - "Standard shots 1-8"
@		1-4 	are standard directional
@		5-6 	are left/right with the addition of a move in time with scroll vertically
@		7-8		are left/right with the addition of a move with scroll vertically x2
@				This shot type is directly affected by "shotSpeed"!
	moveStandardShot:
	stmfd sp!, {r0-r10, lr}	
		
		mov r4,#SPRITE_FIRE_SPEED_OFFS
		ldr r5,[r2,r4]			@ r5=shotSpeed
		cmp r3,#1				@ Standard UP
		bne standard1
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			sub r1,r5
			str r1,[r2,r4]
			cmp r1,#352
			bpl standard1
				mov r1,#0
				str r1,[r2]
		standard1:
		cmp r3,#2				@ Standard RIGHT
		bne standard2
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			add r1,r5
			str r1,[r2,r4]
			cmp r1,#384
			bmi standard2
				mov r1,#0
				str r1,[r2]
		standard2:
		cmp r3,#3				@ Standard DOWN
		bne standard3
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			add r1,r5
			str r1,[r2,r4]
		standard3:
		cmp r3,#4				@ Standard LEFT
		bne standard4
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			subs r1,r5
			str r1,[r2,r4]
			bpl standard4
				mov r1,#0
				str r1,[r2]
		standard4:
		cmp r3,#5				@ Standard LEFT with Scroll Drift
		bne standard5
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			add r1,#1
			str r1,[r2,r4]
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			subs r1,r5
			str r1,[r2,r4]
			cmp r1,#0
			bpl standard5
				mov r1,#0
				str r1,[r2]	
		standard5:			
		cmp r3,#6				@ Standard RIGHT with Scroll Drift
		bne standard6
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			add r1,#1
			str r1,[r2,r4]
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			add r1,r5
			str r1,[r2,r4]
			cmp r1,#384
			bmi standard6
				mov r1,#0
				str r1,[r2]
		standard6:
		cmp r3,#7				@ Standard LEFT with Scroll Driftx2
		bne standard7
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			add r1,#2
			str r1,[r2,r4]
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			subs r1,r5
			str r1,[r2,r4]
			cmp r1,#0
			bpl standard7
				mov r1,#0
				str r1,[r2]	
		standard7:			
		cmp r3,#8				@ Standard RIGHT with Scroll Driftx2
		bne standard8
			mov r4,#SPRITE_Y_OFFS
			ldr r1,[r2,r4]
			add r1,#2
			str r1,[r2,r4]
			mov r4,#SPRITE_X_OFFS
			ldr r1,[r2,r4]
			add r1,r5
			str r1,[r2,r4]
			cmp r1,#384
			bmi standard8
				mov r1,#0
				str r1,[r2]
		standard8:		


	ldmfd sp!, {r0-r10, pc}
	
@
@ "MOVE" - "Tracker shot 9"			@ slightly more complex but still.....
@									@ "FireSpeed" is the rate of FALL
	moveTrackerShot:
	stmfd sp!, {r0-r10, lr}
	@ first, sheck the bullets coord in relation to your x (r0)

		mov r6,#SPRITE_SPEED_X_OFFS				@ r6 is index to bullex x speed
		ldr r7,[r2,r6]					@ r7 is the bullets current speed
	
		mov r4,#SPRITE_SPEED_DELAY_X_OFFS		@ Update the speed delay
		ldr r5,[r2,r4]					@ r5 = speed delay x
		subs r5,#1						@ take 1 off
		str r5,[r2,r4]					@ put it back
		cmp r5,#0						@ if <> 0
		bpl tShotDone					@ carry on
		mov r5,#12						@ else reset counter
		str r5,[r2,r4]					@ store it and allow update of speed
	
		mov r4,#SPRITE_X_OFFS
		ldr r4,[r2,r4]					@ r4 = bullet X coord

		cmp r4,r0						@ is bullet left or right of players x (r0)
		beq tShotDone					@ it is the same, we will not do anything
		bpl tShotLeft					@ if right, go left - else, go right
	
		tShotRight:		
			add r7,#1					@ add 1 to the speed
			cmp r7,#2					@ compare with current speed
			movgt r7,#2					@ if greater - max maximum
			str r7,[r2,r6]				@ store r7 to speed x
			b tShotDone

		tShotLeft:
			subs r7,#1					@ sub 1 from the speed			
			cmp r7,#-2					@ compre with current speed
			movlt r7,#-2				@ if it is less than, reset to maximum negative!
			str r7,[r2,r6]				@ store r7 to speed x

		tShotDone:

		mov r4,#SPRITE_X_OFFS			
		ldr r5,[r2,r4]					@ load our bullet x pos
		adds r5,r7						@ add/sub our speed
		str r5,[r2,r4]					@ store it back

		mov r4,#SPRITE_FIRE_SPEED_OFFS
		ldr r7,[r2,r4]					@ r7=our fire speed

		mov r4,#SPRITE_Y_OFFS
		ldr r5,[r2,r4]
		add r5,r7						@ add speed to bullet Y
		str r5,[r2,r4]					@ put it back

	ldmfd sp!, {r0-r10, pc}
	
	
@
@ "MOVE" - "Acceleration shot 10"		@ a shot that accelerates on fire (Nasty!)
@ 										@ "FireSpeed" has no affect on this shot type
	moveAccelShot:
	stmfd sp!, {r0-r10, lr}
	@ first, sheck the bullets coord in relation to your x (r0)
		mov r6,#SPRITE_SPEED_Y_OFFS
		ldr r8,[r2,r6]
		mov r6,#SPRITE_SPEED_DELAY_Y_OFFS		@ r6 is index to bullex y delay
		ldr r7,[r2,r6]					@ r7 is the bullets current delay
		add r7,#1
		str r7,[r2,r6]
		mov r5,#12						@ All we are doing here is using Y speed
		sub r5,r8,lsl #1				@ to make the delay exponetial :)
		cmp r7,r5						@ if > then accelerate shot
		bmi accShotUpdate
			mov r7,#0					@ reset delay
			str r7,[r2,r6]
			mov r6,#SPRITE_SPEED_Y_OFFS
			ldr r7,[r2,r6]
			add r7,#1					@ add 1 to y speed
			cmp r7,#8					@ if >, keep the same
			moveq r7,#8
			str r7,[r2,r6]				@ store speed back
		accShotUpdate:
			mov r6,#SPRITE_SPEED_Y_OFFS
			ldr r7,[r2,r6]	
			mov r4,#SPRITE_Y_OFFS			
			ldr r5,[r2,r4]					@ load our bullet Y pos
			add r5,r7						@ add/sub our speed
			str r5,[r2,r4]					@ store it back
			cmp r5,#768
			bmi accShotActive
				mov r1,#0
				str r1,[r2]					@ kill bullet if off screen
		accShotActive:

	ldmfd sp!, {r0-r10, pc}
	
@
@ "MOVE" - "Ripple shot 11"		@ a shot that "wibbles" on fire
	moveRippleShot:
	stmfd sp!, {r0-r10, lr}
		mov r4,#SPRITE_SPEED_DELAY_X_OFFS
		ldr r5,[r2,r4]					@ load our BACKUP X coord into R5 (modify this and store in ACTUAL)
			
		mov r6,#SPRITE_SPEED_X_OFFS				@ speed X is the possiion in the sine data
		ldr r8,[r2,r6]					@ r8 = sine number, now load it from ripple sine
		ldr r9,=fireRippleSine
		ldrsb r4,[r9,r8]				@ r4 = value in sine at r9 + r8
		adds r5,r4						@ add current sine to X pos BACKUP (starts at 0)
		mov r4,#SPRITE_X_OFFS
		str r5,[r2,r4]					@ store it back in our ACTUAL X coord
			
		add r8,#1						@ add to sine offset
		cmp r8,#48						@ we have 48 units in sine (0-47)
		moveq r8,#0						@ so, if we excede - loop!
		str r8,[r2,r6]					@ and put the little bugger back
		
		mov r7,#SPRITE_FIRE_SPEED_OFFS
		ldr r7,[r2,r7]					@ get speed of bullet
		
		mov r6,#SPRITE_Y_OFFS				@ get y coord
		ldr r5,[r2,r6]
		add r5,r7
		str r5,[r2,r6]					@ put it back!
		
	ldmfd sp!, {r0-r10, pc}

@
@ "MOVE" - "Mine shot 13"		@ a shot that launches, sits, and explodes!
	moveMineShot:

	stmfd sp!, {r0-r10, lr}

		mov r6,#SPRITE_SPEED_Y_OFFS
		ldr r7,[r2,r6]					@ r7 = y speed and r6 is offset

		@ First we need to slow the mine down
		mov r8,#SPRITE_SPEED_DELAY_Y_OFFS
		ldr r5,[r2,r8]					@ load our delay
		add r5,#1						@ add 1
		cmp r5,#12						@ check if it is time to slow
		moveq r5,#0						@ zero delay
		str r5,[r2,r8]					@ put it back
		bne iMineNot					@ if not...
			subs r7,#1					@ take one off our Y speed
			movmi r7,#0					@ no negatives here!
			str r7,[r2,r6]				@ put it back!
		iMineNot:
		
		mov r6,#SPRITE_SPEED_DELAY_X_OFFS
		ldr r5,[r2,r6]					@ load our EXPLODE delay
		sub r5,#1
		str r5,[r2,r6]
		cmp r5,#15
		bne mineBloomPass
			mov r6,#SPRITE_BLOOM_OFFS
			mov r5,#16					@ set a little bloom for when nearly EXPLODED
			str r5,[r2,r6]
		mineBloomPass:
		cmp r5,#0
		bne mineNoExplode
			bl playAlienExplodeScreamSound
			mov r6,#SPRITE_BLOOM_OFFS
			mov r5,#16					@ set a little bloom to whiten initial explosion
			str r5,[r2,r6]
			mov r6,#5					@ set mine to an explosion
			str r6,[r2]
			mov r6,#14					@ set the initial explosion frame
			mov r8,#SPRITE_OBJ_OFFS			
			str r6,[r2,r8]
			mov r6,#4					@ reset the explode delay
			mov r8,#SPRITE_EXP_DELAY_OFFS
			str r6,[r2,r8]
			b mineShotActive
		mineNoExplode:
		mov r6,#SPRITE_Y_OFFS				
		ldr r5,[r2,r6]					@ r5 = y coord
		add r5,r7						@ add our speed
		str r5,[r2,r6]					@ put it back
		cmp r5,#768						@ check if off screen
		bmi mineShotActive
			mov r1,#SPRITE_KILL
			mov r6,#SPRITE_Y_OFFS
			str r1,[r2,r6]
		mineShotActive:
		
	
	ldmfd sp!, {r0-r10, pc}	

@
@ "MOVE" - "Angled Shot 14"				@ a shot that Shoots to an angle (of Sorts)
	moveAngleShot:
	stmfd sp!, {r0-r10, lr}

		@ first to the X move
		@ check the delay (sub from the delay and if -N, reset and move)
		@ we use SPRITE_TRACK_X_OFFS and SPRITE_TRACK_Y_OFFS to restore delays
		mov r6,#SPRITE_SPEED_DELAY_X_OFFS
		ldr r5,[r2,r6]
		subs r5,#1
		str r5,[r2,r6]
		cmp r5,#0
		bgt noAngleX
			mov r7,#SPRITE_TRACK_X_OFFS
			ldr r5,[r2,r7]
			str r5,[r2,r6]			@ reset delay
			mov r6,#SPRITE_X_OFFS
			ldr r5,[r2,r6]			@ r5=Xcoord
			mov r8,#SPRITE_SPEED_X_OFFS
			ldrsb r8,[r2,r8]		@ r8=X speed
			adds r5,r8				@ add to X coord
			str r5,[r2,r6]			@ store it back	
		noAngleX:

		mov r6,#SPRITE_SPEED_DELAY_Y_OFFS
		ldr r5,[r2,r6]
		subs r5,#1
		str r5,[r2,r6]
		bgt noAngleY

			mov r7,#SPRITE_TRACK_Y_OFFS
			ldr r5,[r2,r7]
			str r5,[r2,r6]			@ reset delay
			mov r6,#SPRITE_Y_OFFS
			ldr r5,[r2,r6]			@ r5=Ycoord
			mov r8,#SPRITE_SPEED_Y_OFFS
			ldrsb r8,[r2,r8]		@ r8=Y speed
			adds r5,r8				@ add to Y coord
			str r5,[r2,r6]			@ store it back
		noAngleY:
		
	ldmfd sp!, {r0-r10, pc}	

@
@ "MOVE" - "Ripple single 15 & 16"		@ a shot that "wibbles" on fire (single bullet)
	moveRippleShotSingle:
	stmfd sp!, {r0-r10, lr}
		mov r4,#SPRITE_SPEED_DELAY_X_OFFS
		ldr r5,[r2,r4]					@ load our BACKUP X coord into R5 (modify this and store in ACTUAL)
			
		mov r6,#SPRITE_SPEED_X_OFFS				@ speed X is the possiion in the sine data
		ldr r8,[r2,r6]					@ r8 = sine number, now load it from ripple sine
		ldr r9,=fireRippleSine
		ldrsb r4,[r9,r8]				@ r4 = value in sine at r9 + r8
		adds r5,r4						@ add current sine to X pos BACKUP (starts at 0)
		mov r4,#SPRITE_X_OFFS
		str r5,[r2,r4]					@ store it back in our ACTUAL X coord
			
		add r8,#1						@ add to sine offset
		cmp r8,#48						@ we have 48 units in sine (0-47)
		moveq r8,#0						@ so, if we excede - loop!
		str r8,[r2,r6]					@ and put the little bugger back
		
		mov r6,#SPRITE_Y_OFFS				@ get y coord
		ldr r5,[r2,r6]
		mov r7,#SPRITE_FIRE_SPEED_OFFS
		ldr r8,[r2,r7]
		add r5,r8						@ add y speed
		str r5,[r2,r6]					@ put it back!
		
	ldmfd sp!, {r0-r10, pc}	

@
@ "MOVE" - "Direct Shot 17"				@ a shot that Shoots to a set coord (single bullet)
	moveDirectShot:
	stmfd sp!, {r0-r10, lr}
		
		@ we use SPRITE_TRACK_X_OFFS and SPRITE_TRACK_Y_OFFS to restore delays
		mov r6,#SPRITE_SPEED_DELAY_X_OFFS
		ldr r5,[r2,r6]				@ format 20.12
		ldr r9,=0xFFF				@ AND value to grab fractional
		mov r7,r5					@ use a backup in r7
		cmp r7,#0
		beq directXUpdate		
		lsr r7,#12					@ convert to the integer
		subs r7,#1					@ take one off our delay
		lsl r7,#12					@ return to fixed point
		and r5,r9					@ seperate the fractional
		mov r9,r5					@ store that for later in r9
		add r5,r7					@ add the fixed point whole back
		str r5,[r2,r6]				@ and return safely :)
		bgt noDirectX				@ act on our SUBS earlier
			mov r7,#SPRITE_TRACK_X_OFFS
			ldr r10,[r2,r7]			@ load our backup stepping in r10
			add r10,r9				@ add the fractional from earlier
			str r10,[r2,r6]			@ and store this for our next delay
			directXUpdate:
			mov r6,#SPRITE_X_OFFS
			ldr r5,[r2,r6]			@ r5=Xcoord
			mov r8,#SPRITE_SPEED_X_OFFS
			ldrsb r8,[r2,r8]		@ r8=X speed
			adds r5,r8				@ add to X coord
			cmp r5,#384
				bpl directDeath
			cmp r5,#0
				bmi directDeath
			str r5,[r2,r6]			@ store it back	
		noDirectX:
		mov r6,#SPRITE_SPEED_DELAY_Y_OFFS
		ldr r5,[r2,r6]				@ format 20.12
		ldr r9,=0xFFF				@ AND value to grab fractional
		mov r7,r5					@ use a backup in r7
		cmp r7,#0
		beq DirectYUpdate
		lsr r7,#12					@ convert to the integer		
		subs r7,#1					@ take one off our delay
		lsl r7,#12					@ return to fixed point
		and r5,r9					@ seperate the fractional
		mov r9,r5					@ store that for later in r9
		add r5,r7					@ add the fixed point whole back
		str r5,[r2,r6]				@ and return safely :)
		bgt noDirectY				@ act on our SUBS earlier
			mov r7,#SPRITE_TRACK_Y_OFFS
			ldr r10,[r2,r7]			@ load our backup stepping in r10
			add r10,r9				@ add the fractional from earlier
			str r10,[r2,r6]			@ and store this for our next delay	
		DirectYUpdate:
			mov r6,#SPRITE_Y_OFFS	@
			ldr r5,[r2,r6]			@ r5=ycoord
			mov r8,#SPRITE_SPEED_Y_OFFS
			ldrsb r8,[r2,r8]		@ r8=y speed
			adds r5,r8				@ add speed to y coord
			cmp r5,#364
				bmi directDeath
			cmp r5,#788
				bpl directDeath
			str r5,[r2,r6]			@ store it back
		noDirectY:	
			ldmfd sp!, {r0-r10, pc}	
		directDeath:
			mov r1,#SPRITE_KILL
			mov r6,#SPRITE_Y_OFFS
			str r1,[r2,r6]
	ldmfd sp!, {r0-r10, pc}	

@
@ "MOVE" - "Banana shot 20"		@ strange tracking shot
	moveBananaShot:
	stmfd sp!, {r0-r10, lr}
	@ now we need to check out flag, if 1 = curving shot, 0 = still faling

		mov r7,#SPRITE_ANGLE_OFFS
		ldr r6,[r2,r7]
		cmp r6,#0
		bne moveBananaCurve
			@ still a standard movement
			mov r7,#SPRITE_FIRE_SPEED_OFFS
			ldr r7,[r2,r7]					@ get speed of bullet
		
			mov r6,#SPRITE_Y_OFFS			@ get y coord
			ldr r5,[r2,r6]
		
			ldr r0,=spriteY	
			ldr r0,[r0]						@ r0=players Y coord
			sub r0,r7,lsl#3						@ take it off player y coord
			sub r0,r7
			cmp r5,r0						@ is bullet lower than calculated player y?						
			ble moveBananaNoUpdate
				@ ok, we are now ready to curve the shot towards the player
				ldr r0,=spriteX
				ldr r0,[r0]
				ldr r1,=horizDrift
				ldr r1,[r1]
				add r0,r1					@ r0=player X (drift corrected)
				mov r6,#SPRITE_X_OFFS
				ldr r5,[r2,r6]				@ r5=Alien bullet
				cmp r5,r0
				movle r3,#1
				movgt r3,#-1
				
				mov r6,#SPRITE_SPEED_X_OFFS
				str r3,[r2,r6]				@ set the "signed" X speed
				mov r6,#SPRITE_ANGLE_OFFS
				mov r3,#1
				str r3,[r2,r6]				@ set to curved shot
		
			moveBananaDone:
		ldmfd sp!, {r0-r10, pc}
		moveBananaCurve:
			@ now, we need to check the delay in SPRITE_SPEED_DELAY_X_OFFS
			@ and when 8 (for eg) do the curve adjust
			mov r4,#SPRITE_SPEED_Y_OFFS
			ldr r4,[r2,r4]
			mov r6,#SPRITE_SPEED_DELAY_X_OFFS
			ldr r5,[r2,r6]
			add r5,#1
			str r5,[r2,r6]
			mov r0,#8
			subs r0,r4
			
			cmp r5,r0
			bne moveBananaNoUpdate
				@ ok, time to update curve..
				mov r5,#0
				str r5,[r2,r6]				@ reset delay
				
				mov r6,#SPRITE_SPEED_X_OFFS
				ldr r0,[r2,r6]
				cmp r0,#0
				bpl mbanana1
				subs r0,#1
				mov r1,#SPRITE_SPEED_Y_OFFS
				ldr r1,[r2,r1]				
				rsb r1,r1,#0
				cmp r0,r1
				movlt r0,r1
				b mbanana2
				mbanana1:
				add r0,#1
				mov r1,#SPRITE_SPEED_Y_OFFS
				ldr r1,[r2,r1]	
				cmp r0,r1
				movgt r0,r1
				mbanana2:
				str r0,[r2,r6]
				
				mov r6,#SPRITE_FIRE_SPEED_OFFS
				ldr r0,[r2,r6]
				cmp r0,#0
				beq moveBananaNoUpdate
				
				sub r0,#1
				str r0,[r2,r6]
			moveBananaNoUpdate:
			
			mov r6,#SPRITE_SPEED_X_OFFS
			ldr r0,[r2,r6]
			mov r5,#SPRITE_X_OFFS
			ldr r1,[r2,r5]
			adds r1,r0
			str r1,[r2,r5]
			
			cmp r1,#0
			bmi killBanana
			cmp r1,#384
			bpl killBanana
			
			mov r6,#SPRITE_Y_OFFS
			ldr r0,[r2,r6]
			mov r5,#SPRITE_FIRE_SPEED_OFFS
			ldr r1,[r2,r5]
			add r0,r1
			str r0,[r2,r6]
	
		ldmfd sp!, {r0-r10, pc}

		killBanana:
			mov r1,#SPRITE_KILL
			mov r6,#SPRITE_Y_OFFS
			str r1,[r2,r6]
	ldmfd sp!, {r0-r10, pc}			

@
@ "MOVE" - "Gable shot 21"		@ twin spread shot
	moveGableShot:
	stmfd sp!, {r0-r10, lr}
	@ first we need to update x/y, then check the delay and if 0, make the bullet a standard down shot
	
	mov r7,#SPRITE_X_OFFS
	ldr r6,[r2,r7]							@ r6= X coord
	mov r0,#SPRITE_SPEED_X_OFFS
	ldr r1,[r2,r0]							@ r1= speed of X (signed)
	adds r6,r1
	str r6,[r2,r7]							@ store new X coord

	mov r7,#SPRITE_Y_OFFS
	ldr r6,[r2,r7]							@ r6= y coord
	add r6,#1
	str r6,[r2,r7]							@ store new Y back

	mov r7,#SPRITE_SPEED_DELAY_X_OFFS
	ldr r6,[r2,r7]
	add r6,#1
	str r6,[r2,r7]
	cmp r6,#14
	beq gableShotDone

		ldmfd sp!, {r0-r10, pc}	

	gableShotDone:
	@ now we need to convert the shot to a downward shot
	
	mov r7,#SPRITE_FIRE_TYPE_OFFS
	mov r6,#3
	str r6,[r2,r7]	

	ldmfd sp!, {r0-r10, pc}	

@
@ "MOVE" - "Track Explode shot 23"		@ tracks for a bit and then explodes
	moveTrackExplodeShot:
	@ I ""MUST"" RECODE THIS - IT IS SHIT!!! (Using 12.20 fixed somehow)
	stmfd sp!, {r0-r10, lr}
	@ First, do X, check the delay and update speeds if delay at fixed value.
	ldr r0,=spriteX
	ldr r0,[r0]
	ldr r1,=horizDrift
	ldr r1,[r1]
	add r0,r1							@ r0 = Players X
	
	mov r1,#SPRITE_SPEED_DELAY_X_OFFS
	ldr r3,[r2,r1]
	add r3,#1
	str r3,[r2,r1]

	mov r8,#SPRITE_X_OFFS
	ldr r7,[r2,r8]					@ r7=alien x coord
	mov r4,#SPRITE_SPEED_X_OFFS
	ldr r5,[r2,r4]					@ r5=X speed (signed)
	mov r6,#SPRITE_FIRE_SPEED_OFFS
	ldr r6,[r2,r6]					@ r6=max speed of fire	

	mov r9,r5
	teq r9,#0						@ check the sign of r9
	rsbmi r9,r9,#0					@ make it positive

	cmp r3,#12
	bne TExpXno
		@ now we need to update X speed based on X coord to Player X
		cmp r7,r0						@ is alien X > player X
		bgt TExpXLeft
			@ ok, we need to head right
			adds r5,#1
			cmp r5,r6
			movpl r5,r6
			b TExpXno
		TExpXLeft:
		blt TExpXno
			subs r5,#1
			rsb r6,r6,#0
			cmp r5,r6
			movlt r5,r6	
	TExpXno:
		str r5,[r2,r4]
		adds r7,r5
		cmp r7,#16
		movmi r7,#16		
		str r7,[r2,r8]
	
	mov r8,#SPRITE_Y_OFFS
	ldr r7,[r2,r8]					@ r7=alien y coord
	mov r4,#SPRITE_SPEED_Y_OFFS
	ldr r5,[r2,r4]					@ r5=y speed (signed)
	mov r6,#SPRITE_FIRE_SPEED_OFFS
	ldr r6,[r2,r6]					@ r6=max speed of fire	
	ldr r0,=spriteY
	ldr r0,[r0]

	mov r10,r5
	teq r10,#0						@ check the sign of r10
	rsbmi r10,r10,#0				@ make it positive
	add r9,r10
	
	cmp r3,#12
	bne TExpYno
		mov r3,#0
		str r3,[r2,r1]					@ reset the delay
		@ now we need to update y speed based on y coord to Player y
		cmp r7,r0						@ is alien y > player y
		bgt TExpYUp
			@ ok, we need to head down
			adds r5,#1
			cmp r5,r6
			movpl r5,r6
			b TExpYno
		TExpYUp:
			subs r5,#1
			rsb r6,r6,#0
			cmp r5,r6
			movlt r5,r6	
	TExpYno:
		str r5,[r2,r4]
		adds r7,r5
		cmp r7,#16
		movmi r7,#16		
		str r7,[r2,r8]

	@ now that is all done, we need to check our timer for "explode time"
	mov r0,#SPRITE_ANGLE_OFFS
	ldr r1,[r2,r0]
	add r1,r9						@ r9 is out calculate "distance travelled"
	str r1,[r2,r0]					@ it is by no means accurate, but will do
	
	cmp r1,#400						@ duration of "life"
	blt TExplodeDone
	
		@ ok, time to make it an explosion
		mov r6,#SPRITE_BLOOM_OFFS
		mov r5,#16					@ set a little bloom to whiten initial explosion
		str r5,[r2,r6]
		mov r6,#5					@ set tracker to an explosion
		str r6,[r2]
		mov r6,#14					@ set the initial explosion frame
		mov r8,#SPRITE_OBJ_OFFS			
		str r6,[r2,r8]
		mov r6,#4					@ reset the explode delay
		mov r8,#SPRITE_EXP_DELAY_OFFS
		str r6,[r2,r8]	
		mov r8,#SPRITE_FIRE_TYPE_OFFS
		mov r6,#0
		str r6,[r2,r8]
		
		bl playAlienExplodeScreamSound
	
	TExplodeDone:
		mov r0,#SPRITE_Y_OFFS
		ldr r1,[r2,r0]
		cmp r1,#768
		blt TExplodeNotYet
			mov r1,#SPRITE_KILL
			str r1,[r2,r0]
	
	TExplodeNotYet:

	ldmfd sp!, {r0-r10, pc}	

	.pool
	.end
