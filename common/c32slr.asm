		TITLE	SLR-SUBS Copyright (c) SLR Systems, Inc 1990

		INCLUDE MACROS
		INCLUDE SLR32

		PUBLIC	FLUSHSTUFF_SLR32,PUTSTUFF_SMALL_SLR32,PUTSTUFF_SLR32,FIX_BUFFERS_SLR32

PACK_SLR	SEGMENT PARA PUBLIC 'UNPACK_DATA'

	SOFT	EXTB	POS_TABLE

	SOFT	EXTA	POS_TABLE_LEN

PACK_SLR	ENDS

		.DATA

	SOFT	EXTD	SLRBUF_PTR

		.CODE	PASS2_TEXT

	SOFT	EXTP	MOVE_DSSI_TO_FINAL_HIGH_WATER,DOT

		ASSUME	DS:NOTHING

FLUSHSTUFF_SLR32	PROC	NEAR
		;
		;END OF DATA, FLUSH OUT EVERYTHING
		;
		MOV	AX,SLR_EOF
		CALL	PUTSTUFF_SLR32
		MOV	DI,SLR_TMP_PTR.OFFS
		CALL	FLUSH_MINI_SLR			;FLUSH PARTIAL BUFFER
		CALL	DO_SENDBLOCK			;DUMP BLOCK
		LES	DI,HUF_PUT_PTR
		XOR	BX,BX
		MOV	AL,7
		CALL	PUTBITS 	;FLUSH LAST BYTE
		MOV	PUTBYTE_TEMP,DI
		MOV	DI,PUTBYTE_ADDR1
		JMP	FIX_OUTPUT

FLUSHSTUFF_SLR32	ENDP

PUTSTUFF_SMALL_SLR32	PROC	NEAR
		;
		;AL IS CHARACTER TO OUTPUT
		;
		MOV	DI,SLR_TMP_PTR.OFFS
		STOSB
		XOR	AH,AH
		MOV	BX,AX
		ADD	BX,BX
		INC	ES:HUF_FREQ_CHAR[BX]
		SHR	SLR_MASK,1
		JZ	51$
		MOV	SLR_TMP_PTR.OFFS,DI
		RET

PUTSTUFF_SLR32:
		;
		;AX IS REPEAT COUNT
		;BX IS DISTANCE
		;
		MOV	DI,AX			;FIRST UPDATE FREQ COUNTER
if	limited_charset
		CMP	AX,CHARSET_SIZE
		JNC	1$
endif
		ADD	DI,DI
		INC	ES:HUF_FREQ_CHAR[DI]	;CHARACTER FREQUENCY
19$:
		;
		;NOW STORE CHAR
		;
		MOV	DI,SLR_TMP_PTR.OFFS
		STOSB
		CMP	AX,SLR_FIX_BUFFERS
		JAE	2$
		XCHG	AX,BX			;IF COUNT = 2, JUST USE 1 BYTE OFFSET
		OR	BL,BL
		JNZ	3$
		STOSB
2$:
		MOV	SLR_TMP_PTR.OFFS,DI	;AND DON'T COUNT ANY FREQUENCY
		JMP	4$

if	limited_charset
1$:
		INC	ES:HUF_FREQ_CHAR[(CHARSET_SIZE-1)*2]
		JMP	19$
endif

3$:

		STOSW
		XCHG	AX,DI
		MOV	SLR_TMP_PTR.OFFS,AX
		;
		;HANDLE FREQ COUNTER ON OFFSET
		;
		SHRI	DI,HARD_CODED
		ADD	DI,DI
		INC	ES:HUF_FREQ_POS[DI]
		;
		;UPDATE FLAGS
		;
4$:
		MOV	AX,SLR_MASK
		MOV	BX,SLR_CPOS
		OR	ES:WPTR [BX],AX
		SHR	SLR_MASK,1
		JZ	5$
		RET

5$:
		MOV	DI,SLR_TMP_PTR.OFFS
		;
		;NEED NEW MASK
		;
51$:
		MOV	SLR_MASK,8000H
		CMP	DI,HUF_MINI_BUFFER+HMB_SIZE-52
		JA	FLUSH_MINI_SLR
52$:
		MOV	SLR_CPOS,DI
		XOR	AX,AX
		STOSW
		MOV	SLR_TMP_PTR.OFFS,DI
		RET

FLUSH_MINI_SLR:
		;
		;MINI_BUFFER IS FULL, FLUSH IT TO BIG BUFFER
		;
		PUSHM	DS,SI
		MOV	SLR_TMP_PTR.OFFS,DI
		MOV	CX,DI
		MOV	SI,HUF_MINI_BUFFER
		SUB	CX,SI			;# TO MOVE TO REAL BUFFER
		LES	DI,SLRBUF_PTR
		ADD	DI,CX			;WILL WE OVERFLOW?
		JC	6$
		CMP	DI,MAXBUF
		JA	6$
		SUB	DI,CX
		MOV	DS,SLR_VARS
		OPTI_MOVSB
		MOV	SLRBUF_PTR.OFFS,DI
		MOV	DI,HUF_MINI_BUFFER
		PUSH	DS
		POP	ES
		POPM	SI,DS
		JMP	51$


6$:
		;
		;BIG BUFFER IS FULL, FLUSH IT ALL
		;
		CALL	DO_SENDBLOCK
		POPM	SI,DS
		RET

PUTSTUFF_SMALL_SLR32	ENDP

DO_SENDBLOCK	PROC	NEAR
		;
		;FLUSH LARGE AND SMALL BUFFERS
		;
		MOV	DS,SLR_VARS
		MOV	ES,SLR_VARS
		CALL	SENDBLOCK		;FLUSH THAT BLOCK
		MOV	ES,SLR_VARS
		MOV	DS,SLR_DATA
		MOV	DI,HUF_MINI_BUFFER
		MOV	SLR_CPOS,DI
		XOR	AX,AX
		STOSW
		MOV	SLR_TMP_PTR.OFFS,DI
		MOV	SLRBUF_PTR.OFFS,AX
		RET

DO_SENDBLOCK	ENDP

MAKETREE_CHAR	PROC	NEAR
		;
		;DETERMINE HUFFMAN ENCODING FOR CHARACTERS
		;
		CALL	INIT_HUF_INSTALL	;INITIALIZE POINTERS

		LEA	DI,DS:HUF_FREQ_CHAR
		MOV	CX,CHARSET_SIZE
		XOR	AX,AX
