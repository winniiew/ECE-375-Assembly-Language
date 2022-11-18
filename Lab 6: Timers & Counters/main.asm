;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: Winnie Woo and Joseph Borisch
;*	 Date: 11/16/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	PWMLevel = r17			; register for tracking duty cycle
.def	SpeedDisplay = r18		; register for tracking/ displaying current speed
.def	SpeedInc = r19			; value to increase the speed by
.def	waitcnt = r20			
.def	ilcnt = r21			
.def	olcnt = r22

.equ	WTime = 25
.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit
.equ	MovFwd = (1<<EngDirR|1<<EngDirL) ; instruction to make TekBot move forward
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		rcall SPEED_UP			; interrupt to speed up tekbot one level
		reti

.org	$0004
		rcall SLOW_DOWN			; interrupt to slow tekbot down one level
		reti

.org	$0008	
		rcall SPEED_MAX			; interrupt to set tekbot to max speed
		reti

.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi mpr, low(RAMEND)	; Low byte of END SRAM addr
		out SPL, mpr			; Write byte to SPL
		ldi mpr, high(RAMEND)	; high byte of END sram addr
		out SPH, mpr			; Write byte to SPH

		; Configure I/O ports
		; Initialize Port B for output
		ldi mpr, $FF			; Set Port B Data Direction Register
		out DDRB, mpr			; for output
		ldi mpr, $00			; Initialize Port B Data Register
		out PORTB, mpr			; so all Port B outputs are low

		; Initialize Port D for input
		ldi mpr, $00			; Set Port D Data Direction Register
		out DDRD, mpr			; for input
		ldi mpr, $FF			; Initialize Port D Data Register
		out PORTD, mpr			; so all Port D inputs are Tri-State

		; Configure External Interrupts, if needed
		ldi		mpr, 0b10001010 ; (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC31)|(0<<ISC30) => sets trigger state to falling 
		sts		EICRA, mpr		; use sts, EICRA is in extended I\O space	
						
		; Configure the External Interrupt Mask
		ldi		mpr, 0b00001011	; (1<<INT0)|(1<<INT1)|(1<<INT3) => enables INT0, INT1, INT3
		out		EIMSK, mpr	
		; Configure 16-bit Timer/Counter 1A and 1B
		ldi		mpr, 0b11110001			; Fast PWM, 8-bit mode (WGM11:10)
		sts		TCCR1A, mpr				; / inverting mode (COM1A1:COM1A0 and COM1B1:COM1B0)
		ldi		mpr, 0b00001001			; Fast PWM, 8-bit mode (WGM13:WGM12)
		sts		TCCR1B, mpr				; / no prescale (CS12:CS10)
		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B
		ldi		mpr, MovFwd
		out		PORTB, mpr
		; Set value for speed to be increased by (255/15 =17)
		ldi		SpeedInc, $11
		; Set initial speed, display on Port B pins 3:0
		clr		SpeedDisplay
		or		mpr, SpeedDisplay		; load speed level into lower mpr / save MovFwd command
		out		PORTB, mpr
		clr		PWMLevel				; initially 0
		clr		mpr
		sts		OCR1AH, mpr				; 
		sts		OCR1AL, PWMLevel		; Set compare vlaue for new pulse speed
		sts		OCR1BH, mpr				; 
		sts		OCR1BL, PWMLevel		; Set compare vlaue for new pulse speed
		sbi		DDRB, PB5				; turn on portb pin 5 for changing brightness
		sbi		DDRB, PB6				; turn on portb pin 6 for changing brightness
		; Enable global interrupts (if any are used)
		sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		ldi		mpr, MovFwd				; load move forward command
		or		mpr, SpeedDisplay		; load speed level without destroying MovFwd
		out		PORTB, mpr				; Update PORTB 
		rjmp	MAIN					; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func:	SPEED_UP
