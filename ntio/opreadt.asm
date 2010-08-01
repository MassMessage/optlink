		TITLE OPREADT - Copyright (c) 1994 by SLR Systems

		INCLUDE	MACROS

if	fgh_inthreads

		INCLUDE	IO_STRUC
		INCLUDE	EXES
		INCLUDE	WIN32DEF

		PUBLIC	OPREADT

;
;	STANDARD OBJ'S SCAN OBJ PATHLIST IF NOT FOUND		8-17-89
;	LIBOPENT MUST HANDLE 'STUB' AND 'OLD'
;
;		1: WAIT TILL ALL OPEN & READ THREADS HAVE FINISHED, FLAG FACT
;		2: CLEAR LIBS_DONE FLAG
;		3: FIND, OPEN, START A READ THREAD ON 'STUB'
;		4: FIND, OPEN, START A READ THREAD ON 'OLD'
;		5: WHEN SIGNALLED, GO THROUGH LIBS_DONE PROCESS AGAIN...
;


		.DATA

		EXTERNDEF	NUM_HANDLES:DWORD,NONRES_LENGTH:DWORD,RES_LENGTH:DWORD

		EXTERNDEF	_NONRES_LENGTH_SEM:GLOBALSEM_STRUCT,HANDLE_CHECK_SEM:GLOBALSEM_STRUCT,OBJPATH_LIST:FILE_LISTS
		EXTERNDEF	STUBPATH_LIST:FILE_LISTS,LIBPATH_LIST:FILE_LISTS,_FILE_LIST_GARRAY:STD_PTR_S
		EXTERNDEF	TCONVERT_SEM:GLOBALSEM_STRUCT


		.CODE	PASS1_TEXT

		EXTERNDEF	_read_old_proc:proc
		EXTERNDEF	_read_40H:proc
		EXTERNDEF	_position:proc
		EXTERNDEF	_get_next_open_struc:proc
		EXTERNDEF	_get_next_file_name:proc
		EXTERNDEF	_open_file:proc
		EXTERNDEF	_try_search:proc
		EXTERNDEF	_try_open:proc
		EXTERNDEF	_get_next_buffer:proc
		EXTERNDEF	_read_next_block:proc
		EXTERNDEF	_read_first_block:proc
		EXTERNDEF	_read_block:proc
		EXTERNDEF	_read_16:proc
		EXTERNDEF	_readt_abort:proc
		EXTERNDEF	_capture_eax:proc
		EXTERNDEF	_release_eax:proc
		EXTERNDEF	_release_eax_bump:proc
		EXTERNDEF	CAPTURE_EAX:PROC,RELEASE_EAX:PROC,_release_block:PROC,TERR_ABORT:PROC,_get_new_phys_blk:proc
		EXTERNDEF	_move_ecxpath_eax:proc,_oerr_abort:proc,_close_handle:proc,XCNOTIFY:PROC

		EXTERNDEF	FILE_NOT_FOUND_ERR:ABS,QFH_FAILED_ERR:ABS,CLOSE_ERR:ABS,DOS_POS_ERR:ABS,UNEXP_EOF_ERR:ABS
		EXTERNDEF	DOS_READ_ERR:ABS


OPREADT		PROC
		;
		;FILE OPENNER - READER... THIS GUYS SOLE FUNCTION IN LIFE IS
		;TO OPEN AND READ FILES...
		;
		;MAKE THIS SLIGHTLY HIGHER PRIORITY THAN MAIN
		;
		MOV	EBX,[ESP+4]

		PUSHM	-1,0
		PUSH	OFF XCNOTIFY
		ASSUME	FS:NOTHING

		PUSH	DWORD PTR FS:[0]
		MOV	FS:[0],ESP

		PUSH	THREAD_PRIORITY_ABOVE_NORMAL	;WAS NORMAL
		ASSUME	EBX:PTR MYI2_STRUCT

		MOV	EAX,[EBX].MYI2_OPREAD_THREAD_HANDLE

		PUSH	EAX
		CALL	SetThreadPriority	;I DON'T CARE IF THIS FAILS
OPENT_LOOP::
		push	EBX
		call	_get_next_open_struc	;GET MY NEXT 'OPEN' STRUCTURE IN SI
						;THIS WILL NEED TO WAIT IF
						;4 FILES ALREADY OPEN
		add	ESP,4

		push	EBX
		call	_get_next_file_name	;GET AX GINDEX TO NEXT FILENAME_LIST
						;THIS WILL WAIT IF NO FILES
						;IN LIST
		add	ESP,4

		push	EAX
		mov	ECX,ESP
		push	EAX
		mov	EDX,ESP

		push	ECX	; pEDI
		push	EDX	; pESI
		push	EBX
		push	EAX
		call	_open_file		;RETURNS SI=NFN_STRUC, DI=OPENFILE_STRUC
		add	ESP,16
		pop	ESI
		pop	EDI
		test	EAX,EAX
		JNZ	OPENT_LOOP

		ASSUME	ESI:PTR NFN_STRUCT

		XOR	ECX,ECX
		MOV	AL,[ESI].NFN_TYPE

		MOV	[EDI].OPENFILE_ADDR,ECX
		CMP	AL,NFN_OBJ_TTYPE

		JNZ	READ_LIBS		;SPECIAL FILE TYPES...