01$:
		REPNE	SCASW			;SKIP ANY NONZERO
		JNZ	09$
		LEA	BX,-HUF_FREQ_CHAR-2[DI]
		SHR	BX,1
		MOV	HUF_FREQ_CHAR_LB[BX],1
		JCXZ	09$
		JMP	01$

09$:

		LEA	SI,DS:HUF_FREQ_CHAR
		MOV	CX,CHARSET_SIZE 	;# TO CHECK
		;
		;BUILD TABLE OF CHARS SORTED BY FREQUENCY
		;
1$:
;		LODSW				;ALL HAVE AT LEAST _LB PRESENT
;		OR	AX,AX
;		JZ	2$
		PUSHM	SI,CX
		LEA	AX,-(HUF_FREQ_CHAR)[SI]
		CALL	HUF_INSTALL_CHAR
		POPM	CX,SI
		ADD	SI,2
2$:
		LOOP	1$
		MOV	HUF_AVAIL,CHARSET_SIZE*2
		;
		;IF TABLE LESS THAN TWO (0 OR 1), RETURN THAT FACT
		;
;               MOV     DI,HUF_HEAP_END
;		SUB	DI,HUF_HEAP+2
;		CMP	DI,2
;		JA	3$
;		MOV	HUF_BITLEN_CHAR[DI],0
;		MOV	AX,DI
;		NOT	AX
;		RET

3$:
		;
		;WHILE AT LEAST TWO ENTRIES, REMOVE 2, INSTALL NEW WITH
		;COMBINED FREQ, BUILD LEFT & RIGHT TABLES
		;
		LEA	SI,DS:HUF_HEAP+4
		LEA	DI,DS:HUF_HEAP
		PUSHM	WPTR [DI],WPTR 2[DI]
		MOV	CX,HUF_HEAP_END
		SUB	CX,SI
		SHR	CX,1
		REP	MOVSW
		MOV	HUF_HEAP_END,DI
		POPM	DI,SI
		MOV	BX,HUF_AVAIL
		SHR	BX,1
		SHR	SI,1
		SHR	DI,1
		MOV	AL,HUF_FREQ_CHAR_LB[SI]
		ADD	AL,HUF_FREQ_CHAR_LB[DI]
		MOV	HUF_FREQ_CHAR_LB[BX],AL
		PUSHF
		ADD	BX,BX
		ADD	SI,SI
		ADD	DI,DI
		POPF
		MOV	AX,HUF_FREQ_CHAR[SI]
		ADC	AX,HUF_FREQ_CHAR[DI]
		MOV	HUF_FREQ_CHAR[BX],AX
		ADD	HUF_AVAIL,2
		MOV	HUF_LEFT_CHAR[BX],SI
		MOV	HUF_RIGHT_CHAR[BX],DI
		XCHG	AX,BX
		CALL	HUF_INSTALL_CHAR
		CMP	HUF_HEAP_END,OFF HUF_HEAP+2
		JA	3$
		;
		;ZERO OUT BITLEN ARRAY
		;
		LEA	DI,DS:HUF_BITLEN_CHAR
		MOV	CX,CHARSET_SIZE
		XOR	AX,AX
		REP	STOSW			;MAYBE HALF THIS IF BYTES

		MOV	BX,HUF_AVAIL
		DEC	BX
		DEC	BX
		PUSH	BX
		CALL	FINDBITLEN_CHAR 	;USE AVAIL-2

4$:
		CALL	MAKECODE_CHAR		;MAKES HUF_CODEWORD TABLE

		CMP	BX,MAXBITLEN
		JBE	5$
		CALL	ADJUSTLENGTH_CHAR
		JMP	4$

5$:
		POP	AX
		RET

MAKETREE_CHAR	ENDP

MAKETREE_POS	PROC	NEAR
		;
		;DETERMINE HUFFMAN ENCODING FOR POSITIONS
		;
		CALL	INIT_HUF_INSTALL	;INITIALIZE POINTERS

		LEA	DI,DS:HUF_FREQ_POS
		MOV	CX,1 SHL POS_BITS
		XOR	AX,AX
01$:
		REPNE	SCASW			;SKIP ANY NON-ZERO
		JNZ	09$
		LEA	BX,-HUF_FREQ_POS-2[DI]
		SHR	BX,1
		MOV	HUF_FREQ_POS_LB[BX],1
		JCXZ	09$
		JMP	01$

09$:
		LEA	SI,DS:HUF_FREQ_POS
		MOV	CX,1 SHL POS_BITS	;# TO CHECK
		;
		;BUILD TABLE OF CHARS SORTED BY FREQUENCY
		;
1$:
;		LODSW				;ALL HAVE AT LEAST _LB PRESENT
;		OR	AX,AX
;		JZ	2$
		PUSHM	SI,CX
		LEA	AX,-(HUF_FREQ_POS)[SI]
		CALL	HUF_INSTALL_POS
		POPM	CX,SI
		ADD	SI,2
2$:
		LOOP	1$
		MOV	HUF_AVAIL,(1 SHL POS_BITS)*2
		;
		;IF TABLE LESS THAN TWO (0 OR 1), RETURN THAT FACT
		;
;               MOV     DI,HUF_HEAP_END
;		SUB	DI,HUF_HEAP+2
;		CMP	DI,2
;		JA	3$
;		MOV	HUF_BITLEN_POS[DI],0
;		MOV	AX,DI
;		NOT	AX
;		RET

