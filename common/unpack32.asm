		TITLE	LZW-EXPANDER Copyright (c) SLR Systems 1989

		INCLUDE MACROS
		INCLUDE SLR32

		PUBLIC	EXP_STRUCT_SIZE,SLRPACK_PARAS,SLR_SKIP_PARAS
		PUBLIC	SLR_STACK_ADR,SLR_START_ADR,SLR_PACK_LEN
		PUBLIC	POS_TABLE,POS_TABLE_LEN,SLRUNPACK,FIX_INT21

EXP_STRUCT	STRUC

CURN_CHARSET_SIZE	DW	?
LIMIT		EQU	CURN_CHARSET_SIZE
CURN_RT_SIZE	DW	?
BITLEN		DB	CHARSET_SIZE DUP(?)
IF	$ AND 1
		DB	?
ENDIF
DECLEN		DB	256 DUP(?)
DECTBL		DW	256 DUP(?)
RIGHT		DW	CHARSET_SIZE*2 DUP(?)
LEFT		DW	CHARSET_SIZE*2 DUP(?)

POSITION_STUFF	DB	$ DUP(?)

SIZE_BP 	DW	?

EXP_STRUCT	ENDS

EXP_STRUCT_SIZE EQU	(SIZE EXP_STRUCT+15) AND 0FFF0H

GETBYTE 	MACRO

		MOV	AL,[BX]
		INC	BX
		XOR	AH,AH

		ENDM

PACK_SLR	SEGMENT PARA PUBLIC 'UNPACK_DATA'

		ASSUME	NOTHING,CS:PACK_SLR

SLRUNPACK_START:
SLRUNPACK:
		DB	87H,0C0H
		JMP	SHORT SLRUNPACK1

		DW	SLR_START_JMP
		DB	02			;COMPRESSION TYPE

SLR_STACK_ADR		DD	?
SLR_START_ADR		DD	?

SLRUNPACK1:
		;
		;STACK IS WHERE I WANT IT...
		;
		CLD
		MOV	DX,DS			;PSP
		ADD	DX,10H
		PUSH	DX
		PUSH	SS
		POP	ES
		PUSH	CS
		POP	DS
		ASSUME	DS:PACK_SLR
		ADD	SLR_STACK_ADR.SEGM,DX
		ADD	SLR_START_ADR.SEGM,DX
		XOR	SI,SI
		XOR	DI,DI
		MOV	CX,SLR_PACK_LEN/2+1
		REP	MOVSW
		PUSH	ES
		MOV	AX,OFF SLR_MOVE_REST
		PUSH	AX
		RETF

SLR_MOVE_REST	PROC	NEAR
		;
		;MOVE COMPRESSED DATA UP SO WE CAN EXPAND DOWN...
		;
		STD
		MOV	BX,SLRPACK_PARAS	;# OF PARAGRAPHS TO MOVE...
		ASSUME	DS:NOTHING
1$:
		;
		;MOVE SMALLER OF BX AND 1000H PARAS
		;
		MOV	CX,1000H		;ASSUME 64K
		CMP	BX,CX
		JA	2$
		MOV	CX,BX
2$:
		SUB	BX,CX
		MOV	AX,DS
		SUB	AX,CX
		MOV	DS,AX
		MOV	AX,ES
		SUB	AX,CX
		MOV	ES,AX
		ADD	CX,CX
		ADD	CX,CX
		ADD	CX,CX			;# OF WORDS TO MOVE
		MOV	DI,CX
		DEC	DI
		ADD	DI,DI			;ADDRESS OF FIRST WORD TO MOVE
		MOV	SI,DI
		REP	MOVSW
		OR	BX,BX
		JNZ	1$
		CLD
		PUSH	ES
;		POP	DS
		LEA	BX,2[DI]

SLR_MOVE_REST	ENDP

SLR_1		PROC	NEAR
		;
		;INITIALIZATION
		;
;		PUSH	DS
		PUSH	SS
		POP	ES
		PUSH	CS
		POP	DS
		MOV	DI,DATA_BASE
		MOV	BP,DI
		LEA	SI,INIT_1
		MOVSW
		MOVSW
		MOV	DI,POSITION_STUFF+DATA_BASE
		MOVSW
		MOVSW
		POP	DS
		XOR	DI,DI		;# OF BYTES NOT PACKED...

		ADD	DX,8080H
SLR_SKIP_PARAS	EQU	$-2

		MOV	ES,DX
		MOV	DH,[BX]
		INC	BX
		MOV	DL,[BX]
		INC	BX
		MOV	CX,8
;		CALL	FIX_PTRS
		JMP	NEW_BLOCK

INIT_1		DW	CHARSET_SIZE
		DW	9
		DW	1 SHL (POSSIZE-HARD_CODED)
		DW	POSSIZE-HARD_CODED

