*-----------------------------------------------------------
* Title      : Disassembler
* Written by : Cool Dudes (Cheuk-Hang Tse, Leonardo Mota-Villaraldo,
*              Sean Le, Zachary Joseph Morrison)
* Date       : 11/02/2020
* Description: Disassemmbles M68000 machine code into instructions
*-----------------------------------------------------------
    
LF      EQU     $0A      ; Line feed
CR      EQU     $0D      ; Carriage return
STADR   DS.L    1        ; allocate long in memory for
                         ; starting address
ENADR   DS.L    1        ; allocate for end address

NEWLINE DC.B    CR,LF,0

ASKST   DC.B    'Please enter starting address in hex:',0
ASKEN   DC.B    CR,LF,'Please enter ending address in hex:',0
DISST   DC.B    CR,LF,'Starting Address:',0
DISEN   DC.B    CR,LF,'Ending Address:',0
INVALIDMSG DC.B    CR,LF,'You entered an invalid address. Try again.',CR,LF,0

DISNOP  DC.B    'NOP',0
DISDATA DC.B    ' DATA ',0
        ORG     $1000     ; start at 1000
START:          

STARTADR:                   
        LEA     ASKST,A1    ; load message to A1
        MOVE.B  #13,D0      ; use trap task 13
        TRAP    #15
        BRA     CHARLOOP    ; loop to get start address
ENDADR:
        LEA     ASKEN,A1    ; load message to A1
        MOVE.B  #13,D0      ; use trap task 13
        TRAP    #15
        MOVE.B  #1,D7       ; set D7 to 1 (using as bool)
                            ; to later check if asking for end
        BRA     CHARLOOP    ; loop to get end address
CHARLOOP:
        MOVE.B  #5,D0       ; loop through user input until two 
                            ; hexa characters are entered.
        TRAP    #15
        ADD.B   #1,D3
        BLT     ISEND
ISEND:
        CMP.B   #$D,D1
        BEQ     PRESSEDENT
        BRA     CONVERTTOHEX

* START: The following section converts ascii characters to
* corresponding hex
CONVERTTOHEX:
        CMP.B   #$30,D1     ; if the less than 0x30 not valid
        BLT     INVALID
        SUB.B   #$30,D1     ; offset by 0x30 
        CMP.B   #$9,D1      ; if greater than 0x9, could be a HEX letter
        BGT     ISUPP
        BRA     SHIFT4NXT
ISUPP: * Checks if the character is a HEX letter in uppercase
        SUB.B   #$7,D1      ; offset by 0x07 
        CMP.B   #$A,D1      
        BLT     INVALID        ; if less than 0xA, invalid char
        CMP.B   #$F,D1  
        BGT     ISLOW       ; could be lowercase HEX letter
        BRA     SHIFT4NXT
ISLOW: * Checks if the character is a HEX letter in lowercase
        SUB.B   #$20,D1     ; offset by 0x20
        CMP.B   #$A,D1      ; if less than 0xA, invalid char
        BLT     INVALID
        CMP.B   #$F,D1      ; if greater than 0xF, invalid char
        BGT     INVALID
        BRA     SHIFT4NXT
* END * 

SHIFT4NXT:
        ADD.B  D1,D2
        CMP.B   #8,D3       ; check if reached max characters
                            ; otherwise bitshift for next char
        BEQ     ISLASTIN    ; check if asking for last
        ASL.L   #4,D2
        BRA     CHARLOOP
PRESSEDENT:
        ASR.L   #4,D2       ; remove the extra bit shift since when
                            ; pressing enter max chars is 7
ISLASTIN:
        CMP.B   #1,D7       ; if D7 is set, asking for last input
        BEQ     VALIDATEIN  ; branch to the next place if asking for end
        CLR.L   D3          ; Clear character count
        MOVE.L  D2,STADR
        CLR.L   D2
        BRA     ENDADR      ; else ask for input

INVALID:                    ; handle an invalid input
        LEA     INVALIDMSG,A1
        MOVE.B  #13,D0
        TRAP    #15

        CLR.L   D0
        CLR.L   D1
        CLR.L   D2
        CLR.L   D3
        CLR.L   D4
        CLR.L   D5
        CLR.L   D6
        CLR.L   D7
        BRA     STARTADR
VALIDATEIN:
        CLR.L   D3
        MOVE.L  D2,ENADR    ; saving since latest address has not been saved yet
        MOVE.L  STADR,D1
        CMP.L   D1,D2       ; check if ending is before start
        BLO     INVALID
        CMP.L   #$1000,D1   ; check if start is before program start
        BLT     INVALID
        LSR.B   #1,D1       ; check starting address to avoid loading invalid address
        BCS     INVALID     ; 68k only allows loading even addresses 
READMEM:
        CLR.L   D7
        CLR.L   D3     
        CLR.L   D2
        CLR.L   D1
        MOVE.L  STADR,A2    ; load starting address
LOOPMEM:
        MOVE.W  (A2),D2    ; each instruction is at least a word in machine code
        * Do action here *
DECODENOP:
        MOVE.W  D2, D3      ; make a copy in d3 to run tests on the copy
        EORI.W  #$4E71,D3   ; NOP XOR NOP would equal 0
        CMP.W   #0,D3
        BEQ     PRINTNOP
INVALIDOP:                 ; when an opcode is invalid, print the address, 'data', and data in memory
        MOVE.L  A2,D1      ; load the current address to print
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15

        LEA     DISDATA,A1 ; load 'DATA' string to print
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.W  (A2),D1    ; load data in A2 to print
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15

        LEA     NEWLINE,A1 ; print a new line for reading purposes
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.W  (A2)+,D2   ; increment the address
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE

PRINTNOP:
        LEA     DISNOP,A1  ; display NOP string
        MOVE.B  #13,D0     
        TRAP    #15

        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        BRA     LOOPMEM

DONE:
        CLR.L   D1          ; clear up the data registers used.
        CLR.L   D2
        CLR.L   D3
        CLR.L   D7
        END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
