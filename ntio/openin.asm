		TITLE	OPEN_INPUT - Copyright (C) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC
		INCLUDE	WIN32DEF
		INCLUDE	WINMACS

		PUBLIC	OPEN_INPUT


		.DATA

		EXTERNDEF	SHARE_ANDER:BYTE,ASCIZ:BYTE

		EXTERNDEF	NUMBLKS:DWORD,CURN_FILE_LIST_GINDEX:DWORD

		EXTERNDEF	MYI_STUFF:MYI_STRUCT


		.CODE	PHASE1_TEXT

		EXTERNDEF	_read_16k_input:proc
		EXTERNDEF	_close_handle:proc,MOVE_FN_TO_ASCIZ:PROC,_recover_handle:PROC,_dosread:proc
		EXTERNDEF	GET_NEW_IO_LOG_BLK:PROC,REPORT_ASCIZ:PROC,REPORT_PROGRESS:PROC


OPEN_INPUT	PROC
		;
		;OPEN FILE NFN IN EAX
		;
		;RETURN EAX IS 'DEVICE'
		;
		PUSHM	ESI,EBX

		MOV	EBX,OFF MYI_STUFF		;ONLY ONE FOR DOS...
		ASSUME	EBX:PTR MYI_STRUCT
		MOV	ESI,EAX
		ASSUME	ESI:PTR NFN_STRUCT

		XOR	EDX,EDX
		MOV	ECX,CURN_FILE_LIST_GINDEX

		MOV	EAX,[EBX].MYI_HANDLE
		MOV	[EBX].MYI_HANDLE,EDX

		TEST	EAX,EAX
		JZ	L1$

		PUSH	ECX

		push	EAX
		call	_close_handle
		add	ESP,4

		POP	ECX
L1$:
		MOV	[EBX].MYI_FILE_LIST_GINDEX,ECX
		;
		;EAX IS NFN STRUCTURE
		;
;		CALL	MOVE_FN_TO_ASCIZ
L15$:
		MOV	ECX,[EBX].MYI_FILE_LIST_GINDEX
		MOV	EAX,FILE_FLAG_SEQUENTIAL_SCAN

		TEST	ECX,ECX
		JZ	L16$

		CONVERT	ECX,ECX,_FILE_LIST_GARRAY

		MOV	DL,[ECX].FILE_LIST_STRUCT.FILE_LIST_FLAGS

		AND	DL,MASK FLF_RANDOM
		JZ	L16$

		MOV	EAX,FILE_FLAG_RANDOM_ACCESS

L16$:
		PUSH	0			;TEMPLATE FILE
		PUSH	EAX			;ATTRIBS&FLAGS

		PUSH	OPEN_EXISTING		;FILE MUST ALREADY EXIST
		PUSH	0			;SECURITY DESCRIPTOR

		PUSH	FILE_SHARE_READ		;OTHERS MAY READ THIS
		PUSH	GENERIC_READ		;I WILL ONLY READ THIS

		LEA	EDX,[ESI].NFN_TEXT

		PUSH	EDX

;		ASCIZMSG	'Calling CreateFileA',EDX

		CALL	CreateFile

		LEA	EDX,[ESI].NFN_TEXT
;		ASCIZMSG	'Survived CreateFileA',EDX

		CMP	EAX,INVALID_HANDLE_VALUE
		JZ	L5$

		MOV	[EBX].MYI_HANDLE,EAX
if	fgh_win32dll
		LEA	EAX,[ESI].NFN_TEXT
		CALL	REPORT_ASCIZ		;REPORT THE FILENAME IN ASCIZ

		YIELD
endif
		;
		;DO WE NEED TO GET FILE T&D?
		;
		TEST	[ESI].NFN_FLAGS,MASK NFN_TIME_VALID
		JNZ	L2$

		MOV	EAX,[EBX].MYI_HANDLE
		PUSH	0

		PUSH	EAX
		CALL	GetFileSize

		OR	[ESI].NFN_FLAGS,MASK NFN_TIME_VALID
		MOV	[ESI].NFN_FILE_LENGTH,EAX
L2$:
		XOR	EAX,EAX
		MOV	ECX,[ESI].NFN_FILE_LENGTH

		MOV	[EBX].MYI_BYTE_OFFSET,EAX
		MOV	[EBX].MYI_FILE_LENGTH,ECX

		MOV	ECX,OFF _read_16k_input
		MOV	[EBX].MYI_PHYS_ADDR,EAX

		MOV	[EBX].MYI_COUNT,EAX	;BUFFER EMPTY
		MOV	EAX,EBX

		MOV	[EBX].MYI_FILLBUF,ECX

		POPM	EBX,ESI

		RET

L5$:
		CALL	_recover_handle
		TEST	EAX,EAX
		JZ	L15$

		MOV	EAX,EBX
		CMP	ESP,-1

		POPM	EBX,ESI

		RET

OPEN_INPUT	ENDP




		END

