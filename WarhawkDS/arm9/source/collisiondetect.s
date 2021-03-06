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

	.arm
	.align
	.text
	.global detectBGL
	.global detectBGR
	.global detectALN
	.global alienCollideCheck
	.global drawShard
	.global detectShipAsFire
	
@-------------- DETECT Left BULLET
detectBGL:						@ OUR CODE TO CHECK IF BULLET (OFFSET R0) IS IN COLLISION WITH A BASE
								@ AND LATER ALSO CHECK AGAINST ENEMIES
	stmfd sp!, {r0-r6, lr}
	
	ldr r1, =spriteX+4			@ DO X COORD CONVERSION
	ldr r1, [r1, r0, lsl #2]	@ r1=our x coord
	sub r1, #64					@ our sprite starts at 64 (very left of map) + 10 for left bullet
	add r1, #10					@ our left bullet is right a bit in the sprite
	lsr r1, #5					@ divide x by 32
	ldr r2, =spriteY+4			@ DO Y COORD CONVERSION
	ldr r2, [r2, r0, lsl #2]	@ r2=our BULLETS y coord	
	sub r2, #384				@ take 384 off our coord, as this is the top of the screen
	lsr r2,#5					@ convert to a 32 block
	lsl r2,#5					
	ldr r3,=yposSub
	ldr r3,[r3]					@ load the yposSub
	sub r3,#160					@ take that bloody 160 off
	add r3,r2					@ add our scroll and bullet y together
	lsr r3,#5					@ divide by 32 (our blocks)
	lsl r3,#4					@ mul by 16	to convert to our colMapStore format	
	add r3,r1					@ add our X, r3 is now an offset to our collision data

	ldr r4,=colMapStore
	ldrb r6,[r4,r3]			@ Check in collision map with r3 as byte offset
	cmp r6,#0					@ if we find a 0 = no hit!
	beq no_hit
	cmp r6,#3					@ 1 and 2 = Hit!
	bpl no_hit
	mov r11,#0
	detectBGL2:
	bl playExplosionSound

	ldr r9,=basesLeft
	ldr r8,[r9]
	sub r8,#1					@ deduct one from the base count
	str r8,[r9]

	ldr r9,=basesShot
	ldr r8,[r9]
	add r8,#1					@ add one to the base shot count
	str r8,[r9]

	lsl r6,#2 					@ times by 4
	ldr r9,=craterFrame			@ get our frame for use as a crater
	ldr r8,[r9]
	add r8,#1					@ add one to it
	cmp r8,#4					@ are we at crater 5 (0-4)
	moveq r8,#0					@ if so, reset back to the first crater
	str r8,[r9]					@ store it back
	add r6,r8					@ and add it to our collmap ref!
	strb r6, [r4, r3]			@ store CRATER in collmap (as 4 or 8) + frame (0-3)
	mov r9,r6					@ save r6 in r9 for the crater draw

@-------------- the CRATER draw code	
		push {r0-r4}				@ We need a check for if crater at top on main, draw also base of sub
		ldr r4, =spriteY+4			@ DO Y COORD CONVERSION
		ldr r4, [r4, r0, lsl #2]
		add r4,r11
		lsr r4,#5					@ convert to a 32 block
		lsl r4,#5

		ldr r1,=575
		cmp r4,r1
		bpl bottomS
			ldr r1,=vofsSub		@---- Draw Crater on Top Screen
			ldr r1,[r1]
			sub r4,#384
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			ldr r2, =spriteX+4			@ DO X COORD CONVERSION
			ldr r2, [r2, r0, lsl #2]
			sub r2,#54					@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			bl drawCraterBlockSub	
			b nonono
			
		bottomS:
			ldr r1,=vofsSub		@---- Draw crater on Bottom Screen
			ldr r1,[r1]
			sub r4,#576
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			ldr r2, =spriteX+4				@ DO Y COORD CONVERSION
			ldr r2, [r2, r0, lsl #2]
			sub r2,#54						@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			push {r0}
			bl drawCraterBlockMain
			pop {r0}

			cmp r4,#33
			bpl nonono
				ldr r1,=vofsSub				@ Draw Crater on Top Screen
				ldr r1,[r1]
				add r1,#192
				add r1,r4
				lsr r1,#5
				lsl r1,#2	
				bl drawCraterBlockSub

		nonono:
		pop {r0-r4}	
@--------------- end of CRATER draw code
	
		mov r10,#10
		bl initBaseExplode			@ Draw the EXPLOSION
									@ pass r5 with the offset for the bullet (ie 6)
		
		ldr r1, =spriteObj+4
		ldr r2, [r1,r0, lsl #2]
		cmp r2,#4
		beq LFPower					@ If powershot, keep the bullet going :)
		
			ldr r1,=spriteY+4			@ Kill the bullet
			mov r2,#SPRITE_KILL
			str r2, [r1,r0, lsl #2]

		LFPower:
		
		ldr r0,=adder+7				@ add 65 to the score
		mov r1,#5
		strb r1,[r0]
		sub r0,#1
		mov r1,#6
		strb r1,[r0]
		sub r0,#1
		bl addScore
		ldmfd sp!, {r0-r6, pc}
	
	no_hit:
	@ check mid bullet (we never move more that 6 pixels, so y+6 should work fine!)
	ldr r1, =spriteX+4			@ DO X COORD CONVERSION
	ldr r1, [r1, r0, lsl #2]	@ r1=our x coord
	sub r1, #64					@ our sprite starts at 64 (very left of map) + 10 for left bullet
	add r1, #10					@ our left bullet is right a bit in the sprite
	lsr r1, #5					@ divide x by 32
	ldr r2, =spriteY+4			@ DO Y COORD CONVERSION
	ldr r2, [r2, r0, lsl #2]	@ r2=our BULLETS y coord	
	sub r2, #384				@ take 384 off our coord, as this is the top of the screen
	add r2,#8
	lsr r2,#5					@ convert to a 32 block
	lsl r2,#5					
	ldr r3,=yposSub
	ldr r3,[r3]					@ load the yposSub
	sub r3,#160					@ take that bloody 160 off
	add r3,r2					@ add our scroll and bullet y together
	lsr r3,#5					@ divide by 32 (our blocks)
	lsl r3,#4					@ mul by 16	to convert to our colMapStore format	
	add r3,r1					@ add our X, r3 is now an offset to our collision data

	ldr r4,=colMapStore
	ldrb r6,[r4,r3]			@ Check in collision map with r3 as byte offset
	cmp r6,#0					@ if we find a 0 = no hit!
	beq no_hit2
	cmp r6,#3					@ 1 and 2 = Hit!
	bpl no_hit2
	mov r11,#8
	b detectBGL2
	no_hit2:
	ldmfd sp!, {r0-r6, pc}

@-------------- DETECT Right BULLET	
detectBGR:						@ OUR CODE TO CHECK IF BULLET (OFFSET R0) IS IN COLLISION WITH A BASE
								@ AND LATER ALSO CHECK AGAINST ENEMIES
	stmfd sp!, {r0-r6, lr}
	
	ldr r1, =spriteX+4			@ DO X COORD CONVERSION
	ldr r1, [r1, r0, lsl #2]	@ r1=our x coord
	sub r1, #64					@ our sprite starts at 64 (very left of map) + 6 for left bullet
	add r1, #22					@ our left bullet is right a bit in the sprite
	lsr r1, #5					@ divide x by 32
	ldr r2, =spriteY+4			@ DO Y COORD CONVERSION
	ldr r2, [r2, r0, lsl #2]	@ r2=our BULLETS y coord	
	sub r2, #384				@ take 384 off our coord, as this is the top of the screen
	lsr r2,#5					@ convert to a 32 block
	lsl r2,#5					
	ldr r3,=yposSub
	ldr r3,[r3]					@ load the yposSub
	sub r3,#160					@ take that bloody 160 off
	add r3,r2					@ add our scroll and bullet y together
	lsr r3,#5					@ divide by 32 (our blocks)
	lsl r3,#4					@ mul by 16	to convert to our colMapStore format	
	add r3,r1					@ add our X, r3 is now an offset to our collision data

	ldr r4,=colMapStore
	ldrb r6,[r4,r3]			@ Check in collision map with r3 as byte offset
	cmp r6,#0					@ if we find a 0 = no hit!
	beq no_hitR
	cmp r6,#3					@ 1 and 2 = Hit!
	bpl no_hitR
	mov r11,#0
	detectBGR2:
	bl playExplosionSound

	ldr r9,=basesLeft
	ldr r8,[r9]
	sub r8,#1					@ deduct one from the base count
	str r8,[r9]
	
	ldr r9,=basesShot
	ldr r8,[r9]
	add r8,#1					@ add one to the base shot count
	str r8,[r9]

	lsl r6,#2 					@ times by 4
	ldr r9,=craterFrame			@ get our frame for use as a crater
	ldr r8,[r9]
	add r8,#1					@ add one to it
	cmp r8,#4					@ are we at crater 5 (0-4)
	moveq r8,#0					@ if so, reset back to the first crater
	str r8,[r9]					@ store it back
	add r6,r8					@ and add it to our collmap ref!
	strb r6, [r4, r3]			@ store CRATER in collmap (as 4 or 8) + frame (0-3)
	mov r9,r6					@ save r6 in r9 for the crater draw

@-------------- the CRATER draw code	
		push {r0-r4}				@ We need a check for if crater at top on main, draw also base of sub
		ldr r4, =spriteY+4			@ DO Y COORD CONVERSION
		ldr r4, [r4, r0, lsl #2]
		add r4,r11
		lsr r4,#5					@ convert to a 32 block
		lsl r4,#5

		ldr r1,=575
		cmp r4,r1
		bpl bottomSR
			ldr r1,=vofsSub		@---- Draw Crater on Top Screen
			ldr r1,[r1]
			sub r4,#384
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			ldr r2, =spriteX+4			@ DO X COORD CONVERSION
			ldr r2, [r2, r0, lsl #2]
			sub r2,#32+10					@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			bl drawCraterBlockSub	
			b nononoR
			
		bottomSR:
			ldr r1,=vofsSub		@---- Draw crater on Bottom Screen
			ldr r1,[r1]
			sub r4,#576
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			ldr r2, =spriteX+4				@ DO Y COORD CONVERSION
			ldr r2, [r2, r0, lsl #2]
			sub r2,#32+10						@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			push {r0}
			bl drawCraterBlockMain
			pop {r0}

			cmp r4,#33
			bpl nononoR
				ldr r1,=vofsSub				@ Draw Crater on Top Screen
				ldr r1,[r1]
				add r1,#192
				add r1,r4
				lsr r1,#5
				lsl r1,#2	
				bl drawCraterBlockSub

		nononoR:
		pop {r0-r4}	
@--------------- end of CRATER draw code
	
		mov r10,#22
		bl initBaseExplode			@ Draw the EXPLOSION
									@ pass r5 with the offset for the bullet (ie 6)
			
		ldr r1, =spriteObj+4
		ldr r2, [r1,r0, lsl #2]
		cmp r2,#4
		beq RFPower					@ If powershot, keep the bullet going :)
		
			ldr r1,=spriteY+4			@ Kill the bullet
			mov r2,#SPRITE_KILL
			str r2, [r1,r0, lsl #2]

		RFPower:
		ldr r0,=adder+7				@ add 65 to the score
		mov r1,#5
		strb r1,[r0]
		sub r0,#1
		mov r1,#6
		strb r1,[r0]
		bl addScore
		ldmfd sp!, {r0-r6, pc} @ <--- This was missing and caused our NB bug!

	no_hitR:
	ldr r1, =spriteX+4			@ DO X COORD CONVERSION
	ldr r1, [r1, r0, lsl #2]	@ r1=our x coord
	sub r1, #64					@ our sprite starts at 64 (very left of map) + 6 for left bullet
	add r1, #22					@ our left bullet is right a bit in the sprite
	lsr r1, #5					@ divide x by 32
	ldr r2, =spriteY+4			@ DO Y COORD CONVERSION
	ldr r2, [r2, r0, lsl #2]	@ r2=our BULLETS y coord	
	sub r2, #384				@ take 384 off our coord, as this is the top of the screen
	add r2,#8
	lsr r2,#5					@ convert to a 32 block
	lsl r2,#5					
	ldr r3,=yposSub
	ldr r3,[r3]					@ load the yposSub
	sub r3,#160					@ take that bloody 160 off
	add r3,r2					@ add our scroll and bullet y together
	lsr r3,#5					@ divide by 32 (our blocks)
	lsl r3,#4					@ mul by 16	to convert to our colMapStore format	
	add r3,r1					@ add our X, r3 is now an offset to our collision data

	ldr r4,=colMapStore
	ldrb r6,[r4,r3]			@ Check in collision map with r3 as byte offset
	cmp r6,#0					@ if we find a 0 = no hit!
	beq no_hitR2
	cmp r6,#3					@ 1 and 2 = Hit!
	bpl no_hitR2
	mov r11,#8
	b detectBGR2
	bl playExplosionSound
	no_hitR2:
	ldmfd sp!, {r0-r6, pc}
	
@-------------- The init EXPLOSION Code
@ first find a blank explosion from 113-127
initBaseExplode:
	stmfd sp!, {r0-r8, lr}
	ldr r4,=spriteActive
	mov r6,#127
	expFindBase:
		ldr r5,[r4,r6, lsl #2]
		cmp r5,#0
		beq startBaseExp
		sub r6,#1
		cmp r6,#111
	bne expFindBase
	ldmfd sp!, {r0-r8, pc}
		
	startBaseExp:
									@ r6 is our ref to the explosion sprite
									@ calculate the x/y to plot explosion
		ldr r1, =spriteX+4			@ DO X COORD CONVERSION
		ldr r1, [r1, r0, lsl #2]	@ r1=our x coord
		add r1, r10					@ our left bullet is right a bit in the sprite
		lsr r1, #5					@ divide x by 32
		lsl r1, #5					@ multiply by 32
		ldr r2, =spriteY+4			@ DO Y COORD CONVERSION
		ldr r2, [r2, r0, lsl #2]	@ r2=our y coord
		add r2,r11
		ldr r3,=pixelOffsetMain		@ load our pixeloffset (1-32)
		ldr r3,[r3]
		subs r3,#1					@ try to compensate for pixeloffs being 1-32 (need 0-31)
		movmi r3,#31				@ pixel offset is now 0-31
		lsr r2, #5					@ divide bullet coord by 32
		lsl r2, #5					@ times by 32	: this aligns to a block of 32x32
		add r2,r3					@ add them together

		sub r2,#30					@ re align (for some reason 32 is not quite correct)
									@ r4 is sprite active register already
	mov r5,#5						@ and r6 is the sprite number to use for explosion
	str r5,[r4,r6, lsl #2]			@ set sprite to "base explosion"
	ldr r4,=spriteObj
	mov r5,#12						@ sprite 13-1 as added to on first update in drawsprite.s
	str r5,[r4,r6, lsl #2]			@ set object to explosion frame
	ldr r4,=spriteX
	str r1,[r4,r6, lsl #2]			@ store r1 as X, calculated above
	ldr r4,=spriteY
	str r2,[r4,r6, lsl #2]			@ store r2 as Y, calculated above
	ldr r4,=spriteExplodeDelay
	mov r2,#4						@ Set sprite delay for anim (once evey 4 updates seems to work nice)
	str r2,[r4,r6, lsl #2]
	bl getRandom
	and r8,#0x1						@ randomly flip the explosion
	ldr r4,=spriteHFlip
	str r8,[r4,r6, lsl #2]

	ldmfd sp!, {r0-r8, pc}			@ all done
	
@-------------------------------------------------------------------	
detectALN:						@ OUR CODE TO CHECK IF BULLET (OFFSET R0) IS IN COLLISION WITH AN ALIEN

	stmfd sp!, {r0-r8, lr}
	@ First we need to grab the X and Y of the bullet and cycle trough the aliens to find a hit
	
	ldr r1, =deathMode			@ we use some sprites in death with bullet values
	ldr r1,[r1]					@ so, we need to make sure this is not used to detect against
	cmp r1,#0
	beq detectALNActive
	
		ldmfd sp!, {r0-r8, pc}
		
	detectALNActive:

	ldr r1, =spriteX+4			
	ldr r1, [r1, r0, lsl #2]	@ r1= BULLET X
	ldr r2, =spriteY+4			
	ldr r2, [r2, r0, lsl #2]	@ r2= BULLET Y
	add r2,#4
	ldr r7, =spriteObj+4		@ The Bullet object tells us what type of shot!
	ldr r7, [r7,r0, lsl #2]	@ r7 = 3 normal shot / 4 Power shot!
								@ use this is a match is found!
	cmp r7,#4					@ If powershot,
	moveq r7,#10				@ power is UPPED
	movne r7,#1					@ else, just the normal 1	
	
	mov r3,#111					@ Alien index (sprites 17 - 80 = 64)

	detectAlienLoop:
		ldr r4,=spriteActive+68		@ add 68 (17*4) for start of aliens
		add r4,r3, lsl #2			@ r4=aliens base offset so we can use the "offs" for data grabbing
		ldr r5,[r4]					@ r5= the active alien value
		cmp r5,#0
		beq detectNoAlien
		cmp r5,#128
		beq bossDetect
		cmp r5,#256
		beq bossDetect
		cmp r5,#512
		beq bossDetect
		cmp r5,#9					@ drop ship
		beq bossDetect
		cmp r5,#10					@ powerup
		beq bossDetect
		cmp r5,#4
		bpl detectNoAlien
		bossDetect:
		@ Found an ALIEN!!
			@ Do checks
			mov r8,#SPRITE_X_OFFS
			ldr r6,[r4,r8]					@ r6=current Alien X
			add r6,#22						
			cmp r6,r1						@ r1=Bullet x
			bmi detectNoAlien
			sub r6,#22
			add r1,#22
			cmp r6,r1
			sub r1,#22
			bpl detectNoAlien

			mov r8,#SPRITE_Y_OFFS
			ldr r6,[r4,r8]					@ r6=current Alien y
			add r6,#22
			cmp r6,r2						@ r2=bullet y
			bmi detectNoAlien
			sub r6,#22
			add r2,#22
			cmp r6,r2
			sub r2,#22
			bpl detectNoAlien
				@ ALIEN DETECTED!!
				
				ldr r8,=spriteY+4			@ Kill the bullet
				mov r6,#SPRITE_KILL
				str r6, [r8,r0, lsl #2]				
				
				cmp r5,#128
				bne bigBossHitCheck1
					bl bossIsShot			@ it is the Boss!!!
					b detectNoAlien
				bigBossHitCheck1:
				cmp r5,#256					@ this is big boss, normal area... so, kill bullet and shard
				beq alienBloomed
				
				@ ok, now we need to see how many hits to kill
				cmp r5,#2					@ this is a meteor!
				beq meteorShot

				alienHitDeduct:
				
				mov r8,#SPRITE_MISC_TYPE_OFFS
				ldr r6,[r4,r8]
				cmp r6,#1					@ skip if Vortex
				beq multishotBloom
				
				mov r8,#SPRITE_HIT_OFFS
				ldr r6,[r4,r8]
				subs r6,r7
				str r6,[r4,r8]

				cmp r6,#0
				bmi detectAlienKill			@ Alien	*IS DEAD*
				multishotBloom:
					@ MULTISHOT ALIEN *NOT DEAD*		
					@ ok, if the alien has an ident, we need to bloom all with the same ident!!
					mov r8,#SPRITE_IDENT_OFFS
					ldr r8,[r4,r8]
					cmp r8,#2
					bmi alienNoIdent
					cmp r8,#4
					beq alienNoIdent
					cmp r8,#5
					beq alienNoIdent
						@ ok, for this ident, we need to flash all matching
						@ r6=hits, copy to all idented aliens
						mov r7,#111
						ldr r9,=spriteIdent+68
						fireBloomLoop:
							ldr r3,[r9,r7,lsl #2]
							cmp r3,r8
							bne fireBloomNot
								@ ok, we have found a matching ident
								ldr r2,=spriteBloom+68
								mov r3,#16
								str r3,[r2,r7,lsl #2]	@ make it FLASH	
								ldr r2,=spriteHits+68
								str r6,[r2,r7,lsl #2]	@ store new hits
							fireBloomNot:
							subs r7,#1
						bpl fireBloomLoop
					b alienBloomed
					
					alienNoIdent:
					mov r8,#SPRITE_BLOOM_OFFS
					mov r6,#16				@ do bloom
					str r6,[r4,r8]			@ store it back
		
					alienBloomed:
		
					@ ok, alien not dead yet!!, so, play "Hit" sound
					@ and perhaps a "shard" (mini explosion) activated under BaseExplosion?
					push {r7}
					mov r8,#SPRITE_X_OFFS
					ldr r6,[r4,r8]
					mov r6,r1			@ just test with bullet x (comment out to use alien x)
					mov r8,#SPRITE_Y_OFFS
					ldr r7,[r4,r8]
					bl drawShard
					pop {r7}
					
					@ add score
					ldr r8,=adder+7				@ add 5 to the score
					mov r6,#5
					strb r6,[r8]
					bl addScore	
					bl playShipArmourHit1Sound
					b detectNoAlien
			
			detectAlienKill:
			@ we use this do DESTROY an alien, but if it is a bigboss, we really want to use our code for that!
			cmp r5,#512							@ is it a big boss??
			beq bigBossDestroyedSkip
			cmp r5,#2						@ if this is a meteor, give player a little energy
			bleq addEnergy
			mov r8,#SPRITE_IDENT_OFFS
			ldr r8,[r4,r8]
			cmp r8,#3
			bmi explodeSNoIdent
			cmp r8,#4
			beq explodeSNoIdent
			cmp r8,#5
			beq explodeSNoIdent
			b explodeSIdent

			dropCheck:
			cmp r5,#9					@ was this a dropship?
			bleq dropShipShot
	
		detectNoAlien:
		subs r3,#1
		bpl detectAlienLoop
	
	ldmfd sp!, {r0-r8, pc}

bigBossDestroyedSkip:

	bl bigBossInitExplode				@ this must change all values of spriteActive and init the explosion
	b detectNoAlien


meteorShot:
	@ this code alters the way meteors work when shot
	@ r4=offeset to mine
	@ if r7=10, this is a powershot
	cmp r7,#10
	beq alienHitDeduct
	
	@ so, on a standard shot, we need to move the mine back a bit
	@ so, we need to grab the speed and use that..

	mov r6,#SPRITE_SPEED_Y_OFFS
	ldr r6,[r4,r6]
	lsl r6,#1
	add r6,#4

	mov r8,#SPRITE_Y_OFFS
	ldr r7,[r4,r8]
	subs r7,r6
	str r7,[r4,r8]
	b multishotBloom
	
explodeSNoIdent:				@ this is to destroy a single alien
	
	ldr r6,=SPRITE_EXPLODE_TYPE_OFFS
	ldr r6,[r4,r6]
	cmp r6,#0
	beq notExplodeAndFire
		@ ok, we need to fire bullet type 14 at the aliens X/Y Coord (or a 5 shot 18)
		push {r1,r3}	
		mov r8,#SPRITE_FIRE_SPEED_OFFS
		mov r1,#4
		str r1,[r4,r8]
		mov r1,r4
		mov r3,r6
		bl alienFireInit
		pop {r1,r3}

	notExplodeAndFire:
	
			
	@ check for our special type misc 2
	mov r6,#SPRITE_MISC_TYPE_OFFS
	ldr r6,[r4, r6]
	cmp r6,#2							@ 2=drop on death (1=vortex)
	beq initDroppingShip				@ ok, lets drop it!!! :)
	
	@ ok, destroy a single/no ident alien
	
	
	@ first, is the alien shot a Hunter?
	ldr r6,[r4]
	cmp r6,#3					@ spriteActive 3 = Hunter
	bne notShotHunter
	
		@ ok, if hunterTimeCounter is 0, check for a match with gen/shot
		@ if not, add the shot counter
				
		ldr r8,=huntersShot
		ldr r6,[r8]
		add r6,#1					@ add to hunters shot
		str r6,[r8]	
	
		ldr r8,=hunterTimerCounter
		ldr r6,[r8]
		cmp r6,#0
		bne notShotHunter			@ hunters are still being generated
		
			@ this perhaps the last hunter (check shot against gen)
			
			ldr r8,=huntersShot
			ldr r6,[r8]
			ldr r8,=huntersGen
			ldr r9,[r8]
			cmp r6,r9
			bne notShotHunter
			
			@ last hunter shot
			@ we need to add a big score bonus and an explosion to show the bonus??
			
			bl hunterBonus
			b dropCheck

	notShotHunter:
	
	mov r6,#4					@ set to explosion type
	str r6,[r4]
	mov r6,#6					@ set the frame to start
	mov r8,#SPRITE_OBJ_OFFS
	str r6,[r4,r8]
	mov r6,#4					@ set initial delay for explosion
	mov r8,#SPRITE_EXP_DELAY_OFFS
	str r6,[r4,r8]
	bl getRandom
	and r8,#0x1					@ randomly flip the explosion
	mov r9,#SPRITE_HORIZ_FLIP_OFFS
	str r8,[r4,r9]

	ldr r8,=adder+7				@ add 78 to the score
	mov r6,#8
	strb r6,[r8]
	sub r8,#1
	mov r6,#7
	strb r6,[r8]
	bl addScore		
	bl playAlienExplodeSound
	b dropCheck

explodeSIdent:					@ this is to explode an alien that is part of a bigger ship
	bl explodeIdentAlien
	ldr r8,=adder+7				@ add 184 to the score (dont ask why?)
	mov r6,#4
	strb r6,[r8]
	sub r8,#1
	mov r6,#8
	strb r6,[r8]
	sub r8,#1
	mov r6,#1
	strb r6,[r8]

	bl addScore		
	bl playIdentShipExplode
	
	b dropCheck	

initDroppingShip:																									@ (())
	@ ok, need to do a few things here,
	@ first, init and explosion if possible
	@ chamge spriteActive to 14, and hit points to 127
	mov r0,#SPRITE_X_OFFS
	ldr r0,[r4,r0]
	mov r1,#SPRITE_Y_OFFS
	ldr r1,[r4,r1]
	bl generateExplosion
	
	bl playAlienScreamSound
	
	mov r6,#14
	str r6,[r4]					@ set spriteActive
	mov r8,#SPRITE_HIT_OFFS
	mov r6,#127
	str r6,[r4,r8]
	
	b detectNoAlien

	
@--------------------------- Draw "shard" at alien coord r6,r7	
drawShard:
	stmfd sp!, {r1-r3, lr}

	ldr r1,=spriteActive
	mov r2,#127
	shardFindBase:
		ldr r3,[r1,r2, lsl #2]
		cmp r3,#0
		beq startShard
		sub r2,#1
		cmp r2,#111
	bne shardFindBase
	ldmfd sp!, {r1-r3, pc}
	
	startShard:
	@ r2=sprite number to use for a shard! (6 is active ident for a shard)

	mov r3,#6						@ and r6 is the sprite number to use for explosion
	str r3,[r1,r2, lsl #2]			@ set sprite to "base explosion"
	ldr r1,=spriteObj
	mov r3,#22						@ sprite 13-1 as added to on first update in drawsprite.s
	str r3,[r1,r2, lsl #2]			@ set object to explosion frame
	ldr r1,=spriteX
	str r6,[r1,r2, lsl #2]			@ store r1 as X, calculated above
	ldr r1,=spriteY
	add r7,#24
	str r7,[r1,r2, lsl #2]			@ store r2 as Y, calculated above
	ldr r1,=spriteExplodeDelay
	mov r3,#2						@ Set sprite delay for anim (once evey 4 updates seems to work nice)
	str r3,[r1,r2, lsl #2]
	ldmfd sp!, {r1-r3, pc}
	
@----------------------------- Check alien collision with ship (Seemed the best place to put it :) )
							@	The detection (apart from alien bullet) needs a tidy - too many add and subs
							@ r1=offset to alien base


alienCollideCheck:
	stmfd sp!, {r0-r9, lr}
	
			ldr r5,=deathMode		@ if you are in major explode, no detection with ship
			ldr r5,[r5]
			cmp r5,#DEATHMODE_MAIN_EXPLODE
			bpl noPlayer
	
			ldr r5,=bossMan
			ldr r5,[r5]
			cmp r5,#3
			bpl noPlayer

			ldr r5,=spriteX
			ldr r3,[r5]						@ r3 is player x
			ldr r5,=spriteY
			ldr r4,[r5]						@ r4 is player y
			ldr r5,=horizDrift
			ldr r5,[r5]
			add r3,r5						@ we MUST account for level horizontal movement (player is not tied to level)

			mov r8,#SPRITE_X_OFFS
			ldr r6,[r1,r8]					@ r6=current Alien X

			@ simple detect code!!!
			add r6,#20						
			cmp r6,r3						@ r3=player x
			bmi noPlayer
			sub r6,#20
			add r3,#20
			cmp r6,r3
			bpl noPlayer

			mov r8,#SPRITE_Y_OFFS
			ldr r6,[r1,r8]					@ r6=current Alien y
			add r6,#18
			cmp r6,r4						@ r4=player y
			bmi noPlayer
			sub r6,#18
			add r4,#18
			cmp r6,r4
			bpl noPlayer
		
				ldr r10,=deathMode
				ldr r10,[r10]
				cmp r10,#DEATHMODE_STILL_ACTIVE
				bne noDyingBlooms
				
				ldr r8,[r1]					@ load the ACTIVE value
				cmp r8,#10					@ have we collided with a powerup?
				bne notPowerup
					bl powerupCollect		@ if so, collect it!
					b acNoDestroy
				notPowerup:
				cmp r8,#9					@ is it a dropship?
				bne notDropShip				@ if so, somehow launch powerup???
					mov r4,r1				@ how the hell???
					bleq dropShipShot		@ ok, this works!! BUT there shoud be a energy loss
					ldr r6,=energy					@ Take 1 off your energy
					ldr r7,[r6]
					subs r7,#8						@ -8 units - PENALTY
					movmi r7,#0						@ if less than 0 make 0
					str r7,[r6]					
				
				notDropShip:
				ldr r6,=spriteBloom
				mov r7,#16
				str r7,[r6]						@ make shp flash
			
				noDyingBlooms:
			
				bl playSteelSound				@ activate sound for YOUR ship being hit!
			
				ldr r6,=energy					@ Take 1 off your energy
				ldr r7,[r6]
				subs r7,#1						@ -1
				movmi r7,#0						@ if less than 0 make 0
				str r7,[r6]
				
				mov r6,#SPRITE_IDENT_OFFS		@ skip if normal boss
				ldr r7,[r1, r6]
				cmp r7,#128
				beq missForBoss
				cmp r8,#256						@ skip if big boss
				bge missForBoss
				
					ldr r6,=SPRITE_HIT_OFFS			@ get alien hit points
					ldr r7,[r1,r6]
					subs r7,#1						@ take one off (i think an ident collide shoud take more?)
					str r7,[r1,r6]
					cmp r7,#0						@ if alien dead?
					bmi acDestroy					@ yes!, DESTROY it
	
				missForBoss:
				
					bl playShipArmourHit1Sound		@ activate sound for YOUR ship hitting alien!
					mov r6,#SPRITE_IDENT_OFFS
					ldr r6,[r1,r6]
					cmp r6,#2
					bmi alienSingleBloom
					cmp r6,#4
					beq alienSingleBloom
					cmp r6,#5
					beq alienSingleBloom
					
					cmp r6,#128
					bne playerDyingBlooms
						cmp r10,#0
						bne acNoDestroy
					playerDyingBlooms:
					mov r9,r8
						@ ok, for this ident, we need to flash all matching
						@ and decrement the hits and store the value in ALL idents
						@ r7=hits left
						mov r8,#111
						ldr r5,=spriteIdent+68
						alienBloomLoop:
							ldr r3,[r5,r8,lsl #2]
							cmp r3,r6
							bne alienBloomNot
								@ ok, we have found a matching ident
								ldr r2,=spriteBloom+68
								mov r3,#16
								str r3,[r2,r8,lsl #2]	@ make it FLASH	
								ldr r2,=spriteHits+68
								cmp r9,#256
								strlt r7,[r2,r8,lsl #2]
							alienBloomNot:
							subs r8,#1
						bpl alienBloomLoop
						b acNoDestroy				

					alienSingleBloom:
					mov r8,#SPRITE_BLOOM_OFFS	@ ok, alien not dead, so lets make him flash
					mov r6,#16					@ do bloom
					str r6,[r1,r8]				@ store it back
					bl playShipArmourHit1Sound	@ make that "TING" sound
					b acNoDestroy				@ jump out of what we are doing
				acDestroy:
						
					@ explode alien
					@ we have 2 options here - ident and non ident
					
					mov r6,#SPRITE_IDENT_OFFS
					ldr r6,[r1,r6]
					cmp r6,#2
					bmi explodeNonIdent
					cmp r6,#4
					beq explodeNonIdent
					cmp r6,#5
					beq explodeNonIdent	
					b explodeIdent

				acNoDestroy:
			noPlayer:
			
			mov r6,#SPRITE_MISC_TYPE_OFFS
			ldr r6,[r1,r6]
			cmp r6,#1
			bleq alienCyclone
			
	ldmfd sp!, {r0-r9, pc}
	
explodeNonIdent:
		mov r6,#4					@ set alien to an explosion
		str r6,[r1]
	
		mov r6,#6					@ set the initial explosion frame
		mov r8,#SPRITE_OBJ_OFFS			
		str r6,[r1,r8]
		mov r6,#4					@ reset the explode delay
		mov r8,#SPRITE_EXP_DELAY_OFFS
		str r6,[r1,r8]
	bl getRandom
	and r8,#0x1					@ randomly flip the explosion
	mov r9,#SPRITE_HORIZ_FLIP_OFFS
	str r8,[r1,r9]


			
		@ add score
		ldr r8,=adder+7				@ add 21 to the score (THAT IS ALL YOU GET FOR CRASHING)
		mov r6,#1					@ first a 1
		strb r6,[r8]
		sub r8,#1
		mov r6,#2					@ then a 2
		strb r6,[r8]
		bl addScore		
		bl playAlienExplodeSound
		b noPlayer
		
explodeIdent:
		@ r6=ident to explode
		mov r8,r6
		bl explodeIdentAlien
		ldr r8,=adder+7				@ add 42 to the score (dont ask why?)
		mov r6,#2
		strb r6,[r8]
		sub r8,#1
		mov r6,#4
		strb r6,[r8]

		bl addScore		
		bl playIdentShipExplode	@ HK - we really need a meatier explode here?

		b noPlayer
		
detectShipAsFire:		
	stmfd sp!, {r0-r9, lr}
	
	ldr r1, =bossMan
	ldr r1,[r1]
	cmp r1,#0
	beq detectShipAsFireOK
	
		ldmfd sp!, {r0-r9, pc}
	
	detectShipAsFireOK:
	
	ldr r1, =spriteX			@ DO X COORD CONVERSION
	ldr r1, [r1]				@ r1=our x coord
	ldr r2,=horizDrift
	ldr r2,[r2]
	add r1,r2
	sub r1, #64					@ our sprite starts at 64 (very left of map) + 10 for left bullet
	add r1, #16					@ our left bullet is right a bit in the sprite
	lsr r1, #5					@ divide x by 32
	ldr r2, =spriteY			@ DO Y COORD CONVERSION
	ldr r2,[r2]					@ r2=our BULLETS y coord	
	sub r2, #384				@ take 384 off our coord, as this is the top of the screen
	add r2,#24					@ make middle of sprites Y
	lsr r2,#5					@ convert to a 32 block
	lsl r2,#5					
	ldr r3,=yposSub
	ldr r3,[r3]					@ load the yposSub
	sub r3,#160					@ take that bloody 160 off
	add r3,r2					@ add our scroll and bullet y together
	lsr r3,#5					@ divide by 32 (our blocks)
	lsl r3,#4					@ mul by 16	to convert to our colMapStore format	
	add r3,r1					@ add our X, r3 is now an offset to our collision data

	ldr r4,=colMapStore
	ldrb r6,[r4,r3]			@ Check in collision map with r3 as byte offset
	cmp r6,#0					@ if we find a 0 = no hit!
	beq playerAsShotFail
	cmp r6,#3					@ 1 and 2 = Hit!
	bpl playerAsShotFail
	mov r11,#0
	bl playExplosionSound

	lsl r6,#2 					@ times by 4
	ldr r9,=craterFrame			@ get our frame for use as a crater
	ldr r8,[r9]
	add r8,#1					@ add one to it
	cmp r8,#4					@ are we at crater 5 (0-4)
	moveq r8,#0					@ if so, reset back to the first crater
	str r8,[r9]					@ store it back
	add r6,r8					@ and add it to our collmap ref!
	strb r6, [r4, r3]			@ store CRATER in collmap (as 4 or 8) + frame (0-3)
	mov r9,r6					@ save r6 in r9 for the crater draw

		push {r0-r4}				@ We need a check for if crater at top on main, draw also base of sub
		ldr r4, =spriteY			@ DO Y COORD CONVERSION
		ldr r4, [r4]
		add r4,#24
		lsr r4,#5					@ convert to a 32 block
		lsl r4,#5

		ldr r2,=spriteX
		ldr r2,[r2]
		ldr r1,=horizDrift
		ldr r1,[r1]
		add r2,r1
		add r2,#16

		ldr r1,=575
		cmp r4,r1
		bpl bottomSX
			ldr r1,=vofsSub		@---- Draw Crater on Top Screen
			ldr r1,[r1]
			sub r4,#384
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			sub r2,#64					@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			push {r0}
			bl drawCraterBlockSub
			pop {r0}
			b nononoX
			
		bottomSX:
			ldr r1,=vofsSub		@---- Draw crater on Bottom Screen
			ldr r1,[r1]
			sub r4,#576
			add r1,r4
			lsr r1,#5
			lsl r1,#2	
			sub r2,#64						@ 64 - 6 (bullet offset)
			lsr r2, #5
			lsl r2, #2
			mov r0,r2
			push {r0}
			bl drawCraterBlockMain
			pop {r0}

			cmp r4,#33
			bpl nononoX
				ldr r1,=vofsSub				@ Draw Crater on Top Screen
				ldr r1,[r1]
				add r1,#192
				add r1,r4
				lsr r1,#5
				lsl r1,#2	
				bl drawCraterBlockSub

		nononoX:
		pop {r0-r4}	
@--------------- end of CRATER draw code
	
		bl initBaseExplodePlayer	@ Draw the EXPLOSION for players location

		ldr r0,=adder+7				@ add 25 to the score
		mov r1,#5
		strb r1,[r0]
		sub r0,#1
		mov r1,#2
		strb r1,[r0]
		sub r0,#1
		bl addScore
		
		playerAsShotFail:
	ldmfd sp!, {r0-r9, pc}	
	
@----------------- Draw a base explosion in ref to our players x/y
	
initBaseExplodePlayer:
	stmfd sp!, {r0-r9, lr}
	ldr r4,=spriteActive
	mov r6,#127
	expFindBaseP:
		ldr r5,[r4,r6, lsl #2]
		cmp r5,#0
		beq startBaseExpP
		sub r6,#1
		cmp r6,#111
	bne expFindBaseP
	ldmfd sp!, {r0-r9, pc}			@ return if we cannot find a spare sprite
		
	startBaseExpP:
									@ r6 is our ref to the explosion sprite
									@ calculate the x/y to plot explosion
		ldr r1, =spriteX			@ DO X COORD CONVERSION
		ldr r1, [r1]				@ r1=our x coord
		add r1, #16
		ldr r2, =horizDrift
		ldr r2,[r2]
		add r1,r2
		lsr r1, #5					@ divide x by 32 (could we not jusr and #31?)
		lsl r1, #5					@ multiply by 32
		ldr r2, =spriteY			@ DO Y COORD CONVERSION
		ldr r2, [r2]				@ r2=our y coord
		add r2,#24
		ldr r3,=pixelOffsetMain		@ load our pixeloffset (1-32)
		ldr r3,[r3]
		subs r3,#1					@ try to compensate for pixeloffs being 1-32 (need 0-31)
		movmi r3,#31				@ pixel offset is now 0-31
		lsr r2, #5					@ divide bullet coord by 32
		lsl r2, #5					@ times by 32	: this aligns to a block of 32x32
		add r2,r3					@ add them together

		sub r2,#30					@ re align (for some reason 32 is not quite correct)
									@ r4 is sprite active register already
	mov r5,#5						@ and r6 is the sprite number to use for explosion
	str r5,[r4,r6, lsl #2]			@ set sprite to "base explosion"
	ldr r4,=spriteObj
	mov r5,#12						@ sprite 13-1 as added to on first update in drawsprite.s
	str r5,[r4,r6, lsl #2]			@ set object to explosion frame
	ldr r4,=spriteX
	str r1,[r4,r6, lsl #2]			@ store r1 as X, calculated above
	ldr r4,=spriteY
	str r2,[r4,r6, lsl #2]			@ store r2 as Y, calculated above
	ldr r4,=spriteExplodeDelay
	mov r2,#4						@ Set sprite delay for anim (once evey 4 updates seems to work nice)
	str r2,[r4,r6, lsl #2]
	bl getRandom
	and r8,#0x1						@ randomly flip the explosion
	ldr r9,=spriteHFlip
	str r8,[r9,r6, lsl #2]

	ldmfd sp!, {r0-r9, pc}			@ all done

@-------------------------------------
	
alienCyclone:
stmfd sp!, {r0-r10, lr}	
	@ r1 = offset table for alien
	mov r9,#SPRITE_X_OFFS
	ldr r0,[r1,r9]					@ r0= alien X
	ldr r5,=spriteX
	ldr r2,[r5]
	ldr r3,=horizDrift
	ldr r3,[r3]
	add r2,r3						@ r2= player x
				@ X checks

	adds r0,#64						@ boundry
	cmp r2,r0	
	bpl noCyclone
	adds r2,#128					@ boundry value * 2
	cmp r2,r0
	bmi noCyclone
	subs r2,#128

	ldr r6,=spriteY
	ldr r7,[r6]						@ r7=player y
	mov r8,#SPRITE_Y_OFFS
	ldr r4,[r1,r8]					@ r8=Alien y
				@ Y checks
	adds r4,#64
	cmp r7,r4
	bpl noCyclone
	adds r7,#128
	cmp r7,r4
	bmi noCyclone
	subs r7,#128
	@ ok, now in square bounds around cyclone
	@ r2,[r5] = x r7,[r6] = y

		ldr r3,[r1,r9]				@ alien X
		cmp r2,r3
		blgt cycloneRightPull
		bllt cycloneLeftPull
		@addlt r2,#1
		@subgt r2,#1
		@ldr r3,=horizDrift
		@ldr r3,[r3]
		@subs r2,r3
		@str r2,[r5]
		
		ldr r3,[r1,r8]
		cmp r7,r3
		addlt r7,#1
		subgt r7,#1
		cmp r7,#384+8
		movmi r7,#384+8
		cmp r7,#736
		movpl r7,#736
		str r7,[r6]

	noCyclone:

ldmfd sp!, {r0-r10, pc}

cycloneRightPull:
	stmfd sp!, {r0-r10, lr}

		ldr r6,=spriteX
		ldr r8,=horizDrift
		ldr r8, [r8]
		cmp r8,#0
		beq CYleftmove
			subs r8,#1
			cmp r8,#0
			movmi r8,#0
			ldr r4,=horizDrift
			strb r8,[r4]
		@	ldmfd sp!, {r0-r10, pc}
		CYleftmove:
		ldr r8,[r6]
		ldr r1,=pullCount
		ldr r2,[r1]
		add r2,#1
		cmp r2,#2
		moveq r2,#0
		str r2,[r1]

		subs r8,r2
		cmp r8,#64
		movle r8,#64
		str r8,[r6]
	
ldmfd sp!, {r0-r10, pc}

cycloneLeftPull:
	stmfd sp!, {r0-r10, lr}

		ldr r6,=spriteX
		ldr r8,=horizDrift
		ldr r8, [r8]
		cmp r8,#64
		beq CYRightmove
			adds r8,#1
			cmp r8,#64
			movpl r8,#64
			ldr r4,=horizDrift
			strb r8,[r4]
		@	ldmfd sp!, {r0-r10, pc}
		CYRightmove:
		ldr r8,[r6]
		mov r4,#256
		add r4,#32
		ldr r1,=pullCount
		ldr r2,[r1]
		add r2,#1
		cmp r2,#2
		moveq r2,#0
		str r2,[r1]
		adds r8,r2
		cmp r8,r4
		movpl r8,r4
		str r8,[r6]
	
ldmfd sp!, {r0-r10, pc}

addEnergy:
	@ add energy to player
	stmfd sp!, {r0-r1, lr}
	ldr r0,=energy
	ldr r1,[r0]
	add r1,#20
	cmp r1,#72
	movge r1,#72
	str r1,[r0]
	bl drawAllEnergyBars
	bl playPowerupCollect
ldmfd sp!, {r0-r1, pc}

hunterBonus:					@ do a bonus thing for all hunters shot
stmfd sp!, {r0-r10, lr}

	mov r6,#4					@ set to explosion type
	str r6,[r4]
	mov r6,#6					@ set the frame to start
	mov r8,#SPRITE_OBJ_OFFS
	str r6,[r4,r8]
	mov r6,#4					@ set initial delay for explosion
	mov r8,#SPRITE_EXP_DELAY_OFFS
	str r6,[r4,r8]
	bl getRandom
	and r8,#0x1					@ randomly flip the explosion
	mov r9,#SPRITE_HORIZ_FLIP_OFFS
	str r8,[r4,r9]

	ldr r8,=adder+7				@ add 8888 to the score
	mov r6,#8
	strb r6,[r8]
	sub r8,#1
	strb r6,[r8]
	sub r8,#1
	strb r6,[r8]
	sub r8,#1
	strb r6,[r8]
	bl addScore	

	@ ok, now we want some way to show it???
	@ r4 is still the index to the alien
	mov r2,#SPRITE_X_OFFS
	ldr r5,[r4,r2]				@ r5=x
	mov r2,#SPRITE_Y_OFFS
	ldr r6,[r4,r2]				@ r6=y

	mov r9,#10
	
	hunterExplodeLoop:
	
		bl getRandom
		and r8,#47
		subs r8,#24
		mov r0,r5
		adds r0,r8
		bl getRandom
		and r8,#47
		subs r8,#24
		mov r1,r6
		adds r1,r8

		bl generateExplosion

	subs r9,#1
	bne  hunterExplodeLoop

ldmfd sp!, {r0-r10, pc}

pullCount:
	.word 0


	.pool
	.end