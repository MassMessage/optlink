		TITLE	UNMANGLE -

		INCLUDE	MACROS
		INCLUDE	IO_STRUC


		PUBLIC	UNMANGLE


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE,FNTBL:BYTE

		EXTERNDEF	UNMANGLE_STUFF:ALLOCS_STRUCT


		.CODE	MIDDLE_TEXT

		EXTERNDEF	UNMANGLE_POOL_GET:PROC,CBTA32:PROC,_release_minidata:proc


UM_STRUCT	STRUC

ZNAMEI	DD	?
ZNAMES	DD	10 DUP(?)

ARGI	DD	?
ARGS	DD	10 DUP(?)

UM_STRUCT	ENDS


UNMANGLE	PROC
		;
		;
		;
;		JMP	L9$

		CMP	BPTR [EAX],'?'
		JNZ	L9$

		PUSHM	EDI,ESI,EBX,EAX

		PUSH	EAX
		MOV	EAX,OFF UNMANGLE_STUFF	;RELEASE MEMORY USED LAST TIME...

		push	EAX
		call	_release_minidata
		add	ESP,4

		POP	EBX
		CALL	UM_NESTNAME

		TEST	EAX,EAX
		JZ	L69$
		;
		;APPEND THIS TO ORIGINAL STRING.
		;
		MOV	ECX,")("
		CALL	STR_BRACKET

		POP	ECX		
		MOV	EDX,[EAX]

		PUSH	EAX
		MOV	ESI,ECX

		LEA	EAX,[EBX+8+EDX]

		SUB	EAX,ECX
		CALL	UNMANGLE_POOL_GET

		MOV	ECX,EBX
		MOV	EDI,EAX

		SUB	ECX,ESI
		MOV	EDX,EAX

		REP	MOVSB

		POP	ECX
		MOV	BPTR [EDI],' '

		INC	EDI
		PUSH	EDX

		LEA	ESI,[ECX+4]
		MOV	ECX,[ECX]

		REP	MOVSB

		MOV	DPTR [EDI],0
L69$:
		POPM	EAX,EBX,ESI,EDI
L9$:
		RET

UNMANGLE	ENDP


UM_NESTNAME	PROC

		PUSHM	EDI,ESI

		XOR	ECX,ECX
		MOV	EDI,-1		;OPIDX

		MOV	UM.ZNAMEI,ECX
		MOV	UM.ARGI,ECX

		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'?'
		JZ	L1$

		DEC	EBX
		CALL	UM_ZNAME

		POPM	ESI,EDI

		RET

L1$:
		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'?'
		JNZ	L2$
		;
		;?? IS OPERATOR
		;
		XOR	EAX,EAX

		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,30H
		XOR	EDI,EDI

		CMP	AL,10		;0-9
		JB	L15$

		CMP	AL,'_'-30H	;_
		JNZ	L10$

		ADD	EDI,10+26
		MOV	AL,[EBX]

		INC	EBX
		SUB	AL,30H

		CMP	AL,10
		JB	L15$
L10$:
		CMP	AL,'A'-'0'
		JB	L8$

		SUB	AL,'A'-'9'-1

		CMP	AL,10+26
		JA	L8$
L15$:
		ADD	EDI,EAX

		MOV	EAX,UM_TABLE[EDI*4]
		CALL	STR_DUP

		JMP	L3$

L2$:
		;
		;
		;
		DEC	EBX
		CALL	UM_ZNAME
L3$:
		TEST	EAX,EAX
		JZ	RETT

		MOV	ESI,EAX
		;
		;HANDLE SCOPING
		;
L4$:
		CMP	BPTR [EBX],'@'
		JZ	L6$

		CALL	UM_ZNAME

		TEST	EAX,EAX
		JZ	RETT

		TEST	EDI,EDI
		JNZ	L42$

		PUSH	EAX
		CALL	STR_DUP

		MOV	ESI,EAX
		POP	EAX

		DEC	EDI
		JMP	L46$

L42$:
		CMP	EDI,1
		JNZ	L46$

		MOV	ECX,EAX
		MOV	EAX,OFF SQUIGGLE_M

		PUSH	ECX
		CALL	STR_CAT

		MOV	ESI,EAX
		POP	EAX

		MOV	EDI,-1
L46$:
		PUSH	EAX
		MOV	EAX,OFF COLONCOLON_M

		MOV	ECX,ESI
		CALL	STR_CAT

		MOV	ECX,EAX
		POP	EAX

		CALL	STR_CAT

		MOV	ESI,EAX
		JMP	L4$

L6$:
		INC	EBX
		MOV	EAX,ESI

		CALL	UM_TYPE_ENCODING

		CMP	EDI,11
		JNZ	L61$

		MOV	ECX,EAX
		MOV	EAX,OFF OPERATOR_M

		CALL	STR_CAT
L61$:
		POPM	ESI,EDI

		RET

RETT:
L8$:
		XOR	EAX,EAX
		JMP	L61$

UM_NESTNAME	ENDP


UM_ZNAME	PROC
		;
		;RETURN POINTER TO STRING
		;
		TEST	EBX,EBX
		JZ	L9$

		XOR	EAX,EAX
		MOV	ECX,UM.ZNAMEI

		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,30H

		CMP	AL,10
		JNC	L2$

		CMP	CL,AL		;IS THIS A VALID INDEX INTO UM?
		JBE	L8$

		MOV	EAX,UM.ZNAMES[EAX*4]
		JMP	STR_DUP

L8$:
		DEC	EBX
L9$:
		XOR	EAX,EAX

		RET

L81$:
		MOV	EBX,ECX
		XOR	EAX,EAX

		RET

L2$:
		CMP	AL,'$' - 30H
		JZ	L21$

		CMP	AL,'?' - 30H
		JNZ	L3$

		MOV	AL,[EBX]

		CMP	AL,'$'
		JNZ	L3$