READ_LIBS_NOPE::
		push	EBX
		call	_get_next_buffer	;GET OWNERSHIP OF NEXT 16K	SI IS INS_STRUCT - BP
						;THIS WILL WAIT IF NO BUFFERS
						;AVAILABLE
		add	ESP,4
		mov	ESI,EAX

		push	EBX
		push	EDI
		push	ESI
		call	_read_first_block	;READ NEXT 16K FROM FILE (ADJUSTS SIZE IF LIB)
		add	ESP,12
		cmp	EAX,PAGE_SIZE

		JNZ	OPENT_CLOSE		;IF LAST BLOCK, YOU ARE DONE
BLOCK_LOOP:
		push	EBX
		call	_get_next_buffer	;GET OWNERSHIP OF NEXT 16K
						;THIS WILL WAIT IF NO BUFFERS
						;AVAILABLE
		add	ESP,4
		mov	ESI,EAX

		push	EBX
		push	EDI
		push	ESI
		call	_read_next_block	;READ NEXT 16K FROM FILE
		add	ESP,12
		CMP	EAX,PAGE_SIZE

		JZ	BLOCK_LOOP		;MORE IN FILE, LOOP
OPENT_CLOSE:
		XOR	EAX,EAX

		XCHG	EAX,[EDI].OPENFILE_HANDLE	;IN CASE ANOTHER THREAD TERMINATING ME

		TEST	EAX,EAX
		JZ	OPENT_LOOP

		push	EAX
		call	_close_handle
		add	ESP,4

		JMP	OPENT_LOOP

OPREADT		ENDP


READ_LIBS	PROC
		;
		;OK, EITHER A LIBRARY FILE, STUB FILE, OR 'OLD' FILE
		;
if	fg_segm
		CMP	AL,NFN_RES_TTYPE	;.RES FILES READ SEQUENTIALLY LIKE .OBJ'S
		JZ	READ_LIBS_NOPE

		CMP	AL,NFN_STUB_TTYPE
		JZ	READ_LIBS_NOPE		;STUB FILES READ SEQUENTIALLY...

		CMP	AL,NFN_OLD_TTYPE
		JNZ	NO_READ_OLD_PROC

		push	EDI
		push	EBX
		call	_read_old_proc
		add	ESP,8

		jmp	OPENT_LOOP
NO_READ_OLD_PROC:
endif

if	fg_dosx
		CMP	AL,NFN_LOD_TTYPE
		JZ	READ_LIBS_NOPE
endif
		;
		;WE ARE STARTING LIBRARY HANDLING...
		;
		;DI IS OPENFILE STRUCTURE
		;
		push	EDI
		push	EBX
		call	_read_16		;READS 16 BYTES
		add	ESP,8

		MOV	EAX,DPTR [EBX].MYI2_TEMP_RECORD

		CMP	AL,0F0H
		JNZ	READ_LIBS_NOPE	;MIGHT BE SEARCHING AN OBJ FILE

		SHR	EAX,8
		MOV	ECX,DPTR [EBX].MYI2_TEMP_RECORD+7

		CMP	AX,4096
		JNC	READ_LIBS_NOPE
		;
		;GET OFFSET TO DICTIONARY
		;
		MOV	EAX,DPTR [EBX].MYI2_TEMP_RECORD+3
		AND	ECX,0FFFFH

		PUSHM	EAX,ECX

		PUSH	FILE_BEGIN
		PUSH	0			;NO HIGH WORD

		MOV	ECX,[EDI].OPENFILE_HANDLE
		PUSH	EAX			;DISTANCE TO MOVE

		PUSH	ECX			;FILE HANDLE
		CALL	SetFilePointer

		INC	EAX
		JZ	OPOS_ERROR

		POPM	EAX,ECX			;# OF DICT BLOCKS, ADDRESS

		SHL	EAX,9
		MOV	EDX,[EDI].OPENFILE_NAME

		MOV	[EDI].OPENFILE_ADDR,ECX
		ADD	ECX,EAX
		ASSUME	EDX:PTR NFN_STRUCT
		;
		;NEED TO ADJUST LENGTH REPORTED IN FN_LENGTH TO SKIP EXTENDED
		;ES:DI IS OPENFILE STRUCTURE...
		;
		SHR	EAX,9
		MOV	[EDX].NFN_FILE_LENGTH,ECX

		MOV	ECX,EAX			;ECX IS # OF BLOCKS
		JZ	NO_DIRS
		;
		;NOW READ DIRECTORY BLOCKS
		;
