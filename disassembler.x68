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

ASKST   DC.B    'Please enter starting address in hex:',0
ASKEN   DC.B    CR,LF,'Please enter ending address in hex:',0
DISST   DC.B    CR,LF,'Starting Address:',0
DISEN   DC.B    CR,LF,'Ending Address:',0

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
        BLT     DONE
        SUB.B   #$30,D1     ; offset by 0x30 
        CMP.B   #$9,D1      ; if greater than 0x9, could be a HEX letter
        BGT     ISUPP
        BRA     SHIFT4NXT
ISUPP: * Checks if the character is a HEX letter in uppercase
        SUB.B   #$7,D1      ; offset by 0x07 
        CMP.B   #$A,D1      
        BLT     DONE        ; if less than 0xA, invalid char
        CMP.B   #$F,D1  
        BGT     ISLOW       ; could be lowercase HEX letter
        BRA     SHIFT4NXT
ISLOW: * Checks if the character is a HEX letter in lowercase
        SUB.B   #$20,D1     ; offset by 0x20
        CMP.B   #$A,D1      ; if less than 0xA, invalid char
        BLT     DONE
        CMP.B   #$F,D1      ; if greater than 0xF, invalid char
        BGT     DONE
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
        BRA     DONE
VALIDATEIN:
        MOVE.L  STADR,D1
        CMP.L   D1,D2       ; check if ending is before start
        BLT     INVALID
        CMP.L   #$1000,D1 ; check if start is before program start
        BLT     INVALID

READMEM:
        MOVE.L  D2,ENADR    ; saving since latest address has not been saved yet
        CLR.L   D7
        CLR.L   D3     
        CLR.L   D2
        CLR.L   D1
        MOVE.L  STADR,A1    ; load starting address
LOOPMEM:
        MOVE.L  (A1)+,D2
        CMP.L   ENADR,A1
        BLT     LOOPMEM
        
        LEA     DISST,A1
        MOVE.B  #13,D0
        TRAP    #15

        MOVE.L  STADR,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        CLR.L     D1

        LEA     DISEN,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        MOVE.L  ENADR,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
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