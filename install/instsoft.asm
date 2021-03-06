		TITLE	INSTSOFT - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	CDDATA

		PUBLIC	INSTALL_SOFT_REF

;
;		DS:SI (CX) IS SYMBOL TO BE ADDED TO LIST OF COMDAT SOFT REFERENCES
;

		.DATA

		EXTERNDEF	MYCOMDAT_LINDEX:DWORD


		.CODE	PASS1_TEXT

		EXTERNDEF	ALLOC_LOCAL:PROC


INSTALL_SOFT_REF	PROC
		;
		;EAX IS SYMBOL_GINDEX TO ADD TO LIST OF SYMBOLS REFERENCED BY THIS COMDAT...
		;
		PUSH	EDI
		MOV	EDI,EAX

		MOV	EAX,MYCOMDAT_LINDEX		;LATEST COMDAT REFERENCED
		CONVERT_MYCOMDAT_EAX_ECX

		PUSH	EBX
		MOV	EBX,ECX

		MOV	EDX,EDI
		LEA	EDI,[ECX].MYCOMDAT_STRUCT._MCD_FIRST_SOFT_BLOCK

		XOR	ECX,ECX
L1$:
		MOV	EAX,[EDI]

		TEST	EAX,EAX				;NEXT BLOCK EXISTS?
		JZ	L8$				;NOPE, GO CREATE IT

		LEA	EDI,[EAX+4]
		MOV	ECX,[EAX]			;SCAN FOR MATCHING SYMBOL

		MOV	EAX,EDX
		MOV	EBX,ECX

		REPNE	SCASD

		JZ	L9$				;JUMP IF MATCH

		CMP	EBX,SOFT_PER_BLK
		JZ	L1$
		;
		;ROOM FOR ANOTHER, STORE IT
		;
		LEA	ECX,[EBX*4]
		INC	EBX

		NEG	ECX

		MOV	[EDI],EAX

		MOV	[EDI+ECX-4],EBX
L9$:
		POPM	EBX,EDI

		RET


L8$:
		;
		;CREATE NEW BLOCK, ES:DI GETS POINTER, DX
		;
		MOV	EAX,SOFT_PER_BLK*4+8
		CALL	ALLOC_LOCAL

		MOV	[EDI],EAX
		LEA	EDI,[EAX+8]

		MOV	DPTR [EAX],1
		MOV	DPTR [EAX+4],EDX

		XOR	EAX,EAX
		MOV	ECX,(SOFT_PER_BLK*4+8-8)/4

		REP	STOSD

		POPM	EBX,EDI

		RET

INSTALL_SOFT_REF	ENDP


		END