READ_ONE:
		PUSH	ECX
		push	EBX
		call	_get_next_buffer	;16K BUFFER
		add	ESP,4
		mov	ESI,EAX

		push	EBX
		push	EDI
		push	ESI
		call	_read_next_block	;Get first buffer full
		add	ESP,12
		CMP	EAX,PAGE_SIZE

		POP	ECX

		SUB	ECX,PAGE_SIZE/512
		JA	READ_ONE
NO_DIRS:
		JMP	OPENT_LOOP

OPOS_ERROR:
		MOV	ECX,[EDI].OPENFILE_NAME
		MOV	AL,DOS_POS_ERR

		ADD	ECX,NFN_STRUCT.NFN_TEXT
		push	ECX
		push	EAX
		call	_oerr_abort
		add	ESP,8

READ_LIBS	ENDP

if	fg_segm

READ_OLD_PROC	PROC
		;
		;READ STUFF NEEDED FOR 'OLD' ENTRY POINTS
		;
;		CALL	READ_40H
		push	EDI
		push	EBX
		call	_read_40H
		add	ESP,8
		test	EAX,EAX
		JNZ	L19$

		ASSUME	ESI:PTR EXE

		XOR	EDX,EDX

		CMP	[ESI]._EXE_SIGN,'ZM'
		JNZ	L12$

		CMP	[ESI]._EXE_RELOC_OFF,40H
		JNZ	L19$

		MOV	EAX,DPTR [ESI+3CH]

		MOV	NE_BASE,EAX

		CALL	POSITION
;		push	EDI
;		push	EAX
;		call	_position
;		add	ESP,8
;		test	EAX,EAX

		JNZ	L19$

;		CALL	READ_40H
		push	EDI
		push	EBX
		call	_read_40H
		add	ESP,8
		test	EAX,EAX

		JNZ	L19$
L12$:
		ASSUME	ESI:PTR NEXE

		CMP	[ESI]._NEXE_SIGN,'EN'
		JNZ	L19$

		XOR	EAX,EAX
		XOR	EDX,EDX

		MOV	AX,[ESI]._NEXE_NONRES_LENGTH
		MOV	ECX,[ESI]._NEXE_NRESNAM_OFFSET

		MOV	NONRES_LENGTH,EAX
		MOV	NONRES_POSITION,ECX

		MOV	DX,[ESI]._NEXE_RESNAM_OFFSET
		MOV	ECX,NE_BASE

		MOV	AX,[ESI]._NEXE_MODREF_OFFSET
		ADD	ECX,EDX		;BASE + RESNAM

		SUB	EAX,EDX		;MODREF - RESNAM
		JC	L19$

		PUSH	EAX
		MOV	EAX,ECX

;		CALL	POSITION
		push	EDI
		push	EAX
		call	_position
		add	ESP,8
		test	EAX,EAX

		POP	EAX
		JZ	L1$
L19$:
		XOR	EAX,EAX
L1$:
		MOV	RES_LENGTH,EAX
		;
		;SET FILE_LENGTH BASED ON BYTES LEFT TO READ
		;
		MOV	ESI,[EDI].OPENFILE_NAME
		ASSUME	ESI:PTR NFN_STRUCT

		MOV	ECX,NONRES_POSITION
		MOV	EDX,NONRES_LENGTH

		ADD	EDX,ECX
		MOV	EAX,OFF _NONRES_LENGTH_SEM

		MOV	[ESI].NFN_FILE_LENGTH,EDX
		CALL	RELEASE_EAX		;TELL HIM LENGTH IS VALID
		;
		;NOW, READ CX BYTES FROM FILE - IN NORMAL FASHION...
		;
		MOV	EAX,RES_LENGTH

		TEST	EAX,EAX
		JZ	L5$
L2$:
		PUSH	EAX

		push	EBX
		call	_get_next_buffer
		add	ESP,4
		mov	ESI,EAX

		push	EBX
		push	EDI
		push	ESI
		call	_read_next_block	;READ NEXT 16K FROM FILE
		add	ESP,12
		CMP	EAX,PAGE_SIZE

		POP	EAX

		SUB	EAX,PAGE_SIZE
		JA	L2$
L5$:
		MOV	EAX,NONRES_LENGTH
		MOV	ECX,NONRES_POSITION

		TEST	EAX,EAX
		JZ	L9$

		PUSH	EAX
		MOV	EAX,ECX