L21$:
		;
		;SET UP TO CALL UNMANGLE_PT
		;
		PUSHM	EBP,EDI,ESI
		MOV	EBP,ESP

		SUB	ESP,SIZEOF UM_STRUCT
		MOV	ESI,OFF UM

		MOV	ECX,SIZEOF UM_STRUCT/4
		MOV	EDI,ESP

		REP	MOVSD

		DEC	EBX
		CALL	UNMANGLE_PT

		MOV	ESI,ESP
		MOV	EDI,OFF UM

		MOV	ECX,SIZEOF UM_STRUCT/4

		REP	MOVSD

		MOV	ESP,EBP
;		DEC	EBX

		TEST	EAX,EAX
		POPM	ESI,EDI,EBP
		JNZ	L5$
L3$:
		;
		;DEFINE A NEW ZNAME
		;
		LEA	ECX,[EBX-1]	;START OF STRING
		DEC	EBX
L31$:
		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,0
		JZ	L81$

		CMP	AL,'@'
		JNZ	L31$

		DEC	EBX
		PUSH	EDI

		MOV	EAX,EBX
		PUSH	ESI

		MOV	ESI,ECX
		SUB	EAX,ECX

		PUSH	EAX
		ADD	EAX,4

		CALL	UNMANGLE_POOL_GET

		POP	ECX
		LEA	EDI,[EAX+4]

		MOV	[EAX],ECX
		ADD	ECX,3

		SHR	ECX,2

		REP	MOVSD

		POPM	ESI,EDI
L5$:
		MOV	ECX,UM.ZNAMEI
		INC	EBX

		CMP	ECX,10
		JAE	L6$

		MOV	UM.ZNAMES[ECX*4],EAX
		INC	ECX

		MOV	UM.ZNAMEI,ECX
		JMP	STR_DUP

L6$:

		RET

UM_ZNAME	ENDP


PT_STRUCT	STRUC

T_BP		DD	?
BUF_BP		DD	10 DUP(?)

FIRST_BP	DB	?
NEW_MANGLE_BP	DB	?
		DB	?
		DB	?

PT_STRUCT	ENDS


FIX	MACRO	XX

XX	EQU	<[EBP - SIZEOF PT_STRUCT].(XX&_BP)>

	ENDM


FIX	T
FIX	BUF
FIX	FIRST
FIX	NEW_MANGLE


UNMANGLE_PT	PROC
		;
		;
		;
		PUSHM	EBP,EDI

		PUSH	ESI
		MOV	EBP,ESP
		ASSUME	EBP:PTR PT_STRUCT

		MOV	ESI,EBX
		XOR	EAX,EAX

		SUB	ESP,SIZEOF PT_STRUCT
		MOV	NEW_MANGLE,AL

		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'?'
		JNZ	L05$

		MOV	NEW_MANGLE,1

		MOV	AL,[EBX]
		INC	EBX
L05$:
		CMP	AL,'$'
		JZ	L09$
L06$:
		MOV	ESP,EBP
		XOR	EAX,EAX

		MOV	EBX,ESI
		POP	ESI

		POPM	EDI,EBP

		RET


L09$:
		XOR	EAX,EAX

		MOV	UM.ZNAMEI,EAX
		MOV	UM.ARGI,EAX

		CALL	UM_ZNAME

;		TEST	EAX,EAX
;		JZ	L9$

		MOV	CL,'<'		;ADD A < TO END
		CALL	STR_CATC

		MOV	T,EAX

		MOV	FIRST,1
L0$:
		MOV	AL,[EBX]
		INC	EBX

		MOV	CL,NEW_MANGLE

		TEST	CL,CL
		JZ	OLD_MANGLE

		CMP	AL,'$'
		JZ	OLD_MANGLE1

		CMP	AL,'@'
		JZ	SPEC

		CMP	AL,0
		JNZ	DO_ARG
SPEC:
		DEC	EBX
		JMP	DONE

DO_ARG:
		DEC	EBX
		CALL	UM_ARGUMENT

		TEST	EAX,EAX
		JZ	DONE

		JMP	L8$

OLD_MANGLE1:
		MOV	AL,[EBX]
		INC	EBX
OLD_MANGLE:
		;
		;@, D, F, I, L, R, S, T	
		;
		CMP	AL,'L'
		JB	BELOW_L

		CMP	AL,'S'
		JB	BELOW_S

		JZ	EQUAL_S

		CMP	AL,'T'
		JZ	EQUAL_T

		JMP	DONE

BELOW_S:
		CMP	AL,'L'
		JZ	EQUAL_L

		CMP	AL,'R'
		JZ	EQUAL_R

		JMP	DONE

BELOW_L:
		CMP	AL,'F'
		JB	BELOW_F

		JZ	EQUAL_F

		CMP	AL,'I'
		JZ	EQUAL_I

		JMP	DONE

BELOW_F:
		CMP	AL,'D'
		JZ	EQUAL_D

		CMP	AL,'0'
		JZ	EQUAL_I

		CMP	AL,'1'
		JZ	EQUAL_1

		CMP	AL,'@'
		JNZ	DONE

		DEC	EBX
		JMP	DONE

EQUAL_I:
		LEA	EDI,BUF+4
		CALL	UM_DIMENSION

		MOV	ECX,EDI
		CALL	CBTA32

		SUB	EAX,EDI		;LENGTH OF STRING

		MOV	BUF,EAX
		LEA	EAX,BUF

		JMP	L8$

EQUAL_@:
		DEC	EBX
		JMP	DONE

EQUAL_F:
		MOV	ECX,4
		JMP	L1

EQUAL_1:
		MOV	EAX,OFF UM_BAND
		CALL	STR_DUP

		PUSH	EAX
		CALL	UM_NESTNAME

		MOV	ECX,EAX
		POP	EAX

		CALL	STR_CAT

		JMP	L8$
		

