		TITLE	MVSRCFIL - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC

		PUBLIC	MOVE_SRCPRIM_TO_EAX_CLEAN,MOVE_SRCPRIM_TO_EAX,MOVE_ECXPRIM_TO_EAX


		.DATA

		EXTERNDEF	SRCNAM:NFN_STRUCT


		.CODE	FILEPARSE_TEXT

MOVE_SRCPRIM_TO_EAX_CLEAN	LABEL	PROC

		ASSUME	EAX:PTR NFN_STRUCT

		XOR	ECX,ECX
		MOV	[EAX].NFN_PRIMLEN,ECX
		MOV	[EAX].NFN_PATHLEN,ECX
		MOV	[EAX].NFN_EXTLEN,ECX
		MOV	[EAX].NFN_TOTAL_LENGTH,ECX

MOVE_SRCPRIM_TO_EAX	PROC
		;
		;MOVE PRIMARY PART OF SRCNAM TO FILNAM
		;
		MOV	ECX,OFF SRCNAM
		ASSUME	ECX:PTR NFN_STRUCT

MOVE_ECXPRIM_TO_EAX	LABEL	PROC
		;
		;FIRST DELETE ANY EXISTING PRIMARY NAME
		;
		PUSH	EDI
		MOV	EDX,ECX
		ASSUME	ECX:NOTHING,EDX:PTR NFN_STRUCT

		MOV	ECX,[EAX].NFN_PRIMLEN
		PUSH	ESI
		OR	ECX,ECX
		LEA	ESI,[EAX].NFN_TEXT
		JZ	L1$
		ADD	ESI,[EAX].NFN_PATHLEN
		SUB	[EAX].NFN_TOTAL_LENGTH,ECX
		MOV	EDI,ESI
		ADD	ESI,ECX
		MOV	ECX,[EAX].NFN_EXTLEN
		REP	MOVSB
L1$:
		;
		;NEXT MOVE EXTENT DOWN PRIMLEN BYTES
		;
		LEA	ESI,[EAX].NFN_TEXT-1
		MOV	ECX,[EAX].NFN_EXTLEN
		ADD	ESI,[EAX].NFN_TOTAL_LENGTH
		MOV	EDI,ESI
		STD
		ADD	EDI,[EDX].NFN_PRIMLEN
		REP	MOVSB
		CLD
		INC	EDI
		;
		;NOW MOVE PRIMARY FROM SRCNAM
		;
		LEA	ESI,[EDX].NFN_TEXT
		MOV	ECX,[EDX].NFN_PRIMLEN
		ADD	ESI,[EDX].NFN_PATHLEN
		MOV	[EAX].NFN_PRIMLEN,ECX
		ADD	[EAX].NFN_TOTAL_LENGTH,ECX
		SUB	EDI,ECX
		MOV	EDX,[EAX].NFN_TOTAL_LENGTH
		REP	MOVSB
		MOV	DPTR [EDX+EAX].NFN_TEXT,ECX
		POPM	ESI,EDI
		RET

MOVE_SRCPRIM_TO_EAX	ENDP


		END