;		CALL	POSITION
		push	EDI
		push	EAX
		call	_position
		add	ESP,8
		test	EAX,EAX

		POP	EAX
L6$:
		PUSH	EAX

		push	EBX
		call	_get_next_buffer
		add	ESP,4
		mov	ESI,EAX

		push	EBX
		push	EDI
		push	ESI
		call	_read_next_block	;READ NEXT 16K FROM FILE
		add	ESP,12
		CMP	EAX,PAGE_SIZE

		POP	EAX

		SUB	EAX,PAGE_SIZE
		JA	L6$
L9$:
		;
		;CLOSE ASAP SO WE CAN OPEN IT WRITE-MODE...
		;
		XOR	EAX,EAX

		XCHG	EAX,[EDI].OPENFILE_HANDLE	;IN CASE ANOTHER THREAD TERMINATING ME

		TEST	EAX,EAX
		JZ	L99$

		push	EAX
		call	_close_handle
		add	ESP,4
L99$:
		JMP	OPENT_LOOP

READ_OLD_PROC	ENDP


READ_40H	PROC	NEAR
		;
		;READ 40H BYTES FROM FILE INTO MYI2_TEMP_RECORD
		;
		PUSH	EAX		;ROOM FOR RESULT
		MOV	EDX,ESP

		PUSH	0		;NOT OVERLAPPED
		PUSH	EDX		;RESULT

		LEA	EAX,[EBX].MYI2_TEMP_RECORD
		MOV	ECX,[EDI].OPENFILE_HANDLE	;FILE HANDLE

		PUSH	40H
		PUSH	EAX		;BUFFER ADDRESS

		PUSH	ECX
		CALL	ReadFile

		TEST	EAX,EAX
		JZ	ERR_40H

		POP	EAX

		CMP	EAX,40H
		JNZ	ERR_40H

		ADD	[EDI].OPENFILE_ADDR,40H
		XOR	EAX,EAX

		RET

ERR_40H:
		OR	AL,-1

		RET

READ_40H	ENDP


POSITION	PROC	NEAR
		;
		;EAX IS SEEK ADDRESS
		;
		PUSH	EAX

		PUSH	FILE_BEGIN
		PUSH	0

		MOV	ECX,[EDI].OPENFILE_HANDLE
		PUSH	EAX

		PUSH	ECX
		CALL	SetFilePointer

		INC	EAX
		JZ	POS_ERR

		POP	ECX
		DEC	EAX

		CMP	EAX,ECX
		MOV	[EDI].OPENFILE_ADDR,EAX

		RET

POS_ERR:
		POP	ECX
		OR	AL,-1

		RET

POSITION	ENDP

endif


GET_NEXT_OPEN_STRUC	PROC	NEAR
		;
		;WAIT FOR NEXT AVAILABLE OPENFILE STRUCTURE
		;
		MOV	EAX,[EBX].MYI2_NEXT_OPEN_STRUC
		PUSH	ESI

		INC	EAX

		AND	AL,3

		IMUL	ESI,EAX,SIZE OPEN_STRUCT
		ASSUME	ESI:NOTHING

		MOV	[EBX].MYI2_NEXT_OPEN_STRUC,EAX

		LEA	EAX,[EBX].OPENFILE_AVAIL_SEM
		CALL	CAPTURE_EAX		;MAKE SURE MAIN THREAD IS DONE WITH THIS...

		GETT	CL,OPREADS_DONE
		XOR	EAX,EAX

		OR	CL,CL
		JNZ	L8$

		MOV	[EBX+ESI].MYI2_OPEN_STRUC.OPENFILE_FLAGS,EAX
		POP	ESI

		RET

L8$:
		push	EBX
		call	_readt_abort

GET_NEXT_OPEN_STRUC	ENDP


GET_NEXT_FILE_NAME	PROC	NEAR
		;
		;GET NEXT FILENAME IN AX
		;THIS WILL WAIT IF NO FILES IN LIST & NOT TIME FOR LIBRARIES.
		;
		LEA	EAX,[EBX].MYI2_FILENAME_LIST_SEM	;WAIT FOR ANOTHER FILE IN LIST
		CALL	CAPTURE_EAX

		GETT	CL,OPREADS_DONE
		MOV	EAX,[EBX].MYI2_LAST_FILENAME_OPENED_GINDEX

		OR	CL,CL
		JNZ	L8$
		;
		;GET NEXT FILENAME TO OPEN
		;
		CONVERT	EAX,EAX,_FILE_LIST_GARRAY
		ASSUME	EAX:PTR FILE_LIST_STRUCT

		MOV	EAX,[EAX].FILE_LIST_MY_NEXT_GINDEX

		MOV	[EBX].MYI2_LAST_FILENAME_OPENED_GINDEX,EAX

		RET

