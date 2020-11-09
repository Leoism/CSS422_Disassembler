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
        BRA     IS0
* START: The following section converts ascii characters to
* corresponding hex
IS0:
        CMP.B   #$30,D1
        BNE     IS1
        CLR     D1
        ADD.B   #$00,D2
        BRA     SHIFT4NXT
IS1:
        CMP.B   #$31,D1
        BNE     IS2
        CLR     D1
        ADD.B   #$01,D2
        BRA     SHIFT4NXT
IS2:
        CMP.B   #$32,D1
        BNE     IS3
        CLR     D1
        ADD.B   #$02,D2
        BRA     SHIFT4NXT
IS3:
        CMP.B   #$33,D1
        BNE     IS4
        CLR     D1
        ADD.B   #$03,D2
        BRA     SHIFT4NXT
IS4:
        CMP.B   #$34,D1
        BNE     IS5
        CLR     D1
        ADD.B   #$04,D2
        BRA     SHIFT4NXT
IS5:
        CMP.B   #$35,D1
        BNE     IS6
        CLR     D1
        ADD.B   #$05,D2
        BRA     SHIFT4NXT
IS6:
        CMP.B   #$36,D1
        BNE     IS7
        CLR     D1
        ADD.B   #$06,D2
        BRA     SHIFT4NXT
IS7:
        CMP.B   #$37,D1
        BNE     IS8
        CLR     D1
        ADD.B    #$07,D2
        BRA     SHIFT4NXT
IS8:
        CMP.B   #$38,D1
        BNE     IS9
        CLR     D1
        ADD.B   #$08,D2
        BRA     SHIFT4NXT
IS9:
        CMP.B   #$39,D1
        BNE     ISA
        CLR     D1
        ADD.B   #$09,D2
        BRA     SHIFT4NXT
ISA:
        CMP.B   #$41,D1
        BNE     LCA
        BEQ     ISAC
LCA:
        CMP.B   #$61,D1
        BNE     ISB
ISAC:
        CLR     D1
        ADD.B   #$0A,D2
        BRA     SHIFT4NXT    
ISB:
        CMP.B   #$42,D1
        BNE     LCB
        BEQ     ISBC
LCB:
        CMP.B   #$62,D1
        BNE     ISC
ISBC:
        CLR     D1
        ADD.B   #$0B,D2
        BRA     SHIFT4NXT
ISC:
        CMP.B   #$43,D1
        BNE     LCC
        BEQ     ISCC
LCC:
        CMP.B   #$63,D1
        BNE     ISD
ISCC:
        CLR     D1
        ADD.B   #$0C,D2        
        BRA     SHIFT4NXT
ISD:
        CMP.B   #$44,D1
        BNE     LCD
        BEQ     ISDC
LCD:
        CMP.B   #$64,D1
        BNE     ISE
ISDC:
        CLR     D1
        ADD.B   #$0D,D2        
        BRA     SHIFT4NXT
ISE:
        CMP.B   #$45,D1
        BNE     LCE
        BEQ     ISEC
LCE:
        CMP.B   #$65,D1
        BNE     ISF
ISEC:
        CLR     D1
        ADD.B   #$0E,D2        
        BRA     SHIFT4NXT
ISF:
        CMP.B   #$46,D1
        CLR     D1
        ADD.B   #$0F,D2        
        BRA     SHIFT4NXT
* END * 

SHIFT4NXT:
        CMP.B   #8,D3       ; check if reached max characters
                            ; otherwise bitshift for next char
        BEQ     ISLASTIN    ; check if asking for last
        ASL.L   #4,D2
        BRA     CHARLOOP
ISLASTIN:
        CMP.B   #1,D7       ; if D7 is set, asking for last input
        BEQ     PRINTVAL        ; branch to the next place if asking for end
        CLR.L   D3          ; Clear character count
        MOVE.L  D2,STADR
        CLR     D2
        BRA     ENDADR      ; else ask for input
PRESSEDENT:
        ASR.L   #4,D2       ; remove the extra bit shift since when
                            ; pressing enter max chars is 7
PRINTVAL:
        MOVE.L  D2,ENADR    ; saving since latest address has not been saved yet
        
        LEA     DISST,A1
        MOVE.B  #13,D0
        TRAP    #15

        MOVE.L  STADR,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        CLR     D1

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