EQUAL_D:
EQUAL_L:
		MOV	ECX,8
L1:
		;
		;WE WANT ECX HEX DIGITS, TO STORE INTO BUF
		;
		LEA	EDX,BUF+4
		MOV	BUF,ECX
L12$:
		MOV	EAX,[EBX]	;I DON'T CONVERT FLOATS YET...
		ADD	EBX,4

		MOV	[EDX],EAX
		ADD	EDX,4

		SUB	ECX,4
		JNZ	L12$

		LEA	EAX,BUF
		JMP	L8$

EQUAL_R:
		CALL	UM_ZNAME

		TEST	EAX,EAX
		JNZ	L8$

		JMP	L91$

EQUAL_S:
		CALL	UM_STRING

		MOV	ECX,'""'
		CALL	STR_BRACKET

		JMP	L8$

EQUAL_T:
		CALL	UM_ARGUMENT
L8$:
		;
		;EAX IS A STRING
		;
		CMP	FIRST,0
		JNZ	L81$

		PUSH	EAX
		MOV	EAX,T

		MOV	CL,','
		CALL	STR_CATC

		MOV	T,EAX
		POP	EAX
L81$:
		MOV	ECX,EAX
		MOV	EAX,T

		CALL	STR_CAT

		MOV	FIRST,0

		MOV	T,EAX
		JMP	L0$

DONE:
		MOV	EAX,T
		MOV	CL,'>'

		CALL	STR_CATC
L91$:
		MOV	ESP,EBP
L9$:
		POPM	ESI,EDI,EBP

		RET

UNMANGLE_PT	ENDP


UM_DIMENSION	PROC
		;
		;
		;
		XOR	ECX,ECX
		XOR	EAX,EAX

		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'0'
		JB	L5$

		CMP	AL,'9'
		JA	L5$

		SUB	AL,'0'-1

		RET

L1$:
		SHL	ECX,4
		SUB	AL,'A'

		CMP	AL,16
		JAE	L8$

		OR	CL,AL
		MOV	AL,[EBX]

		INC	EBX
L5$:
		CMP	AL,'@'
		JNZ	L1$
L8$:
		MOV	EAX,ECX

		RET

UM_DIMENSION	ENDP


UM_STRING	PROC
		;
		;
		;
		PUSHM	EDI,ESI

		SUB	ESP,512		;ROOM FOR A BIG STRING

		MOV	EDX,ESP
		MOV	ESI,ESP
L1$:
		MOV	AL,[EBX]
		INC	EBX
		;
		;CASES ARE: NUL, @, ?, ALPHANUMERIC
		;
		AND	EAX,0FFH
		JZ	L8$

		CMP	AL,'@'
		JZ	L7$

		CMP	AL,'?'
		JZ	L5$

		MOV	CL,FNTBL[EAX]

		AND	CL,MASK IS_ALPHA + MASK IS_NUMERIC
		JZ	L8$

L4$:
		MOV	[EDX],AL
		INC	EDX

		JMP	L1$

L5$:
		;
		;AFTER ?
		;
		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'$'
		JZ	L55$

		MOV	CL,FNTBL[EAX]

		AND	CL,MASK IS_NUMERIC + MASK IS_ALPHA
		JZ	L8$

		AND	CL,MASK IS_NUMERIC
		JZ	L57$
		;
		;IS_ALPHA
		;
		ADD	AL,80H
		JMP	L4$

L57$:
		;
		;IS_DIGIT
		;
		MOV	AL,SPECIAL_CHAR[EAX-30H]
		JMP	L4$

L55$:
		;
		;AFTER ?$
		;
		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,'A'

		CMP	AL,16
		JAE	L8$

		SHL	AL,4
		MOV	CL,[EBX]

		SUB	CL,'A'
		INC	EBX

		CMP	CL,16
		JAE	L8$

		OR	AL,CL
		JMP	L4$

L7$:
		;
		;WE ARE KEEPING THIS STRING, ALLOCATE SPACE AND COPY...
		;
		MOV	EAX,EDX

		SUB	EAX,ESI

		MOV	ECX,EAX			;LENGTH OF STRING
		ADD	EAX,4			;BYTES TO ALLOCATE

		PUSH	ECX
		CALL	UNMANGLE_POOL_GET

		POP	ECX
		LEA	EDI,[EAX+4]

		MOV	[EAX],ECX
		ADD	ECX,3

		SHR	ECX,2

		REP	MOVSD
L9$:
		ADD	ESP,512

		POPM	ESI,EDI

		RET

L8$:
		XOR	EAX,EAX
		JMP	L9$

UM_STRING	ENDP


UM_ARGUMENT	PROC
		;
		;
		;
		XOR	EAX,EAX
		MOV	EDX,EBX

		MOV	AL,[EBX]	;IF NUMERIC, JUST RETURN AN ALREADY-DEFINED
		INC	EBX

		SUB	AL,30H
		MOV	ECX,UM.ARGI

		CMP	AL,10
		JAE	L2$

		CMP	AL,CL
		JAE	L8$

		MOV	EAX,UM.ARGS[EAX*4]
		JMP	STR_DUP

L8$:
		XOR	EAX,EAX		;RETURN ERROR

		RET

L2$:
		;
		;WE BE DEFINING AN ARGUMENT TO STORE AND RETURN
		;
		PUSH	ESI
		MOV	ESI,EDX

		PUSH	EDI
		DEC	EBX

		MOV	EAX,OFF EMPTY_M	;NULL STRING
		CALL	STR_DUP

		CALL	UM_DATA_TYPE

		TEST	EAX,EAX
		JZ	L7$

		MOV	ECX,UM.ARGI
		MOV	EDX,EBX

		CMP	ECX,10
		JAE	L7$

		SUB	EDX,ESI

		CMP	EDX,1
		JBE	L7$

		MOV	UM.ARGS[ECX*4],EAX
		INC	ECX

		POP	EDI
		MOV	UM.ARGI,ECX

		POP	ESI
		JMP	STR_DUP

