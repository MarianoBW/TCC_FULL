.include "m328Pdef.inc"


.def temp  = R16
.def time1 = r17
.def time2 = r18
.def time3 = r19
.def sum40 = r20
.def dir   = r21

.def flag40khz = R23
.def pin40khz = r24



.org 0x0000
	rjmp start

.org 0x004           ; local da memoria do ext_int1 
	rjmp int1_calc

.org 0x001A   ; timer1 ovf
	rjmp timer1_ovf

.org 0x001C   ; local da memoria do TIM0_COMPA 
	rjmp TIM0_COMPA

;//////////////////////////////////////// CONFIGURACAO INICIAL ////////////////////////////////////////////

start:

	;desativa interrupções
	cli

	;configura CLK, desativa div8
	;ldi temp,0b10000000
	;sts CLKPR,temp
	;ldi temp,0b00000000
	;sts CLKPR,temp

	;configura pinos de saida
	
	ldi temp,0b00001111 ; saidas para sinal de 40kHz, 1 para cada direcao
	out DDRC,temp
	
	ldi temp,0b00000001 ;saida Direcao 4 (Oeste) + gravaçao e crystal
	out DDRB,temp
	
	ldi temp,0b11100100 ;saida Direcao 3,2,1, (Sul,Leste,Norte, 00 ,max485 select Rx/Tx, 00)
	out DDRD,temp

	;configura serial
		; baudrate 9600
	ldi temp,0b00000000 ;0
	out UBRR0H, temp
	ldi temp,0b10000001 ;129
	out UBRR0L, temp
		; ativa RX , 
	ldi temp,0b00010000; RX
	out UCSR0B, temp
		; 8 Bit, sem paridade e 1 bit de fim 
	ldi temp, 0b00000110
	out UCSR0C, temp
	
	;Timer0 40KHz
	ldi temp,0b00000000
	out TCCR0A,temp
	out TCCR0B,temp
	ldi temp,0b00000010    ;configura TCC0A    CTC mode	
	out TCCR0A,temp
	ldi temp,0b00000000    ;configura TCC0B    clk=0 (ativa depois)
	out TCCR0B,temp
	ldi temp,0b11111000    ; OCR0A = 248  // para clk=20MHz
	out OCR0A,temp
	ldi temp,0b00000000    ; saida = 0
	out PORTD,temp
	ldi temp,0b00000010    ;liga clk 40khz
	sts TIMSK0,temp

	;Timer1 config
	ldi temp,0b00000000
	out TCCR1A,temp        ;configura TCCR1A    normal mode
	ldi temp,0b00000000    ;configura TCCR1B    clk=0 (ativa depois)
	out TCCR1B,temp
	ldi temp,0b00000001    ;liga timer1 ovf
	sts TIMSK1,temp

	;interrupção externa
	ldi temp,0b00001100 ;  The rising edge of INT1 generates an interrupt request 
	sts EICRA,temp
	ldi temp,0b00000000 ; liga int1 depois
	out EIMSK,temp

	;zerar tudo 
	ldi temp,0b00000000

	ldi time1,0b00000000
	ldi time2,0b00000000
	ldi time3,0b00000000
	ldi sum40,0b00000000 ; contador de pulsos
	ldi dir,0b00000000
	ldi flag40khz,0b00000000    ; flag 40khz
	ldi pin40khz,0b00000000
	out PORTB,temp
	out PORTC,temp
	out PORTD,temp

	; ativa interrupções
	sei	
	
	; vai para RX esperar comando				 
	rjmp RX



;//////////////////////////////// COMUNICACAO ///////////////////////////////////////
RX:
	; aguarda receber instrução em RX
	cbi PORTD,2 ;configura max485 para receber dados 
	lds temp, UCSR0A 
	sbrs temp, RXC0	;verifica se foram recebidos dados
	rjmp RX
	; guarda instrução recebida
	lds dir, UDR0

	; desativa comunicação RX
	ldi temp,0b00000000
	sts UCSR0B, temp
	
	; zera flag int1
	ldi temp,0b00000010
	sts EIFR, temp

	; verifica se comando = 1
	cpi dir, 0b00110001 
	BRNE nao1 ; se /= 1
	rjmp DIR1  ; se = 1

nao1:
	; verifica se comando = 2
	cpi dir, 0b00110010 
	BRNE nao2 ; se /= 2 
	rjmp DIR2  ; se = 2

nao2:
	; verifica se comando = 3
	cpi dir, 0b00110011 
	BRNE nao3 ; se /= 3 
	rjmp DIR3  ; se = 3

nao3:
	; verifica se comando = 4
	cpi dir, 0b00110100 
	BRNE erro ; se /= 4 (comando invalido)
	rjmp DIR2  ; se = 4

erro:
	ldi temp,0b00001000;TX on
	sts UCSR0B, temp
	sbi PORTD,2 ; configura max485 para enviar dados

	lds temp, UCSR0A 
	sbrs temp, UDRE0
	rjmp erro
	ldi r22,0b01000101
    sts UDR0, r22

	rjmp comfim

comfim: ; fim da comunicação
	lds temp, UCSR0A 
	sbrs temp,TXC0
	rjmp comfim
	ldi temp,0b01100000;TX fim
	sts UCSR0A, temp
	ldi temp,0b00010000; RX on
	sts UCSR0B, temp
	rjmp RX