3$:
		;
		;WHILE AT LEAST TWO ENTRIES, REMOVE 2, INSTALL NEW WITH
		;COMBINED FREQ, BUILD LEFT & RIGHT TABLES
		;
		LEA	SI,DS:HUF_HEAP+4
		LEA	DI,DS:HUF_HEAP
		PUSHM	WPTR [DI],WPTR 2[DI]
		MOV	CX,HUF_HEAP_END
		SUB	CX,SI
		SHR	CX,1
		REP	MOVSW
		MOV	HUF_HEAP_END,DI
		POPM	DI,SI
		MOV	BX,HUF_AVAIL
		SHR	BX,1
		SHR	SI,1
		SHR	DI,1
		MOV	AL,HUF_FREQ_POS_LB[SI]
		ADD	AL,HUF_FREQ_POS_LB[DI]
		MOV	HUF_FREQ_POS_LB[BX],AL
		PUSHF
		ADD	BX,BX
		ADD	SI,SI
		ADD	DI,DI
		POPF
		MOV	AX,HUF_FREQ_POS[SI]
		ADC	AX,HUF_FREQ_POS[DI]
		MOV	HUF_FREQ_POS[BX],AX
		ADD	HUF_AVAIL,2
		MOV	HUF_LEFT_POS[BX],SI
		MOV	HUF_RIGHT_POS[BX],DI
		XCHG	AX,BX
		CALL	HUF_INSTALL_POS
		CMP	HUF_HEAP_END,OFF HUF_HEAP+2
		JA	3$
		;
		;ZERO OUT BITLEN ARRAY
		;
		LEA	DI,DS:HUF_BITLEN_POS
		MOV	CX,1 SHL POS_BITS
		XOR	AX,AX
		REP	STOSW			;MAYBE HALF THIS IF BYTES

		MOV	BX,HUF_AVAIL
		DEC	BX
		DEC	BX
		PUSH	BX
		CALL	FINDBITLEN_POS		;USE AVAIL-2

4$:
		CALL	MAKECODE_POS		;MAKES HUF_CODEWORD TABLE

		CMP	BX,MAXBITLEN
		JBE	5$
		CALL	ADJUSTLENGTH_POS
		JMP	4$

5$:
		;
		;RETURN
		;
		POP	AX
		RET

MAKETREE_POS	ENDP

		ALIGN	4
FINDBITLEN_CHAR PROC	NEAR
		;
		;BX IS CHAR(*2) TO CALC BITLEN
		;
		CMP	BX,CHARSET_SIZE*2
		JAE	5$
		MOV	HUF_BITLEN_CHAR[BX],CX
		RET

		ALIGN	4
5$:
		PUSH	HUF_RIGHT_CHAR[BX]
		INC	CX		;HUF_DEPTH
		MOV	BX,HUF_LEFT_CHAR[BX]
		CALL	FINDBITLEN_CHAR
		POP	BX
		CALL	FINDBITLEN_CHAR
		DEC	CX		;HUF_DEPTH
		RET

FINDBITLEN_CHAR ENDP

		ALIGN	4
FINDBITLEN_POS	PROC	NEAR
		;
		;BX IS CHAR(*2) TO CALC BITLEN
		;
		CMP	BX,(1 SHL POS_BITS)*2
		JAE	5$
		MOV	HUF_BITLEN_POS[BX],CX
		RET

		ALIGN	4
5$:
		PUSH	HUF_RIGHT_POS[BX]
		INC	CX		;HUF_DEPTH
		MOV	BX,HUF_LEFT_POS[BX]
		CALL	FINDBITLEN_POS
		POP	BX
		CALL	FINDBITLEN_POS
		DEC	CX		;HUF_DEPTH
		RET

FINDBITLEN_POS	ENDP

MAKECODE_CHAR	PROC	NEAR
		;
		;BUILDS CODEWORD ARRAY FROM BITLEN ARRAY
		;RETURNS MAXLEN IN BX
		;
		XOR	SI,SI		;HIGH
		XOR	BX,BX		;LOW
		MOV	HUF_CODETEMP_LOW,BX
		MOV	DX,8000H	;D=8000
		MOV	AX,1		;LEN=1
1$:
		MOV	DI,HUF_BITLEN_CHAR ;I = 0
		MOV	CX,CHARSET_SIZE
2$:
		REPNE	SCASW
		JNZ	29$

		MOV	HUF_CODEWORD_CHAR-2-HUF_BITLEN_CHAR[DI],SI
;		MOV	HUF_CODEWORD_CHAR_LOW-2-HUF_BITLEN_CHAR[DI],BX
		ADD	BX,HUF_CODETEMP_LOW
		ADC	SI,DX
		JNZ	2$
		OR	BX,BX
		JNZ	2$
		XCHG	AX,BX
		RET

29$:
		INC	AX		;INCREASE BITLEN
		SHR	DX,1
		RCR	HUF_CODETEMP_LOW,1
		JMP	1$

MAKECODE_CHAR	ENDP

MAKECODE_POS	PROC	NEAR
		;
		;BUILDS CODEWORD ARRAY FROM BITLEN ARRAY
		;RETURNS MAXLEN IN BX
		;
		XOR	SI,SI		;CODE HIGH
		XOR	BX,BX		;CODE LOW
		MOV	DX,8000H	;TEMP_HIGH
		MOV	HUF_CODETEMP_LOW,BX
		MOV	AX,1		;LEN=1
1$:
		MOV	DI,HUF_BITLEN_POS ;I = 0
		MOV	CX,1 SHL POS_BITS
2$:
		REPNE	SCASW
		JNZ	29$
		MOV	HUF_CODEWORD_POS-2-HUF_BITLEN_POS[DI],SI
;		MOV	HUF_CODEWORD_POS_LOW-2-HUF_BITLEN_POS[DI],BX
		ADD	BX,HUF_CODETEMP_LOW
		ADC	SI,DX
		JNZ	2$
		OR	BX,BX
		JNZ	2$
		XCHG	AX,BX
		RET

29$:
		INC	AX
		SHR	DX,1
		RCR	HUF_CODETEMP_LOW,1
		JMP	1$

MAKECODE_POS	ENDP

ADJUSTLENGTH_CHAR	PROC	NEAR
		;
		;HANDLE CODES LONGER THAN MAXBITLEN
		;
		LEA	DI,ES:HUF_BITLEN_CHAR
		MOV	CX,CHARSET_SIZE
		XOR	BX,BX		;CODE COUNTER
		MOV	AX,MAXBITLEN
		;
		;MARK AND COUNT ANY ABOVE OR EQUAL MAXBITLEN
		;
1$:
		SCASW			;ABOVE OR EQUAL?
		JA	2$
		DEC	BX
		MOV	-2[DI],AX	;SET TO MAXBITLEN LENGTH
2$:
		LOOP	1$
		;
		;NOW EXPAND SHORTER BIT PATTERNS TO MAXBITLEN LENGTH TILL ENOUGH CODES LEFT
		;
		MOV	DX,AX
		STD
		LEA	SI,DS:HUF_HEAP
3$:
		DEC	AX
		LEA	DI,ES:HUF_BITLEN_CHAR+CHARSET_SIZE*2-2
		MOV	CX,CHARSET_SIZE
