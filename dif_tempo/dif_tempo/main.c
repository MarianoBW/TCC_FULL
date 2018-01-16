/*
 * dif_tempo.c
 *
 * Created: 23/11/2017 21:12:11
 * Author: Mariano Berwanger Wille
 */ 
 
 #include <avr/io.h>
 #include <avr/interrupt.h>
 
// #include <avr/wdt.h>
// #include <avr/power.h>
// #include "avr/iom328p.h"
// int control=0;
//unsigned char sreg;
//unsigned int NS,SN; 

//void loop(void);


  int main(void)
  {
	  
	//wdt_disable();
	cli(); 
	////////////////////////////////////////////////////////////////////////
	CLKPR = (1 << CLKPCE);
	CLKPR = 0;
	
	// 40kHz gerador // 
		
  	DDRD = 0b11000001;  //configura pino PD0,PD6,PD7 como saída e demais como entradas

  	TCCR0A = 0;
	TCCR0B = 0;
	
  	TCCR0A = (0<<WGM00)|(1<<WGM01) |(0<<COM0A0)|(0<<COM0A1)|(0<<COM0B0)|(0<<COM0B1)  ; 
  	
	TCCR0B = (0<<FOC0A)|(0<<FOC0B) |(0<<WGM02)| (0<<CS02)|(0<<CS01)|(1<<CS00)  ;
	
	TCNT0 = 0;  
	OCR0A = 100;
	
	TIMSK0 = (1 << OCIE0A);

	///////////////////////////////////////////////////////////////////////
	
	// external interupt //
	//                INT1                  INT0
	EICRA = (0<<ISC11)|(0<<ISC10)|(0<<ISC01)|(0<<ISC00); //The rising edge generates an interrupt request.
	EIMSK = (0<<INT1)|(0<<INT0); // on int1, on int0
	

	
	///////////////////////////////////////////////////////////////////////
	
	 sei();
	 //loop();
  	
      while(1)
			{
			
			//__no_operation();
			//if (control==0)
			//{
        		//TIMSK0 = (0 << OCIE0A);  
				//TCNT0=0;
			//}
			}
	 }
  
	ISR(TIMER0_COMPA_vect)
	{
		PORTD ^= (1 << PORTD6);
		//cli();
		
	}
  
  
//	ISR(INT0_vect )	
//	{
//		//sreg = SREG; 
//		cli();
//		NS=TCNT0;
//		//EIMSK |= (1<<INT1)|(0<<INT0);
//		//TIMSK0 = (0 << OCIE0A);
//		TCNT0=0;
//		PORTD =(0 << PORTD0) | (0 << PORTD6 );
//		//SREG = sreg;
//		//sei();
//		
//		
//
//		//cli();
//		//reti();
//	 }
	 
	 
//	ISR(INT1_vect)
//	{
//		//sreg = SREG;
//		cli();
//		EIMSK = (0<<INT1)|(1<<INT0);
//		PORTD =(1 << PORTD0) | (0 << PORTD6 );
//		TCNT0=0;
//		TIMSK0 = (1 << OCIE0A);
//		//SREG = sreg;
//		//loop();
//		//sei();
//		
//
//	}	 
	
	//void loop()
	//{
	//	loop();
	//}
