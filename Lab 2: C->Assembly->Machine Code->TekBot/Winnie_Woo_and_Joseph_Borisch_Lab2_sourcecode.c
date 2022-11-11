/*
Lab 2: C- > Assembler -> Machine Code -> Tekbot
Author: Winnie Woo and Joseph Borisch
Date: 10/11/2022

This code will cause a TekBot connected to the AVR board to
move forward and when if right whisker is hit: move backwards, turn left, resume forward
If the left whisker is hit: move backwards, turn right, resume forward

PORT MAP
Port B, Pin 5 -> Output -> Right Motor Enable
Port B, Pin 4 -> Output -> Right Motor Direction
Port B, Pin 6 -> Output -> Left Motor Enable
Port B, Pin 7 -> Output -> Left Motor Direction
Port D, Pin 5 -> Input -> Left Whisker
Port D, Pin 4 -> Input -> Right Whisker
*/



#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB=0b11110000; //configure PORTB pins for input/output (LED)
	PORTB=0b11110000; //set initial value for PORTB outputs as halt

	DDRD=0b00000000; //configure PORTD for input (Button)
	PORTD=0b1111111; //enable pull-up resistor
	PIND = 0b00000000;     // set initial value for PIN D inputs

	PORTB=0b10010000; // make TekBot move forward

	while (1) // loop forever
	{
		uint8_t mpr = PIND & 0b00110000;        //read the input into temporary register MPR
		//if right whisker was triggered
		//PIND input and whskrL are same value
		//PIND = 0b00001000
		if (mpr == 0b00000000 || mpr == 0b00100000)        //Check if both whiskers are hit or the right whisker respectively
		{
			PORTB=0b00000000;        //Move backwards
			_delay_ms(500);            // wait 500 ms
			PORTB=0b00010000;        //Turn left
			_delay_ms(1000);        //wait for 1000 ms
			PORTB = 0b10010000;     //move forward
		}
		//if left whisker was triggered
		//if PIND input and whskrR and whskrL are same value
		//PIND = 0b00001010
		else if (mpr == 0b00010000)        //check if left whisker has been hit
		{
			PORTB=0b00000000;    //Move backwards
			_delay_ms(500);     //wait 500 ms
			PORTB=0b10000000;   //Turn right
			_delay_ms(2000);    //wait for 2000 ms
			PORTB = 0b10010000; //move forward

		}
	}
}