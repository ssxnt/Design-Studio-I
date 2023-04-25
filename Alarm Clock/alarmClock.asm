; ISR_example.asm: a) Increments/decrements a BCD variable every half second using
; an ISR for timer 2; b) Generates a 2kHz square wave at pin P1.1 using
; an ISR for timer 0; and c) in the 'main' loop it displays the variable
; incremented/decremented using the ISR for timer 2 on the LCD.  Also resets it to 
; zero if the 'BOOT' pushbutton connected to P4.5 is pressed.
$NOLIST
$MODLP51RC2
$LIST

CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
DEBOUNCE_DELAY EQU 50

BOOT_BUTTON   equ P4.5
SOUND_OUT     equ P1.1
;UPDOWN        equ P0.0
secB		  equ P2.0
minB 		  equ P2.2
hrB		      equ P2.4

aMinB		  equ P0.4
aHrB		  equ P0.7
aToggleB	  equ P0.0

; Reset vector
org 0x0000
    ljmp main

; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

; External interrupt 1 vector (not used in this code)
org 0x0013
	reti

; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
	reti

; Serial port receive/transmit interrupt vector (not used in this code)
org 0x0023 
	reti
	
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR

; In the 8051 we can define direct access variables starting at location 0x30 up to location 0x7F
dseg at 0x30
Count1ms:     ds 2 ; Used to determine when half second has passed
;BCD_counter:  ds 1 ; The BCD counter incrememted in the ISR and displayed in the main loop
minAlarm: ds 1
hrAlarm: ds 1

secClock: ds 1
minClock: ds 1
hrClock: ds 1

; In the 8051 we have variables that are 1-bit in size.  We can use the setb, clr, jb, and jnb
; instructions with these variables.  This is how you define a 1-bit variable:
bseg
flagOneSec: dbit 1 ; Set to one in the ISR every time 500 ms had passed
flagAlarm: dbit 1 ; Set to one when alarm is toggled
flagAM: dbit 1 ; Set to one if AM
flagAMalarm: dbit 1 ; Set to one if alarm is set to AM

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;                     1234567890123456    <- This helps determine the location of the counter
timeMSG:  db 'TIME xx:xx:xxXM', 0
alarmMSG: db 'ALRM xx:xxXM OXX', 0

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;
Timer0_Init:
	mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD)
	mov RL0, #low(TIMER0_RELOAD)
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    clr TR0  ; changed from clr to setb because the timer will start right away; I don't want that
	ret

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;
Timer0_ISR:
	;clr TF0  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P1.1!
	reti

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	cpl P1.0 ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	; Increment the 16-bit one mili second counter
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1

Inc_Done:
	; Check if half second has passed
	mov a, Count1ms+0
	cjne a, #low(1000), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), Timer2_ISR_done ; changed 0.5 s to 1 s
	; 100 milliseconds = 1 second have/has passed.  Set a flag so the main program knows
	setb flagOneSec ; Let the main program know half second had passed
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	mov a, secClock
	cjne a, #0x59, secIncrement
	clr a
	mov secClock, a
	mov a, minClock
	cjne a, #0x59, minIncrement
	clr a
	mov minClock, a
	mov a, hrClock
	cjne a, #0x12, hrIncrement
	clr a
	sjmp hrIncrement ; hrClock should switch am to pm or vice versa when overflowed

secIncrement:
	add a, #0x01
	da a
	mov secClock, a
	sjmp Timer2_ISR_done

minIncrement:
	add a, #0x01
	da a
	mov minClock, a
	ljmp Timer2_ISR_done

hrIncrement: 
	add a, #0x01
	da a
	mov hrClock, a
	cjne a, #0x12, Timer2_ISR_done ; when clock hits midnight, set am flag
	cpl flagAM
	
Timer2_ISR_done:
	pop psw
	pop acc
	reti