L7$:
		POPM	EDI,ESI

		RET

UM_ARGUMENT	ENDP


UM_DATA_TYPE	PROC
		;
		;
		;
		PUSHM	EDI,ESI

		MOV	EDI,EAX
		XOR	EAX,EAX

		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,'A'
		XOR	ESI,ESI		;T=NULL

		CMP	AL,'Y'-'A'
		JA	L2$

		JMP	UDT_TABLE[EAX*4]

L2$:
		CMP	AL,'?'-'A'
		JZ	UDT_QMARK

		CMP	AL,'_'
		JZ	UDT__
L4$:
		XOR	EAX,EAX

		POPM	ESI,EDI

		RET

UDT_QMARK:
		POP	ESI
		CALL	UM_INDIRECT_TYPE

		MOV	ECX,EDI
		CALL	STR_CAT

		POP	EDI
		JMP	UM_DATA_TYPE

UDT__:
		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,'A'

		CMP	AL,'J'-'A'
		JB	L4$

		CMP	AL,'K'-'A'
		JA	L4$

		MOV	EAX,BASIC_TBL[EAX*4]
		MOV	ECX,BASIC_TBL[9*4]

		CALL	STR_CAT

		JMP	L1$


UDT_A:
UDT_B:
		PUSH	EAX
		CALL	UM_INDIRECT_TYPE

		MOV	ESI,EAX
		MOV	EAX,OFF EMPTY_M

		CALL	STR_DUP

		CALL	UM_DATA_TYPE

		MOV	ECX,ESI
		CALL	STR_CAT

		MOV	CL,'&'
		CALL	STR_CATC

		POP	ECX

		CMP	CL,'B'-'A'
		JNZ	UDT_B2

		MOV	ECX,OFF VOLATILE_M
		CALL	STR_CAT
UDT_B2:
L1$:
		MOV	ECX,EDI
		POP	ESI

		POP	EDI
		JMP	STR_CAT

UDT_C:
		MOV	EAX,BASIC_TBL[EAX*4]
		CALL	STR_DUP

		JMP	L1$

UDT_P:
		MOV	AH,[EBX]

		MOV	ESI,EAX
		CALL	UM_INDIRECT_TYPE

		MOV	ECX,ESI

		CMP	CH,'6'
		JB	UDT_P2

		CMP	CH,'9'
		JBE	UDT_P3
UDT_P2:
		MOV	CL,'*'
		CALL	STR_CATC

		MOV	ECX,ESI
UDT_P3:
		CMP	CL,'Q'-'A'
		JZ	UDT_P4

		CMP	CL,'S'-'A'
		JNZ	UDT_P5
UDT_P4:
		MOV	ECX,OFF CONST_M
		CALL	STR_CAT

		MOV	ECX,ESI
UDT_P5:
		CMP	CL,'R'-'A'
		JB	UDT_P6

		MOV	ECX,OFF VOLATILE_M
		CALL	STR_CAT
UDT_P6:
		MOV	ECX,EDI
		CALL	STR_CAT

		MOV	ECX,ESI

		POPM	ESI,EDI

		CMP	CH,'6'
		JB	UM_DATA_TYPE

		CMP	CH,'9'
		JA	UM_DATA_TYPE

		RET

UDT_W:
		INC	EBX
UDT_T:
UDT_U:
UDT_V:
		CALL	UM_SCOPE

		MOV	CL,' '
		CALL	STR_CATC

		JMP	L1$

UDT_X:
		MOV	EAX,OFF VOID_M
		CALL	STR_DUP

		JMP	L1$

UDT_Y:
		MOV	EAX,EDI
		POP	ESI

		POP	EDI
		JMP	UM_ARRAY_TYPE


		.CONST

UDT_TABLE	DD	UDT_A
		DD	UDT_B
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_C
		DD	UDT_P
		DD	UDT_P
		DD	UDT_P
		DD	UDT_P
		DD	UDT_T
		DD	UDT_U
		DD	UDT_V
		DD	UDT_W
		DD	UDT_X
		DD	UDT_Y


		.CODE	MIDDLE_TEXT

UM_DATA_TYPE	ENDP


UM_SCOPE	PROC
		;
		;
		;
		PUSH	ESI
		MOV	AL,[EBX]

		XOR	ESI,ESI
		JMP	L8$

L1$:
		TEST	ESI,ESI
		JZ	L6$

		MOV	EAX,ESI
		MOV	CL,':'

		CALL	STR_CATC

		MOV	CL,':'
		CALL	STR_CATC

		MOV	ESI,EAX
		CALL	UM_ZNAME

		TEST	EAX,EAX
		JZ	L9$

		MOV	ECX,EAX
		MOV	EAX,ESI

		CALL	STR_CAT

		MOV	ESI,EAX
		JMP	L7$

L6$:
		CALL	UM_ZNAME

		TEST	EAX,EAX
		JZ	L9$

		MOV	ESI,EAX
L7$:
		MOV	AL,[EBX]
L8$:
		CMP	AL,0
		JZ	L9$

		CMP	AL,'@'
		JNZ	L1$

		INC	EBX
		MOV	EAX,ESI

		POP	ESI

		RET


L9$:
		POP	ESI
		XOR	EAX,EAX

		RET

UM_SCOPE	ENDP


UM_ARRAY_TYPE	PROC
		;
		;
		;
		PUSHM	EBP,EDI,ESI,EAX

		MOV	EBP,ESP
		SUB	ESP,512

		MOV	EDI,ESP
		CALL	UM_DIMENSION

		XOR	ECX,ECX
		MOV	ESI,EAX

		MOV	[EDI],ECX
		ADD	EDI,4
		
		TEST	EAX,EAX
		JZ	L2$
