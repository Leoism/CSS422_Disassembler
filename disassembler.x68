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

******** USER INPUT/OUTPUT/INTERACTIONS ********
ASKST   DC.B    'Please enter starting address in hex:',0
ASKEN   DC.B    CR,LF,'Please enter ending address in hex:',0
DISST   DC.B    CR,LF,'Starting Address:',0
DISEN   DC.B    CR,LF,'Ending Address:',0
INVALIDMSG DC.B    CR,LF,'You entered an invalid address. Try again.',CR,LF,0

******** COMMON CHARACTERS ********
NEWLINE DC.B    CR,LF,0
DISCOMMA DC.B   ',',0
DISPOUND DC.B   '#',0
DISDOLLAR DC.B  '$',0
******** INSTRUCTION PRINTS ********
DISNOP  DC.B    'NOP',0
DISLSL  DC.B    'LSL',0
DISLSR  DC.B    'LSR',0
DISASL  DC.B    'ASL',0
DISASR  DC.B    'ASR',0
DISROL  DC.B    'ROL',0
DISROR  DC.B    'ROR',0
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

******** INVALID DATA ********
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
******** DECODE SHIFTS ********
DECODESHIFTS:
        MOVE.W  D2,D3
        ANDI.W  #$E000,D3  ; all shifts start with 1110
        CMPI.W  #$E000,D3
        BNE     INVALIDOP  ; REPLACE WITH OPCODES AS THEY GET DONE
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
        JSR     DETERMINE_ADDR_MODE
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
        RTS
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

        JSR     PRINTDOLLAR
        MOVE.L  D6,D1
        MOVE.B  #16,D2
        MOVE.B  #15,D0
        TRAP    #15

        JSR     PRINTNEWLINE
        JSR     CLEAR_ALL
        RTS
******** PRINT REGISTER SHIFTS ********
******** PRINT LOGIC REGISTER SHIFTS ********
PRINTLSL_REG:
        * D7: register, D6: is Count/Dn
        * D5: Size Op,  D4: Count/Dn
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
        LEA     DISLSL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTLSR_MEM:
        * D6 contains the EA
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
        LEA     DISASL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTASR_MEM:
        * D6 contains the EA
        LEA     DISASR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTROL_MEM:
        * D6 contains the EA
        LEA     DISROL,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
PRINTROR_MEM:
        * D6 contains the EA
        LEA     DISROR,A1
        MOVE.B  #14,D0
        TRAP    #15

        JSR     PRINT_MEM_SHIFT_INFO
        CMP.L   ENADR,A2   ; keep looping until reach the end
        BLT     LOOPMEM
        BRA     DONE
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
**************************************
******** PRINT DATA REGISTERS ********
**************************************
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
****************************************
******** PRINT COMMON CHARCTERS ********
****************************************
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
        CLR.L   D1          ; clear up the data registers used.
        CLR.L   D2
        CLR.L   D3
        CLR.L   D7
        END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
