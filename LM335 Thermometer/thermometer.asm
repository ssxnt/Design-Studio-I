x$MODLP51RC2
org 0000H
   ljmp MainProgram

; These register definitions needed by 'math32.inc'
dseg at 30H
y: ds 4
x: ds 4
bcd: ds 5
result: ds 2

BSEG
mf: dbit 1

$NOLIST
$include(math32.inc)
$LIST

; These 'equ' must match the hardware wiring
; They are used by 'LCD_4bit.inc'
LCD_RS equ P3.2
; LCD_RW equ Px.x ; Always grounded
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

$NOLIST
$include(LCD_4bit.inc)
$LIST

CLK  EQU 22118400
BAUD equ 115200
BRG_VAL equ (0x100-(CLK/(16*BAUD)))
; These �EQU� must match the wiring between the microcontroller and ADC 
CE_ADC    EQU  P2.0 
MY_MOSI   EQU  P2.1  
MY_MISO   EQU  P2.2 
MY_SCLK   EQU  P2.3 

temperature: db 'TEMPERATURE: xxC', '\r', '\n', 0
newLine: db '\r', '\n', 0

CSEG

; Configure the serial port and baud rate
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret

; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret

; send a bcd number to PuTTY in ASCII
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
endmac

?Send_BCD:
	push acc
	mov a, r0 ; msd
	swap a
	anl a, #0FH
	orl a, #30H
	lcall putchar
	mov a, r0 ; lsd
	anl a, #0FH
	orl a, #30H
	lcall putchar
	pop acc
	ret
 
Hello_World:
    DB  'Hello, World!', '\r', '\n', 0
    
INIT_SPI: 
    setb MY_MISO    ; Make MISO an input pin 
    clr MY_SCLK     ; For mode (0,0) SCLK is zero 
    ret 
  
DO_SPI_G: 
    push acc 
    mov R1, #0      ; Received byte stored in R1 
    mov R2, #8      ; Loop counter (8-bits) 
DO_SPI_G_LOOP: 
    mov a, R0       ; Byte to write is in R0 
    rlc a           ; Carry flag has bit to write 
    mov R0, a 
    mov MY_MOSI, c 
    setb MY_SCLK    ; Transmit 
    mov c, MY_MISO  ; Read received bit 
    mov a, R1       ; Save received bit in R1 
    rlc a 
    mov R1, a 
    clr MY_SCLK 
    djnz R2, DO_SPI_G_LOOP 
    pop acc 
    ret 

MainProgram:
	setb CE_ADC
    mov SP, #7FH ; Set the stack pointer to the begining of idata
    ;mov P3M1, #0
    ;mov P2M1, #0
    
    lcall InitSerialPort
    lcall INIT_SPI
    lcall LCD_4BIT
 
 	Set_Cursor(1, 1)
 	Send_Constant_String(#temperature)
 	
mainLoop:
	clr CE_ADC
	mov R0, #00000001B
	lcall DO_SPI_G
	mov R0, #10000000B
	lcall DO_SPI_G
	mov a, R1
	anl a, #00000011B
	mov result+1, a
	mov R0, #55H
	lcall DO_SPI_G
	mov result,R1
	setb CE_ADC
   	mov x+0, result+0
   	mov x+1, result+1
   	mov x+2, #0
   	mov x+3, #0
   	load_Y(410)
   	lcall mul32
	load_Y(1023)
	lcall div32
	load_Y(273)
	lcall sub32
	lcall hex2bcd
	Set_Cursor(1, 14)
	Display_BCD(bcd)
	Send_BCD(bcd)
	mov a, #'\r'
	lcall putchar
	mov a, #'\n'
	lcall putchar
    sjmp mainLoop ; This is equivalent to 'forever: sjmp forever'
END