L1$:
		MOV	BPTR [EDI],'['
		CALL	UM_DIMENSION

		LEA	ECX,[EDI+1]
		CALL	CBTA32

		LEA	EDI,[EAX+1]
		MOV	BPTR [EAX],']'

		DEC	ESI
		JNZ	L1$
L2$:
		SUB	EDI,ESP
		MOV	EAX,ESP

		SUB	EDI,4

		MOV	[ESP],EDI
		CALL	STR_DUP

		MOV	ESP,EBP
		MOV	ESI,EAX

		POP	EDX
		MOV	AL,' '

		OR	CL,1

		LEA	EDI,[EDX+4]
		MOV	ECX,[EDX]

		REPNE	SCASB

		MOV	EAX,EDX
		JNZ	L3$

		MOV	ECX,')('
		CALL	STR_BRACKET
L3$:
		CALL	UM_DATA_TYPE

		MOV	ECX,ESI
		POPM	ESI,EDI,EBP

		JMP	STR_CAT

UM_ARRAY_TYPE	ENDP


UM_INDIRECT_TYPE	PROC
		;
		;
		;
		XOR	EAX,EAX
		PUSH	ESI

		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,'0'
		JC	L9$

		CMP	AL,10
		JB	L1$

		SUB	AL,'A'-'0'
		JB	L9$

		CMP	AL,'Z'-'A'
		JA	L9$

		MOV	ESI,EAX
		JMP	L2$


L1$:
		LEA	ESI,[EAX+26]
L2$:
		CMP	ESI,'M'-'A'
		JB	L5$

		CMP	ESI,'P'-'A'
		JBE	L9$

		CMP	ESI,'6'-'0'+26
		JB	L5$

		CMP	ESI,'8'-'0'+26
		JB	L3$

		CALL	UM_SCOPE

		MOV	ECX,OFF CCA_M
		CALL	STR_CAT

		JMP	L4$

L3$:
		CMP	ESI,'6'-'0'+26
		JNZ	L31$

		MOV	EAX,OFF UM_TIMES
		CALL	STR_DUP

		JMP	L4$

L31$:
		MOV	EAX,OFF FARA_M
		CALL	STR_DUP
L4$:
		MOV	ECX,')('
		CALL	STR_BRACKET

		XOR	ECX,ECX
		CALL	UM_FUNCTION_TYPE

		JMP	L7$

L5$:
		MOV	EAX,OFF EMPTY_M
		CALL	STR_DUP

		CMP	ESI,'Q'-'A'

		JB	L55$

		CALL	UM_SCOPE

		MOV	ECX,OFF COLONCOLON_M
		CALL	STR_CAT
L55$:
		MOV	ECX,ESI

		AND	ECX,12
		PUSH	EAX

		MOV	EAX,PTR_TBL[ECX]
		CALL	STR_DUP

		MOV	ECX,EAX
		POP	EAX

		CALL	STR_CAT

		TEST	ESI,1
		JZ	L56$

		MOV	ECX,OFF CONST_M
		CALL	STR_CAT
L56$:
		TEST	ESI,2
		JZ	L57$

		MOV	ECX,OFF VOLATILE_M
		CALL	STR_CAT
L57$:

L7$:
		POP	ESI

		RET

L9$:
		POP	ESI
		XOR	EAX,EAX

		RET


UM_INDIRECT_TYPE	ENDP


UM_FUNCTION_TYPE	PROC
		;
		;
		;
		PUSHM	EDI,ESI

		PUSHM	ECX,EAX

		CALL	UM_CALLING_CONVENTION

		POP	ECX
		CALL	STR_CAT

		MOV	ESI,EAX
		MOV	EDI,EBX

		MOV	AL,[EBX]
		INC	EBX

		CMP	AL,'@'
		JZ	L1$

		DEC	EBX
		MOV	EAX,OFF EMPTY_M

		CALL	STR_DUP

		CALL	UM_DATA_TYPE
L1$:
		CALL	UM_ARGUMENT_TYPES

		MOV	ECX,EAX
		MOV	EAX,ESI

		POP	ESI
		CALL	STR_CAT

		TEST	ESI,ESI
		JZ	L2$

		MOV	ECX,ESI
		CALL	STR_CAT
L2$:
		MOV	ESI,EAX
		CALL	UM_ARGUMENT_TYPES

		MOV	EAX,ESI
		MOV	CL,[EDI]

		CMP	CL,'@'
		JZ	L4$

		PUSH	EBX
		MOV	EBX,EDI

		CALL	UM_DATA_TYPE

		POP	EBX
L4$:
		POPM	ESI,EDI

		RET


UM_FUNCTION_TYPE	ENDP


UM_CALLING_CONVENTION	PROC
		;
		;
		;
		XOR	EAX,EAX

		MOV	AL,[EBX]
		INC	EBX

		SUB	AL,'A'

		CMP	AL,'K'-'A'
		JA	L9$

		SHR	EAX,1

		MOV	EAX,CC_TBL[EAX*4]

		JNC	STR_DUP

		MOV	ECX,OFF SAVEREGS_M
		JMP	STR_CAT

L9$:
		XOR	EAX,EAX

		RET

UM_CALLING_CONVENTION	ENDP


UM_TYPE_ENCODING	PROC
		;
		;
		;
		PUSHM	EDI,ESI

		XOR	EDI,EDI
		XOR	ESI,ESI

		PUSH	EAX
		XOR	EAX,EAX
L0$:
		MOV	AL,[EBX]
		INC	EBX
L1$:
		CMP	AL,'_'
		JZ	L0$

		CMP	AL,'$'
		JZ	L0$

		SUB	AL,30H
		JB	L8$

		CMP	AL,'Z'-'0'
		JA	L8$

		JMP	UTE_TBL[EAX*4]

