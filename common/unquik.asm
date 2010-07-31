		TITLE	LZ-EXPANDER Copyright (c) SLR Systems 1989

		INCLUDE MACROS

		PUBLIC	QUIKPACK_PARAS
		PUBLIC	QUIK_STACK_ADR,QUIK_START_ADR,QUIK_PACK_LEN,QUIK_SKIP_PARAS
		PUBLIC	QUIK_UNPACK,QUIK_FIX_INT21

PACK_QUIK	SEGMENT PARA PUBLIC 'UNPACK_DATA'

		ASSUME	NOTHING,CS:PACK_QUIK

QUIK_UNPACK:
		DB	87H,0C0H
		JMP	SHORT QUIKUNPACK1

		DW	QUIK_START_JMP
		DB	02			;COMPRESSION TYPE

QUIK_STACK_ADR		DD	?
QUIK_START_ADR		DD	?

QUIKUNPACK1:
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
		ASSUME	DS:PACK_QUIK
		ADD	QUIK_STACK_ADR.SEGM,DX
		ADD	QUIK_START_ADR.SEGM,DX
		XOR	SI,SI
		XOR	DI,DI
		MOV	CX,QUIK_PACK_LEN/2+1
		REP	MOVSW
		PUSH	ES
		MOV	AX,OFF QUIK_MOVE_REST
		PUSH	AX
		RETF

QUIK_MOVE_REST	PROC	NEAR
		;
		;MOVE COMPRESSED DATA UP SO WE CAN EXPAND DOWN...
		;
		STD
		MOV	BX,QUIKPACK_PARAS	;# OF PARAGRAPHS TO MOVE...
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
		POP	DS
		LEA	SI,2[DI]

QUIK_MOVE_REST	ENDP

QUIK_1		PROC	NEAR
		;
		;INITIALIZATION
		;
		XOR	DI,DI		;# OF BYTES NOT PACKED...
		ADD	DX,8080H
QUIK_SKIP_PARAS EQU	$-2

		MOV	ES,DX

QUIK_1		ENDP

MEAT		PROC	NEAR
		;
		;DECOMPRESSOR
		;
		LODSW
		XCHG	AX,BP
		MOV	DX,0010H		;16 BITS LEFT TO ROTATE
		JMP	1$

25$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	251$

26$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	261$

51$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	511$

52$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	521$

		ALIGN	4,,1
15$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JNC	2$
0$:
		;
		;STRAIGHT BYTE
		;
		MOVSB
1$:
		ADD	BP,BP
		DEC	DX
		JZ	15$
		JC	0$
2$:
		;
		;0
		;
		ADD	BP,BP
		DEC	DX
		JZ	25$
251$:
		JC	3$
		;
		;00x	2 or 3, these are most likely
		;
		XOR	BH,BH
252$:
		INC	CX		;CX = 1
		ADD	BP,BP
		DEC	DX
		JZ	26$
261$:
		ADC	CX,CX		;CX = 2 OR 3
		CMP	CX,2
		JZ	27$
5$:
		;
		;GET HIGH BYTE OF OFFSET
		;
		XOR	BH,BH
		PUSH	CX
		ADD	BP,BP
		DEC	DX
		JZ	51$
511$:
		JC	6$
		;
		;0
		;
		ADD	BP,BP
		DEC	DX
		JZ	52$
521$:
		JC	55$
		;
		;00 IS 0
		;
RANGE_DONE:
		POP	CX
27$:
		LODSB				;LOW BYTE OF RANGE
		MOV	BL,AL
		NOT	BX
		XCHG	AX,SI			;02
		LEA	SI,[BX+DI]		;03
		CLI				;02
		REP MOVS [DI],ES:BPTR [SI]	;05+04 PER
		STI				;02
		XCHG	SI,AX			;02 =
		JMP	1$

		EVEN
55$:
		;
		;01
		;
		INC	BH
		ADD	BP,BP
		DEC	DX
		JZ	56$
561$:
		JNC	RANGE_DONE		;010 IS 1
		;
		;011X  IS 2 OR 3
		;
		MOV	CX,201H
GET_RANGE_CX:
		XOR	BH,BH
58$:
		ADD	BP,BP
		DEC	DX
		JZ	59$
591$:
		ADC	BH,BH
		DEC	CL
		JNZ	58$
		ADD	BH,CH
		JMP	RANGE_DONE

56$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	561$

59$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	591$

3$:
		;
		;1
		;
		INC	CX			;1
		ADD	BP,BP
		DEC	DX
		JZ	31$
