		TITLE	MYCOMDAT_INSTALL - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	CDDATA

		PUBLIC	MYCOMDAT_INSTALL,MYCOMDAT_SEARCH

;
;		INSTALL OR FIND A MYCOMDAT RECORD USING LNAME IN AX
;


		.DATA

		EXTERNDEF	LAST_MYCOMDAT_LINDEX:DWORD,VIRDEF_MCD_HASH_TABLE_PTR:DWORD,VIRDEF_MCD_HASH:DWORD

		EXTERNDEF	LNAME_LARRAY:LARRAY_STRUCT,SYMBOL_LARRAY:LARRAY_STRUCT


		.CODE	PASS1_TEXT

		EXTERNDEF	ALLOC_LOCAL:PROC


MYCOMDAT_INSTALL	PROC
		;
		;EAX IS ITEM TO STORE... SEGMENT:OFFSET
		;
		;RETURN EAX IS LINDEX, ECX IS PHYSICAL
		;
		CALL	MYCOMDAT_SEARCH

		JC	L1$

		CMP	ESP,-1

		RET

L1$:
		CMP	EAX,16K
		JA	L5$				;VIRDEF SPECIAL...
		;
		;NEED TO ALLOCATE A MCD STRUCTURE
		;
		;EAX IS LNAME INDEX
		;ECX IS LNAME_PPTR
		;
		;
		PUSH	EDI
		MOV	EDX,EAX

		MOV	EAX,SIZEOF MYCOMDAT_STRUCT
		CALL	ALLOC_LOCAL

		PUSH	EBX
		MOV	DPTR [ECX+_PTP_MCD],EAX

		MOV	EBX,EAX
		MOV	EDI,EAX
		ASSUME	EBX:PTR MYCOMDAT_STRUCT

		MOV	ECX,SIZEOF MYCOMDAT_STRUCT/4
		XOR	EAX,EAX

		REP	STOSD				;ZERO OUT RECORD

		MOV	[EBX]._MCD_LNAME_LINDEX,EDX
		MOV	EAX,LAST_MYCOMDAT_LINDEX

		MOV	LAST_MYCOMDAT_LINDEX,EDX
		MOV	[EBX]._MCD_NEXT_MCD_LINDEX,EAX

		MOV	EAX,EDX
		MOV	ECX,EBX

		POPM	EBX,EDI

		RET

L5$:
		;
		;NEED TO ALLOCATE A MCD STRUCTURE
		;
		;EAX IS EXTDEF INDEX + 4000H
		;ECX GETS POINTER
		;
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		PUSH	EDI
		MOV	EDX,EAX			;SAVE EXTDEF_LINDEX

		MOV	EAX,SIZE MYCOMDAT_STRUCT
		CALL	ALLOC_LOCAL

		PUSH	EBX
		MOV	[ECX]._MCD_NEXT_HASH_PTR,EAX

		MOV	EBX,EAX
		MOV	EDI,EAX

		MOV	ECX,SIZE MYCOMDAT_STRUCT/4
		XOR	EAX,EAX

		REP	STOSD

		MOV	EAX,EDX
		MOV	[EBX]._MCD_LNAME_LINDEX,EDX

		SUB	EAX,16K
		CONVERT_LINDEX_EAX_EAX	SYMBOL_LARRAY,EDI

		MOV	[EBX]._MCD_SYMBOL_GINDEX,EAX
		MOV	EAX,LAST_MYCOMDAT_LINDEX

		MOV	LAST_MYCOMDAT_LINDEX,EDX
		MOV	[EBX]._MCD_NEXT_MCD_LINDEX,EAX

		MOV	EAX,EDX
		MOV	ECX,EBX

		POPM	EBX,EDI

		OR	EDX,EDX			;CLEAR CARRY

		RET

MYCOMDAT_INSTALL	ENDP


MYCOMDAT_SEARCH	PROC
		;
		;EAX IS ITEM TO FIND... SEGMENT:OFFSET
		;
		;RETURN EAX IS LINDEX, ECX IS PHYSICAL,
		;OR, ECX IS PLACE TO STORE...
		;
		CMP	EAX,16K
		JA	L5$				;VIRDEF SPECIAL...

		MOV	EDX,EAX
		CONVERT_LINDEX_EAX_EAX	LNAME_LARRAY,ECX

		MOV	ECX,EAX
		MOV	EAX,DPTR [EAX+_PTP_MCD]

		OR	EAX,EAX
		JZ	L2$

		MOV	ECX,EAX
		MOV	EAX,EDX

		RET

L2$:
		MOV	EAX,EDX
		CMP	ESP,-1

		RET

L5$:
		;
		;SPECIAL VIRDEF REFERENCE
		;
		PUSH	EBX
		MOV	EBX,EAX

		SUB	EAX,16K
		XOR	EDX,EDX

		MOV	ECX,VIRDEF_MCD_HASH_TABLE_PTR

		HASHDIV	VIRDEF_MCD_HASH

		MOV	EAX,DPTR [ECX+EDX*4]
		LEA	ECX,[ECX+EDX*4 - MYCOMDAT_STRUCT._MCD_NEXT_HASH_PTR]
MCD_NEXT:
		ASSUME	EAX:PTR MYCOMDAT_STRUCT

		TEST	EAX,EAX
		JZ	DO_SEARCH_FAIL

		MOV	ECX,EAX
		MOV	EDX,[EAX]._MCD_LNAME_LINDEX

		CMP	EDX,EBX
		MOV	EAX,[EAX]._MCD_NEXT_HASH_PTR

		JNZ	MCD_NEXT

		MOV	EAX,EBX
		POP	EBX

		RET

DO_SEARCH_FAIL:
		CMP	ESP,-1
		MOV	EAX,EBX

		POP	EBX

		RET

MYCOMDAT_SEARCH	ENDP


		END