CASE1:
		;
		;A,B,E,F,I,J,M,N,Q,R,U,V
		;
		CALL	UM_INDIRECT_TYPE

		MOV	EDI,EAX
		JMP	L2$

CASE2:
		;
		;C,D,K,L,S,T,Y
		;
		JMP	L2$

CASE3:
		;
		;Z
		;
		MOV	EAX,OFF FAR_M
		CALL	STR_DUP

		POP	ECX
		CALL	STR_CAT

		PUSH	EAX
L2$:
		POP	EAX
		MOV	ECX,EDI

		PUSH	EAX
		CALL	UM_FUNCTION_TYPE

		MOV	ESI,EAX
		JMP	DEFAULT

CASE4:
		POP	EAX

		PUSH	EAX
		CALL	UM_DATA_TYPE

		MOV	ESI,EAX
		CALL	UM_INDIRECT_TYPE	;STORAGE CONVENTION

		MOV	ECX,ESI
		CALL	STR_CAT

		MOV	ESI,EAX
		JMP	DEFAULT

CASE5:
		CALL	UM_INDIRECT_TYPE

		POP	ECX

		PUSH	ECX
		CALL	STR_CAT

		MOV	ESI,EAX

		CALL	UM_SCOPE

;		JMP	DEFAULT


DEFAULT:
L8$:
		MOV	EAX,ESI
		POP	ECX

		POPM	ESI,EDI

		RET


		.CONST


UTE_TBL		DD	CASE4,CASE4,CASE4,CASE4		;0-3
		DD	DEFAULT,DEFAULT			;4-5
		DD	CASE5,CASE5			;6-7
		DD	DEFAULT,DEFAULT			;8-9
		DD	L8$,L8$,L8$,L8$,L8$,L8$,L8$
		DD	CASE1,CASE1,CASE2,CASE2		;ABCD
		DD	CASE1,CASE1,DEFAULT,DEFAULT	;EFGH
		DD	CASE1,CASE1,CASE2,CASE2		;IJKL
		DD	CASE1,CASE1,DEFAULT,DEFAULT	;MNOP
		DD	CASE1,CASE1,CASE2,CASE2		;QRST
		DD	CASE1,CASE1,DEFAULT,DEFAULT	;UVWX
		DD	CASE2,CASE3			;YZ

		.CODE	MIDDLE_TEXT

UM_TYPE_ENCODING	ENDP


UM_ARGUMENT_TYPES	PROC
		;
		;
		;
		MOV	CL,[EBX]
		MOV	EAX,OFF VOID_M

		CMP	CL,'X'
		JZ	L8$

		MOV	EAX,OFF DOTDOTDOT_M

		CMP	CL,'Z'
		JZ	L8$

		PUSH	ESI
		XOR	ESI,ESI
L1$:
		MOV	AL,[EBX]
		MOV	ECX,OFF COMMADDD_M

		CMP	AL,'Z'
		JZ	L4$

		CMP	AL,0
		JZ	L5$

		CMP	AL,'@'
		JZ	L6$

		TEST	ESI,ESI
		JZ	L2$

		MOV	EAX,ESI
		MOV	CL,','

		CALL	STR_CATC

		JMP	L3$

L2$:
		MOV	EAX,OFF EMPTY_M
		CALL	STR_DUP
L3$:
		MOV	ESI,EAX
		CALL	UM_ARGUMENT

		MOV	ECX,EAX
		MOV	EAX,ESI

		CALL	STR_CAT

		MOV	ESI,EAX
		JMP	L1$

L4$:
		MOV	EAX,ESI
		CALL	STR_CAT
L41$:
		POP	ESI
		INC	EBX
L9$:
		MOV	ECX,')('
		JMP	STR_BRACKET

L6$:
		MOV	EAX,ESI
		JMP	L41$

L8$:
		INC	EBX
		CALL	STR_DUP

		JMP	L9$

L5$:
		XOR	EAX,EAX
		POP	ESI

		RET

UM_ARGUMENT_TYPES	ENDP


STR_DUP		PROC
		;
		;
		;
		TEST	EAX,EAX
		JZ	L9$

		PUSHM	EDI,ESI

		MOV	ESI,EAX
		MOV	EAX,[EAX]	;LENGTH

		ADD	EAX,4
		CALL	UNMANGLE_POOL_GET

		MOV	ECX,[ESI]
		MOV	EDI,EAX

		ADD	ECX,7

		SHR	ECX,2

		REP	MOVSD

		POPM	ESI,EDI
L9$:
		RET

STR_DUP		ENDP


STR_CATC	PROC
		;
		;CL IS CHARACTER TO ADD ONTO EAX
		;
		TEST	EAX,EAX
		JZ	L9$

		MOV	EDX,[EAX]

		TEST	DL,3

		JZ	L1$

		MOV	[EAX+EDX+4],CL
		INC	EDX

		MOV	[EAX],EDX
L9$:
		RET

L1$:
		PUSHM	EDI,ESI

		PUSH	ECX
		MOV	ESI,EAX

		LEA	EAX,[EDX+5]
		CALL	UNMANGLE_POOL_GET

		MOV	ECX,[ESI]
		MOV	EDI,EAX

		ADD	ESI,4
		INC	ECX

		MOV	[EDI],ECX
		ADD	EDI,4

		SHR	ECX,2
		POP	EDX

		REP	MOVSD

		POP	ESI
		MOV	[EDI],DL

		POP	EDI

		RET

STR_CATC	ENDP


