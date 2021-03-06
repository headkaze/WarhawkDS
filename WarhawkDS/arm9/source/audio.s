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
#include "video.h"
#include "background.h"
#include "dma.h"
#include "ipc.h"

	#define MUSIC_CHANNEL		0
	#define SOUND_CHANNEL		1
	#define FORCE_SOUND_CHANNEL	2

	#define STOP_SOUND		-1

	.arm
	.align
	.text
	
	.global stopSound
	.global playBlasterSound					@ Used = Normal Fire
	.global playExplosionSound					@ used = player death & base explode
	.global playAlienExplodeSound				@ used = alien explode
	.global playAlienExplodeScreamSound			@ used = (powershot), mineshot explode, player death
	.global playPowershotSound					@ used = For when a powershot is fired 
	.global playElecShotSound					@ used = alien fire
	.global playLaserShotSound					@ used = alien fire
	.global playShipArmourHit1Sound				@ used = boss shot, player/alien collision
	.global playCrashBuzSound					@ used = alien fire
	.global playDinkDinkSound					@ used = cheatmode and level start
	.global playLowSound						@ used = alien fire
	.global playSteelSound						@ used = eol counter, alien/player collide, alien fire
	.global playBossExplodeSound				@ used = Player explode
	.global playFireworksSound					@ used = fireworks
	.global playPowerupCollect					@ used = for powerup collection
	.global playIdentShipExplode				@ used = for when a multi-sprite ship is destroyed
	.global playKeyboardClickSound				@ used = for menu navigation/options
	.global playBossExplode2Sound				@ used = Boss Explosion
	.global playAlertSound						@ used = big boss attack
	.global playAlienScreamSound				@ used = "Misc 2" aliens
	.global playWellDoneSound					@ user = End of Level
	.global playLaughSound						@ user = End of Level and big boss appear
	.global playNeverDefeatSound				@ user = End of Level
	.global playNoTimeSound						@ user = End of Level
	.global playTryAgainSound					@ user = End of Level
	.global playDefeatMeSound					@ user = End of Level
	.global playFedUpSound						@ user = End of Level
	.global playLastWarningSound				@ user = End of Level
	.global playLaVeyScream						@ used = big boss death
	
	@ ones with "*" i feel need to be redone/improved

stopSound:

	stmfd sp!, {r0-r1, lr}
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	mov r1, #STOP_SOUND									@ Stop sound value
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r1, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playLaVeyScream:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =laveyScream_raw_end							@ Get the sample end
	ldr r2, =laveyScream_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =laveyScream_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playPowershotSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =powerShot_raw_end							@ Get the sample end
	ldr r2, =powerShot_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =powerShot_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
		
playBlasterSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =blaster_raw_end							@ Get the sample end
	ldr r2, =blaster_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =blaster_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
		
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playExplosionSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(FORCE_SOUND_CHANNEL)			@ Get the IPC sound length address
	ldr r1, =explosion_raw_end							@ Get the sample end
	ldr r2, =explosion_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(FORCE_SOUND_CHANNEL)		@ Get the IPC sound data address
	ldr r1, =explosion_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playAlienExplodeSound:

	stmfd sp!, {r0-r2, lr}

	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =alien_explode_raw_end						@ Get the sample end
	ldr r2, =alien_explode_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =alien_explode_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playAlienExplodeScreamSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =alien_explode_scream_raw_end				@ Get the sample end
	ldr r2, =alien_explode_scream_raw					@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =alien_explode_scream_raw					@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playElecShotSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =elecshot_raw_end							@ Get the sample end
	ldr r2, =elecshot_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =elecshot_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playLaserShotSound:

	stmfd sp!, {r0-r2, lr}

	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =lasershot_raw_end							@ Get the sample end
	ldr r2, =lasershot_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =lasershot_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playShipArmourHit1Sound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =ship_armour_hit1_raw_end					@ Get the sample end
	ldr r2, =ship_armour_hit1_raw						@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)							@ Get the IPC sound data address
	ldr r1, =ship_armour_hit1_raw						@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playCrashBuzSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =crashbuz_raw_end							@ Get the sample end
	ldr r2, =crashbuz_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =crashbuz_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playDinkDinkSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =dinkdink_raw_end							@ Get the sample end
	ldr r2, =dinkdink_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =dinkdink_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playLowSound:

	stmfd sp!, {r0-r2, lr}

	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =low_raw_end								@ Get the sample end
	ldr r2, =low_raw									@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =low_raw									@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playSteelSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =steel_raw_end								@ Get the sample end
	ldr r2, =steel_raw									@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =steel_raw									@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playBossExplodeSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(FORCE_SOUND_CHANNEL)			@ Get the IPC sound length address
	ldr r1, =boss_explode_raw_end						@ Get the sample end
	ldr r2, =boss_explode_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(FORCE_SOUND_CHANNEL)		@ Get the IPC sound data address
	ldr r1, =boss_explode_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playFireworksSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =fireworks_raw_end							@ Get the sample end
	ldr r2, =fireworks_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =fireworks_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 
	
	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playBossExplode2Sound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(FORCE_SOUND_CHANNEL)			@ Get the IPC sound length address
	ldr r1, =boss_explode2_raw_end						@ Get the sample end
	ldr r2, =boss_explode2_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(FORCE_SOUND_CHANNEL)		@ Get the IPC sound data address
	ldr r1, =boss_explode2_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return

	@ ---------------------------------------------
	
playKeyboardClickSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =keyclick_raw_end							@ Get the sample end
	ldr r2, =keyclick_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =keyclick_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return

	@ ---------------------------------------------
	
playPowerupCollect:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =powerupcollect_raw_end						@ Get the sample end
	ldr r2, =powerupcollect_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =powerupcollect_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return

	@ ---------------------------------------------
	
playIdentShipExplode:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =bigshipexplode_raw_end						@ Get the sample end
	ldr r2, =bigshipexplode_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =bigshipexplode_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playAlertSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =alert_raw_end								@ Get the sample end
	ldr r2, =alert_raw									@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =alert_raw									@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------

playAlienScreamSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =alien_scream_raw_end						@ Get the sample end
	ldr r2, =alien_scream_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =alien_scream_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	

playWellDoneSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =well_done_raw_end							@ Get the sample end
	ldr r2, =well_done_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =well_done_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playLaughSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =laugh_raw_end								@ Get the sample end
	ldr r2, =laugh_raw									@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =laugh_raw									@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playNeverDefeatSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =never_defeat_raw_end						@ Get the sample end
	ldr r2, =never_defeat_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =never_defeat_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playNoTimeSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =no_time_raw_end							@ Get the sample end
	ldr r2, =no_time_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =no_time_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playTryAgainSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =try_again_raw_end							@ Get the sample end
	ldr r2, =try_again_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =try_again_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playDefeatMeSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =defeat_me_raw_end							@ Get the sample end
	ldr r2, =defeat_me_raw								@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =defeat_me_raw								@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playFedUpSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =fed_up_raw_end								@ Get the sample end
	ldr r2, =fed_up_raw									@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =fed_up_raw									@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
playLastWarningSound:

	stmfd sp!, {r0-r2, lr}
	
	ldr r0, =IPC_SOUND_LEN(SOUND_CHANNEL)				@ Get the IPC sound length address
	ldr r1, =last_warning_raw_end						@ Get the sample end
	ldr r2, =last_warning_raw							@ Get the same start
	sub r1, r2											@ Sample end - start = size
	str r1, [r0]										@ Write the sample size
	
	ldr r0, =IPC_SOUND_DATA(SOUND_CHANNEL)				@ Get the IPC sound data address
	ldr r1, =last_warning_raw							@ Get the sample address
	str r1, [r0]										@ Write the value
	
	ldr r0, =REG_IPC_SYNC
	ldr r1, =IPC_SEND_SYNC(0)
	strh r1, [r0] 

	ldmfd sp!, {r0-r2, pc} 							@ restore registers and return
	
	@ ---------------------------------------------
	
	.pool
	.end
