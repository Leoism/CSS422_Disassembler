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
LOOPCOUNT DS.L  1       ; keep track of loop
PC_COUNT  DC.L  1       ; keep track of pc
IS_IN_MEM_BOOL DC.B  1

******** USER INPUT/OUTPUT/INTERACTIONS ********
ASKST   DC.B    'Please enter starting address in hex:',0
ASKEN   DC.B    CR,LF,'Please enter ending address in hex:',0
DISST   DC.B    CR,LF,'Starting Address:',0
DISEN   DC.B    CR,LF,'Ending Address:',0
DISWAIT DC.B    'Please press any key to continue displaying',0
DISDONE DC.B    'Finished.',0
INVALIDMSG DC.B    CR,LF,'You entered an invalid address. Try again.',CR,LF,0

******** COMMON CHARACTERS ********
NEWLINE DC.B    CR,LF,0
DISCOMMA DC.B   ',',0
DISPOUND DC.B   '#',0
DISDOLLAR DC.B  '$',0
DISPARENL DC.B   '(',0
DISPARENR DC.B   ')',0
DISPLUS DC.B    '+',0
DISMIN  DC.B    '-',0
DISTAB DC.B     '  ',0
******** INSTRUCTION PRINTS ********
DISNOP  DC.B    'NOP',0
DISLSL  DC.B    'LSL',0
DISLSR  DC.B    'LSR',0
DISASL  DC.B    'ASL',0
DISASR  DC.B    'ASR',0
DISROL  DC.B    'ROL',0
DISROR  DC.B    'ROR',0
DISADD  DC.B    'ADD',0
DISADDA DC.B    'ADDA',0
DISADDQ DC.B    'ADDQ',0
DISSUB  DC.B    'SUB',0
DISBRA  DC.B    'BRA  ',0
DISBLT  DC.B    'BLT  ',0
DISBGT  DC.B    'BGT  ',0
DISBLE  DC.B    'BLE  ',0
DISBGE  DC.B    'BGE  ',0
DISBEQ  DC.B    'BEQ  ',0
******** SIZE PRINTS ********
DISB    DC.B    '.B  ',0
DISW    DC.B    '.W  ',0
DISL    DC.B    '.L  ',0

******** DATAREGISTER/ADDRESS REGISTER PRINTS ********
DISD0   DC.B    'D0',0
DISD1   DC.B    'D1',0
DISD2   DC.B    'D2',0
DISD3   DC.B    'D3',0
DISD4   DC.B    'D4',0
DISD5   DC.B    'D5',0
DISD6   DC.B    'D6',0
DISD7   DC.B    'D7',0
DISA0   DC.B    'A0',0
DISA1   DC.B    'A1',0
DISA2   DC.B    'A2',0
DISA3   DC.B    'A3',0
DISA4   DC.B    'A4',0
DISA5   DC.B    'A5',0
DISA6   DC.B    'A6',0
DISA7   DC.B    'A7',0
******** INVALID DATA ********
DISDATA DC.B    '  DATA  ',0
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
        * Clear the screen
        MOVE.W  $FF00,D1
        MOVE.B  #15,D0
        TRAP    #15

        CLR.L   D1
        MOVE.L  STADR,A2    ; load starting address
LOOPMEM:
        ADDQ.L  #1,LOOPCOUNT
        CMPI.L  #30,LOOPCOUNT
        JSR     WAIT
        MOVE.L  A2,PC_COUNT
        MOVE.W  (A2),D2    ; each instruction is at least a word in machine code
        * Do action here *
DECODENOP:
        MOVE.W  D2, D3      ; make a copy in d3 to run tests on the copy
        EORI.W  #$4E71,D3   ; NOP XOR NOP would equal 0
        CMP.W   #0,D3
        BEQ     PRINTNOP
******** DECODE SHIFTS ********
DECODESHIFTS:
        MOVE.W  D2,D3
        LSR.W   #7,D3
        LSR.W   #5,D3
        CMPI.B  #$E,D3
        BNE     DECODEADDS  ; REPLACE WITH OPCODES AS THEY GET DONE
        MOVE.L  D2,D3
        LSR.L   #6,D3      
        ANDI.B  #$3,D3
        CMP.B   #$3,D3
        BEQ     DECODE_SHIFT_MEM  ; if 0 then a right shift.