4$:
		REPNE	SCASW
		JNZ	3$
		MOV	2[DI],DX	;SET TO MAXBITLEN

		MOV	[SI],DI 	;STACK IT FOR LATER IF NEEDED
		INC	SI
		INC	SI

		DEC	BX
		CMP	HUF_CODEWORD_CHAR[DI-(HUF_BITLEN_CHAR-2)],BX
		JA	4$
		;
		;ADD CODE TO SAVE AS MUCH AS POSSIBLE OF UNEVEN DIFFERENCE
		;
		JZ	8$
		MOV	DX,HUF_CODEWORD_CHAR[DI-(HUF_BITLEN_CHAR-2)]	;CURRENT CODE...
		SUB	BX,DX					;# OF BITS TO USE UP...
5$:
		INC	BX
		MOV	AX,BX
		XOR	CX,CX
		;
		;GET NEXT BITLEN TO USE
		;
51$:
		ADD	AX,AX
		INC	CX
		JNC	51$
		;
		;MAKE DI POINT TO 2 PAST ITEM TO CHANGE
		;
		CMP	SI,HUF_HEAP
		JZ	52$
		DEC	SI
		DEC	SI
		MOV	DI,[SI] 	;PTS TO BITLEN
		CMP	SI,HUF_HEAP
		JNZ	53$
		MOV	2[DI],CX		;NEW BITLEN
		MOV	HUF_CODEWORD_CHAR[DI-(HUF_BITLEN_CHAR-2)],DX
		LEA	DI,DS:HUF_BITLEN_CHAR+CHARSET_SIZE*2-2
		JMP	54$

52$:
		PUSHM	CX
		MOV	CX,CHARSET_SIZE
		MOV	AX,MAXBITLEN
		REPNE	SCASW
		POPM	CX
53$:
		MOV	2[DI],CX		;NEW BITLEN
		MOV	HUF_CODEWORD_CHAR[DI-(HUF_BITLEN_CHAR-2)],DX
54$:
		MOV	AX,1
		ROR	AX,CL
		ADD	DX,AX
		XOR	BX,AX
		JNZ	5$
8$:					;EXIT
		XOR	BX,BX
		LEA	DI,ES:HUF_BITLEN_CHAR+CHARSET_SIZE*2-2
		MOV	CX,CHARSET_SIZE
		MOV	AX,MAXBITLEN
81$:
		REPNE	SCASW
		JNZ	82$
		DEC	BX
		MOV	HUF_CODEWORD_CHAR[DI-(HUF_BITLEN_CHAR-2)],BX
		JMP	81$

82$:
		CLD
		RET

ADJUSTLENGTH_CHAR	ENDP

ADJUSTLENGTH_POS	PROC	NEAR
		;
		;HANDLE CODES LONGER THAN MAXBITLEN
		;
		LEA	DI,ES:HUF_BITLEN_POS
		MOV	CX,1 SHL POS_BITS
		XOR	BX,BX		;CODE COUNTER
		MOV	AX,MAXBITLEN
		;
		;MARK AND COUNT ANY ABOVE OR EQUAL MAXBITLEN
		;
1$:
		SCASW
		JA	2$
		DEC	BX
		MOV	-2[DI],AX
2$:
		LOOP	1$

		;
		;NOW EXPAND SHORTER BIT PATTERNS TO MAXBITLEN LENGTH TILL ENOUGH CODES LEFT
		;
		MOV	DX,AX
		STD
		LEA	SI,DS:HUF_HEAP
3$:
		DEC	AX
		LEA	DI,ES:HUF_BITLEN_POS+(1 SHL POS_BITS)*2-2
		MOV	CX,1 SHL POS_BITS
4$:
		REPNE	SCASW
		JNZ	3$
		MOV	2[DI],DX	;SET TO MAXBITLEN

		MOV	[SI],DI
		INC	SI
		INC	SI

		DEC	BX
		CMP	HUF_CODEWORD_POS[DI-(HUF_BITLEN_POS-2)],BX
		JA	4$
		;
		;ADD CODE TO SAVE AS MUCH AS POSSIBLE OF UNEVEN DIFFERENCE
		;
		JZ	8$
		MOV	DX,HUF_CODEWORD_POS[DI-(HUF_BITLEN_POS-2)]	;CURRENT CODE...
		SUB	BX,DX					;# OF BITS TO USE UP...
5$:
		INC	BX
		MOV	AX,BX
		XOR	CX,CX
		;
		;GET NEXT BITLEN TO USE
		;
51$:
		ADD	AX,AX
		INC	CX
		JNC	51$
		;
		;MAKE DI POINT TO 2 PAST ITEM TO CHANGE
		;
		CMP	SI,HUF_HEAP
		JZ	52$
		DEC	SI
		DEC	SI
		MOV	DI,[SI] 	;PTS TO BITLEN
		CMP	SI,HUF_HEAP
		JNZ	53$
		MOV	2[DI],CX		;NEW BITLEN
		MOV	HUF_CODEWORD_POS[DI-(HUF_BITLEN_POS-2)],DX
		LEA	DI,DS:HUF_BITLEN_POS+(1 SHL POS_BITS)*2-2
		JMP	54$

52$:
		PUSHM	CX
		MOV	CX,1 SHL POS_BITS
		MOV	AX,MAXBITLEN
		REPNE	SCASW
		POPM	CX
53$:
		MOV	2[DI],CX		;NEW BITLEN
		MOV	HUF_CODEWORD_POS[DI-(HUF_BITLEN_POS-2)],DX
54$:
		MOV	AX,1
		ROR	AX,CL
		ADD	DX,AX
		XOR	BX,AX
		JNZ	5$
8$:					;EXIT

		XOR	BX,BX
		LEA	DI,ES:HUF_BITLEN_POS+(1 SHL POS_BITS)*2-2
		MOV	CX,1 SHL POS_BITS
		MOV	AX,MAXBITLEN
81$:
		REPNE	SCASW
		JNZ	82$
		DEC	BX
		MOV	HUF_CODEWORD_POS[DI-(HUF_BITLEN_POS-2)],BX
		JMP	81$

82$:
		CLD
		RET

ADJUSTLENGTH_POS	ENDP