L8$:
		push	EBX
		call	_readt_abort

GET_NEXT_FILE_NAME	ENDP


OPEN_FILE	PROC	NEAR
		;
		;EAX IS FILE_LIST_GINDEX STRUCTURE.
		;
		CONVERT	ESI,EAX,_FILE_LIST_GARRAY
		ASSUME	ESI:PTR FILE_LIST_STRUCT

		IMUL	EDI,[EBX].MYI2_NEXT_OPEN_STRUC,SIZE NFN_STRUCT

		MOV	ECX,[ESI].FILE_LIST_NFN.NFN_TOTAL_LENGTH
		LEA	ESI,[ESI].FILE_LIST_NFN
		ASSUME	ESI:PTR NFN_STRUCT

		ADD	ECX,NFN_STRUCT.NFN_TEXT+4
		LEA	EDI,[EBX+EDI].MYI2_NAMS
		;
		;DS:SI IS NFN_STRUCT, STORE TO ES:DI
		;
		SHR	ECX,2
		MOV	EDX,EDI
		
		REP	MOVSD

		IMUL	EDI,[EBX].MYI2_NEXT_OPEN_STRUC,SIZE OPEN_STRUCT

		MOV	ESI,EDX

		LEA	EDI,[EBX+EDI].MYI2_OPEN_STRUC
		ASSUME	EDI:PTR OPEN_STRUCT
		;
		;EDI PTS TO OPENFILE STRUCTURE
		;
		XOR	EAX,EAX

		XCHG	EAX,[EDI].OPENFILE_HANDLE	;MULTITHREAD

		TEST	EAX,EAX
		JZ	OI_1

		push	EAX
		call	_close_handle
		add	ESP,4

OI_1:
		XOR	EAX,EAX
		MOV	[EDI].OPENFILE_NAME,ESI

		MOV	[EDI].OPENFILE_PATH_GINDEX,EAX
		push	EBX
		push	EDI
		push	ESI
		call	_try_open		;TRY TO OPEN IT AS STATED
		add	ESP,12
		test	EAX,EAX

		MOV	AL,[ESI].NFN_FLAGS
		JZ	L8$
		;
		;NOPE, WAS PATH SPECIFIED?
		;
		TEST	AL,MASK NFN_PATH_SPECIFIED
		JNZ	L5$			;CANNOT TRY ANY MORE...
		;
		;DIFFERENT SEARCH LISTS FOR OBJ VS LIB VS OLD/STUB
		;
		MOV	AL,[ESI].NFN_TYPE
		MOV	ECX,OBJPATH_LIST.FILE_FIRST_GINDEX

		CMP	AL,NFN_OBJ_TTYPE
		JZ	L1$

		CMP	AL,NFN_RES_TTYPE	;RES FILES USE SAME PATHS
		JNZ	L2$
L1$:
		MOV	EAX,ECX
		push	EBX
		push	EDI
		push	ESI
		push	EAX
		call	_try_search		;TRY OBJ= FIRST
		add	ESP,16
		test	EAX,EAX
		JZ	L8$
		JMP	L3$			;NOPE, TRY LIB= TOO

L2$:
if	fg_segm
		MOV	ECX,STUBPATH_LIST.FILE_FIRST_GINDEX
		CMP	AL,NFN_OLD_TTYPE

		JZ	L4$

		CMP	AL,NFN_STUB_TTYPE
		JZ	L4$
endif
L3$:
		MOV	ECX,LIBPATH_LIST.FILE_FIRST_GINDEX
L4$:
		MOV	EAX,ECX
		push	EBX
		push	EDI
		push	ESI
		push	EAX
		call	_try_search
		add	ESP,16
		test	EAX,EAX
		JZ	L8$
		;
		;OBJ AND RES FILES ARE FATAL, REST ARE WARNINGS...
		;
L5$:
		XOR	ECX,ECX
		LEA	EAX,[EBX].OPENFILE_OPEN_SEM

		MOV	[EDI].OPENFILE_HANDLE,ECX
		CALL	RELEASE_EAX

		OR	AL,-1			;MARK IT NOT FOUND...
		RET

L8$:
		;
		;TELL MAIN WE GOT THE FILE OPENED...
		;
		LEA	EAX,[EBX].OPENFILE_OPEN_SEM
		CALL	RELEASE_EAX
		;
		;DS:DI IS MYI2_OPENFILE_STRUC
		;DS:SI IS NFN STRUCTURE
		;
		XOR	EAX,EAX

		RET

OPEN_FILE	ENDP