******** DECODE REGISTER SHIFTS ********
DECODE_REG:
        MOVE.L  D2,D3       ; restore D3 
        BTST    #8,D3
        BEQ     DECODELSR_REG
******** DECODE LSL REG ******** 
DECODELSL_REG:
        BTST.L  #4,D3      ; shifts are set to 0
        BNE     DECODEROL_REG  ; rotates are set to 1
        BTST.L  #3,D3      ; arthimetic shift is set to 0
        BEQ     DECODEASL_REG
        JSR     GET_REG_SHIFT_DATA
        BRA     PRINTLSL_REG       
******** DECODE ASL REG ********
DECODEASL_REG:
        JSR     GET_REG_SHIFT_DATA 
        BRA     PRINTASL_REG
******** DECODE ROL REG ********
DECODEROL_REG:
        MOVE.L  D2,D3
        BTST.L  #3,D3
        BEQ     INVALIDOP   ; we are not supporting ROXL
        JSR     GET_REG_SHIFT_DATA
        BRA     PRINTROL_REG
******** DECODE LSR REG ********
DECODELSR_REG:
        BTST.L  #4,D3      ; shifts are set to 0
        BNE     DECODEROR_REG  ; rotates are set to 1
        BTST.L  #3,D3      ; arthimetic shift is set to 0
        BEQ     DECODEASR_REG
        JSR     GET_REG_SHIFT_DATA
        BRA     PRINTLSR_REG    
******** DECODE ASR REG ********
DECODEASR_REG:
        JSR     GET_REG_SHIFT_DATA 
        BRA     PRINTASR_REG
******** DECODE ROR REG ********
DECODEROR_REG:
        MOVE.L  D2,D3
        BTST.L  #3,D3
        BEQ     INVALIDOP   ; we are not supporting ROXR
        JSR     GET_REG_SHIFT_DATA
        BRA     PRINTROR_REG
******** DECODE MEMORY SHIFTS ********
DECODE_SHIFT_MEM:
        MOVE.L  D2,D3       ; restore D3 
        BTST.L  #8,D3
        BEQ     DECODE_LSR_MEM
******** DECODE LSL MEM ********
DECODE_LSL_MEM:
        BTST.L  #10,D3
        BNE     DECODE_ROL_MEM
        BTST.L  #9,D3
        BEQ     DECODE_ASL_MEM
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTLSL_MEM
******** DECODE ASL MEM ********
DECODE_ASL_MEM:
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTASL_MEM
******** DECODE ROL MEM ********
DECODE_ROL_MEM:
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTROL_MEM
******** DECODE LSR MEM ********
DECODE_LSR_MEM:
        BTST.L  #10,D3
        BNE     DECODE_ROR_MEM
        BTST.L  #9,D3
        BEQ     DECODE_ASR_MEM
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTLSR_MEM
******** DECODE ASR MEM ********
DECODE_ASR_MEM:
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTASR_MEM
******** DECODE ROR MEM ********
DECODE_ROR_MEM:
        JSR     GET_MEM_SHIFT_DATA
        BRA     PRINTROR_MEM
******** DECODE ADDITIONS ********
DECODEADDS:
        MOVE.W  D2,D3
        LSR.W   #7,D3
        LSR.W   #5,D3
        CMPI.B  #$D,D3
        BNE     DECODE_ADDQ
        MOVE.W  D2,D3
        * Check if its ADDA * 
        LSR.W   #6,D3
        ANDI.W  #$3,D3
        CMPI.W  #%011,D3
        BEQ     DECODE_ADDA_AnDn
        CMPI.W  #%111,D3
        BEQ     DECODE_ADDA_AnDn
        * Start ADD decode *
        * Check if ea or An/Dn *
        MOVE.W  D2,D3
        LSR.W   #3,D3
        ANDI.W  #$7,D3
        CMPI.W  #%111,D3
        BEQ     DECODE_ADD_EA
******** DECODE ADD Dn,Dn ********
DECODE_ADD_Dn:
        JSR     GET_ADD_MODE_REG
        JSR     GET_ADD_OPMODE
        JSR     GET_ADD_REG
        BRA     PRINT_ADD_Dn
******** DECODE ADD ea,Dn/Dn,ea ********
DECODE_ADD_EA:
        JSR     GET_ADD_MODE_REG
        JSR     GET_ADD_OPMODE
        JSR     GET_ADD_REG
        JSR     GET_ADD_EA
        BRA     PRINT_ADD_EA
