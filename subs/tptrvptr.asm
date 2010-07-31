		TITLE	TPTRVPTR

		INCLUDE	MACROS

		PUBLIC	MAKE_TPTR_LINDEX


		.DATA

		EXTERNDEF	SYM_HASH_MOD:DWORD

		EXTERNDEF	LNAME_LARRAY:LARRAY_STRUCT


		.CODE	ROOT_TEXT

		EXTERNDEF	ALLOC_LOCAL:PROC


MAKE_TPTR_LINDEX	PROC
		;
		;CONVERT EAX TO LINDEX
		;
		PUSH	ESI
		MOV	ESI,EAX
		ASSUME	ESI:PTR TPTR_STRUCT

		MOV	EAX,[EAX].TPTR_STRUCT._TP_LENGTH
		PUSH	EDI

		ADD	EAX,SIZE TPTR_STRUCT+SIZE PRETEXT_PTR_STRUCT-3	;
		CALL	ALLOC_LOCAL		;ES:DI IS PHYS, AX LOG

		LEA	EDX,[EAX+4]
		LEA	EAX,[EAX+4]

		INSTALL_POINTER_LINDEX	LNAME_LARRAY

		XOR	ECX,ECX			;PTR TO MYCOMDAT STRUCTURE
		MOV	EAX,SYM_HASH_MOD	;MODULE # IF LOCAL

		MOV	[EDX-4],ECX
		MOV	ECX,[ESI]._TP_LENGTH
		ASSUME	EDX:PTR TPTR_STRUCT

		MOV	[EDX]._TP_FLAGS,EAX
		MOV	[EDX]._TP_LENGTH,ECX

		SHR	ECX,2
		MOV	EAX,[ESI]._TP_HASH

		INC	ECX
		MOV	[EDX]._TP_HASH,EAX

		LEA	ESI,[ESI]._TP_TEXT
		LEA	EDI,[EDX]._TP_TEXT

		OPTI_MOVSD

		POPM	EDI,ESI

		MOV	EAX,LNAME_LARRAY._LARRAY_LIMIT

		RET

MAKE_TPTR_LINDEX	ENDP


		END