TRY_SEARCH	PROC	NEAR
		;
		;EAX IS GINDEX OF PATHS TO TRY
		;
		CONVERT	EAX,EAX,_FILE_LIST_GARRAY
		ASSUME	EAX:PTR FILE_LIST_STRUCT

		MOV	EAX,[EAX].FILE_LIST_NEXT_GINDEX
		JMP	TEST_PATH

PATH_LOOP:
		;
		;MOVE JUST PATH
		;
		PUSH	EAX
		CONVERT	EAX,EAX,_FILE_LIST_GARRAY
		LEA	ECX,[EAX].FILE_LIST_NFN
		ASSUME	ECX:PTR NFN_STRUCT

		MOV	EDX,[EAX].FILE_LIST_NEXT_GINDEX

		MOV	AL,[ECX].NFN_FLAGS
		PUSH	EDX

		TEST	AL,MASK NFN_PATH_SPECIFIED
		JZ	NEXT_PATH		;SKIP NUL
		;
		;MOVE NEW PATH PLEASE
		;
		MOV	EAX,ESI
		push	ECX
		push	EAX
		call	_move_ecxpath_eax
		add	ESP,8

		push	EBX
		push	EDI
		push	ESI
		call	_try_open		;TRY TO OPEN IT AS STATED
		add	ESP,12
		test	EAX,EAX
		JZ	FANCY_SUCCESS
NEXT_PATH:
		POPM	EAX,EDX
TEST_PATH:
		TEST	EAX,EAX
		JNZ	PATH_LOOP
FANCY_FAIL:
		CMP	ESP,-1

		RET

FANCY_SUCCESS:
		POP	EDX			;NEXT PATH
		POP	EAX			;THIS PATH

		MOV	[EDI].OPENFILE_PATH_GINDEX,EAX
		OR	EAX,EAX

		RET

		ASSUME	EAX:NOTHING

TRY_SEARCH	ENDP


TRY_OPEN	PROC	NEAR
		;
		;SI IS MY_NFN STRUCTURE
		;DI IS OPENFILE STRUCTURE
		;
		;
		;DEFINE OPEN_FLAGS BASED ON FILE TYPE...
		;
		;.OBJ, .RES, STUB SEQUENTIAL ACCESS, OTHERS UNKNOWN
		;
		GETT	CL,OPREADS_DONE
		MOV	AL,[ESI].NFN_TYPE

		OR	CL,CL
		JZ	L1

		push	EBX
		call	_readt_abort
L1:
		MOV	ECX,FILE_FLAG_SEQUENTIAL_SCAN

		CMP	AL,NFN_LIB_TTYPE
		JZ	L0$

		CMP	AL,NFN_OLD_TTYPE
		JNZ	L05$
L0$:
		MOV	ECX,FILE_FLAG_RANDOM_ACCESS
L05$:
		PUSH	0

		PUSH	ECX
		PUSH	OPEN_EXISTING		;FILE MUST ALREADY EXIST

		PUSH	0			;SECURITY DESCRIPTOR
		PUSH	FILE_SHARE_READ		;OTHERS MAY READ THIS

		LEA	EDX,[ESI].NFN_TEXT
		PUSH	GENERIC_READ		;I WILL ONLY READ THIS

		PUSH	EDX
		CALL	CreateFile

		CMP	EAX,INVALID_HANDLE_VALUE
		JNZ	DO_TIME_AND_SIZE

		CALL	HANDLE_CHECK

		JZ	TRY_OPEN

		RET

TRY_OPEN	ENDP


DO_TIME_AND_SIZE	PROC	NEAR
		;
		;
		;
		MOV	ECX,[EDI].OPENFILE_FLAGS
		MOV	[EDI].OPENFILE_HANDLE,EAX

		OR	ECX,1
		MOV	AL,[ESI].NFN_FLAGS

		MOV	[EDI].OPENFILE_FLAGS,ECX	;OPEN SUCCESSFUL
		TEST	AL,MASK NFN_TIME_VALID		;VALID IF AMBIGUOUS FILENAME

		MOV	ECX,[EDI].OPENFILE_HANDLE
		JNZ	L3$

		PUSH	0				;NO SUPPORT FOR HUGE FILES
		OR	AL,MASK NFN_TIME_VALID

		PUSH	ECX
		MOV	[ESI].NFN_FLAGS,AL

		CALL	GetFileSize

		CMP	EAX,-1
		JZ	L9$

		MOV	[ESI].NFN_FILE_LENGTH,EAX
L3$:
		XOR	EAX,EAX

		RET

L9$:
		LEA	ECX,[ESI].NFN_TEXT
		MOV	AL,QFH_FAILED_ERR
		push	ECX
		push	EAX
		call	_oerr_abort
		add	ESP,8