*****************************
******** DECODE ADDA ********
*****************************
******** DECODE ADDA.x Dn,An & An,An ********
DECODE_ADDA_AnDn:
        JSR     GET_ADD_MODE_REG
        JSR     GET_ADD_OPMODE
        JSR     GET_ADD_REG
        * Check if we're dealing with Dn,An;An,An * 
        CMPI.B  #1,D7
        BLE     PRINT_ADDA_DnAn
        * CHeck if we're dealing with effective addressing *
        CMPI.B  #%111,D7
        BEQ     DECODE_ADDA_EA
        BRA     PRINT_ADDA_INDIRECT
DECODE_ADDA_EA:
        JSR     GET_ADD_EA
        BRA     PRINT_ADDA_EA
DECODE_ADDQ:
        MOVE.W  D2,D3
        LSR.W   #7,D3
        LSR.W   #5,D3
        CMPI.B  #5,D3
        BNE     DECODE_SUB
        MOVE.W  D2,D3
DECODE_ADDQ_AnDn:
        BTST.L  #8,D3
        BNE     INVALIDOP  ; bit #8 should be 0
        JSR     GET_ADD_MODE_REG
        JSR     GET_ADDQ_SIZE
        JSR     GET_ADDQ_DATA

        * CHeck if dealing with ea * 
        CMPI.B  #%111,D7
        BEQ     DECODE_ADDQ_EA
        CMPI.B  #%1,D7
        * Check if invalid size *
        CMPI.B  #%11,D5
        BEQ     INVALIDOP
        * Check if dealing with An/Dn *
        BLE     PRINT_ADDQ_AnDn
        BRA     PRINT_ADDQ_INDIRECT
DECODE_ADDQ_EA:
        JSR     GET_ADD_EA
        BRA     PRINT_ADDQ_EA
DECODE_SUB:
        MOVE.W  D2,D3
        LSR.W   #7,D3
        LSR.W   #5,D3
        CMPI.B  #9,D3
        BNE     DECODEBRANCHES
        MOVE.W  D2,D3