;////////////////////////////////////// SELECAO SAIDA-ENTRADA ////////////////////////////////////
DIR1:

	cli
	
	ldi pin40khz,0b00000001  ; saida T1
	
	; ativa int1
	ldi temp,0b00000010 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	cbi PORTD,5 ; entrada T1
	cbi PORTD,6 ; entrada T2
	sbi PORTD,7 ; entrada T3 on
	cbi PORTB,0 ; entrada T4
	sei
	rjmp loop

DIR2:

	cli
	
	ldi pin40khz,0b00000010  ; saida T2
	

	; ativa int1
	ldi temp,0b00000010 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	cbi PORTD,5 ; entrada T1
	cbi PORTD,6 ; entrada T2
	cbi PORTD,7 ; entrada T3
	sbi PORTB,0 ; entrada T4 on
	sei
	rjmp loop

DIR3:
	
	cli
	
	ldi pin40khz,0b00000100  ; saida T3
	
	; ativa int1
	ldi temp,0b00000010 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	sbi PORTD,5 ; entrada T1 on
	cbi PORTD,6 ; entrada T2
	cbi PORTD,7 ; entrada T3
	cbi PORTB,0 ; entrada T4
	sei
	rjmp loop

DIR4:

	ldi pin40khz,0b00001000  ; saida T4
	cli

	; ativa int1
	ldi temp,0b00000010 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	cbi PORTD,5 ; entrada T1
	sbi PORTD,6 ; entrada T2 on
	cbi PORTD,7 ; entrada T3
	cbi PORTB,0 ; entrada T4
	sei
	rjmp loop

;////////////////////////////////////////// LOOP //////////////////////////////////////////////////

loop:
	rjmp loop


;////////////////////////////////////////// 40kHz MAKE ////////////////////////////////////////////
TIM0_COMPA:
	cli
	;cpi sum40,0b00000101
	;breq fim40khz
	cpi flag40khz,0b00000000 ; se flag = 0 
	brne baixo ;PC+2 ; entao   / pula 1 linha se nao igual
	rjmp cima  ; seta 1 no pind6

cima:
	;sbi PORTD,6 ; seta 1 no pind6
	out PORTC,pin40khz
	ldi flag40khz,0b00000001 ; levanta flag 40khz
	sei
	add sum40,flag40khz
	rjmp loop
baixo:
	;cbi PORTD,6 ; se nao, seta 0 no pind6
	;out POTRC,
	ldi flag40khz,0b00000000 ; zerra flag 40khz
	sei
	;RET
	rjmp loop
fim40khz:
	cbi PORTD,6
	ldi flag40khz,0b00000000
	
	ldi temp,0b00000000    ;configura TCC0B    clk off			 pg 107
	sts TCCR0B,temp
	sei
	;RET
	rjmp loop

;/////////////////////////////////////////////// TIMER EXTRA //////////////////////////

timer1_ovf:
	cli
	INC time3
	sei
	rjmp loop
	
;////////////////////////////////////////////// AQUISICAO DE DADOS ///////////////////////////

int1_calc:
	cli

	ldi temp,0b00000000    
	sts TCCR1B,temp ;configura TCC1B    clk off	
	out TCCR0B,temp ;configura TCC0B    clk off	 

	ldi temp,0b00000000 ;desativa int1
	out EIMSK,temp

	lds time1,TCNT1L    ; guarda valores de tempo
	lds time2,TCNT1H    
	
	out PORTC,temp ;  seta 0 no pind2
	ldi flag40khz,0b00000000 ; zerra flag 40khz
	
	; zerra controles de direção
	cbi PORTD,5 ; entrada T1
	cbi PORTD,6 ; entrada T2
	cbi PORTD,7 ; entrada T3
	cbi PORTB,0 ; entrada T4

;////////////////////////////////////////////// TRANSMICAO DOS DADOS //////////////////////////////////////////////////////	

	ldi temp,0b00001000;TX on
	sts UCSR0B, temp
	sbi PORTD,2 ; configura max485 para enviar dados	
	sei
	rjmp TXdir

; comando de direcao 
TXdir:
	lds temp, UCSR0A 
	sbrs temp, UDRE0
	rjmp TXdir
    sts UDR0, dir
TXdirfim:
	lds temp, UCSR0A 
	sbrs temp,TXC0
	rjmp TXdirfim
	ldi temp,0b01100000;TX fim
	sts UCSR0A, temp

; tempo 
TXtime1:
	lds temp, UCSR0A 
	sbrs temp, UDRE0
	rjmp TXtime1
    sts UDR0, time1
TX1fim:
	lds temp, UCSR0A 
	sbrs temp,TXC0
	rjmp TX1fim
	ldi temp,0b01100000;TX fim
	sts UCSR0A, temp

TXtime2:
	lds temp, UCSR0A 
	sbrs temp, UDRE0
	rjmp TXtime2
    sts UDR0, time2
TX2fim:
	lds temp, UCSR0A 
	sbrs temp,TXC0
	rjmp TX2fim
	ldi temp,0b01100000;TX fim
	sts UCSR0A, temp

TXtime3:
	lds temp, UCSR0A 
	sbrs temp, UDRE0
	rjmp TXtime3
    sts UDR0, time3

	rjmp comfim