SENDBLOCK	PROC	NEAR
		;
		;ds and es are SLR_VARS
		;
		;
		;DETERMINE IF WE ARE USING A NEW HUFFMAN TABLE, OR THE OLD ONE...
		;
if	limited_charset
		INC	DS:HUF_FREQ_CHAR[(CHARSET_SIZE-1)*2]
else
		INC	DS:HUF_FREQ_CHAR[SLR_BLOCK_END*2]
endif
		MOV	HUF_TOTALS.HW,-1	;IN CASE FIRST TIME
		BITT	HUF_FIRST_TIME
		JZ	0$
		MOV	DI,HUF_PUT_PTR.OFFS
		MOV	AX,SLR_BLOCK_END
		CALL	ENCODE_CHARACTER
		MOV	HUF_PUT_PTR.OFFS,DI
		MOV	SI,HUF_BITLEN_CHAR	;SAVE OLD BITLEN STUFF
		MOV	DI,HUF_BITLEN_CHAR_OLD
		MOV	CX,CHARSET_SIZE
		REP	MOVSW
;		MOV	DI,HUF_BITLEN_CHAR	;CAN'T USE IF ANY ZERO
;		MOV	CX,CHARSET_SIZE
;		XOR	AX,AX
;01$:
;		REPNE	SCASW
;		JNZ	04$
;		CMP	(HUF_FREQ_CHAR-HUF_BITLEN_CHAR-2)[DI],AX
;		JNZ	0$
;		CMP	AX,DI
;		JMP	01$
;
;04$:
		CALL	CALC_SIZE_CHAR		;CALC # OF BITS REQUIRED
0$:
		PUSHM	HUF_TOTALS.HW,HUF_TOTALS.LW

		CALL	MAKETREE_CHAR		;HANDLE HUFMAN ENCODING
		;
		;TELL THEM HOW MANY CHARS TO EXPECT
		;
		MOV	DI,HUF_PUT_PTR.OFFS
;		OR	AX,AX
;		JS	1$
;		XCHG	AX,BX
;		MOV	BX,HUF_FREQ_CHAR[BX]
;		MOV	HUF_SIZE,BX
;		MOV	AX,BUFBITS		;16
;		CALL	PUTBITS
		;
		;NOW DETERMINE WHICH TABLE SAVES MORE BITS...
		;
		CALL	CALC_SIZE_CHAR
		PUSH	DI
		MOV	CX,CHARSET_SIZE
		MOV	DI,HUF_BITLEN_CHAR
		CALL	GET_HUFTABLE_SIZE	;IN DX:AX
		MOV	HUF_TREESIZE_CHAR,AX
		POP	DI
		ADD	AX,HUF_TOTALS.LW
		ADC	DX,HUF_TOTALS.HW
		POPM	BX,CX
		CMP	DX,CX
		JA	05$			;USE OLD
		JB	06$			;USE NEW
		CMP	AX,BX
		JA	05$
06$:
		;
		;USING A NEW TABLE
		;
		MOV	AL,1
		CALL	PUTBIT
		CALL	WRITETREE_CHAR
		JMP	2$

05$:
		;
		;USING PREVIOUS TABLE...
		;
		MOV	AL,0
		CALL	PUTBIT
		;
		;RESTORE OLD TABLE
		;
		PUSH	DI
		MOV	DI,HUF_BITLEN_CHAR	;SAVE OLD BITLEN STUFF
		MOV	SI,HUF_BITLEN_CHAR_OLD
		MOV	CX,CHARSET_SIZE
		REP	MOVSW
		CALL	MAKECODE_CHAR
		POP	DI
;		JMP	2$
;
;1$:
;		NOT	AX
;		XCHG	AX,BX
;		PUSH	BX
;		MOV	BX,HUF_FREQ_CHAR[BX]
;		MOV	HUF_SIZE,BX
;		MOV	AX,BUFBITS		;16
;		CALL	PUTBITS
;		MOV	AL,1			;NEW TABLE COMING...
;		CALL	PUTBIT
;		MOV	CX,3
;11$:
;		PUSH	CX
;		MOV	BX,1 SHL LENFIELD
;		MOV	AX,LENFIELD+1
;		CALL	PUTBITS
;		POP	CX
;		LOOP	11$
;		POP	BX
;		MOV	AX,9
;		CALL	PUTBITS

2$:
		MOV	HUF_PUT_PTR.OFFS,DI
		;
		;NOW DETERMINE SMALLEST POSSIBILITY FOR POSITION TREE
		;
		;READYMADE AND MAKECODE ALREADY DONE...
		;

;		MOV	DI,HUF_FREQ_POS
;		MOV	CX,1 SHL POS_BITS
;		XOR	AX,AX
;20$:
;		REPNE	SCASW
;		JNZ	201$
;		INC	WPTR -2[DI]
;		JMP	20$
;201$:

		MOV	HUF_TOTALS.HW,-1	;CAN'T USE OLD IF FIRST TIME
		BITT	HUF_FIRST_TIME
		JZ	21$
		MOV	SI,HUF_BITLEN_POS	;SAVE OLD BITLEN STUFF
		MOV	DI,HUF_BITLEN_POS_OLD
		MOV	CX,1 SHL POS_BITS
		REP	MOVSW
		;
		;CAN'T USE OLD IF IT HAS A ZERO WHERE I NEED SOMETHING NOW...
		;
;		MOV	DI,HUF_BITLEN_POS	;CAN'T USE IF ANY ZERO
;		MOV	CX,1 SHL POS_BITS
;		XOR	AX,AX
;202$:
;		REPNE	SCASW
;		JNZ	205$
;		CMP	(HUF_FREQ_POS-HUF_BITLEN_POS-2)[DI],AX
;		JNZ	21$
;		CMP	AX,DI
;		JMP	202$
;
;205$:
		CALL	CALC_SIZE_POS