******** DECODE SUB Dn,Dn ********
DECODE_SUB_Dn:
        JSR     GET_ADD_MODE_REG
        JSR     GET_ADD_OPMODE
        JSR     GET_ADD_REG
        * check if opmode is 111 or 011 (not supporting addressing for SUB *
        CMPI.W  #%111,D6
        BEQ     INVALIDOP
        CMPI.W  #%011,D6
        BEQ     INVALIDOP
        * check if dealing with ea *
        CMPI.W  #%111,D7
        BEQ     DECODE_SUB_EA
        BRA     PRINT_SUB_Dn
******** DECODE ADD ea,Dn/Dn,ea ********
DECODE_SUB_EA:
        JSR     GET_ADD_EA
        BRA     PRINT_SUB_EA
        
*****************************
******** DECODE Bcc ********
*****************************
******** DECODE BRA, Bcc ********
*Assume that 0110 has been found branching to this
*D2 is original, D3 is manipulated copy, D4 is Conditional(4b), d5 is displacement(8b)
DECODEBRANCHES:
        MOVE.W  D2,D3   *reinstate the full machine code
        LSR.W   #7,D3 *0110 check probably in main method
        LSR.W   #5,D3
        CMPI.B  #%0110,D3
        BNE     INVALIDOP *Or the next decoding branch
        *-----------------------------------------------------------------------------
        MOVE.W  D2,D3   *reinstate the full machine code
        LSR.W   #7,D3
        LSR.W   #1,D3   *Get to the conditional bits
        ANDI.W  #$0F,D3 *Mask everything else to get conditional bits
        CMPI.W  #0,D3
        BEQ     DECODE_BRA
        CMPI.W  #%1101,D3
        BEQ     DECODE_BLT
        CMPI.W  #%1110,D3
        BEQ     DECODE_BGT
        CMPI.W  #%1111,D3
        BEQ     DECODE_BLE
        CMPI.W  #%1100,D3
        BEQ     DECODE_BGE
        CMPI.W  #%0111,D3
        BEQ     DECODE_BEQ
DECODE_BRA:
        JSR     PRINT_PC
        *We know that conditional is 0000, BRA
        JSR     PRINT_BRA *Print just BRA and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
DECODE_BLT:
        JSR     PRINT_PC
        *We know that conditional is 1101, BLT
        JSR     PRINT_BLT *Print just BLT and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
DECODE_BGT:
        JSR     PRINT_PC
        *We know that conditional is 1110, BGT
        JSR     PRINT_BGT *Print just BRA and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
DECODE_BLE:
        JSR     PRINT_PC
        *We know that conditional is 1111, BLE
        JSR     PRINT_BLE *Print just BLE and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
DECODE_BGE:
        JSR     PRINT_PC
        *We know that conditional is 1100, BGE
        JSR     PRINT_BGE *Print just BGE and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
DECODE_BEQ:  
        JSR     PRINT_PC
        *We know that conditional is 0111, BEQ
        JSR     PRINT_BEQ *Print just BEQ and come back
        JSR     GET_DISPLACEMENT
        CMP.W   #$00, D3    *Check if displacement = $00, word addressing
        BEQ     BRANCH_WORD
        CMP.W   #$FF, D3    *Check if displacement = $FF, long word addresing
        BEQ     BRANCH_LONG
        *If not, two's complement and subtract from current address   
        NOT     D5          *Flip all
        ADD.W   #%0000001, D5 *Add one
        MOVE.L  PC_COUNT,D3 *Get current address
        SUB.W  D5,D3        *Subtract D5 from current address
        MOVE.L  D3,D1 *Print D3, as it is the address
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
BRANCH_WORD:
        MOVE.B  #0,D7 *(Set 000 for word)
        JSR     DETERMINE_ADDR_MODE *Get word address
        JSR     PRINTDOLLAR
        MOVE.L  D6,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
BRANCH_LONG:
        MOVE.B  #1,D7 *(Set 001 for long)
        JSR     DETERMINE_ADDR_MODE *Get long address
        JSR     PRINTDOLLAR
        MOVE.L  D6,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE  
GET_DISPLACEMENT:
        MOVE.L  D2,D3   *Get new copy
        ANDI.W  #$FF,D3 *Mask first 8
        MOVE.W  D3,D5   *Store displacement into d5
        RTS
PRINT_BRA: *Prints just BRA
        LEA     DISBRA,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINT_BLT:
        LEA     DISBLT,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINT_BGT:
        LEA     DISBGT,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINT_BLE:
        LEA     DISBLE,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINT_BGE:
        LEA     DISBGE,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINT_BEQ:
        LEA     DISBEQ,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
        
******** INVALID OUTPUT ********
* THIS SHOULD ALWAYS BE THE LAST DECODE BRANCH
* THAT WAY AFTER ATTEMPTING ALL ADDRESSING MODE AND FAILING
* IT WILL FALLBACK TO THIS BRANCH
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

        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2   ; increment the address
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** ADDQ FUNCTIONS ********
* Returns:
*   D5 - contains size operation
GET_ADDQ_SIZE:
        MOVE.W  D2,D3
        LSR.W   #6,D3
        ANDI.W  #%11,D3    ; gets the size operation
        MOVE.B  D3,D5
        MOVE.W  D2,D3
        RTS
* Returns:
*   D6 - contains data
GET_ADDQ_DATA:
        MOVE.W  D2,D3
        LSR.W   #6,D3
        LSR.W   #3,D3
        ANDI.W  #%111,D3   ; gets the data 
        MOVE.B  D3,D6
        MOVE.W  D2,D3
        RTS
******** ADD FUNCTIONS ********
* Returns:
*   D7 - contains the register mode
*   D4 - contains the register number
GET_ADD_MODE_REG:
        MOVE.W  D2,D3
        LSR.W   #3,D3
        ANDI.W  #$7,D3     ; Gets the mode
        CMPI.W  #%101,D3
        BEQ     INVALIDOP
        CMPI.W  #%110,D3   ; we are not supporting this addressing modes
        BEQ     INVALIDOP 
        MOVE.W  D3,D7
        MOVE.W  D2,D3
        ANDI.W  #$7,D3     ; gets the register number
        MOVE.W  D3,D4
        MOVE.W  D2,D3
        RTS
* Returns:
*   D6 - contains opmode
GET_ADD_OPMODE:
        MOVE.W  D2,D3
        LSR.W   #6,D3
        ANDI.W  #$7,D3
        MOVE.W  D3,D6
        MOVE.W  D2,D3
        RTS
* Returns:
*   D5 - contains register
GET_ADD_REG:
        MOVE.W  D2,D3
        LSR.W   #5,D3
        LSR.W   #4,D3
        ANDI.W  #$7,D3
        MOVE.W  D3,D5
        RTS
* Returns:
*   D7 - contains ea 
GET_ADD_EA:
        CMP.B   #0,D4
        BEQ     ADD_WORD_ADDR
        CMP.B   #1,D4
        BEQ     ADD_LONG_ADDR
        BRA     INVALIDOP
ADD_WORD_ADDR:
        * Increment PC Counter
        CMP.W   #0,(A2)+   ; instructions are word size
        MOVE.W  (A2)+,D7    ; D6 will contain the address
        RTS
ADD_LONG_ADDR:
        * Increment PC Counter
        CMP.W   #0,(A2)+   ; instructions are word size
        MOVE.L  (A2)+,D7    ; D6 will contain the address
        RTS
******** COMMON SHIFT FUNCTIONS ********
* Returns:
*   D7 - Register
*   D6 - 1 or 0, determines if count or data register
*   D5 - Contains size of operation
*   D4 - Contains count or register as determined by D6
GET_REG_SHIFT_DATA:
        MOVE.L  D2,D3
        ANDI.B  #$7,D3     ; clear the 4th bit
        MOVE.B  D3,D7      ; D7 will contain the register
        MOVE.L  D2,D3      ; reset D3
        LSR.W   #5,D3      ; test the i/r bit
        ANDI.B  #$1,D3
        MOVE.B  D3,D6      ; D6 will contain if count or Dn
        MOVE.L  D2,D3
        LSR.W   #6,D3
        ANDI.W  #$3,D3
        MOVE.B  D3,D5      ; D5 will contain size operation
        CMPI.B  #%11,D5
        BEQ     INVALIDOP
        MOVE.L  D2,D3
        LSR.W   #5,D3
        LSR.W   #4,D3
        ANDI.W  #$7,D3
        MOVE.B  D3,D4      ; D4 will contain count/reg
        RTS
* Returns:
*   D7 - Contains register (word or long addressing)
*   D6 - Contains the address 
GET_MEM_SHIFT_DATA:
        BTST.L  #11,D3     ; the 11th bit must always be 0 for shifts
        BNE     INVALIDOP
        ANDI.L  #$7,D3
        MOVE.B  D3,D7      ; D7 will have register
        MOVE.L  D2,D3
        JSR     IS_MEM_INDIRECT
        CMPI.B  #$FF,IS_IN_MEM_BOOL
        BEQ     RETURN  
        JSR     DETERMINE_ADDR_MODE
        RTS
IS_MEM_INDIRECT:
        MOVE.W  D2,D3
        LSR.W   #3,D3
        ANDI.W  #%111,D3
        CMPI.W  #%111,D3
        BEQ     RETURN
        MOVE.B  D7,D4
        MOVE.B  D3,D7
        MOVE.B #$FF,IS_IN_MEM_BOOL
        RTS
******** DETERMINING ADDRESS MODES ********
* D7 should contain register.
* 000 for Word addressing
* 001 for Long addressing
DETERMINE_ADDR_MODE:
        CMP.B   #0,D7
        BEQ     WORD_ADDR
        CMP.B   #1,D7
        BEQ     LONG_ADDR
        BRA     INVALIDOP
WORD_ADDR:
        * Increment PC Counter
        CMP.W   #0,(A2)+   ; instructions are word size
        MOVE.W  (A2)+,D6    ; D6 will contain the address
        RTS
LONG_ADDR:
        * Increment PC Counter
        CMP.W   #0,(A2)+   ; instructions are word size
        MOVE.L  (A2)+,D6    ; D6 will contain the address
        RTS
************************************        
******** PRINT INSTRUCTIONS ********
************************************
PRINTNOP:
        JSR     PRINT_PC
        LEA     DISNOP,A1  ; display NOP string
        MOVE.B  #14,D0     
        TRAP    #15
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE

******** PRINT SHIFT INSTRUCTIONS ********
******** COMMON SHIFT FUNCS ********
SHIFT_IN1:
        CMPI.B  #0,D6
        BEQ     PRINT_SHIFT_REG_CONT
        JSR     PRINTDn
        RTS
PRINT_SHIFT_REG_CONT:
        LEA     DISPOUND,A1
        MOVE.B  #14,D0
        TRAP    #15

        CLR.L   D1
        MOVE.B  D4,D1
        MOVE.B  #10,D2
        MOVE.B  #15,D0
        TRAP    #15
        RTS
PRINT_REG_SHIFT_INFO:
        JSR     PRINTSIZEOP
        JSR     SHIFT_IN1
        JSR     PRINTCOMMA
        MOVE.B  D7,D4
        JSR     PRINTDn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        RTS
PRINT_MEM_SHIFT_INFO:
        MOVE.B  #1,D5
        JSR     PRINTSIZEOP

        JSR     PRINT_IS_MEM_IN
        JSR     PRINTDOLLAR
        MOVE.L  D6,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15

        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        RTS
PRINT_IS_MEM_IN:
        CMPI.B  #$FF,IS_IN_MEM_BOOL
        BNE     RETURN
        MOVE.B  #0,IS_IN_MEM_BOOL
        JSR     PRINT_ADDA_INDIRECT_TYPE
        JSR     PRINTNEWLINE
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT REGISTER SHIFTS ********
******** PRINT LOGIC REGISTER SHIFTS ********
PRINTLSL_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISLSL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTLSR_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISLSR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ARITHMETIC REGISTER SHIFTS ********
PRINTASL_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISASL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTASR_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISASR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ROTATATE SHIFTS ********
PRINTROL_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISROL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTROR_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
        JSR     PRINT_PC
        LEA     DISROR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_REG_SHIFT_INFO
        MOVE.W  (A2)+,D2    ; address should be incremented at the end of each print
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT MEMORY SHIFTS ********
******** PRINT LOGIC MEMORY SHIFTS ********
PRINTLSL_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISLSL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTLSR_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISLSR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ARITHMETIC MEMORY SHIFTS ********
PRINTASL_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISASL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTASR_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISASR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTROL_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISROL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTROR_MEM:
        * D6 contains the EA
        JSR     PRINT_PC
        LEA     DISROR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** ADDITION INSTRUCTIONS ********
******** PRINT ADD Dn,Dn ********
PRINT_ADD_Dn:
*   D7 - register mode, D4 - register number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISADD,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADD_OPMODE
        * Check if its Dn, ea *
        CMPI.B  #8,D6 
        BNE     PRINT_ADD_Dn_Ea

        JSR     PRINT_ADDA_Dn_OR_An
        JSR     PRINTCOMMA
        MOVE.W  D5,D4
        JSR     PRINTDn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINT_ADD_Dn_Ea:
        MOVE.W  D4,D1
        MOVE.W  D5,D4
        JSR     PRINTDn
        JSR     PRINTCOMMA
        MOVE.W  D1,D4
        JSR     PRINT_ADDA_Dn_OR_An
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE  
PRINT_ADD_EA:
*   D7 - EA, D4 - register number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISADD,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADD_OPMODE
        JSR     PRINT_EA_DN_OR_DN_EA
        JSR     CLEAR_ALL

        MOVE.W  (A2),D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ADDA Dn,An & An,An ********
PRINT_ADDA_DnAn:
*   D7 - ea mode, D4 - ea number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISADDA,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADDA_OPMODE
        JSR     PRINT_ADDA_Dn_OR_An
        JSR     PRINTCOMMA
        MOVE.W  D5,D4
        JSR     PRINTAn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ADDA (An),An & (An)+,An & -(An),An ********
PRINT_ADDA_INDIRECT:
        JSR     PRINT_PC
        LEA     DISADDA,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADDA_OPMODE
        JSR     PRINT_ADDA_INDIRECT_TYPE
        JSR     PRINTCOMMA

        MOVE.W  D5,D4
        JSR     PRINTAn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** PRINT ADDA ea,An ********
PRINT_ADDA_EA:
*   D7 - EA, D4 - register number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISADDA,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADDA_OPMODE
        JSR     PRINT_ADDA_EADDR
        JSR     PRINTCOMMA

        MOVE.W  D5,D4
        JSR     PRINTAn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2),D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE 