STR_BRACKET	PROC
		;
		;INSERT CL ON LEFT, CH ON RIGHT
		;
		TEST	EAX,EAX
		JZ	L9$

		PUSH	EDI
		MOV	EDX,[EAX]

		PUSH	ESI
		INC	EDX

		AND	DL,2
		JZ	L5$
		;
		;DON'T NEED ANY MEMORY
		;
		MOV	EDX,ECX
		MOV	ECX,[EAX]

		LEA	ESI,[EAX+3+ECX]
		LEA	EDI,[EAX+4+ECX]

		MOV	BPTR [EAX+5+ECX],DH

		STD

		REP	MOVSB

		CLD

		MOV	[EDI],DL
		POP	ESI

		POP	EDI
		ADD	DPTR [EAX],2
L9$:
		RET

L5$:
		MOV	ESI,EAX
		MOV	EAX,[EAX]

		PUSH	ECX
		ADD	EAX,4+2

		CALL	UNMANGLE_POOL_GET

		LEA	EDI,[EAX+5]
		MOV	ECX,[ESI]

		ADD	ECX,2
		POP	EDX

		MOV	[EDI-5],ECX
		SUB	ECX,2

		MOV	[EDI-1],DL
		ADD	ESI,4

		REP	MOVSB

		MOV	[EDI],DH
		POP	ESI

		POP	EDI

		RET

STR_BRACKET	ENDP


STR_CAT		PROC
		;
		;EAX & ECX...
		;
		TEST	EAX,EAX
		JZ	L9$

		TEST	ECX,ECX
		JZ	L91$

		PUSH	EDI
		MOV	EDX,[ECX]	;LENGTH OF SECOND STRING

		TEST	EDX,EDX
		JZ	L7$

		PUSHM	ESI,EBX

		MOV	ESI,EAX
		MOV	EAX,[EAX]	;LENGTH OF FIRST STRING

		MOV	EBX,ECX
		ADD	EAX,EDX

		ADD	EAX,4
		CALL	UNMANGLE_POOL_GET

		LEA	EDI,[EAX+4]
		MOV	ECX,[ESI]

		ADD	ESI,4
		MOV	EDX,ECX

		ADD	ECX,3

		SHR	ECX,2

		REP	MOVSD

		LEA	EDI,[EAX+4+EDX]
		MOV	ECX,[EBX]

		LEA	ESI,[EBX+4]
		ADD	EDX,ECX

		REP	MOVSB

		MOV	[EAX],EDX
		POPM	EBX,ESI
L7$:
		POP	EDI

		RET

L91$:
		XOR	EAX,EAX
L9$:
		RET

STR_CAT		ENDP


		.CONST

UM_TABLE	DD	UM_CTOR,UM_DTOR
		DD	UM_NEW,UM_DELETE
		DD	UM_SETEQUAL,UM_SHR
		DD	UM_SHL,UM_NOT
		DD	UM_EQUAL,UM_NOTEQUAL
		DD	UM_BRACKETS,UM_NOTHING
		DD	UM_RIGHT_ARROW,UM_TIMES
		DD	UM_INC,UM_DEC
		DD	UM_MINUS,UM_PLUS
		DD	UM_BAND,UM_HUH
		DD	UM_DIVIDE,UM_MOD
		DD	UM_LT,UM_LE
		DD	UM_GT,UM_GE
		DD	UM_COMMA,UM_PARENS
		DD	UM_SQUIGGLE,UM_UPARROW
		DD	UM_BOR,UM_LAND
		DD	UM_LOR,UM_TIMESEQ
		DD	UM_PLUSEQ,UM_MINUSEQ
		DD	UM_DIVEQ,UM_MODEQ
		DD	UM_SHLEQ,UM_SHREQ
		DD	UM_ANDEQ,UM_OREQ
		DD	UM_HATEQ,UM_VFTABLE
		DD	UM_VBTABLE,UM_VCALL_THUNK
		DD	UM_METACLASS,UM_GUARD
		DD	UM_LITSTRING,UM_ULTVBASEDTOR
		DD	UM_VECDELDTOR,UM_DEFCTORCLOS
		DD	UM_SCALDELDTOR,UM_VECCTOR
		DD	UM_VECDTOR,UM_VECVBASECTOR

		DD	4 DUP(UM_NOTHING)

		DD	UM_NOTHING,UM_NEWB
		DD	UM_DELETEB,UM_QR

		DD	UM_SYMC1,UM_SYMC2
		DD	UM_SYMC3,UM_SYMC4
		DD	UM_SYMC5,UM_SYMC6
		DD	UM_SYMC7,UM_SYMC8


UM_CTOR		DD	0
UM_DTOR		DD	0
UM_NEW		DD	3
		DB	'new',0
UM_DELETE	DD	6
		DB	'delete',0,0
UM_SETEQUAL	DD	1
		DB	'=',0,0,0
UM_SHR		DD	2
		DB	'>>',0,0
UM_SHL		DD	2
		DB	'<<',0,0
UM_NOT		DD	1
		DB	'!',0,0,0
UM_EQUAL	DD	2
		DB	'==',0,0
UM_NOTEQUAL	DD	2
		DB	'!=',0,0
UM_BRACKETS	DD	2
		DB	'[]',0,0
UM_NOTHING	DD	0
UM_RIGHT_ARROW	DD	2
		DB	'->',0,0
UM_TIMES	DD	1
		DB	'*',0,0,0
UM_INC		DD	2
		DB	'++',0,0
UM_DEC		DD	2
		DB	'--',0,0
UM_MINUS	DD	1
		DB	'-',0,0,0
UM_PLUS		DD	1
		DB	'+',0,0,0
UM_BAND		DD	1
		DB	'&',0,0,0
UM_HUH		DD	3
		DB	'->*',0
UM_DIVIDE	DD	1
		DB	'/',0,0,0
UM_MOD		DD	1
		DB	'%',0,0,0
UM_LT		DD	1
		DB	'<',0,0,0
UM_LE		DD	2
		DB	'<=',0,0
UM_GT		DD	1
		DB	'>',0,0,0
UM_GE		DD	2
		DB	'>=',0,0
UM_COMMA	DD	1
		DB	',',0,0,0
