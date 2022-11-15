;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: Winnie Woo and Joseph Borisch
;*	 Date: 11/7/2022
;*
;***********************************************************
.include "m32U4def.inc"			; Include definition file
;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	waitcnt = r17			; wait loop counter
.def	ilcnt = r18				; inner loop counter
.def	olcnt = r19				; outer loop counter
.def	rightcnt = r23			; HitRight counter
.def	leftcnt = r24			; HitLeft counter
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	WTime = 100				; Time to wait in wait loop
.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00			; Move Backward Command
.equ	TurnR = (1<<EngDirL)	; Turn Right Command
.equ	TurnL = (1<<EngDirR)	; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL) ; Halt Command
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment
;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0002					; INT0 => pin0, PORTD
		rcall	HitRight		; Call HitRight subroutine
		reti					; Return from interrupt
.org	$0004					; INT1 => pin1, PORTD
		rcall	HitLeft			; Call HitLeft subroutine
		reti					; Return from interrupt
.org	$0008					; INT3 => pin3, PORTD
		rcall	ClearButton		; Call ClearButton subroutine
		reti					; Return from interrupt
.org	$0046					; End of Interrupt Vectors
;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low
		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; Initialize LCD Display
		rcall	LCDInit			; Initialize LCD Display
		rcall	lcdbacklighton	; backlight on
		clr		rightcnt		; clear the counter for the right whisker
		call	CountHitRight	; call function to display right whisker counter to LCD (initially 0)
		clr		leftcnt			; clear the counter for the left whisker
		call	CountHitLeft	; call function to display left whisker counter to LCD (initially 0)
		; Initialize external interrupts
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, 0b10001010;	(1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC31)|(0<<ISC30) => sets trigger state to falling 
		sts		EICRA, mpr			; use sts, EICRA is in extended I\O space					
		; Configure the External Interrupt Mask
		ldi		mpr, 0b00001011;	(1<<INT0)|(1<<INT1)|(1<<INT3) => enables INT0, INT1, INT3
		out		EIMSK, mpr			
		; Turn on interrupts
		sei						; NOTE: This must be the last thing to do in the INIT function
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		ldi		mpr, $90		; Load Move Forward Command (actual command wouldn't compile, had to use bianry value instead)
		out		PORTB, mpr		; Send command to motors
		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.
;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: HitRight
; Desc: If hit, moves backward, turns left, continues forward
;-----------------------------------------------------------
HitRight:
		; Save variable by pushing them to the stack
		push	mpr				; Save mpr
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr
		inc		rightcnt		; Increment HitRight counter
		rcall	CountHitRight	; Write updated coutner value to LCD display
		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		; Turn left for a second
		ldi		mpr, TurnL		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		; Move Forward again
		ldi		mpr, $90		; Load Move Forward command
		out		PORTB, mpr		; Send command to port
		; Clear queued interrupts
		ldi		mpr, $0F		; Cleared by writing a 1 to it
		out		EIFR, mpr
		; Restore variable by popping them from the stack in reverse order
		pop		mpr				; Restore program state
		out		SREG, mpr	
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; End a function with RET
;-----------------------------------------------------------
; Func: HitLeft
; Desc: If hit, moves backward, turns right
;-----------------------------------------------------------
HitLeft:							
		; Save variable by pushing them to the stack
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr			
		inc		leftcnt			; Increment HitLeft counter
		rcall	CountHitLeft	; Write updated coutner value to LCD display
		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		; Turn right for a second
		ldi		mpr, TurnR		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		; Move Forward again
		ldi		mpr, $90		; Load Move Forward command
		out		PORTB, mpr		; Send command to port
		; Clear queued interrupts
		ldi		mpr, $0F		; Cleared by writing a 1 to it
		out		EIFR, mpr
		; Restore variable by popping them from the stack in reverse order
		pop		mpr				; Restore program state
		out		SREG, mpr	
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; Return from subroutine
		ret						; End a function with RET
;-----------------------------------------------------------
; Func: HandleClear
; Desc: Clears LCD display
;-----------------------------------------------------------
ClearButton:
		; Save variables by pushing them to the stack
		push	mpr
		push	waitcnt
		in		mpr, SREG		;save program state
		push	mpr
		; Execute the function here
		clr		rightcnt
		rcall	CountHitRight
		clr		leftcnt
		rcall	CountHitLeft
		ldi		mpr, $0F		; clear queued interrupts
		out		EIFR, mpr
		; Restore variables by popping them from the stack,
		; in reverse order
		pop		mpr
		pop		waitcnt
		out		EIFR, mpr
		pop		mpr
		ret			; End a function with RET
;-----------------------------------------------------------
; Func: CountHitRight
; Desc: Handles functionality of the LCD display when HitRight function is called (called within HitRight)
;-----------------------------------------------------------
CountHitRight:
		; Save variables by pushing them to the stack
		push	mpr
		push	rightcnt
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr
		; Execute the function here
		rcall	LCDClrln1
		mov		mpr, rightcnt	; load to-be converted value into mpr
		ldi		XL, low($0100)	; ; load X with beginning address to be stored (i.e. store directly to where LCD will be looking)
		ldi		XH, high($0100)	;
		rcall	Bin2ASCII		; convert value in ASCII
		rcall	LCDWrLn1		; write ASCII value to LCD line 1
		; Restore variables by popping them from the stack, in reverse order
		pop		mpr
		out		SREG, mpr
		pop		waitcnt
		pop		rightcnt
		pop		mpr
		ret						; End a function with RET
;-----------------------------------------------------------
; Func: CountHitLeft
; Desc: Handles functionality of the LCD display when HitLeft function is called (called within HitLeft)
;-----------------------------------------------------------
CountHitLeft:
		; Save variables by pushing them to the stack
		push	mpr
		push	leftcnt
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr
		; Execute the function here
		rcall	LCDClrln2		; clear line 2 of the LCD
		mov		mpr, leftcnt	; load to-be converted value into mpr
		ldi		XL, low($0110)	; load X with beginning address to be stored (i.e. store directly to where LCD will be looking)
		ldi		XH, high($0110)	;
		rcall	Bin2ASCII		; convert value in ASCII
		rcall	LCDWrLn2		; write ASCII value to LCD line 2
		; Restore variables by popping them from the stack, in reverse order
		pop		mpr
		out		SREG, mpr
		pop		waitcnt
		pop		rightcnt
		pop		mpr
		ret						; End a function with RET
;----------------------------------------------------------------
; Func:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm" ; Include the LCD Driver