******** PRINT ADDQ #data,Dn/An ********
PRINT_ADDQ_AnDn:
* D7 - mode, D6 - data
* D5 - size, D4 - register
        JSR     PRINT_PC
        LEA     DISADDQ,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINTSIZEOP
        JSR     PRINT_ADDQ_DATA
        JSR     PRINTCOMMA
        JSR     PRINT_ADDA_Dn_OR_An
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINT_ADDQ_EA:
        JSR     PRINT_PC
        LEA     DISADDQ,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINTSIZEOP
        JSR     PRINT_ADDQ_DATA
        JSR     PRINTCOMMA
        JSR     PRINT_ADDA_EADDR
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2),D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE 
PRINT_ADDQ_INDIRECT:
        JSR     PRINT_PC
        LEA     DISADDQ,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINTSIZEOP
        JSR     PRINT_ADDQ_DATA
        JSR     PRINTCOMMA
        JSR     PRINT_ADDA_INDIRECT_TYPE
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINT_SUB_Dn:
*   D7 - register mode, D4 - register number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISSUB,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADD_OPMODE
        * Check if its Dn, ea *
        CMPI.B  #8,D6 
        BNE     PRINT_ADD_Dn_Ea

        JSR     PRINT_ADDA_Dn_OR_An
        JSR     PRINTCOMMA
        MOVE.W  D5,D4
        JSR     PRINTDn
        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL

        MOVE.W  (A2)+,D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINT_SUB_EA:
*   D7 - EA, D4 - register number
*   D6 - opmode, D5 - register
        JSR     PRINT_PC
        LEA     DISSUB,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_ADD_OPMODE
        JSR     PRINT_EA_DN_OR_DN_EA
        JSR     CLEAR_ALL

        MOVE.W  (A2),D2
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
******** ADDQ FUNCTIONS ********
PRINT_ADDQ_DATA:
        JSR     PRINTPOUND
        MOVE.B  D6,D1
        MOVE.B  #10,D2
        MOVE.B  #15,D0
        TRAP    #15
        RTS    
******** ADDA FUNCTIONS ********
PRINT_ADDA_Dn_OR_An:
        CMPI.B  #0,D7
        BEQ     PRINTDn
        CMPI.B  #1,D7 
        BEQ     PRINTAn
        BRA     PRINT_ADDA_INDIRECT_TYPE
PRINT_ADDA_OPMODE:
        CMPI.B  #%011,D6
        BEQ     PRINTW
        CMPI.B  #%111,D6
        BEQ     PRINTL
        RTS
PRINT_ADDA_INDIRECT_TYPE:
        CMPI.B  #%010,D7
        BEQ     PRINT_An_IN
        CMPI.B  #%011,D7
        BEQ     PRINT_An_POST
        CMPI.B  #%100,D7
        BEQ     PRINT_An_PRE
        RTS