; Desc:	Increase speed by one level
;-----------------------------------------------------------
SPEED_UP:	; Begin a function with a label

		; If needed, save variables by pushing to the stack
		push	mpr						; save mpr
		in		mpr, SREG				; save program state
		push	mpr
		push	SpeedInc

		rcall	wait					; make sure the speed increases by only 1

		cpi		SpeedDisplay, $0F		; Check if current speed = max (15)
		breq	INCSKIP					; Skip increment if max speed
		add		PWMLevel, SpeedInc		; increase Tekbot speed 255/15 = 17 
		inc		SpeedDisplay			; increase speed by one level 

		clr		mpr
		sts		OCR1AH, mpr				; 
		sts		OCR1AL, PWMLevel		; Set compare vlaue for new pulse speed
		sts		OCR1BH, mpr				; 
		sts		OCR1BL, PWMLevel		; Set compare vlaue for new pulse speed

		clr		mpr						; mpr all zeros
		in		mpr, PORTB				; Save PORTB data 
		or		mpr, SpeedDisplay		; set new speed level
		out		PORTB, mpr				; display new speed level
INCSKIP:
		; Clear queued interrupts
		ldi		mpr, $0F				; Cleared by writing a 1 to it
		out		EIFR, mpr

		; Restore any saved variables by popping from stack
		pop		SpeedInc
		pop		mpr
		out		SREG, mpr
		pop		mpr
		
		ret								; End a function with RET
;-----------------------------------------------------------
; Func:	SLOW_DOWN
; Desc:	Decrease speed by one level
;-----------------------------------------------------------
SLOW_DOWN:	; Begin a function with a label

		; If needed, save variables by pushing to the stack
		push	mpr						; save mpr
		in		mpr, SREG				; save program state
		push	mpr
		push	SpeedInc

		rcall	wait					; make sure the speed increases by only 1

		cpi		SpeedDisplay, $00		; Check if current speed = min (0) 
		breq	DECSKIP					; Skip decrement if min speed
		sub		PWMLevel, SpeedInc		; decrease tekbot speed by 17 
		dec		SpeedDisplay			; decrease speed one level

		clr		mpr
		sts		OCR1AH, mpr				; 
		sts		OCR1AL, PWMLevel		; Set compare vlaue for new pulse speed
		sts		OCR1BH, mpr				; 
		sts		OCR1BL, PWMLevel		; Set compare vlaue for new pulse speed

		clr		mpr						; mpr all zeros
		in		mpr, PORTB				; Save PORTB data
		eor		mpr, SpeedDisplay		; set new speed level
		out		PORTB, mpr				; display new speed level
DECSKIP:
		; Clear queued interrupts
		ldi		mpr, $0F ; Cleared by writing a 1 to it
		out		EIFR, mpr
		; Restore any saved variables by popping from stack
		pop		SpeedInc
		pop		mpr
		out		SREG, mpr
		pop		mpr

		ret								; End a function with RET
;-----------------------------------------------------------
; Func:	SPEED_MAX
; Desc:	Increase speed to max level
;-----------------------------------------------------------
SPEED_MAX:	; Begin a function with a label

		; If needed, save variables by pushing to the stack
		push	mpr						; save mpr
		in		mpr, SREG				; save program state
		push	mpr
		push	SpeedInc

		ldi		SpeedDisplay, $0F		; load max speed value (15) into display reg
		ldi		PWMLevel, $FF			; 0% duty cycle for max speed
		clr		mpr
		sts		OCR1AH, mpr				; 
		sts		OCR1AL, PWMLevel		; Set compare value for new pulse speed
		sts		OCR1BH, mpr				; 
		sts		OCR1BL, PWMLevel		; Set compare value for new pulse speed
		clr		mpr						; mpr all zeros
		in		mpr, PORTB				; Save PORTB data
		or		mpr, SpeedDisplay		; set new speed level
		out		PORTB, mpr				; display new speed level
		; Clear the queued interrupts
		ldi		mpr, $0F			
		out		EIFR, mpr
		; Restore any saved variables by popping from stack
		pop		SpeedInc
		pop		mpr
		out		SREG, mpr
		pop		mpr

		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	WAIT
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

		ldi		waitcnt, WTime		; Load time to delay 


Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt

		brne	 ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register

		ret						; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program