21$:
		PUSHM	HUF_TOTALS.HW,HUF_TOTALS.LW
		CALL	FIX_READY
		CALL	CALC_SIZE_POS
		PUSHM	HUF_TOTALS.HW,HUF_TOTALS.LW

		CALL	MAKETREE_POS
		MOV	HUF_MAKETREE_POS_FLAGS,AX
		CALL	CALC_SIZE_POS
		MOV	CX,(1 SHL POS_BITS)
		MOV	DI,HUF_BITLEN_POS
		CALL	GET_HUFTABLE_SIZE	;IN DX:AX
		MOV	HUF_TREESIZE_POS,AX
		ADD	AX,HUF_TOTALS.LW
		ADC	DX,HUF_TOTALS.HW
		;
		;OK, I WANT THE SMALLEST, PREFERABLY PREVIOUS TREE
		;
		MOV	DI,HUF_PUT_PTR.OFFS
		POPM	BX,CX		;READY MADE
		CMP	CX,DX
		JA	26$		;NEW SMALLER THAN READY-MADE
		JB	27$		;READY-MADE SMALLER THAN NEW
		CMP	BX,AX
		JB	27$		;READY-MADE SMALLER THAN NEW
26$:
		;
		;HERE NEW (DX:AX) IS SMALLER THAN READY-MADE
		;
		POPM	BX,CX		;PREVIOUS TREE
		CMP	CX,DX
		JA	30$		;USE NEW
		JB	31$		;USE PREVIOUS
		CMP	BX,AX
		JA	30$		;USE NEW
		JMP	31$		;USE PREVIOUS

27$:
		;
		;HERE READY-MADE (CX:BX) IS SMALLER THAN NEW
		;
		POPM	AX,DX		;PREVIOUS TREE
		CMP	CX,DX
		JA	31$		;USE PREVIOUS
		JB	32$		;USE READY-MADE
		CMP	BX,AX
		JAE	31$		;USE PREVIOUS
		JMP	32$		;USE READY-MADE

30$:
		;
		;USE NEW TREE
		;
		MOV	AL,1
		CALL	PUTBIT
		MOV	AX,HUF_MAKETREE_POS_FLAGS
;		OR	AX,AX
;		JS	4$
		CALL	WRITETREE_POS
		JMP	5$

31$:
		;
		;USE PREVIOUS TREE
		;
		MOV	BL,0
		MOV	AL,2
		CALL	PUTBITS

		PUSH	DI

		MOV	DI,HUF_BITLEN_POS	;SAVE OLD BITLEN STUFF
		MOV	SI,HUF_BITLEN_POS_OLD
		MOV	CX,1 SHL POS_BITS
		REP	MOVSW
		JMP	39$			;GO REBUILD CODES

32$:
		;
		;USE READY-MADE
		;
		MOV	BL,1
		MOV	AL,2
		CALL	PUTBITS

		PUSH	DI

		CALL	FIX_READY
39$:
		CALL	MAKECODE_POS
		POP	DI
;		JMP	5$
;
;4$:
;		PUSH	AX
;		MOV	DX,3
;41$:
;		MOV	AX,LENFIELD+1
;		MOV	BX,1 SHL LENFIELD
;		CALL	PUTBITS
;		DEC	DX
;		JNZ	41$
;		POP	BX
;		NOT	BX
;		MOV	AL,POS_BITS
;		CALL	PUTBITS
5$:
		SETT	HUF_FIRST_TIME
		LDS	SI,SLRBUF_PTR
		MOV	DO_STUFF_LIMIT,SI
		XOR	SI,SI
		CALL	DO_STUFF
		LDS	SI,SLR_TMP_PTR
		MOV	DO_STUFF_LIMIT,SI
		MOV	SI,HUF_MINI_BUFFER
		CALL	DO_STUFF
		;
		;NOW ZERO OUT FREQUENCIES
		;
		MOV	HUF_PUT_PTR.OFFS,DI
		MOV	DI,HUF_FREQ_CHAR
		MOV	CX,CHARSET_SIZE*3
		XOR	AX,AX
		REP	STOSW
		MOV	DI,HUF_FREQ_POS
		MOV	CX,(1 SHL POS_BITS)*3
		REP	STOSW
		RET

SENDBLOCK	ENDP

DO_STUFF	PROC	NEAR
		;
		;DS:SI IS DATA SOURCE...
		;
		LODSW
		XCHG	AX,DX
		MOV	CX,16
		CMP	DO_STUFF_LIMIT,SI
		JBE	9$

		EVEN
1$:
		ADD	DX,DX
		JC	5$
		LODSB
		XOR	AH,AH
		PUSHM	DX,CX
		CALL	ENCODE_CHARACTER
19$:
		POPM	CX,DX
		CMP	DO_STUFF_LIMIT,SI
		JBE	9$
		LOOP	1$
		JMP	DO_STUFF

5$:
		LODSB
		MOV	AH,1
		PUSHM	DX,CX,AX
		CALL	ENCODE_CHARACTER
		POPM	AX
		OR	AL,AL
		JZ	6$
		CMP	AL,SLR_FIX_BUFFERS-256
		JAE	19$
		LODSW
		CALL	ENCODE_POSITION
		JMP	19$

6$:
		LODSB
;		XOR	AH,AH
;		XCHG	AX,BX
;		MOV	AX,T2_BITS
;		CALL	PUTBITS
		CALL	PUTBYTE
		JMP	19$

9$:
		RET

DO_STUFF	ENDP

GET_HUFTABLE_SIZE	PROC	NEAR
		;
		;CX IS SIZE OF TABLE
		;DI IS POINTER TO TABLE
		;
		;RETURN IN DX:AX AS BITS
		;
		MOV	DX,8		;ONE BYTE FOR BYTE-COUNT
1$:
		MOV	BX,CX
		MOV	AX,[DI]
		REPE	SCASW
		JZ	11$
		DEC	DI
		DEC	DI
		INC	CX
11$:
		SUB	BX,CX		;# OF ITEMS THIS BITLEN
		ADD	BX,15
		AND	BX,0FFF0H
		SHR	BX,1
		ADD	DX,BX
		JCXZ	9$
		JMP	1$

9$:
		XCHG	AX,DX
		XOR	DX,DX
		RET

;		MOV	DX,CX
;		XOR	AX,AX
;1$:
;		SCASW
;		JZ	2$
;		ADD	DX,4
;2$:
;		LOOP	1$
;		XCHG	AX,DX
;		RET

GET_HUFTABLE_SIZE	ENDP

CALC_SIZE_CHAR	PROC	NEAR
		;
		;FOR I = 0 THRU CHARSET_SIZE-1, SUM UP BITLEN*FREQ
		;
		XOR	SI,SI			;PTR
		XOR	BX,BX			;CX:BX IS TOTAL # OF BITS USED
		XOR	CX,CX
		MOV	HUF_TOTALS.LW,CX
		MOV	HUF_TOTALS.HW,CX