PRINT_ADDA_EADDR:
        JSR     PRINTDOLLAR
        MOVE.L  D7,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        RTS
******** ADD FUNCTIONS ********
PRINT_ADD_OPMODE:
        JSR     ADD_EA_DN
        JSR     ADD_DN_EA
        RTS
PRINT_EA_DN_OR_DN_EA:
        CMPI.W  #8,D6
        BEQ     PRINT_EA_DN
        BRA     PRINT_DN_EA
        RTS
****************
* Returns
*   Prints ADD instruction from ea,Dn
PRINT_EA_DN:
        JSR     PRINTDOLLAR
        MOVE.L  D7,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTCOMMA
        MOVE.W  D5,D4
        JSR     PRINTDn
        JSR     PRINTNEWLINE
        RTS
****************
* Returns
*   Prints ADD instruction from Dn,ea
PRINT_DN_EA:
        MOVE.W  D5,D4
        JSR     PRINTDn
        JSR     PRINTCOMMA
        JSR     PRINTDOLLAR

        MOVE.L  D7,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        JSR     PRINTNEWLINE
        RTS
******************
* Returns
*   D6 - contains %1000 if ADD mode is ea,Dn
ADD_EA_DN:
        CMPI.B  #0,D6
        JSR     IS_EA_TO_DN
        BEQ     PRINTB
        CMPI.B  #8,D6      ; MOVE alters Z tag, must get it back.
        BEQ     PRINTB

        CMPI.W  #%001,D6
        JSR     IS_EA_TO_DN
        BEQ     PRINTW
        CMPI.B  #8,D6   ; MOVE alters Z tag, must get it back.
        BEQ     PRINTW

        CMPI.W  #%010,D6
        JSR     IS_EA_TO_DN
        BEQ     PRINTL
        CMPI.B  #8,D6   ; MOVE alters Z tag, must get it back.
        BEQ     PRINTL
        RTS
ADD_DN_EA:
        CMPI.W  #%100,D6
        BEQ     PRINTB
        CMPI.W  #%101,D6
        BEQ     PRINTW
        CMPI.W  #%110,D6
        BEQ     PRINTL
        RTS
