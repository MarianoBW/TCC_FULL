



.def temp  = R16
.def time1 = r17
.def time2 = r18
.def time3 = r19
.def sum40 = r20
.def dir   = r21

.def flag40khz = R23




.org 0x0000
	rjmp start

.org 0x002           ; local da memoria do ext_int0       pag 65
	rjmp int0_calc

.org 0x001A   ; timer1 ovf
	rjmp timer1_ovf

.org 0x001C   ; local da memoria do TIM0_COMPA 
	rjmp TIM0_COMPA

start:

	;desativa interrupções
	cli

	;configura CLK, desativa div8
	ldi temp,0b10000000
	sts CLKPR,temp
	ldi temp,0b00000000
	sts CLKPR,temp

	;configura pinos de saida
	
	sbi DDRC,3 ;direçao 1
	sbi DDRC,4 ;direçao 2
	sbi DDRC,5 ;se 0 RX, se 1 TX (max485) 
	sbi DDRD,6 ;saida 40KHz

	;configura serial
		; baudrate 9600
	ldi temp,0b00000000 ;0
	sts UBRR0H, temp
	ldi temp,0b10000001 ;129
	sts UBRR0L, temp
		; ativa RX , 
	ldi temp,0b00010000; RX
	sts UCSR0B, temp
		; 8 Bit, sem paridade e 1 bit de fim 
	ldi temp, 0b00000110
	sts UCSR0C, temp

	;40KHz
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
	sts TCCR1A,temp        ;configura TCCR1A    normal mode
	ldi temp,0b00000000    ;configura TCCR1B    clk=0 (ativa depois)
	sts TCCR1B,temp
	ldi temp,0b00000001    ;liga timer1 ovf
	sts TIMSK1,temp

	;interrupção externa
	ldi temp,0b00000010 ;  falling edge of INT0 
	sts EICRA,temp
	ldi temp,0b00000000 ; liga int0 depois
	out EIMSK,temp

	;zerar tudo 
	ldi temp,0b00000000
	ldi time1,0b00000000
	ldi time2,0b00000000
	ldi time3,0b00000000
	ldi sum40,0b00000000 ; contador de pulsos
	ldi dir,0b00000000
	ldi flag40khz,0b00000000    ; flag 40khz
	cbi PORTC,5
	cbi PORTC,4
	cbi PORTC,3

	; ativa interrupções
	sei	
	
	; vai para RX esperar comando				 
	rjmp RX

RX:
	; aguarda receber instrução em RX
	cbi PORTC,5
	lds temp, UCSR0A 
	sbrs temp, RXC0
	rjmp RX
	; guarda instrução recebida
	lds dir, UDR0

	; desativa comunicação RX
	ldi temp,0b00000000
	sts UCSR0B, temp
	
	; zera flag int0
	ldi temp,0b00000001
	sts EIFR, temp

	; verifica se comando = 1
	cpi dir, 0b00110001 
	BRNE nao1 ; se /= 1
	rjmp DIR1  ; se = 1


nao1:
	; verifica se comando = 2
	cpi dir, 0b00110010 
	BRNE erro ; se /= 2 (comando invalido)
	rjmp DIR2  ; se = 2

erro:
	ldi temp,0b00001000;TX on
	sts UCSR0B, temp
	sbi PORTC,5

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

DIR1:
	cli

	; ativa int0
	ldi temp,0b00000001 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	
	sbi PORTC,3
	sei
	rjmp loop


DIR2:
	cli

	; ativa int0
	ldi temp,0b00000001 
	out EIMSK,temp 
	
	ldi temp,0b00000000 ; reseta timer 0 e 1
	out TCNT0,temp		;|
	sts TCNT1L,temp     ; -->zerar o tempo									
	sts TCNT1H,temp		;|

	ldi sum40, 0b00000000 ;zera contador de pulsos 

	ldi temp,0b00000001    
	out TCCR0B,temp	;configura TCCR0B    clk/1									         
	sts TCCR1B,temp ;configura TCCR1B    clk/1

	sbi PORTC,4
	sei
	rjmp loop

loop:
	rjmp loop

TIM0_COMPA:
	cli
	;cpi sum40,0b00000101
	;breq fim40khz
	cpi flag40khz,0b00000000 ; se flag = 0 
	brne baixo ;PC+2 ; entao   / pula 1 linha se nao igual
	rjmp cima  ; seta 1 no pind6

cima:
	sbi PORTD,6 ; seta 1 no pind6
	ldi flag40khz,0b00000001 ; levanta flag 40khz
	sei
	add sum40,flag40khz
	;RET
	rjmp loop
baixo:
	cbi PORTD,6 ; se nao, seta 0 no pind6
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

timer1_ovf:
	cli
	INC time3
	sei
	rjmp loop
	;RET


int0_calc:
	cli

	ldi temp,0b00000000    
	sts TCCR1B,temp ;configura TCC1B    clk off	
	out TCCR0B,temp ;configura TCC0B    clk off	 

	ldi temp,0b00000000 ;desativa int0
	out EIMSK,temp

	lds time1,TCNT1L    ; guarda valores de tempo
	lds time2,TCNT1H    
	
	cbi PORTD,6 ;  seta 0 no pind6
	ldi flag40khz,0b00000000 ; zerra flag 40khz
	
	; zerra controles de direção
	cbi PORTC,3  
	cbi PORTC,4
	
	ldi temp,0b00001000;TX on
	sts UCSR0B, temp
	sbi PORTC,5	
	sei
	rjmp TXdir

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

;;;;;;;;;;;;;;;;