DO_TIME_AND_SIZE	ENDP


HANDLE_CHECK	PROC	NEAR
		;
		;HERE WE SEE IF OUT_OF_HANDLES WAS CAUSE OF OPEN FAILURE
		;
		OR	AL,-1

		RET

HANDLE_CHECK	ENDP


GET_NEXT_BUFFER	PROC	NEAR	PRIVATE
		;
		;GET NEXT EMPTY BUFFER, RETURNS SI IS INS_STRUCT
		;
		MOV	EAX,[EBX].MYI2_NEXT_FILE_BUFFER

		INC	EAX

		AND	AL,3

		IMUL	ESI,EAX,SIZE INPUT_STRUCT
		ASSUME	ESI:NOTHING

		MOV	[EBX].MYI2_NEXT_FILE_BUFFER,EAX
		LEA	EAX,[EBX].INS_AVAIL_SEM

		LEA	ESI,[EBX+ESI].MYI2_INPUT_STRUC
		ASSUME	ESI:PTR INPUT_STRUCT
		CALL	CAPTURE_EAX

		GETT	AL,OPREADS_DONE

		OR	AL,AL
		JNZ	L8$

		RET

L8$:
		push	EBX
		call	_readt_abort

GET_NEXT_BUFFER	ENDP


READ_NEXT_BLOCK	PROC	NEAR
		;
		;PTR TO BUFFER STRUCTURE IS IN SI
		;PTR TO OPENFILE STRUCTURE IS IN DI
		;
		push	EDI
		push	ESI
		call	_read_block
		add	ESP,8
		CMP	EAX,PAGE_SIZE
		PUSHFD
RNB_END::
		;
		;MARK BUFFER FULL
		;
		LEA	EAX,[EBX].INS_FULL_SEM
		CALL	RELEASE_EAX

		POPFD

		RET

READ_NEXT_BLOCK	ENDP


READ_FIRST_BLOCK	PROC	NEAR
		;
		;SI IS INS_STRUCT
		;READ 16K BLOCK, TREAT .LIB-FORMAT FILES SPECIALLY
		;
		push	EDI
		push	ESI
		call	_read_block
		add	ESP,8
		CMP	EAX,PAGE_SIZE
		;
		;FIRST BLOCK, LETS SEE IF THIS IS A LIBRARY FILE...
		;
		PUSHFD

		CMP	EAX,16
		JB	NOT_LIB

		MOV	EAX,[ESI].INS_BLOCK

		MOV	ECX,[EAX]

		CMP	CL,0F0H			;LIB-TYPE?
		JNZ	NOT_LIB

		SHR	ECX,8			;TOO LONG?
		MOV	EDX,[EDI].OPENFILE_NAME

		CMP	CX,512-3
		JNC	NOT_LIB
		;
		;GET OFFSET TO DICTIONARY
		;
		MOV	EAX,[EAX+3]
		MOV	ECX,[EDI].OPENFILE_ADDR
		;
		;NEED TO ADJUST LENGTH REPORTED IN FN_LENGTH
		;ES:DI IS OPENFILE STRUCTURE...
		;

		CMP	ECX,EAX
		JAE	NOT_LIB

		MOV	[EDX].NFN_FILE_LENGTH,EAX
NOT_LIB:
		JMP	RNB_END

READ_FIRST_BLOCK	ENDP


READ_BLOCK	PROC	NEAR
		;
		;ESI IS INS_STRUCT
		;EDI IS OPENFILE_STRUCT
		;
		;RETURN EAX == # OF BYTES READ
		;
		ASSUME	ESI:PTR INPUT_STRUCT
		ASSUME	EDI:PTR OPEN_STRUCT

		MOV	EAX,[ESI].INS_BLOCK		;ASSIGN A SEGMENT IF NOT THERE
		MOV	[ESI].INS_OPENFILE,EDI		;MARK OWNING OPEN FILE

		TEST	EAX,EAX
		JNZ	L1$

		;GO GET A SEGMENT
		push	ECX
		push	EDX
		call	_get_new_phys_blk
		pop	EDX
		pop	ECX

		MOV	[ESI].INS_BLOCK,EAX
L1$:
		;
		;SET UP FOR READ...
		;
		PUSH	EAX				;MAKE PLACE FOR RESULT

		MOV	EDX,ESP
		PUSH	0				;NOT OVERLAPPED

		PUSH	EDX				;RESULT
		MOV	EDX,[EDI].OPENFILE_NAME
		ASSUME	EDX:PTR NFN_STRUCT

		MOV	ECX,[EDI].OPENFILE_ADDR		;LEFT AND PAGE_SIZE
		MOV	EDX,[EDX].NFN_FILE_LENGTH	;READ SMALLER OF BYTES

		SUB	EDX,ECX
		MOV	ECX,[EDI].OPENFILE_HANDLE

		CMP	EDX,PAGE_SIZE
		JC	L3$

		MOV	EDX,PAGE_SIZE
