		TITLE	TERRORS - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	IO_STRUC
		INCLUDE	SYMCMACS
		INCLUDE	WIN32DEF

		.DATA

		EXTERNDEF	EOUTBUF:BYTE,TERR_FLAG:BYTE,ERROR_ASCIZ:BYTE

		EXTERNDEF	_ERR_COUNT:DWORD,ERR_NUMBER:DWORD

		EXTERNDEF	ERROR_SEM:GLOBALSEM_STRUCT,TOOL_MESSAGE:TOOL_MESSAGE_STRUCT


ERROR_DATA	SEGMENT	BYTE PUBLIC	'ERROR_DATA'

		EXTERNDEF	ERROR_ADR:BYTE

		EXTERNDEF	ERR_TABLE:DWORD

ERROR_DATA	ENDS


		.CODE	PASS2_TEXT

		EXTERNDEF	_capture_eax:proc
		EXTERNDEF	_release_eax:proc
		EXTERNDEF	_release_eax_bump:proc
		EXTERNDEF	LOUTALL_CON:PROC,_abort:proc,_cbta16:proc,CAPTURE_EAX:PROC,RELEASE_EAX:PROC,REPORT_MESSAGE:PROC

		public	_oerr_abort
_oerr_abort	proc
_oerr_abort	endp

;void _terr_abort(int EAX, unsigned char *ECX)
		public	_terr_abort
_terr_abort	proc
		mov	EAX,4[ESP]
		mov	ECX,8[ESP]
		CALL	TERR_RET
		CALL	_abort
_terr_abort	endp


TERR_RET	PROC
		;
		;ECX IS ASCIZ, EAX IS ERROR MESSAGE #
		;
		MOV	DL,-1

		XCHG	TERR_FLAG,DL

		OR	DL,DL			;SOMEONE ALREADY DOING THREAD-ERROR-ABORT
		JNZ	L9$

		AND	EAX,0FFH

		PUSH	EAX
		CAPTURE	ERROR_SEM		;NON-REENTRANT ERROR HANDLING

if	fgh_win32dll
		MOV	TOOL_MESSAGE._TMSG_FILENAME,ECX
		MOV	TOOL_MESSAGE._TMSG_MSGTYPE,EMSG_ERROR
endif
		MOV	EDI,OFF EOUTBUF
		MOV	ESI,ECX
L1$:
		LODSB
		STOSB
		OR	AL,AL
		JNZ	L1$

		DEC	EDI

		MOV	AX,': '

		STOSW
		STOSB

		INC	_ERR_COUNT

		MOV	ESI,OFF ERROR_ADR
		POP	ECX

		MOVSD
		MOVSW
		MOVSB

		MOV	EAX,ECX
		PUSH	ECX

		MOV	ERR_NUMBER,EAX
		MOV	ECX,EDI

		push	ECX
		push	EAX
		call	_cbta16
		add	ESP,8

		MOV	EDI,EAX
		POP	ESI
		MOV	AX,' :'
		STOSW
		MOV	ESI,ERR_TABLE[ESI*4]
if	fgh_win32dll
		MOV	TOOL_MESSAGE._TMSG_MSGTEXT,EDI
endif

		LODSB
		XCHG	AX,CX
		AND	ECX,07FH

		REP	MOVSB
		MOV	AL,' '
		STOSB
;		POP	EAX
;		CALL	CBTA16
		MOV	AX,0A0DH
		STOSW
		MOV	ECX,EDI
		MOV	EAX,OFF EOUTBUF
		SUB	ECX,EAX
		CALL	LOUTALL_CON

if	fgh_win32dll
		MOV	EAX,OFF TOOL_MESSAGE
		MOV	ECX,ERR_NUMBER
		ASSUME	EAX:PTR TOOL_MESSAGE_STRUCT

		MOV	BPTR [EDI-2],0

		MOV	[EAX]._TMSG_LINENUMBER,K_NOLINENUMBER

		MOV	[EAX]._TMSG_COLNUMBER,K_NOCOLNUMBER

		MOV	[EAX]._TMSG_MSGNUMBER,CX
		CALL	REPORT_MESSAGE
		ASSUME	EAX:NOTHING
endif
		RELEASE	ERROR_SEM

		RET

L9$:
		PUSH	0
		CALL	ExitThread		;JUST GO AWAY...

TERR_RET	ENDP


		.DATA?

TERR_FLAG	DB	?


		END