1$:
		MOV	AX,HUF_FREQ_CHAR[SI]	;FREQUENCY
		MUL	HUF_BITLEN_CHAR[SI]	;* BITLEN
		ADD	BX,AX
		ADC	CX,DX
		ADD	SI,2
		CMP	SI,CHARSET_SIZE*2
		JNZ	1$
		MOV	SI,512
2$:
		MOV	AX,HARD_CODED		;BITLEN
		MUL	HUF_FREQ_CHAR[SI]	;* FREQUENCY
		ADD	BX,AX
		ADC	CX,DX
		ADD	SI,2
		CMP	SI,CHARSET_SIZE*2-3*2
		JNZ	2$
		MOV	HUF_TOTALS.LW,BX
		MOV	HUF_TOTALS.HW,CX
		RET

CALC_SIZE_CHAR	ENDP

CALC_SIZE_POS	PROC	NEAR
		;
		;FOR I = 0 THRU 1 SHL POS_BITS, SUM UP BITLEN*FREQ
		;
		XOR	SI,SI
		XOR	BX,BX
		XOR	CX,CX
		MOV	HUF_TOTALS.LW,CX
		MOV	HUF_TOTALS.HW,CX
1$:
		MOV	AX,HUF_FREQ_POS[SI]
		MUL	HUF_BITLEN_POS[SI]
		ADD	BX,AX
		ADC	CX,DX
		ADD	SI,2
		CMP	SI,(1 SHL POS_BITS)*2
		JNZ	1$
		MOV	HUF_TOTALS.LW,BX
		MOV	HUF_TOTALS.HW,CX
		RET

CALC_SIZE_POS	ENDP

		ALIGN	4
ENCODE_CHARACTER	PROC	NEAR
		;
		;MUST PRESERVE DX AND SI AND DI
		;
		PUSH	AX
		ADD	AX,AX
if	limited_charset
		CMP	AX,CHARSET_SIZE*2
		JB	1$
		MOV	AX,CHARSET_SIZE*2-2
1$:
endif
		XCHG	AX,BX
		MOV	AX,ES:HUF_BITLEN_CHAR[BX]
		MOV	BX,ES:HUF_CODEWORD_CHAR[BX]
		CALL	PUTCODE 		;FROM MSB
		POP	BX
if	limited_charset
		SUB	BX,CHARSET_SIZE-1
		JNC	2$
endif
		RET

if	limited_charset
2$:
		MOV	AX,BX
		JMP	PUTBYTE
endif

ENCODE_CHARACTER	ENDP

ENCODE_POSITION PROC	NEAR
		;
		;AX IS POSITION
		;
		PUSH	AX
		MOV	CL,HARD_CODED-1
		SHR	AX,CL
		AND	AL,0FEH
		XCHG	AX,BX
		MOV	AX,ES:HUF_BITLEN_POS[BX]
		MOV	BX,ES:HUF_CODEWORD_POS[BX]
		CALL	PUTCODE
;		POP	BX
;		AND	BX,(1 SHL HARD_CODED)-1
;		MOV	AX,HARD_CODED
;		JMP	PUTBITS
		POP	AX
		JMP	PUTBYTE

ENCODE_POSITION ENDP

PUTBYTE		PROC	NEAR

		STOSB
		RET

PUTBYTE		ENDP

;		XCHG	AX,BX
;		XOR	BH,BH
;		MOV	AX,8
;		JMP	PUTBITS

		ALIGN	4,,3
PUTBIT:
		XCHG	AX,BX
		MOV	AL,1

PUTBITS 	PROC	NEAR
		;
		;DATA RIGHT JUSTIFIED IN BX
		;
		MOV	CL,16
		SUB	CL,AL
		SHL	BX,CL
PUTCODE:
		;
		;DATA LEFT JUSTIFIED IN BX
		;AX IS # OF BITS
		;
		MOV	CX,SLR_WORD		;# OF BITS IN TARGET
		MOV	DX,BX			;SAVE COPY
		SHR	BX,CL
		OR	CH,BH
		ADD	CL,AL
		CMP	CL,8
		JB	9$
		;
		;OUTPUT CHAR IN CH
		;
		CALL	PUTBITS_CH
		SUB	CL,8			;CL IS # OF BITS LEFT IN BL
		MOV	CH,BL
		CMP	CL,8
		JAE	4$
9$:
		MOV	SLR_WORD,CX
		RET

4$:
		;
		;OUTPUT CHAR IN CH
		;
		CALL	PUTBITS_CH
		;
		;
		SUB	CL,8			;# OF BITS TO RESCUE FROM DX
		SUB	AL,CL
		XCHG	AX,CX
		SHL	DX,CL
		MOV	AH,DH
		MOV	SLR_WORD,AX
		RET

PUTBITS 	ENDP

PUTBITS_CH	PROC	NEAR
		;
		;STORE BYTE IN CH
		;
		MOV	PUTBYTE_TEMP,DI
		MOV	DI,PUTBYTE_ADDR1
		MOV	ES:[DI],CH
		CMP	DI,HUF_PUT_BUF+HPB_SIZE-18-CHARSET_SIZE-(1 SHL POS_BITS) ;BUFFER FULL?
		JAE	2$
29$:
		MOV	DI,PUTBYTE_ADDR2
		MOV	PUTBYTE_ADDR1,DI
		MOV	DI,PUTBYTE_TEMP
		MOV	PUTBYTE_ADDR2,DI
		INC	DI
		RET

2$:
		INC	DI
		CALL	FIX_OUTPUT
		JMP	29$

PUTBITS_CH	ENDP

HUF_INSTALL_POS:
		MOV	SI,HUF_FREQ_POS
		MOV	DI,HUF_FREQ_POS_LB
		JMP	HUF_INSTALL

HUF_INSTALL_CHAR	PROC	NEAR
		;
		;STICK THIS GUY AT CORRECT PLACE IN HEAP
		;
		MOV	SI,HUF_FREQ_CHAR
		MOV	DI,HUF_FREQ_CHAR_LB
HUF_INSTALL:
		PUSH	AX
		MOV	BX,AX
		MOV	DX,[BX+SI]		;FREQUENCY FOR THIS ENTRY HIGH-WORD
		SHR	BX,1
		MOV	CL,[BX+DI]		;LOW BYTE
		MOV	BX,HUF_HEAP_END
		ADD	HUF_HEAP_END,2
		JMP	4$

		EVEN