311$:
		JNC	252$
		;
		;11
		;
		INC	CX			;2
		ADD	BP,BP
		DEC	DX
		JZ	32$
321$:
		JNC	252$
		;
		;111
		;
		CALL	GET_BIT
		MOV	BX,802H
		JNC	GET_BX			;1110XX	IS 8-11
4$:
		;
		;1111
		;
		CALL	GET_BIT
		MOV	BX,0C03H
		JNC	GET_BX			;11110XXX IS 12-19
		;
		;11111
		;
		LODSB
		MOV	AH,0
		CMP	AL,81H
		XCHG	AX,CX
		JB	5$
		JNZ	9$
		CALL	TRY_FIX_DOT
		XOR	CX,CX
		JMP	1$

6$:
		;
		;1
		;
		CALL	GET_BIT
		JC	7$
		;
		;10
		;
		CALL	GET_BIT
		MOV	CX,402H
		JNC	GET_RANGE_CX	;100XX	IS 4-7
		;
		;101XXX IS 8-F
		;
		MOV	CX,803H
		JMP	GET_RANGE_CX

31$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		JMP	311$

7$:
		;
		;11
		;
		CALL	GET_BIT
		MOV	CX,1004H
		JNC	GET_RANGE_CX	;110XXXX IS 10H-1FH
		;
		;111
		;
		CALL	GET_BIT
		MOV	CX,2004H
		JNC	GET_RANGE_CX	;1110XXXX IS 20H-2FH
		;
		;1111
		;
		CALL	GET_BIT
		MOV	CX,3004H
		JNC	GET_RANGE_CX
		MOV	CX,4006H
		JMP	GET_RANGE_CX

32$:
		LODSW
		XCHG	AX,BP
		MOV	DL,10H
		JMP	321$

GET_BX:
		;
		;
		;
		XOR	CX,CX
8$:
		ADD	BP,BP
		DEC	DX
		JZ	81$
811$:
		ADC	CX,CX
		DEC	BL
		JNZ	8$
		ADD	CL,BH
		JMP	5$

81$:
		LODSW
		XCHG	AX,BP
		MOV	DL,10H
		JMP	811$

9$:

MEAT		ENDP


QUIK_STARTUP:
		;
		;SET UP REGS AND SUCH FOR STARTING UP...
		;
		MOV	AL,0DH
		CALL	QUIK_FIX_DOT1
		MOV	AL,0AH
		CALL	QUIK_FIX_DOT1
		POP	DX
		SUB	DX,10H
		MOV	BX,ES		;FOR EXTERNAL UNPACKER
		MOV	DS,DX		;DS & ES ARE PSP
		MOV	ES,DX
		MOV	AX,QUIK_STACK_ADR.SEGM
		CLI
		MOV	SS,AX
		MOV	SP,QUIK_STACK_ADR.OFFS
		STI
QUIK_START_JMP:
		NOP
		JMP	QUIK_START_ADR


		EVEN
GET_BIT		PROC	NEAR
		;
		;
		;
		ADD	BP,BP
		DEC	DX
		JZ	1$
		RET

1$:
		LODSW
		XCHG	AX,BP
		MOV	DL,16
		RET

GET_BIT		ENDP

TRY_FIX_DOT	PROC	NEAR
		;
		;ADJUST STORAGE POINTERS
		;
		OR	SI,SI
		JNS	51$
		SUB	SI,8000H
		MOV	AX,DS
		ADD	AX,800H
		MOV	DS,AX
51$:
		OR	DI,DI
		JNS	1$
		MOV	AX,DI
		AND	AX,7FF0H
		SUB	DI,AX
		PUSH	CX
		MOV	CL,4
		SHR	AX,CL
		MOV	CX,ES
		ADD	CX,AX
		MOV	ES,CX
		POP	CX

;		SUB	DI,4000H
;		MOV	AX,ES
;		ADD	AX,400H
;		MOV	ES,AX
1$:

QUIK_FIX_DOT:
		MOV	AL,'.'
QUIK_FIX_DOT1:
		MOV	AH,2
		PUSH	DX
		MOV	DL,AL
QUIK_FIX_INT21:
		INT	21H
		POP	DX
		CLD
		RET

TRY_FIX_DOT	ENDP

CopyRight	DB	'Copyright (C) Digital Mars 1990-2004'

QUIKPACK_PARAS	DW	?

QUIK_PACK_LEN	EQU	$-QUIK_UNPACK

PACK_QUIK	ENDS

		END
