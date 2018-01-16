/*
 * Desvio_de_Fase.c
 *
 * Created: 16/12/2017 15:44:28
 * Author : MarianoBW
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>

unsigned int NS,SN=0;
int main(void)
{
	
		cli();
		////////////////////////////////////////////////////////////////////////
		CLKPR = (1 << CLKPCE);
		CLKPR = 0;
		
		// 40kHz gerador //
		
		DDRD |= 0b11000001;  //configura pino PD0,PD6,PD7 como saída e demais como entradas

		TCCR0A |= 0;
		TCCR0B |= 0;
		
		TCCR0A |= (0<<WGM00)|(1<<WGM01) |(0<<COM0A0)|(0<<COM0A1)|(0<<COM0B0)|(0<<COM0B1)  ; // CCT mode
		
		TCCR0B |= (0<<FOC0A)|(0<<FOC0B) |(0<<WGM02)| (0<<CS02)|(0<<CS01)|(1<<CS00)  ; //No prescaling
		
		TCNT0 = 0;
		OCR0A |= 99;
		
		TIMSK0 = (1 << OCIE0A);

		///////////////////////////////////////////////////////////////////////
		
		// external interrupt //
		//                INT1                  INT0
		EICRA |= (0<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00); //The rising edge generates an interrupt request.
		EIMSK |= (0<<INT1)|(1<<INT0); // on int1, on int0
		
		///////////////////////////////////////////////////////////////////////
		// Timer 2 (contador)
		//TCCR2A |= 0;
		//TCCR2B |= 0;
		
		//TCCR2A |= (0<<WGM20)|(0<<WGM21) |(0<<COM2A0)|(0<<COM2A1)|(0<<COM2B0)|(0<<COM2B1)  ;
		
		//TCCR2B |= (0<<FOC2A)|(0<<FOC2B) |(0<<WGM22)| (0<<CS22)|(0<<CS21)|(1<<CS20)  ;// No prescaling
		
		//TCNT2 = 0;
		//////////////////////////////////////////////////////////////////////////
		//   PWM
				DDRB |= 0b00001000; // PB3 saída 
				TCCR2A |= 0;
				TCCR2B |= 0;
				
				TCCR2A |= (1<<WGM20)|(1<<WGM21) |(1<<COM2A0)|(1<<COM2A1)|(0<<COM2B0)|(0<<COM2B1)  ; // Fast PWM
				
				TCCR2B |= (0<<FOC2A)|(0<<FOC2B) |(0<<WGM22)| (1<<CS22)|(0<<CS21)|(0<<CS20)  ;// clk/64 (From prescaler)
				
				TCNT2 = 0;

		//TCCR1A |= 0;
		//TCCR1B |= 0;
		//
		//TCCR1A |= (0<<WGM10)|(1<<WGM11) |(0<<COM1A0)|(0<<COM1A1)|(0<<COM1B0)|(0<<COM1B1)  ; // CCT mode
		//
		//TCCR1B |= (0<<FOC1A)|(0<<FOC1B) |(0<<WGM12)| (0<<CS12)|(0<<CS11)|(1<<CS10)  ; //No prescaling
		//
		//TCNT1 = 0;
		//OCR1A |= 0;
		//
		//TIMSK1 = (1 << OCIE1A);
		
		//////////////////////////////////////////////////////////////////////////
		sei();


    while (1) 
    {
		//if ()
		//{
		//	PORTD0 = 1;
		//}
		
		
		
    }
}

	ISR(TIMER0_COMPA_vect)
	{
		PORTD ^= (1 << PORTD6);
		//if (PORTD6==1)
		//{
		//	TCNT2=0;
		//}
		
	}
	
	
	ISR(INT0_vect )
	{
		NS=TCNT0;
		// SN=(SN+NS)/2;
		OCR2A=NS;
		
	}