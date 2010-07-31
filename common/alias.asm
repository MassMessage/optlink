		TITLE	ALIAS - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SYMBOLS

		PUBLIC	ALIASS


		.DATA

		EXTERNDEF	END_OF_RECORD:DWORD

		EXTERNDEF	SYMBOL_GARRAY:STD_PTR_S,SYMBOL_TPTR:TPTR_STRUCT

		EXTERNDEF	OPTI_MOVE:DWORD


		.CODE	PASS1_TEXT

		EXTERNDEF	OBJ_PHASE:PROC,FAR_INSTALL:PROC,ERR_ASCIZ_RET:PROC,ADD_TO_ALIASED_LIST:PROC
		EXTERNDEF	REMOVE_FROM_EXTERNAL_LIST:PROC,REMOVE_FROM_LIBSYM_LIST:PROC,REMOVE_FROM_WEAK_LIST:PROC
		EXTERNDEF	REMOVE_FROM_WEAK_DEFINED_LIST:PROC,REMOVE_FROM_LAZY_DEFINED_LIST:PROC,REMOVE_FROM_LAZY_LIST:PROC
		EXTERNDEF	REMOVE_FROM__IMP__LIST:PROC

		EXTERNDEF	ALIAS_IGNORED_ERR:ABS


;ALIASS_VARS	STRUC

;SYMBOL_TP_BP	TPTR_STRUCT<>
;		DB	SYMBOL_TEXT_SIZE DUP(?)

;ALIASS_VARS	ENDS


;FIX	MACRO	X

;X	EQU	[EBP].ALIASS_VARS.(X&_BP)

;	ENDM

;FIX	SYMBOL_TP


ALIASS		PROC
		;
		;DECLARE A SYMBOL AND ITS ALIAS...
		;
		;MAY BE OVERIDDEN BY PUBDEF OR WHATEVER
		;
		CMP	END_OF_RECORD,ESI
;		LEA	EAX,[ESP - SIZEOF ALIASS_VARS - 4]
		JBE	ALIAS_3
;		PUSH	EBP
;		MOV	EBP,EAX
;		MOV	ESP,EAX
L0$:
;		LEA	EDI,SYMBOL_TP
		MOV	EDI,OFF SYMBOL_TPTR
		ASSUME	EDI:PTR TPTR_STRUCT

		GET_NAME_HASH			;ALIAS_SYMBOL, PUT IN SYMBOL_TEXT

;		LEA	EAX,SYMBOL_TP
;		XOR	ECX,ECX			;NOT A LOCAL SYMBOL
		CALL	FAR_INSTALL		;GET SYMBOL GINDEX
		ASSUME	ECX:PTR SYMBOL_STRUCT

		XOR	EDX,EDX
		PUSH	EAX
		MOV	DL,[ECX]._S_NSYM_TYPE
		PUSHM	ECX,EDX
;		LEA	EDI,SYMBOL_TP
		MOV	EDI,OFF SYMBOL_TPTR
		GET_NAME_HASH			;SUBSTITUTE_SYMBOL, PUT IN SYMBOL_TEXT
;		LEA	EAX,SYMBOL_TP
;		XOR	ECX,ECX
		CALL	FAR_INSTALL		;GET SYMBOL POINTER
		POPM	EBX,ECX
		MOV	EDX,EAX
		POP	EAX
		CALL	ALIAS_TABLE[EBX*2]
ALIAS_2:
		CMP	END_OF_RECORD,ESI
		JA	L0$
;		LEA	ESP,[EBP+SIZEOF ALIASS_VARS+4]
;		MOV	EBP,[EBP+SIZEOF ALIASS_VARS]
ALIAS_3:
		JNZ	ERROR
		RET

ERROR:
		CALL	OBJ_PHASE
		RET

ALIASS		ENDP


		.CONST

		ALIGN	4