2$:
		MOV	AX,[BX] 		;CURRENT CHARACTER
		XCHG	AX,BX
		CMP	[BX+SI],DX		;COMPARE HIGH WORD FREQ
		JA	3$
		JB	5$
		SHR	BX,1
		CMP	[BX+DI],CL
		JBE	5$
		ADD	BX,BX
3$:
		XCHG	AX,BX
		MOV	2[BX],AX
4$:
		SUB	BX,2
		CMP	BX,HUF_HEAP
		JAE	2$
		XCHG	AX,BX
5$:
		XCHG	AX,BX
		POP	AX
		MOV	2[BX],AX
		RET

HUF_INSTALL_CHAR	ENDP

INIT_HUF_INSTALL	PROC	NEAR

;		MOV	HUF_HEAP_START,HUF_HEAP
		MOV	HUF_HEAP_END,HUF_HEAP
		RET

INIT_HUF_INSTALL	ENDP

FIX_BUFFERS_SLR32	PROC	NEAR

		MOV	AX,SLR_FIX_BUFFERS
		CALL	PUTSTUFF_SLR32
		CALL	DOT
		RET

FIX_BUFFERS_SLR32	ENDP

FIX_OUTPUT	PROC	NEAR
		;
		;FLUSH STUFF FROM HUF_PUT_BUF
		;
		PUSHM	DS,SI,ES,DX,CX,BX,AX
		MOV	CX,DI
		MOV	SI,HUF_PUT_BUF
		SUB	CX,SI
		JZ	9$
		PUSH	ES
		POP	DS
		PUSH	CX
		CALL	MOVE_DSSI_TO_FINAL_HIGH_WATER
		POP	CX
9$:
		;
		;ADJUST PTRS
		;
		MOV	DS,SLR_VARS
		MOV	ES,SLR_VARS
		SUB	PUTBYTE_ADDR2,CX
		MOV	SI,HUF_PUT_BUF
		MOV	DI,SI
		ADD	SI,CX
		MOV	CX,PUTBYTE_TEMP
		SUB	CX,SI
		REP	MOVSB
		MOV	PUTBYTE_TEMP,DI
		POPM	AX,BX,CX,DX,ES,SI,DS
		RET

FIX_OUTPUT	ENDP

WRITETREE_CHAR	PROC	NEAR
		;
		;WRITE OUT HUFMAN CODE TABLE
		;
		MOV	AX,HUF_TREESIZE_CHAR
		MOV	CL,3
		SHR	AX,CL
		DEC	AX
		DEC	AX
		STOSB
		;
		MOV	SI,HUF_BITLEN_CHAR
		MOV	CX,CHARSET_SIZE
1$:
		XCHG	SI,DI
		MOV	BX,CX
		MOV	AX,[DI]
		REPE	SCASW
		JZ	11$
		DEC	DI
		DEC	DI
		INC	CX
11$:
		DEC	AX		;BITLEN - 1
		XCHG	SI,DI
		SUB	BX,CX		;# OF ITEMS THIS BITLEN
15$:
		AND	AL,0FH
		;
		;OUTPUT 16 AT A TIME...
		;
		MOV	DX,16
		CMP	BX,DX
		JA	2$
		MOV	DX,BX
2$:
		SUB	BX,DX
		DEC	DX
		SHLI	DX,4
		OR	AL,DL
		STOSB
		OR	BX,BX
		JNZ	15$
		JCXZ	9$
		JMP	1$

9$:
		RET


;		MOV	BX,[SI]
;		OR	BX,BX
;		MOV	AL,1
;		JZ	2$
;		ADD	BX,(1 SHL LENFIELD)-1
;		ADD	AL,LENFIELD
;2$:
;;		MOV	AL,LENFIELD
;		CALL	PUTBITS
;		INC	SI
;		INC	SI
;		CMP	SI,HUF_BITLEN_CHAR+2*CHARSET_SIZE
;		JNZ	1$
;		RET

WRITETREE_CHAR	ENDP

WRITETREE_POS	PROC	NEAR
		;
		;WRITE OUT HUFMAN CODE TABLE
		;
		MOV	AX,HUF_TREESIZE_POS
		MOV	CL,3
		SHR	AX,CL
		DEC	AX
		DEC	AX
		STOSB
		;
		MOV	SI,HUF_BITLEN_POS
		MOV	CX,1 SHL POS_BITS
1$:
		XCHG	SI,DI
		MOV	BX,CX
		MOV	AX,[DI]
		REPE	SCASW
		JZ	11$
		DEC	DI
		DEC	DI
		INC	CX
11$:
		DEC	AX		;BITLEN - 1
		XCHG	SI,DI
		SUB	BX,CX		;# OF ITEMS THIS BITLEN
15$:
		AND	AL,0FH
		;
		;OUTPUT 16 AT A TIME...
		;
		MOV	DX,16
		CMP	BX,DX
		JA	2$
		MOV	DX,BX
2$:
		SUB	BX,DX
		DEC	DX
		SHLI	DX,4
		OR	AL,DL
		STOSB
		OR	BX,BX
		JNZ	15$
		JCXZ	9$
		JMP	1$

9$:
		RET


;		MOV	SI,HUF_BITLEN_POS
;1$:
;		MOV	BX,[SI]
;		OR	BX,BX
;		MOV	AL,1
;		JZ	2$
;		ADD	BX,(1 SHL LENFIELD)-1
;		ADD	AL,LENFIELD
;2$:
;		MOV	AL,LENFIELD
;		CALL	PUTBITS
;		INC	SI
;		INC	SI
;		CMP	SI,HUF_BITLEN_POS+2*(1 SHL POS_BITS)
;		JNZ	1$
;		RET

WRITETREE_POS	ENDP

FIX_READY	PROC	NEAR
		;
		;
		;
		PUSH	DS
		MOV	AX,PACK_SLR
		MOV	DS,AX
		LEA	SI,POS_TABLE
		MOV	DI,HUF_BITLEN_POS
		MOV	AX,1
		MOV	DX,POS_TABLE_LEN
		XOR	CH,CH
1$:
		MOV	CL,[SI]
		INC	SI
		REP	STOSW
		INC	AX
		DEC	DX
		JNZ	1$
		POP	DS
		RET

FIX_READY	ENDP

		END
