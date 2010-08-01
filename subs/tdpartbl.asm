		TITLE	TDPARTBL - Copyright (c) SLR Systems 1993

		INCLUDE	MACROS
		INCLUDE	TDBG

		PUBLIC	PAR_POWER_DSSI,PAR_POWER_ESDI,PAR_ODD_DSSI,PAR_ODD_ESDI

		.DATA

		.CODE

	SOFT	EXTP	GET_NEW_LOG_BLK

		ASSUME	DS:NOTHING

PAR_POWER_DSSI	PROC
		;
		;CHANGE GINDEX INTO ADDRESS OF PARALLEL TABLE
		;
		MOV	ESI,EAX
		AND	EAX,0FFFFFFFFH SHR (32-NBITS)

		SHR	ESI,32-NBITS

		SHL	EAX,NBITS

		MOV	ESI,


		PUSHM	BX,CX

		MOV	CX,DGROUP:[SI]._PAR_SHIFTS
		MOV	BX,AX

		SHR	AX,CL			;AX IS BLK #

		AND	BX,DGROUP:[SI]._PAR_MASK;BX IS ITEM # IN BLOCK
		LDS	SI,DGROUP:[SI]._PAR_PTRS_PTR
		ADD	AX,AX
		MOV	CL,CH
		ADD	SI,AX
		SHL	BX,CL
		MOV	AX,[SI]
		POP	CX
		OR	AX,AX
		JZ	5$
4$:
		MOV	SI,BX
		POP	BX
		MOV	DS,AX
		SYM_CONV_DS
		RET


5$:
		CALL	GET_NEW_LOG_BLK
		MOV	[SI],AX
		PUSHM	ES,DI,CX,AX
		MOV	ES,AX
		CONV_ES
		XOR	DI,DI
		MOV	CX,PAGE_SIZE/2
		XOR	AX,AX
		REP	STOSW
		POPM	AX,CX,DI,ES
		JMP	4$

PAR_POWER_DSSI	ENDP


		ASSUME	DS:NOTHING

PAR_ODD_DSSI	PROC
		;
		;CHANGE GINDEX INTO ADDRESS OF PARALLEL TABLE
		;
		PUSH	DX
		XOR	DX,DX
		DIV	DGROUP:[SI]._PAR_SHIFTS	;# OF ITEMS PER BLOCK, YIELDS AX == BLK #, DX == ENTRY IN BLOCK...
		PUSH	AX
		MOV	AX,DX
		MUL	DGROUP:[SI]._PAR_MASK
		POP	DX			;NOW DX IS BLK #, AX IS OFFSET IN BLOCK

		LDS	SI,DGROUP:[SI]._PAR_PTRS_PTR
		ADD	DX,DX
		ADD	SI,DX
		MOV	DX,AX

		MOV	AX,[SI]
		OR	AX,AX
		JZ	5$
4$:
		MOV	SI,DX
		POP	DX
		MOV	DS,AX
		SYM_CONV_DS
		RET


5$:
		CALL	GET_NEW_LOG_BLK
		MOV	[SI],AX
		PUSHM	ES,DI,CX,AX
		MOV	ES,AX
		CONV_ES
		XOR	DI,DI
		MOV	CX,PAGE_SIZE/2
		XOR	AX,AX
		REP	STOSW
		POPM	AX,CX,DI,ES
		JMP	4$

PAR_ODD_DSSI	ENDP


		ASSUME	DS:NOTHING

PAR_POWER_ESDI	PROC
		;
		;CHANGE GINDEX INTO ADDRESS OF PARALLEL TABLE
		;
		PUSHM	BX,CX
		MOV	CX,DGROUP:[DI]._PAR_SHIFTS
		MOV	BX,AX
		SHR	AX,CL			;AX IS BLK #
		AND	BX,DGROUP:[DI]._PAR_MASK;BX IS ITEM # IN BLOCK
		LES	DI,DGROUP:[DI]._PAR_PTRS_PTR
		ADD	AX,AX
		MOV	CL,CH
		ADD	DI,AX
		SHL	BX,CL
		MOV	AX,ES:[DI]
		POP	CX
		OR	AX,AX
		JZ	5$
4$:
		MOV	DI,BX
		POP	BX
		MOV	ES,AX
		SYM_CONV_ES
		RET


5$:
		CALL	GET_NEW_LOG_BLK
		PUSHM	CX,AX
		MOV	ES:[DI],AX
		MOV	ES,AX
		SYM_CONV_ES
		XOR	DI,DI
		MOV	CX,PAGE_SIZE/2
		XOR	AX,AX
		REP	STOSW
		POPM	AX,CX
		JMP	4$

PAR_POWER_ESDI	ENDP


		ASSUME	DS:NOTHING

PAR_ODD_ESDI	PROC
		;
		;CHANGE GINDEX INTO ADDRESS OF PARALLEL TABLE
		;
		PUSH	DX
		XOR	DX,DX
		DIV	DGROUP:[DI]._PAR_SHIFTS	;# OF ITEMS PER BLOCK, YIELDS AX == BLK #, DX == ENTRY IN BLOCK...
		PUSH	AX
		MOV	AX,DX
		MUL	DGROUP:[DI]._PAR_MASK
		POP	DX			;NOW DX IS BLK #, AX IS OFFSET IN BLOCK

		LES	DI,DGROUP:[DI]._PAR_PTRS_PTR
		ADD	DX,DX
		ADD	DI,DX
		MOV	DX,AX

		MOV	AX,ES:[DI]
		OR	AX,AX
		JZ	5$
4$:
		MOV	DI,DX
		POP	DX
		MOV	ES,AX
		SYM_CONV_ES
		RET


5$:
		CALL	GET_NEW_LOG_BLK
		PUSHM	CX,AX
		MOV	ES:[DI],AX
		MOV	ES,AX
		CONV_ES
		XOR	DI,DI
		MOV	CX,PAGE_SIZE/2
		XOR	AX,AX
		REP	STOSW
		POPM	AX,CX
		JMP	4$

PAR_ODD_ESDI	ENDP


IF 0
INSTALL_RANDOM_POINTER	PROC
		;
		;AX:BX IS POINTER
		;CX IS INDEX #
		;SI IS PAR_STRUCT
		;
		PUSHM	DS,CX
		XCHG	AX,CX
		CMP	DGROUP:[SI]._PAR_LIMIT,AX
		JA	1$
		MOV	DGROUP:[SI]._PAR_LIMIT,AX
1$:
		CALL	PAR_POWER_DSSI

		MOV	AX,CX
		POP	CX
		MOV	[SI].OFFS,BX
		MOV	[SI].SEGM,AX
		POP	DS
		RET

INSTALL_RANDOM_POINTER	ENDP
ENDIF

		END