if	limited_charset
2$:
	IF	EXTRABITS	EQ 8
		GETBYTE
	ELSE
		MOV	AL,EXTRABITS
		CALL	GETBITS
	ENDIF
		JMP	29$
endif

0$:
		STOSB
1$:
		XOR	AH,AH		;TABLE LOOKUP ON BYTE SAYS WHAT
		MOV	AL,DH		;TO DO
		XCHG	AX,SI
		MOV	AL,DECLEN[SI+BP]
		ADD	SI,SI
		MOV	SI,DECTBL[SI+BP]
		;
		;NOW SKIP AL BITS
		;
		;AL IS NUMBER OF BITS TO READ
		;CL IS BITS IN DX (EXCESS 8)
		;
		CALL	SKIP_BITS
		XCHG	AX,SI
		CMP	AX,CHARSET_SIZE
		JAE	DO_DATA_AGAIN
DA_RET:
		OR	AH,AH
		JZ	0$
if	limited_charset
		CMP	AL,CHARSET_SIZE-256-1
		JZ	2$
29$:
endif
		CMP	AL,SLR_FIX_BUFFERS-256
		JAE	4$
5$:
		OR	AL,AL
		JZ	6$
		XOR	AH,AH		;TABLE LOOKUP ON BYTE SAYS WHAT
		PUSH	AX		;GET HI-PART OF POSITION
		MOV	AL,DH		;TO DO
		XCHG	AX,SI
		MOV	AL,DECLEN[SI+POSITION_STUFF+BP]
		ADD	SI,SI
		MOV	SI,[SI+POSITION_STUFF+BP].DECTBL
		CALL	SKIP_BITS
		CMP	SI,1 SHL (POSSIZE-HARD_CODED)
		JAE	55$
56$:
if	hard_coded eq 8
		XCHG	AX,SI
		XCHG	AL,AH
		MOV	SI,AX
		GETBYTE
else
		XCHG	AX,CX
		MOV	CL,HARD_CODED
		SHL	SI,CL
		XCHG	AX,CX
		CALL	GETBITS
endif
		ADD	SI,AX
		NEG	SI
		ADD	SI,DI
		DEC	SI
		POP	AX
		ADD	AX,THRESHOLD
		XCHG	AX,CX
		PUSH	DS
		PUSH	ES
		POP	DS
		REP	MOVSB
		POP	DS
		XCHG	AX,CX
		JMP	1$

55$:
		PUSH	BP
		MOV	BP,POSITION_STUFF+DATA_BASE
		CALL	TRY_AGAIN
		POP	BP
		JMP	56$

DO_DATA_AGAIN:
		XCHG	AX,SI
		CALL	TRY_AGAIN
		XCHG	AX,SI
		JMP	DA_RET

6$:
if	t2_bits eq 8
		GETBYTE
else
		MOV	AL,T2_BITS
		CALL	GETBITS
endif
		LEA	SI,-1[DI]
		SUB	SI,AX
		MOVS	[DI],ES:BPTR[SI]
		MOVS	[DI],ES:BPTR[SI]
		JMP	1$

4$:
		JZ	FIX_PTRS1
		CMP	AL,SLR_EOF-256
		JZ	SLR_STARTUP
NEW_BLOCK:
		CALL	INITIALIZE_BLOCK
		JMP	1$

FIX_PTRS1:
		CALL	FIX_PTRS
		JMP	1$

FIX_PTRS:
		CMP	DI,0C000H
		JB	FIX_DOT
		SUB	DI,4000H
		MOV	AX,ES
		ADD	AX,400H
		MOV	ES,AX
FIX_DOT:
		MOV	AL,'.'
FIX_DOT1:
		MOV	AH,2
		PUSH	DX
		MOV	DL,AL
FIX_INT21:
		INT	21H
		POP	DX
		CLD
FIX_GET:
		OR	BX,BX
		JNS	9$
		MOV	AX,DS
		ADD	AX,800H
		MOV	DS,AX
		SUB	BH,80H
9$:
		RET

SLR_STARTUP:
		;
		;SET UP REGS AND SUCH FOR STARTING UP...
		;
		MOV	AL,0DH
		CALL	FIX_DOT1
		MOV	AL,0AH
		CALL	FIX_DOT1
		POP	DX
		SUB	DX,10H
		MOV	BX,ES		;FOR EXTERNAL UNPACKER
		MOV	DS,DX		;DS & ES ARE PSP
		MOV	ES,DX
		MOV	AX,SLR_STACK_ADR.SEGM
		CLI
		MOV	SS,AX
		MOV	SP,SLR_STACK_ADR.OFFS
		STI
SLR_START_JMP:
		NOP
		JMP	SLR_START_ADR

