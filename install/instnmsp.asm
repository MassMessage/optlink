		TITLE	INSTNMSP - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS

		INCLUDE	CVSTUFF

		PUBLIC	INSTALL_CV_NAMESPACE


		.DATA

		EXTERNDEF	SYMBOL_TEXT:BYTE

		EXTERNDEF	SYMBOL_LENGTH:DWORD,CNS_OFFSET:DWORD,FIRST_NAMESP_GINDEX:DWORD,LAST_NAMESP_GINDEX:DWORD

		EXTERNDEF	RELOC_GARRAY:STD_PTR_S,RELOC_STUFF:ALLOCS_STRUCT,SYMBOL_TPTR:TPTR_STRUCT

		EXTERNDEF	OPTI_MOVE:DWORD


		.CODE	PASS1_TEXT

		EXTERNDEF	COMMON_INST_INIT:PROC,RELOC_POOL_GET:PROC


CV_NAMESP_INIT	PROC	PRIVATE
		;
		;
		;
		PUSH	EAX
		MOV	EAX,OFF RELOC_STUFF

		CALL	COMMON_INST_INIT

		POP	EDX
		JMP	INIT_RET

CV_NAMESP_INIT	ENDP


INSTALL_CV_NAMESPACE	PROC
		;
		;DS:SI IS TEXT, RETURN OFFSET IN NAMESPACE
		;
		;DESTROYS ES,DS,DI,SI,DX,CX
		;
		PUSH	EDI
		MOV	EDI,OFF SYMBOL_TEXT

		PUSH	ESI
		MOV	ESI,EAX

		PUSH	EBX
		MOV	EBX,OFF SYMBOL_TPTR
		ASSUME	EBX:PTR TPTR_STRUCT
L0$:
		MOV	AL,[ESI]
		INC	ESI

		MOV	[EDI],AL
		INC	EDI

		OR	AL,AL
		JNZ	L0$

		LEA	EAX,[EBX]._TP_TEXT+1
		LEA	ESI,[EBX]._TP_LENGTH

		SUB	EDI,EAX

		MOV	[EBX]._TP_LENGTH,EDI
		MOV	EDI,ESI

		GET_NAME_HASHD
INIT_RET::

		MOV	EBX,RELOC_STUFF.ALLO_HASH_TABLE_PTR
		MOV	EAX,EDX

		TEST	EBX,EBX
		JZ	CV_NAMESP_INIT

		XOR	EDX,EDX

		HASHDIV	RELOC_STUFF.ALLO_HASH		;EDX IS HASH VALUE

		MOV	EAX,DPTR [EBX+EDX*4]
		LEA	EBX,[EBX+EDX*4 - CV_NAMESP_STRUCT._CNS_NEXT_HASH_GINDEX]
NAME_NEXT:
		TEST	EAX,EAX
		JZ	DO_INSTALL

		MOV	EDX,EAX
		MOV	ECX,SYMBOL_LENGTH

		CONVERT	EBX,EAX,RELOC_GARRAY
		ASSUME	EBX:PTR CV_NAMESP_STRUCT
		;
		;PROBABLE MATCH, NEED COMPARE...
		;
		SHR	ECX,2
		MOV	EDI,OFF SYMBOL_TEXT

		INC	ECX			;INCLUDE ZERO...
		LEA	ESI,[EBX]._CNS_TEXT

		REPE	CMPSD

		MOV	EAX,[EBX]._CNS_NEXT_HASH_GINDEX
		JNZ	NAME_NEXT

		MOV	EAX,[EBX]._CNS_OFFSET
		POPM	EBX,ESI,EDI

		RET

DO_INSTALL:
		;
		;EBX GETS POINTER...
		;
		MOV	EAX,SYMBOL_LENGTH

		ADD	EAX,SIZE CV_NAMESP_STRUCT-3		;
		CALL	RELOC_POOL_GET			;ES:DI IS PHYS, AX LOG

		MOV	ESI,EBX
		ASSUME	ESI:PTR CV_NAMESP_STRUCT
		MOV	EDI,EAX

		INSTALL_POINTER_GINDEX	RELOC_GARRAY

		MOV	[ESI]._CNS_NEXT_HASH_GINDEX,EAX
		MOV	EBX,EDI

		MOV	ESI,OFF SYMBOL_TEXT
		ASSUME	ESI:NOTHING
		MOV	EDX,LAST_NAMESP_GINDEX

		TEST	EDX,EDX
		JZ	L5$

		CONVERT	EDX,EDX,RELOC_GARRAY
		ASSUME	EDX:PTR CV_NAMESP_STRUCT

		MOV	[EDX]._CNS_NEXT_GINDEX,EAX
L6$:
		MOV	LAST_NAMESP_GINDEX,EAX

		XOR	EAX,EAX
		MOV	ECX,CV_NAMESP_STRUCT._CNS_TEXT/4

		REP	STOSD

		MOV	ECX,[ESI-4]
		MOV	EAX,CNS_OFFSET

		MOV	EDX,ECX
		MOV	[EBX]._CNS_OFFSET,EAX

		SHR	ECX,2
		INC	EDX

		INC	ECX
		ADD	EDX,EAX

		OPTI_MOVSD

		POPM	EBX,ESI,EDI
		MOV	CNS_OFFSET,EDX

		RET

L5$:
		MOV	FIRST_NAMESP_GINDEX,EAX
		JMP	L6$

INSTALL_CV_NAMESPACE	ENDP


		END

