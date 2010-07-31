		TITLE	SEARCH_ENTRY - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	SEGMSYMS

if	fg_segm

		PUBLIC	SEARCH_ENTRY


		.DATA

		EXTERNDEF	ENTRY_STUFF:ALLOCS_STRUCT

		EXTERNDEF	ENTRY_GARRAY:STD_PTR_S


		.CODE	PASS2_TEXT


SEARCH_ENTRY	PROC
		;
		;DL:AX IS ITEM TO FIND... SEGMENT:OFFSET
		;AX BECOMES ORDINAL # ELSE CARRY FLAG
		;
		MOV	CL,DL
		XOR	EDX,EDX

		PUSH	EBX
		MOV	EBX,ENTRY_STUFF.ALLO_HASH_TABLE_PTR

		MOV	DL,CL
		MOV	ECX,EAX

		HASHDIV	ENTRY_STUFF.ALLO_HASH

		MOV	EAX,DPTR [EBX+EDX*4]
NAME_NEXT:
		TEST	EAX,EAX
		JZ	L9$

		CONVERT	EAX,EAX,ENTRY_GARRAY
		ASSUME	EAX:PTR ENTRY_STRUCT,EBX:PTR ENTRY_STRUCT

		MOV	EBX,EAX
		MOV	EDX,[EBX]._ENTRY_OFFSET
		;
		;IS IT A MATCH?
		;
		MOV	EAX,[EBX]._ENTRY_NEXT_HASH_GINDEX
		CMP	EDX,ECX

		JNZ	NAME_NEXT

		MOV	EAX,[EBX]._ENTRY_ORD
		POP	EBX

		RET

L9$:
		CMP	ESP,-1
		POP	EBX

		RET

SEARCH_ENTRY	ENDP

endif

		END