SLR_1		ENDP

		EVEN
TRY_AGAIN	PROC	NEAR
		;
		;
		;
		ADD	SI,SI
		ADD	DX,DX
		DEC	CX
		JZ	7$
79$:
		JC	DO_RIGHT
		MOV	SI,LEFT[SI+BP]
		CMP	LIMIT[BP],SI
		JBE	TRY_AGAIN
		RET

7$:
		MOV	DL,[BX]
		INC	BX
		MOV	CL,8
		JMP	79$

		EVEN
DO_RIGHT:
		MOV	SI,RIGHT[SI+BP]
		CMP	LIMIT[BP],SI
		JBE	TRY_AGAIN
9$:
		RET

TRY_AGAIN	ENDP

		EVEN
GETBIT:
		MOV	AL,1
GETBITS 	PROC	NEAR
		;
		;AL IS NUMBER OF BITS TO READ
		;CL IS BITS IN DX (EXCESS 8)
		;RETURN BITS IN AX
		;
		CMP	AL,8		;08
		JZ	GET8BITS_1	;08
		PUSHM	SI,AX		;24
		SUB	AL,16		;08
		NEG	AL		;08
		XCHG	AX,CX		;04
		MOV	SI,DX		;08
		SHR	SI,CL		;05+4*(16-bits)
		XCHG	AX,CX		;03
		POP	AX		;12
		PUSH	SI		;12
		CALL	SKIP_BITS	;20
		POPM	AX,SI		;24
		RET			;===
					;176

GETBITS 	ENDP

		EVEN
GET8BITS	PROC	NEAR

		MOV	AL,8
GET8BITS_1:
		PUSH	DX
		CALL	SKIP_BITS
		POP	AX
		MOV	AL,AH
		XOR	AH,AH
		RET

GET8BITS	ENDP

		EVEN
SKIP_BITS	PROC	NEAR
		;
		;
		;
		CMP	CL,AL	;08
		JNC	2$	;08
		;
		;NOT ENOUGH, USE WHAT YOU CAN...
		;
		SHL	DX,CL
		MOV	DL,[BX]
		INC	BX
		SUB	AL,CL
		MOV	CL,AL
		SHL	DX,CL
		MOV	CL,8
		SUB	CL,AL
		RET

		EVEN
1$:
		MOV	DL,[BX]
		INC	BX
		MOV	CL,8
		RET

2$:
		;
		;ENOUGH BITS ALREADY HERE
		;
		XCHG	AX,CX	;04
		SHL	DX,CL	;33
		XCHG	AX,CX	;03
		SUB	CL,AL	;02
		JZ	1$	;08
		RET		;12
				;==
				;78

SKIP_BITS	ENDP

REBUILD_TREE	PROC	NEAR
		;
		;
		;
		PUSHM	DS,SI,DX,CX,BX
		MOV	BX,CURN_CHARSET_SIZE[BP]
		MOV	CX,100H ;LEN=1, DEPTH=0
		MOV	DX,-1	;C=-1
		XOR	SI,SI	;CODE=0
		CALL	PARTIAL_TREE
		POPM	BX,CX,DX,SI,DS
		RET

REBUILD_TREE	ENDP

		EVEN
PARTIAL_TREE	PROC	NEAR

		;
		;if (len==depth)
		;
		CMP	CH,CL
		JNZ	5$
		;
		;SCAN FOR MATCHING LEN
		;
		INC	DX
		MOV	AX,CURN_CHARSET_SIZE[BP]
		SUB	AX,DX		;# LEFT TO SCAN
		JBE	4$		; IF NONE LEFT TO SCAN
		XCHG	AX,CX
		MOV	DI,DX
		LEA	DI,BITLEN[DI+BP]
		REPNE	SCASB
		XCHG	AX,CX
		JNZ	4$
		;
		;
		;
		LEA	DX,-BITLEN-1[DI]
		SUB	DX,BP
		;
		;if len<=8
		;
		CMP	CH,8
		JA	3$
		MOV	AL,8
		SUB	AL,CH
		XCHG	AX,CX
		MOV	CH,1
		SHL	CH,CL
		MOV	DI,SI
		MOV	CL,8
		SHR	DI,CL
		PUSHM	AX,DI
		LEA	DI,DECLEN[DI+BP]
		MOV	CL,CH
		XOR	CH,CH
		PUSH	CX
		MOV	AL,AH		;LEN
		REP	STOSB
		POPM	CX,DI
		ADD	DI,DI
		LEA	DI,DECTBL[DI+BP]
		MOV	AX,DX		;C
		REP	STOSW
		POP	CX
3$:
		;
		;return c
		;
		MOV	AX,DX
		RET


