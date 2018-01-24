////********************************************************************************
//// Inicializa a USART - 9600,n,8,1 a 7.3728MHz 
//// 
//// Entradas : nenhuma
//// Saídas   : nenhuma
////********************************************************************************
#define F_CPU 20000000UL
//#include <avr/io.h>
////#include <avr/iom328p.h>
//
//
//void init_UART(void){
//
//    UCSR0B = 0x00;                                                                                    //desabilita TX, RX para setar baud rate
//     UCSR0A = 0x00;                                                                                   //limpa flag TXC, seleciona veloc. normal e desab. Multi-Proc. Com.
//     UCSR0C = ((1<<UMSEL00) |  (1<<UCSZ00) | (1<<UCSZ01));          //modo assincrono, 8 bits, sem paridade e 1 stop bit
//    // UBRR0H = 0x00;                                                                                 //seta baud rate a 9600 bps (7.3728MHz) e U2X=0 (veloc. normal)
//   //  UBRR0L = 0x2F;  
//	UBRR0 = 0x0081;                                                                              //valor 47 decimal, conforme tabela no datasheet
//     UCSR0B = ((1<<RXCIE0) | (1<<RXEN0) | (1<<TXEN0));               //transmissão e recepção habilitados, int de recepção habilitada
//}
//
////********************************************************************************
//// Interrupção UART - RX
////
//// Entradas - nenhuma
//// Saídas   - chama função para realizar tratamento
////********************************************************************************
//ISR(USART_RXC_vect){
//       UART_rec();                        //recebe dado da UART do microcontrolador
//}
//
//
//
//
//
////********************************************************************************
//// Recebe um dado quando vector de interrupção UART_RX_vect é disparado
////
//// Entradas : nenhuma
//// Saidas   : nenhuma
////********************************************************************************
//void UART_rec(void){ 
//    byte c;
//    c = UDR0;                                             //le byte
//    if (bit_is_clear(UCSR0A, RXC0)){              //finalizou recepção
//        rec_u = c;                                        //guarda na variável global, declarada anteriormente
//        mputch(c);                                       //envia eco do caracter recebido
//    }
//}
//
////********************************************************************************
//// Envia um byte através da USART
//// 
//// Entradas : byte a enviar
//// Saídas   : nenhuma
////********************************************************************************
//void mputch(unsigned char caracter){
//     while (! (UCSR0A & (1<<UDRE0)));         //verifica se está desocupado, senão espera
//     UDR0 = caracter;                                 //transmite caracter
//}

#include <avr/io.h>
#define USART_BAUDRATE 9600
#define UBRR_VALUE (((F_CPU / (USART_BAUDRATE * 16UL))) - 1)
void USART0Init(void)
{	
	DDRC =0b00111000;// (1<<DDRC3)|(1<<DDRC4)|(1<<DDRC5);    //0b00111000
	// Set baud rate
	UBRR0H = (uint8_t)(UBRR_VALUE>>8);
	UBRR0L = (uint8_t)UBRR_VALUE;
	// Set frame format to 8 data bits, no parity, 1 stop bit
	UCSR0C |= (1<<UCSZ01)|(1<<UCSZ00);
	//enable transmission and reception
	UCSR0B |= (1<<RXEN0)|(1<<TXEN0);
}
void USART0SendByte(uint8_t u8Data)
{	
	PORTC|=(1<<PORTC5);
	//wait while previous byte is completed
	while(!(UCSR0A&(1<<UDRE0))){};
	// Transmit data
	UDR0 = u8Data;
}
uint8_t USART0ReceiveByte()
{
	// Wait for byte to be received
	while(!(UCSR0A&(1<<RXC0))){};
	// Return received data
	return UDR0;
}
int main (void)
{
	uint8_t u8TempData;
	//Initialize USART0
	USART0Init();
	while(1)
	{
		// Receive data
		u8TempData = USART0ReceiveByte();
		if (u8TempData==0b00110001)
		{
			PORTC|=(1<<PORTC3);
		}
		else {
			PORTC|=(1<<PORTC4);
		}
		
		
		// Increment received data
		//u8TempData++;
		//Send back to terminal
		USART0SendByte(u8TempData);
		PORTC=(0<<PORTC5);

	}
}