ALIAS_TABLE	DD	ALIAS_ASSIGN		;JUST ASSIGN ALIAS PLEASE
		DD	ALIAS_IGNORE		;ALREADY DEFINED - ASEG
		DD	ALIAS_IGNORE		;ALREADY DEFINED - RELOC
		DD	ALIAS_IGNORE		;ALREADY DEFINED - NEAR COMMUNAL
		DD	ALIAS_IGNORE		;ALREADY DEFINED - FAR COMMUNAL
		DD	ALIAS_IGNORE		;ALREADY DEFINED - HUGE COMMUNAL
		DD	ALIAS_IGNORE		;ALREADY DEFINED - CONST
		DD	ALIAS_ASSIGN		;IN LIB, JUST ASSIGN PLEASE
		DD	ALIAS_IGNORE		;ALREADY DEFINED - IMPORT
		DD	ALIAS_IGNORE		;PROMISED, I DON'T KNOW...
		DD	ALIAS_EXTRN		;REMOVE FROM EXTRN LIST, MAKE SURE ALIAS IS IN EXTRN LIST...
		DD	ALIAS_WEAK		;WEAK, ALIAS OVERRIDES
		DD	ALIAS_ASSIGN		;POSWEAK, ALIAS OVERRIDES
		DD	ALIAS_LIB		;REMOVE FROM LIB LIST, MAKE SURE SUBSTITUTE GOES IN CORRECT LIST
		DD	ALIAS_ASSIGN		;__imp__ UNREF, ASSIGN
		DD	ALIAS_COMPARE		;ALREADY ALIAS, COMPARE SYMBOL PLEASE...
		DD	ALIAS_IGNORE		;ALREADY DEFINED - COMDAT
		DD	ALIAS_WEAK_DEFINED	;WEAK_DEFINED, HELP...
		DD	ALIAS_ASSIGN		;WEAK-UNREF, ALIAS OVERRIDES
		DD	ALIAS_COMPARE		;ALIAS-UNREF, COMPARE
		DD	ALIAS_ASSIGN		;POS-LAZY, OVERRIDE
		DD	ALIAS_LAZY		;LAZY, OVERRIDE
		DD	ALIAS_ASSIGN		;LAZY-UNREF, OVERRIDE
		DD	ALIAS_COMPARE		;ALIAS-DEFINED, COMPARE
		DD	ALIAS_LAZY_DEFINED	;LAZY-DEFINED, OVERRIDE
		DD	ALIAS_IGNORE		;NCOMM-UNREF
		DD	ALIAS_IGNORE		;FCOMM-UNREF
		DD	ALIAS_IGNORE		;HCOMM-UNREF
		DD	ALIAS__IMP__		;__imp__, OVERIDE
		DD	ALIAS_IGNORE		;UNDECORATED, CAN'T HAPPEN

.ERRNZ		($-ALIAS_TABLE)/2 -NSYM_SIZE


		.CODE	PASS1_TEXT


ALIAS_IGNORE	PROC	NEAR
		;
		;WHO CARES...
		;
		RET

ALIAS_IGNORE	ENDP


ALIAS_WARN	PROC	NEAR
		;
		;PREVIOUSLY DEFINED, IGNORED
		;
		MOV	AL,ALIAS_IGNORED_ERR
		LEA	ECX,[ECX]._S_NAME_TEXT
		CALL	ERR_ASCIZ_RET
		RET

ALIAS_WARN	ENDP


ALIAS_COMPARE	PROC	NEAR
		;
		;PREVIOUSLY DEFINED AS AN ALIAS, DOES IT MATCH?
		;
		CMP	[ECX]._S_ALIAS_SUBSTITUTE_GINDEX,EDX
		JNZ	L5$
		RET

L5$:
		MOV	[ECX]._S_ALIAS_SUBSTITUTE_GINDEX,EDX
		CALL	ALIAS_WARN
		RET

ALIAS_COMPARE	ENDP


ALIAS_EXTRN	PROC	NEAR
		;
		;REMOVE FROM EXTERNAL_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_EXTERNAL_LIST
AE_1::
		POP	EDX
;		JMP	ALIAS_ASSIGN

ALIAS_EXTRN	ENDP


ALIAS_ASSIGN	PROC	NEAR
		;
		;JUST MARK THIS AS AN ALIAS, PLAIN AND SIMPLE
		;EAX:ECX IS SYMBOL, EDX IS SUBSTITUTE
		;
		MOV	BL,[ECX]._S_REF_FLAGS
		MOV	[ECX]._S_ALIAS_SUBSTITUTE_GINDEX,EDX
		TEST	BL,MASK S_REFERENCED
		MOV	[ECX]._S_NSYM_TYPE,NSYM_ALIASED_UNREF	;ASSUME UNREF
		JZ	L9$
		CALL	ADD_TO_ALIASED_LIST
L9$:
		RET

ALIAS_ASSIGN	ENDP


ALIAS_LIB	PROC	NEAR
		;
		;REMOVE FROM LIBSYM_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_LIBSYM_LIST
		JMP	AE_1

ALIAS_LIB	ENDP


ALIAS_WEAK	PROC	NEAR
		;
		;REMOVE FROM WEAK_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_WEAK_LIST
		JMP	AE_1

ALIAS_WEAK	ENDP


ALIAS_WEAK_DEFINED	PROC	NEAR
		;
		;REMOVE FROM WEAK_DEFINED_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_WEAK_DEFINED_LIST
		JMP	AE_1

ALIAS_WEAK_DEFINED	ENDP


ALIAS_LAZY	PROC	NEAR
		;
		;REMOVE FROM LAZY_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_LAZY_LIST
		JMP	AE_1

ALIAS_LAZY	ENDP


ALIAS__IMP__	PROC	NEAR
		;
		;REMOVE FROM __IMP__LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM__IMP__LIST
		JMP	AE_1

ALIAS__IMP__	ENDP


ALIAS_LAZY_DEFINED	PROC	NEAR
		;
		;REMOVE FROM LAZY_DEFINED_LIST, ADD TO ALIASED LIST
		;
		PUSH	EDX
		CALL	REMOVE_FROM_LAZY_DEFINED_LIST
		JMP	AE_1

ALIAS_LAZY_DEFINED	ENDP


		END

