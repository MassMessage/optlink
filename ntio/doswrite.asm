		TITLE	DO_DOSWRITE - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	IO_STRUC
		INCLUDE	WIN32DEF
		INCLUDE	WINMACS



		.CODE	PASS2_TEXT

		externdef	_close_handle:proc,_doswrite:proc,_release_io_segment:proc
		externdef	_dos_fail_move:proc
		externdef	_dos_fail_seteof:proc


;		PUBLIC	DO_DOSWRITE_CLEAR
;DO_DOSWRITE_CLEAR	LABEL	PROC
;		;
;		;EAX IS DEVICE
;		;
;		;WRITE BLOCK, EDX	ECX=# OF BYTES
;		;
;		ASSUME	EAX:PTR MYO_STRUCT
;		OR	[EAX].MYO_SPEC_FLAGS,MASK F_CLEAR_BLOCK
;		JMP	_do_doswrite2

; MYO_STRUCT *_do_doswrite(MYO_STRUCT *EAX, unsigned ECX)
		public	_do_doswrite
_do_doswrite	label	proc
		mov	EAX,4[ESP]
		mov	ECX,8[ESP]
		ASSUME	EAX:PTR MYO_STRUCT
		mov	EDX,[EAX].MYO_BLOCK
		jmp	_do_doswrite2

		public	_do_doswrite_release
_do_doswrite_release	LABEL	PROC

		mov	EAX,4[ESP]
		mov	ECX,8[ESP]
		mov	EDX,12[ESP]
		OR	[EAX].MYO_SPEC_FLAGS,MASK F_RELEASE_BLOCK
		jmp	_do_doswrite2


		public	_do_doswrite2
_do_doswrite2	PROC
		;
		;F_SEEK_FIRST	;DO DOSPOSITION PLEASE
		;CX <>0 	;WRITE STUFF
		;F_TRUNC_FILE	;TRUNCATE FILE AT THIS POINT
		;F_CLEAR_BLOCK	;CLEAR BLOCK USED
		;F_RELEASE_BLOCK;RELEASE BLOCK USED
		;F_SET_TIME	;SET FILE TIME-DATE STAMP
		;F_CLOSE_FILE	;CLOSE FILE NOW
		;
;		ALLMSG	'DO_DOSWRITE'

		PUSH	ESI
		MOV	ESI,EAX
		ASSUME	ESI:PTR MYO_STRUCT

		TEST	ECX,ECX
		JZ	L0$

		MOV	[ESI].MYO_BLOCK,EDX
L0$:
		PUSH	EBX

		MOV	DL,[ESI].MYO_SPEC_FLAGS
		MOV	[ESI].MYO_BYTES,ECX	;# OF BYTES BEING WRITTEN

		AND	DL,MASK F_SEEK_FIRST
		JZ	L1$
		;
		;FIRST, SEEK TO CORRECT LOCATION IN FILE
		;
		MOV	ECX,[ESI].MYO_DESPOT
		MOV	EAX,[ESI].MYO_PHYS_ADDR

		CMP	ECX,EAX
		JZ	SKIP_POSIT

		MOV	EAX,[ESI].MYO_HANDLE
		PUSH	FILE_BEGIN	;DISTANCE FROM BEGINNING OF FILE

		MOV	[ESI].MYO_PHYS_ADDR,ECX
		PUSH	0		;DISTANCE TO MOVE HIGH

		PUSH	ECX		;DISTANCE TO MOVE
		PUSH	EAX		;HANDLE

		CALL	SetFilePointer

		INC	EAX
		MOV	EAX,ESI

		JZ	DOS_FAIL_MOVE
SKIP_POSIT:

L1$:
		MOV	ECX,[ESI].MYO_BYTES
		MOV	EDX,[ESI].MYO_BLOCK

		TEST	ECX,ECX
		JZ	L2$

		MOV	EAX,ESI

		push	EDX
		push	ECX
		push	EAX
		call	_doswrite
		add	ESP,12
L2$:
		MOV	DL,[ESI].MYO_SPEC_FLAGS
		MOV	EAX,ESI

		AND	DL,MASK F_TRUNC_FILE
		JZ	L3$

		MOV	EAX,[ESI].MYO_HANDLE

		PUSH	EAX
		CALL	SetEndOfFile

		TEST	EAX,EAX
		MOV	EAX,ESI

		JZ	DOS_FAIL_SETEOF
L3$:
		MOV	DL,[ESI].MYO_SPEC_FLAGS
		XOR	ECX,ECX

		AND	DL,MASK F_CLEAR_BLOCK +MASK F_RELEASE_BLOCK
		JZ	L4$

		MOV	EAX,[ESI].MYO_BLOCK
		MOV	[ESI].MYO_BLOCK,ECX

		AND	DL,MASK F_RELEASE_BLOCK
		JZ	L4$

		OR	EAX,EAX
		JZ	L4$

		push	EAX
		call	_release_io_segment
		add	ESP,4
L4$:
;		MOV	DL,[ESI].MYO_SPEC_FLAGS

;		AND	DL,MASK F_SET_TIME
;		JZ	L5$
		;
		;SET T&D STAMP ON FILE
		;
;		MOV	CX,[ESI].MYO_TIME
;		MOV	EBX,[ESI].MYO_HANDLE

;		MOV	DX,[ESI].MYO_DATE
;		MOV	EAX,5701H

;		DOS
;L5$:
		MOV	DL,[ESI].MYO_SPEC_FLAGS
		XOR	ECX,ECX

		AND	DL,MASK F_CLOSE_FILE	;EOF?
		JZ	L6$

		MOV	EAX,[ESI].MYO_HANDLE
		MOV	[ESI].MYO_BUSY,ECX

		TEST	EAX,EAX
		JZ	L6$

		MOV	[ESI].MYO_HANDLE,ECX

		push	EAX
		call	_close_handle
		add	ESP,4
L6$:
		XOR	ECX,ECX
		POP	EBX

		MOV	[ESI].MYO_SPEC_FLAGS,CL
		MOV	EAX,ESI

		POP	ESI

		RET

DOS_FAIL_MOVE:
		push	EAX
		call	_dos_fail_move

DOS_FAIL_SETEOF:
		push	EAX
		call	_dos_fail_seteof

_do_doswrite2	ENDP


		END