L3$:
		PUSH	EDX			;# TO READ
		PUSH	EAX			;BUFFER ADDRESS

		PUSH	ECX			;FILE HANDLE
		MOV	[ESI].INS_BYTES,EDX

		CALL	ReadFile

		TEST	EAX,EAX
		JZ	OREAD_ERROR

		POP	ECX			;# ACTUALLY READ
		MOV	EAX,[ESI].INS_BYTES

		CMP	EAX,ECX
		JNZ	OUNEXP_ERROR

		ADD	[EDI].OPENFILE_ADDR,EAX
		CMP	EAX,PAGE_SIZE
		;
		;RETURN EAX IS # OF BYTES READ
		;
		RET

OREAD_ERROR::
		MOV	ECX,[EDI].OPENFILE_NAME
		MOV	AL,DOS_READ_ERR

		ADD	ECX,NFN_STRUCT.NFN_TEXT
		push	ECX
		push	EAX
		call	_oerr_abort
		add	ESP,8

OUNEXP_ERROR::
OUNEXP1_ERROR::
		MOV	ECX,[EDI].OPENFILE_NAME
		MOV	AL,UNEXP_EOF_ERR

		ADD	ECX,NFN_STRUCT.NFN_TEXT
		push	ECX
		push	EAX
		call	_oerr_abort
		add	ESP,8

READ_BLOCK	ENDP


READ_16		PROC	NEAR
		;
		;READ LIBRARY HEADER
		;
		PUSH	EAX		;ROOM FOR RESULT
		MOV	EDX,ESP

		PUSH	0		;NOT OVERLAPPED
		PUSH	EDX		;RESULT

		LEA	EAX,[EDI].OPENFILE_HEADER
		MOV	ECX,[EDI].OPENFILE_HANDLE

		PUSH	16		;# TO READ
		PUSH	EAX		;BUFFER ADDRESS

		PUSH	ECX		;FILE HANDLE
		CALL	ReadFile

		TEST	EAX,EAX
		JZ	OREAD_ERROR

		POP	EAX

		CMP	EAX,16
		JNZ	OUNEXP1_ERROR

		ADD	[EDI].OPENFILE_ADDR,16
		PUSH	EDI
		;
		;COPY THIS DATA TO SOMEPLACE SAFE PLEASE
		;
		PUSH	ESI
		LEA	ESI,[EDI].OPENFILE_HEADER

		LEA	EDI,[EBX].MYI2_TEMP_RECORD
		MOV	ECX,16/4

		REP	MOVSD

		POPM	ESI,EDI
		;
		;LET OTHER THREAD SEE IT TOO...
		;
		LEA	EAX,[EBX].OPENFILE_HEADER_SEM
		JMP	RELEASE_EAX

READ_16		ENDP


READT_ABORT	PROC	NEAR
		;
		;CLOSE ANY OPEN HANDLES
		;
		MOV	ECX,4
		LEA	ESI,[EBX].MYI2_OPEN_STRUC
		ASSUME	ESI:PTR OPEN_STRUCT
L1$:
		XOR	EAX,EAX

		XCHG	EAX,[ESI].OPENFILE_HANDLE

		TEST	EAX,EAX
		JZ	L2$

		PUSH	ECX

		push	EAX
		call	_close_handle
		add	ESP,4

		POP	ECX
L2$:
		ADD	ESI,SIZE OPEN_STRUCT

		DEC	ECX
		JNZ	L1$
		;
		;NOW, CLAIM REMAINING BUFFERS, RELEASE SEGMENTS
		;
		MOV	ECX,4
		LEA	ESI,[EBX].MYI2_INPUT_STRUC
		ASSUME	ESI:PTR INPUT_STRUCT
L3$:
		XOR	EDX,EDX
		MOV	EAX,[ESI].INS_BLOCK	;SEGMENT ALLOCATED?

		TEST	EAX,EAX
		JZ	L4$

		MOV	[ESI].INS_BLOCK,EDX
		push	EAX
		call	_release_block
		add	ESP,4
L4$:
		ADD	ESI,SIZE INPUT_STRUCT
		DEC	ECX

		JNZ	L3$
		;
		;NOW, TERMINATE THIS THREAD
		;
		PUSH	0
		CALL	ExitThread		;STOP THIS THREAD

READT_ABORT	ENDP


		.DATA

NE_BASE		DD	0
NONRES_POSITION	DD	0

endif

		END