;---------------------------------;
; Main program. Includes hardware ;
; initialization and 'forever'    ;
; loop.                           ;
;---------------------------------;
main:
	; Initialization
    mov SP, #0x7F
    lcall Timer0_Init
    lcall Timer2_Init
    ; In case you decide to use the pins of P0, configure the port in bidirectional mode:
    mov P0M0, #0
    mov P0M1, #0
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT
    ; For convenience a few handy macros are included in 'LCD_4bit.inc':
	Set_Cursor(1, 1)
    Send_Constant_String(#timeMSG)
	Set_Cursor(2, 1)
	Send_Constant_String(#alarmMSG)
	setb flagAMalarm ; flag initialization: AM && !alarm
	setb flagAM
	setb flagOneSec
	mov a, #0x06 ; time initialization (settable, so doesn't really matter) @ 06:00:00 am
	da a
	mov hrClock, a
	mov minClock, #0x00
	mov secClock, #0x00
	mov a, #0x09 ; alarm initialization at 09:00:00 am
	da a
	mov hrAlarm, a 
	mov minAlarm, #0x00
	
hourPressedOrNot: ; this loop repeatedly checks whether or not the hour button is being pressed
	jb hrB, minPressedOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb hrB, minPressedOrNot
	jnb hrB, $

hrCheck: ; this loop checks if hour is at 12 or not
	mov a, hrClock
	cjne a, #0x12, hrIncrementAgain
	clr a

hrIncrementAgain: ; this increments hours on the clock
	add a, #0x01
	da a
	mov hrClock, a
	cjne a, #0x12, temp
	cpl flagAM

temp:
	ljmp LCDscreen ; created a temp because idk if cjne is long enough

minPressedOrNot: ; similar to 'hrPressedOrNot' 
	jb minB, secPressedOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb minB, secPressedOrNot
	jnb minB, $

minCheck: ; similar to 'hrCheck'
	mov a, minClock
	cjne a, #0x59, minIncrementAgain
	clr a
	mov minClock, a
	sjmp hrCheck

minIncrementAgain:
	add a, #0x01
	da a
	mov minClock, a
	ljmp LCDscreen

secPressedOrNot:
	jb secB, hrAlarmPressedOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb secB, hrAlarmPressedOrNot
	jnb secB, $

secCheck:
	mov a, secClock
	cjne a, #0x59, secIncrementAgain
	clr a
	mov secClock, a
	sjmp minCheck

secIncrementAgain:
	add a, #0x01
	da a
	mov secClock, a
	ljmp LCDscreen

hrAlarmPressedOrNot:
	jb aHrB, minAlarmPressedOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb aHrB, minAlarmPressedOrNot
	jnb aHrB, $

hrAlarmCheck:
	mov a, hrAlarm
	cjne a, #0x12, hrAlarmIncrement
	clr a

hrAlarmIncrement:
	add a, #0x01
	da a
	mov hrAlarm, a
	cjne a, #0x12, tempAgain
	cpl flagAMalarm
	sjmp tempAgain

tempAgain:
	ljmp LCDscreen

minAlarmPressedOrNot:
	jb aMinB, alarmToggledOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb aMinB, alarmToggledOrNot
	jnb aMinB, $

minAlarmCheck:
	mov a, minAlarm
	cjne a, #0x59, minAlarmIncrement
	clr a
	mov minAlarm, a
	sjmp hrAlarmCheck

minAlarmIncrement:
	add a, #0x01
	da a
	mov minAlarm, a
	sjmp LCDscreen

alarmToggledOrNot:
	jb aToggleB, bootPressedOrNot
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)
	jb aToggleB, bootPressedOrNot
	jnb aToggleB, $
	cpl flagAlarm
	sjmp LCDscreen

bootPressedOrNot:
	jb BOOT_BUTTON, loop_a  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#DEBOUNCE_DELAY)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb BOOT_BUTTON, loop_a  ; if the 'BOOT' button is not pressed skip
	jnb BOOT_BUTTON, $		; Wait for button release.  The '$' means: jump to same instruction.
	; A valid press of the 'BOOT' button has been detected, reset the BCD counter.
	; But first stop timer 2 and reset the milli-seconds counter, to resync everything.
	clr TR2                 ; Stop timer 2
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Now clear the BCD counter
	mov secClock, a
	mov minClock, a
	mov hrClock, a
	mov minAlarm, a
	mov hrAlarm, a
	setb flagAM
	clr flagAlarm
	setb TR2                ; Start timer 2
	sjmp loop_b             ; Display the new value

loop_a:
	jb flagOneSec, loop_b
	ljmp hourPressedOrNot

loop_b:
	clr flagOneSec

LCDscreen:
	Set_Cursor(1, 6)
	Display_BCD(hrClock)
	Set_Cursor(1, 9)
	Display_BCD(minClock)
	Set_Cursor(1, 12)
	Display_BCD(secClock)
	Set_Cursor(2, 6)
	Display_BCD(hrAlarm)
	Set_Cursor(2, 9)
	Display_BCD(minAlarm)
	Set_Cursor(2, 15)
	jnb flagAlarm, OFFdisplay
	Display_char(#'N')
	Set_Cursor(2, 16)
	Display_char(#' ')
	sjmp AMdisplayAlarm

OFFdisplay:
	Display_char(#'F')
	Set_Cursor(2, 16)
	Display_char(#'F')

AMdisplayAlarm:
	Set_Cursor(2, 11)
	jnb flagAMalarm, PMdisplayAlarm
	Display_char(#'A')
	sjmp AMdisplay

PMdisplayAlarm:
	Display_char(#'P')

AMdisplay: 
	Set_Cursor(1, 14)
	jnb flagAM, PMdisplay
	Display_char(#'A')
	sjmp checkEquals

PMdisplay:
	Display_char(#'P')

checkEquals:
	clr a
	mov b, a
	mov c, flagAM
	mov b.0, c
	mov c, flagAMalarm
	mov acc.0, c
	cjne a, b, soundOff
	mov a, minClock
	cjne a, minAlarm, soundOff
	mov a, hrClock
	cjne a, hrAlarm, soundOff
	setb TR0
	Set_Cursor(2, 15)
	Display_char(#'N')
	Set_Cursor(2, 16)
	Display_char(#' ')
	sjmp restart

soundOff:
	clr TR0

restart:
	ljmp hourPressedOrNot

END