UM_PARENS	DD	2
		DB	'()',0,0
UM_SQUIGGLE	DD	1
		DB	'~',0,0,0
UM_UPARROW	DD	1
		DB	'^',0,0,0
UM_BOR		DD	1
		DB	'|',0,0,0
UM_LAND		DD	2
		DB	'&&',0,0
UM_LOR		DD	2
		DB	'||',0,0
UM_TIMESEQ	DD	2
		DB	'*=',0,0
UM_PLUSEQ	DD	2
		DB	'+=',0,0
UM_MINUSEQ	DD	2
		DB	'-=',0,0
UM_DIVEQ	DD	2
		DB	'/=',0,0
UM_MODEQ	DD	2
		DB	'%=',0,0
UM_SHLEQ	DD	3
		DB	'<<=',0
UM_SHREQ	DD	3
		DB	'>>=',0
UM_ANDEQ	DD	2
		DB	'&=',0,0
UM_OREQ		DD	2
		DB	'|=',0,0
UM_HATEQ	DD	2
		DB	'^=',0,0
UM_VFTABLE	DD	7
		DB	'vftable',0
UM_VBTABLE	DD	7
		DB	'vbtable',0
UM_VCALL_THUNK	DD	11
		DB	'vcall_thunk',0
UM_METACLASS	DD	9
		DB	'metaclass',0,0,0
UM_GUARD	DD	5
		DB	'guard',0,0,0
UM_LITSTRING	DD	10
		DB	'lit_string',0,0
UM_ULTVBASEDTOR	DD	14
		DB	'ult_vbase_dtor',0,0
UM_VECDELDTOR	DD	12
		DB	'vec_del_dtor'
UM_DEFCTORCLOS	DD	13
		DB	'def_ctor_clos',0,0,0
UM_SCALDELDTOR	DD	13
		DB	'scal_del_dtor',0,0,0
UM_VECCTOR	DD	8
		DB	'vec_ctor'
UM_VECDTOR	DD	8
		DB	'vec_dtor'
UM_VECVBASECTOR	DD	14
		DB	'vec_vbase_ctor',0,0
UM_NEWB		DD	5
		DB	'new[]',0,0,0
UM_DELETEB	DD	8
		DB	'delete[]'
UM_QR		DD	3
		DB	'?_R',0
UM_SYMC1	DD	4
		DB	'!<>='
UM_SYMC2	DD	2
		DB	'<>',0,0
UM_SYMC3	DD	3
		DB	'<>=',0
UM_SYMC4	DD	2
		DB	'!>',0,0
UM_SYMC5	DD	3
		DB	'!>=',0
UM_SYMC6	DD	2
		DB	'!<',0,0
UM_SYMC7	DD	3
		DB	'!<=',0
UM_SYMC8	DD	3
		DB	'!<>',0

BASIC_TBL	DD	EMPTY_M
		DD	EMPTY_M
		DD	SCHAR_M
		DD	CHAR_M
		DD	UCHAR_M
		DD	SHORT_M
		DD	USHORT_M
		DD	INT_M
		DD	U_M
		DD	LONG_M
		DD	ULONG_M
		DD	SEGM_M
		DD	FLOAT_M
		DD	DOUBLE_M
		DD	LDOUBLE_M

SCHAR_M		DD	12
		DB	'signed char '
CHAR_M		DD	5
		DB	'char ',0,0,0
UCHAR_M		DD	14
		DB	'unsigned char ',0,0
SHORT_M		DD	6
		DB	'short ',0,0
USHORT_M	DD	15
		DB	'unsigned short ',0
INT_M		DD	4
		DB	'int '
U_M		DD	9
		DB	'unsigned ',0,0,0
LONG_M		DD	5
		DB	'long ',0,0,0
ULONG_M		DD	14
		DB	'unsigned long ',0,0
SEGM_M		DD	10
		DB	'__segment ',0,0
FLOAT_M		DD	6
		DB	'float ',0,0
DOUBLE_M	DD	7
		DB	'double ',0
LDOUBLE_M	DD	12
		DB	'long double '

VOLATILE_M	DD	9
		DB	'volatile ',0,0,0

CONST_M		DD	6
		DB	'const ',0,0

VOID_M		DD	5
		DB	'void ',0,0,0

COLONCOLON_M	DD	2
		DB	'::',0,0

CCA_M		DD	3
		DB	'::*',0

FARA_M		DD	5
		DB	'far *',0,0,0

SPECIAL_CHAR	DB	",/\:. ",0AH,09H,"'-"

PTR_TBL		DD	EMPTY_M
		DD	FAR_M
		DD	HUGE_M
		DD	BASED_M

FAR_M		DD	4
		DB	'far '

HUGE_M		DD	5
		DB	'huge ',0,0,0

BASED_M		DD	6
		DB	'based ',0,0

CC_TBL		DD	CDECL_M
		DD	PASCAL_M
		DD	SYSCALL_M
		DD	STDCALL_M
		DD	FASTCALL_M
		DD	INTERRUPT_M

CDECL_M		DD	6
		DB	'cdecl ',0,0

PASCAL_M	DD	7
		DB	'pascal ',0

SYSCALL_M	DD	8
		DB	'syscall '

STDCALL_M	DD	8
		DB	'stdcall '

FASTCALL_M	DD	9
		DB	'fastcall ',0,0,0

INTERRUPT_M	DD	10
		DB	'interrupt ',0,0

SAVEREGS_M	DD	9
		DB	'saveregs ',0,0,0

COMMADDD_M	DD	4
		DB	',...'

DOTDOTDOT_M	DD	3
		DB	'...',0

SQUIGGLE_M	DD	1
		DB	'~',0,0,0

OPERATOR_M	DD	9
		DB	'operator ',0,0,0


		.DATA?

UM		UM_STRUCT<>
EMPTY_M		DD	?,?


		END