4$:
		;
		;NO MORE THIS BITLEN
		;
		MOV	DX,-1		;C = -1
		INC	CH		; LEN++
5$:
		PUSH	BX		;SAVE I=AVAIL
		INC	BX		;AVAIL++
		INC	CX		;DEPTH++ (CL)
		CALL	PARTIAL_TREE	;
		POP	DI		;I
		ADD	DI,DI		;
		MOV	LEFT[DI+BP],AX	;
		PUSH	SI
		MOV	AX,8000H
		DEC	CX
		SHR	AX,CL
		INC	CX
		XOR	SI,AX
		PUSHM	DI
		CALL	PARTIAL_TREE
		POPM	DI,SI
		MOV	RIGHT[DI+BP],AX
		DEC	CX
		SHR	DI,1
		CMP	CL,8
		JNZ	6$
		MOV	AX,SI
		MOV	AL,AH
		XOR	AH,AH
		XCHG	AX,SI
		MOV	DECLEN[SI+BP],CL;8
		ADD	SI,SI
		MOV	DECTBL[SI+BP],DI
		XCHG	AX,SI
6$:
		XCHG	AX,DI		;RETURN I
		RET

PARTIAL_TREE	ENDP

INITIALIZE_BLOCK	PROC	NEAR
		;
		;
		;
		PUSHM	ES,DI
		PUSH	SS
		POP	ES

		CALL	GETBIT
		OR	AX,AX
		JZ	0$		;JMP IF KEEPING LAST TREE
		CALL	READ_TREE
0$:
		MOV	BP,POSITION_STUFF+DATA_BASE
		CALL	GETBIT
		OR	AX,AX
		JZ	2$
		CALL	READ_TREE		;1 MEANS READ A NEW TREE
05$:
;		OR	AL,1
1$:
		POPM	DI,ES
		XOR	CH,CH
		MOV	BP,DATA_BASE
		RET

2$:
		CALL	GETBIT
		OR	AX,AX			;USE SAME AS LAST TIME...
		JZ	05$
		PUSHM	DS,SI,DX,CX,BX,SS	;ONE MEANS USE DEFAULT
		POP	DS
		LEA	SI,POS_TABLE
		LEA	DI,BITLEN[BP]
		MOV	AL,1
		MOV	DX,LENGTH POS_TABLE
		XOR	CH,CH
3$:
		MOV	CL,[SI]
		INC	SI
		REP	STOSB
		INC	AX
		DEC	DX
		JNZ	3$
		CALL	REBUILD_TREE
		POPM	BX,CX,DX,SI,DS
		JMP	05$

INITIALIZE_BLOCK	ENDP


READ_TREE	PROC	NEAR
		;
		;
		;
		PUSH	CX
		LEA	DI,BITLEN[BP]
		GETBYTE
		MOV	SI,AX
		INC	SI
		XOR	CH,CH
1$:
		GETBYTE
		MOV	AH,AL
		MOV	CL,4
		SHR	AH,CL
		MOV	CL,AH
		AND	AL,0FH
		INC	AX
		STOSB
		REP	STOSB
		DEC	SI
		JNZ	1$
;		CMP	WPTR BITLEN[BP],101H
;		JNZ	2$
;		CMP	BITLEN+2[BP],1
;		JZ	5$
;2$:
		POP	CX
		;
		;NOW, DO BUILD TREE
		;
		JMP	REBUILD_TREE

;5$:
;		POP	CX
;		MOV	AX,CURN_RT_SIZE[BP]
;		CALL	GETBITS
;		PUSH	CX
;		MOV	CX,CURN_CHARSET_SIZE[BP]
;		LEA	DI,DECTBL[BP]
;		PUSH	CX
;		REP	STOSW
;		LEA	DI,DECLEN[BP]
;		POP	CX
;		XOR	AL,AL
;		REP	STOSB
;		JMP	2$

READ_TREE	ENDP

;DO_READEM	PROC	NEAR
		;
		;
		;
;1$:
;		MOV	AL,1
;		CALL	GETBITS
;		OR	AX,AX
;		JZ	2$
;		MOV	AL,LENFIELD
;		CALL	GETBITS
;		INC	AX
;2$:
;		STOSB
;		DEC	SI
;		JNZ	1$
;		RET
;
;DO_READEM	ENDP

CopyRight	DB	'Copyright (C) Digital Mars 1990-2004'

POS_TABLE	DB	1,0,0,1,2,6,15,22,20,19,42	;0,1,0,2,3,7,18,47,50

POS_TABLE_LEN	EQU	$-POS_TABLE

SLRPACK_PARAS		DW	?

SLR_PACK_LEN	EQU	$-SLRUNPACK_START

DATA_BASE	EQU	(SLR_PACK_LEN+15) AND 0FFF0H

PACK_SLR	ENDS

		END