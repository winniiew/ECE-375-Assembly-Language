;
; 
;
;***********************************************************
;*	This is the skeleton file for Lab 3 of ECE 375
;*
;*	 Author: Joseph Borisch and Winnie Woo
;*	 Date: 10/14/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************

.def	mpr = r16			; Multipurpose register is required for LCD Driver
.equ	clrBut = 4			; Clear screen input bit
.equ	wrtBut = 5			; write to screen Input Bit
.equ	swtBut = 6			; swap lines Input Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
	; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
	; Initialize LCD Display
		rcall	LCDInit
	;define variables for strings to be displayed by LCD

	; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State


	; NOTE that there is no RET or RJMP from INIT,
	; this is because the next instruction executed is the
	; first instruction of the main program
;***********************************************************
;*	Main Program
;***********************************************************
		rcall	lcdclr					;clear screen
		rcall lcdbacklighton			;backlight on
MAIN:									; The Main program
		in		mpr, PIND				;get button input
		com		mpr						;acive low buttons
		andi	mpr, (1<<clrBut|1<<swtBut|1<<wrtBut)	;logic and to find what button is pressed
		cpi		mpr, (1<<clrBut)		;check for clear button input
		brne	NEXT1
		rcall	ClearButton				;call subroutine ClearButton
		rjmp	MAIN					;continue with program
NEXT1:	cpi		mpr, (1<<swtBut)		;check for switch button
		brne	NEXT2
		rcall	SwitchButton			;call subroutine SWithcButton
		rjmp	MAIN
NEXT2:	cpi		mpr, (1<<wrtBut)		;check for write button
		brne	MAIN					;no input, continue program
		rcall	WriteButton				;call subroutine WriteButton

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ClearButton
; Desc: Handles functionality of the LCD display when the clear button 
;is triggered
;-----------------------------------------------------------
ClearButton:	; Begin a function with a label
		; Save variables by pushing them to the stack
		push	mpr
		in		mpr, SREG		;save program state
		push	mpr
		; Execute the function here
		rcall	LCDclr			;clear the lcd screen
		; Restore variables by popping them from the stack,
		; in reverse order
		pop		mpr
		out		SREG, mpr
		pop		mpr
		ret			; End a function with RET

;-----------------------------------------------------------
; Func: Write Button
; Desc: Handles functionality of the LCD display when the write button 
;is triggered
;-----------------------------------------------------------
WriteButton:	; Begin a function with a label
		; Save variables by pushing them to the stack
		push	mpr
		in		mpr, SREG		;save program state
		push	mpr
		; Execute the function here

		ldi ZL, low(STRING_BEG<<1)		;load lo string 1 into Z
		ldi ZH, high(STRING_BEG<<1)		;load high string 1 into Z
		ldi YL, $00						;initialize address pointing to first line of low byte on LCD
		ldi YH, $01						;initialize address pointing to first line of high byte on LCD
LOOP1:	lpm mpr, Z+						;mpr gets lo byte of z
		st	Y+, mpr						;low Y gets low z
		cpi ZL, low(STRING_BEG<<1) ; compare the value of the low_end after shifting one bit, required for printing an entire string and not just first letter
		brne	LOOP1
		ldi ZL, low(STRING_END<<1)		;load lo string 2 into Z
		ldi ZH, high(STRING_END<<1)		;load high string 2 into Z
		ldi	YL, $10						;initialize address pointing to second line of low byte on LCD
		ldi	YH, $01						;initialize address pointing to second line of high byte on LCD
LOOP2:	lpm mpr, Z+
		st	Y+, mpr	
		cpi ZL, low(STRING_END<<1) ; compare the value of the low_end after shift one bit, if it is reached that, the break
		brne	LOOP2
		rcall	LCDwrite
		; Restore variables by popping them from the stack,
		; in reverse order
		pop		mpr
		out		SREG, mpr
		pop		mpr
		ret			; End a function with RET

;-----------------------------------------------------------
; Func: Switch Button
; Desc: Handles functionality of the LCD display when the switch button 
;is triggered
;-----------------------------------------------------------
SwitchButton:	; Begin a function with a label
				; Save variables by pushing them to the stack
				;function nearly identical to WriteButton, just switches the memopry location that Y is defined by. Memory locations get flipped
		push	mpr
		in		mpr, SREG		;save program state
		push	mpr
		; Execute the function here
		ldi ZL, low(STRING_END<<1)		;load lo string 1 into Z
		ldi ZH, high(STRING_END<<1)		;load high string 1 into Z
		ldi YL, $00						
		ldi YH, $01
LOOP3:	lpm mpr, Z+						;mpr gets lo byte of z
		st	Y+, mpr						;low Y gets low z
		cpi ZL, low(STRING_END<<1)		;compare the value of the low_end after shift one bit, if it is reached that, the break
		brne	LOOP3
		ldi ZL, low(STRING_BEG<<1)		;load lo string 2 into Z
		ldi ZH, high(STRING_BEG<<1)		;load high string 2 into Z
		ldi	YL, $10
		ldi	YH, $01
LOOP4:	lpm mpr, Z+
		st	Y+, mpr	
		cpi ZL, low(STRING_BEG<<1)
		brne	LOOP4
		rcall	LCDwrite
		; Restore variables by popping them from the stack,
		; in reverse order
		pop		mpr
		out		SREG, mpr
		pop		mpr
		ret			; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------

STRING_BEG:
.DB		"Joe Borisch     "		; Declaring data in ProgMem
STRING_END:
.DB		"Winnie Woo      "		; Declaring data in ProgMem


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