IS_EA_TO_DN:
        BEQ     TRUE_EA_TO_DN
        RTS
TRUE_EA_TO_DN:
        MOVE.L  #8,D6
        RTS
****************************************
******** PRINT INSTRUCTION SIZE ********
****************************************
PRINTSIZEOP:
        CMPI.B  #$0,D5
        BEQ     PRINTB
        CMPI.B  #$1,D5
        BEQ     PRINTW
        CMPI.B  #$2,D5
        BEQ     PRINTL
        RTS
PRINTB:
        LEA     DISB,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTW:
        LEA     DISW,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTL:
        LEA     DISL,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
**********************************************
******** PRINT ADDRESS/DATA REGISTERS ********
**********************************************
* D4 should contain data register
PRINTDn:
        CMP.B #$7,D4
        BEQ PRINTD7
        CMP.B #$6,D4
        BEQ PRINTD6
        CMP.B #$5,D4
        BEQ PRINTD5
        CMP.B #$4,D4
        BEQ PRINTD4
        CMP.B #$3,D4
        BEQ PRINTD3
        CMP.B #$2,D4
        BEQ PRINTD2
        CMP.B #$1,D4
        BEQ PRINTD1
        CMP.B #$0,D4
        BEQ PRINTD0
PRINTD0:
        LEA     DISD0,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD1:
        LEA     DISD1,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD2:
        LEA     DISD2,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD3:
        LEA     DISD3,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD4:
        LEA     DISD4,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD5:
        LEA     DISD5,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD6:
        LEA     DISD6,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTD7:
        LEA     DISD7,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
* D4 should contain data register
PRINTAn:
        CMP.B #$7,D4
        BEQ PRINTA7
        CMP.B #$6,D4
        BEQ PRINTA6
        CMP.B #$5,D4
        BEQ PRINTA5
        CMP.B #$4,D4
        BEQ PRINTA4
        CMP.B #$3,D4
        BEQ PRINTA3
        CMP.B #$2,D4
        BEQ PRINTA2
        CMP.B #$1,D4
        BEQ PRINTA1
        CMP.B #$0,D4
        BEQ PRINTA0
PRINTA0:
        LEA     DISA0,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA1:
        LEA     DISA1,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA2:
        LEA     DISA2,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA3:
        LEA     DISA3,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA4:
        LEA     DISA4,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA5:
        LEA     DISA5,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA6:
        LEA     DISA6,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINTA7:
        LEA     DISA7,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
PRINT_An_IN:
        JSR     PRINTLEFTPAREN
        JSR     PRINTAn
        JSR     PRINTRIGHTPAREN
        RTS
PRINT_An_POST:
        JSR     PRINT_An_IN
        JSR     PRINTPLUS
        RTS
PRINT_An_PRE:
        JSR     PRINTMINUS
        JSR     PRINT_An_IN
        RTS
****************************************
******** PRINT COMMON CHARCTERS ********
****************************************
PRINTPOUND:
        LEA     DISPOUND,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTLEFTPAREN:
        LEA     DISPARENL,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTRIGHTPAREN:
        LEA     DISPARENR,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTPLUS:
        LEA     DISPLUS,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTMINUS:
        LEA     DISMIN,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTCOMMA:
        LEA     DISCOMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTNEWLINE:
        LEA     NEWLINE,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
PRINTDOLLAR:
        LEA     DISDOLLAR,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS
***********************
******** MISC. ********
***********************
WAIT:
        BLT     RETURN     
        LEA     DISWAIT,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.B  #5,D0
        TRAP    #15

        MOVE.L  #0,LOOPCOUNT
        RTS
RETURN:
        RTS
PRINT_PC:
        MOVE.L  PC_COUNT,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15
        CLR.L   D1   ; prevent dirty writing
        LEA     DISTAB,A1
        MOVE.B  #14,D0
        TRAP    #15

        RTS
CLEAR_ALL:
        CLR.L   D1
        CLR.L   D2
        CLR.L   D3
        CLR.L   D4
        CLR.L   D5
        CLR.L   D6
        CLR.L   D7
        RTS
DONE:
        LEA     DISDONE,A1
        MOVE.B  #14,D0
        TRAP    #15
        CLR.L   D1          ; clear up the data registers used.
        CLR.L   D2
        CLR.L   D3
        CLR.L   D7
        END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
