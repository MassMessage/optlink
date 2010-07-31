		TITLE	DLLENTRY - Copyright (c) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	SYMCMACS
		INCLUDE	RELEASE
		INCLUDE	WIN32DEF
		INCLUDE	WINMACS
		INCLUDE	IO_STRUC


		PUBLIC	DLL_ENTRY,_NetSpawnVersion,_DllVersion,DLL_TERMINATE,REPORT_ASCIZ,REPORT_MESSAGE,REPORT_PROGRESS
		PUBLIC	REPORT_OUT_ASCIZ,REPORT_CLOSE_ASCIZ


		.DATA

		EXTERNDEF	MY_ARGC:DWORD,CMDLINE_BLOCK:DWORD,CURN_COUNT:DWORD,YIELD_COUNT:DWORD,GLOBAL_BLOCKS:DWORD
		EXTERNDEF	MY_ARGV:DWORD,CURN_INPTR:DWORD,BEGIN_DATA:DWORD,FINISH_DATA:DWORD,BEGIN_BSS:DWORD,FINISH_BSS:DWORD
		EXTERNDEF	MAIN_THREAD_ID:DWORD,MAIN_THREAD_HANDLE:DWORD,ERR_COUNT:DWORD,OBJ_DEVICE:DWORD
		EXTERNDEF	MAP_THREAD_HANDLE:DWORD,LIB_THREAD_LOCALS:DWORD,EXE_DEVICE:DWORD,MAP_DEVICE:DWORD
		EXTERNDEF	ENVIRONMENT_BLOCK:DWORD

		EXTERNDEF	TOOL_CALLBACKS:TOOL_CALLBACKS_STRUCT,TOOL_MESSAGE:TOOL_MESSAGE_STRUCT,TOOL_DATA:TOOL_DATA_STRUCT
		EXTERNDEF	LIB_REQUEST_ORDER_SEM:GLOBALSEM_STRUCT,GLOBALALLOC_SEM:GLOBALSEM_STRUCT
		EXTERNDEF	SEGS_ORDERED_SEM:GLOBALSEM_STRUCT,EXPS_DEFINED_SEM:GLOBALSEM_STRUCT,PUBS_DEFINED_SEM:GLOBALSEM_STRUCT
		EXTERNDEF	MAPLINES_OK_SEM:GLOBALSEM_STRUCT,START_DEFINED_SEM:GLOBALSEM_STRUCT,XREF_OK_SEM:GLOBALSEM_STRUCT

		.CODE	ROOT_TEXT

		EXTERNDEF	OPTLINK:PROC,CANCEL_TERMINATE:PROC,XCNOTIFY:PROC,CLOSE_SEMAPHORES:PROC,TERMINATE_OPREADS:PROC
		EXTERNDEF	CLOSE_HANDLE:PROC,CLOSE_LIB_FILES:PROC,RELEASE_4K_SEGMENT:PROC,HANDLE_EOF:PROC,END_OF_INDIRECT:PROC
		EXTERNDEF	DO_DOSSLEEP_0:PROC,CAPTURE_EAX:PROC,RELEASE_EAX:PROC,RELEASE_EAX_BUMP:PROC,INIT_EAX:PROC
		EXTERNDEF	MOVE_ASCIZ_ECX_EAX:PROC


DLL_ENTRY	PROC
		;
		;CALLED FROM MAKE
		;
		;FIRST PARAM IS # OF ARGUMENTS	(INT)
		;SECOND IS PTR TO ARGUMENT ARRAY
		;THIRD IS PTR TO CALLBACK ARRAY
		;
;int DLLEXPORT DllEntry(int argc, char *argv[], tToolCallbacks *pCallbacks)
		;
ARGC		EQU	<(DPTR [EBP+8])>
ARGV		EQU	<(DPTR [EBP+12])>
CALLBACK	EQU	<(DPTR [EBP+16])>

		PUSH	EBP
		MOV	EBP,ESP

		PUSHM	EDI,ESI,EBX
		MOV	ESI,CALLBACK
		ASSUME	ESI:PTR TOOL_CALLBACKS_STRUCT

		CMP	[ESI]._TCB_VERSION,VERSION_TOOLCALLBACKS
		JZ	L1$
L9$:
		;
		;HERE WE FAILED, BUT HAVE ALLOCATED NOTHING
		;
		OR	AL,1
		POPM	EBX,ESI,EDI
		POP	EBP
		RET	12

L1$:
		PUSHM	-1,0
		PUSH	OFF XCNOTIFY
		ASSUME	FS:NOTHING

		PUSH	DWORD PTR FS:[0]
		MOV	FS:[0],ESP

		ASSUME	ESI:NOTHING
		;
		;ZERO OUT BSS
		;
		MOV	EDI,OFF BEGIN_BSS
		MOV	ECX,OFF FINISH_BSS+4

		XOR	EAX,EAX
		SUB	ECX,EDI

		SHR	ECX,2
		MOV	EDX,INITIALIZED_DATA_PTR

		REP	STOSD
		;
		;EITHER SAVE OR RESTORE R/W INITIALIZED DATA
		;
		TEST	EDX,EDX
		JNZ	DATA_RESTORE
		;
		;DATA SAVE
		;
		MOV	ESI,OFF BEGIN_DATA
		ASSUME	ESI:NOTHING
		MOV	EBX,OFF FINISH_DATA+4

		SUB	EBX,ESI
		PUSH	PAGE_READWRITE

		PUSH	MEM_RESERVE+MEM_COMMIT
		PUSH	EBX

		PUSH	0
		CALL	VirtualAlloc

		TEST	EAX,EAX
		JZ	L9$

		MOV	ECX,EBX
		MOV	EDI,EAX

		SHR	ECX,2
		MOV	INITIALIZED_DATA_PTR,EAX

		REP	MOVSD

		JMP	DATA_CONTINUE

DATA_RESTORE:
		MOV	EDI,OFF BEGIN_DATA
		MOV	ECX,OFF FINISH_DATA+4

		SUB	ECX,EDI
		MOV	ESI,EDX

		SHR	ECX,2

		REP	MOVSD

DATA_CONTINUE:
		;
		;MOVE CALLBACKS STRUCTURE
		;
		MOV	ESI,CALLBACK
		ASSUME	ESI:PTR TOOL_CALLBACKS_STRUCT
		MOV	EDI,OFF TOOL_CALLBACKS
		MOV	ECX,SIZE TOOL_CALLBACKS_STRUCT/4

		REP	MOVSD
		;
		;DOES THIS HOST SUPPORT THREADS?
		;
;		MOV	HOST_ESP,ESP
		CALL	GetVersion	;HIGH BIT 0 MEANS NT, HIGH TWO BITS ON
					;MEANS CHICAGO...

		OR	EAX,EAX
		JNS	DO_MT

		SHR	EAX,30

		CMP	AL,3
		JNZ	NOT_MT
DO_MT:
		SETT	HOST_THREADED
NOT_MT:
		;
		;MOVE ARGC AND ARGV TO MY NEW DGROUP
		;
		MOV	EAX,ARGC
		MOV	ECX,ARGV

		MOV	MY_ARGC,EAX
		MOV	MY_ARGV,ECX

		TEST	EAX,EAX
		JZ	L9$

		BITT	HOST_THREADED
		JZ	NOT_THREADED
		;
		;
		;
		CALL	CREATE_MANUAL_EVENT

		MOV	MY_EVENT_HANDLE,EAX

		MOV	EAX,OFF ERROR1_SEM
		CALL	INIT_EAX

		MOV	EAX,OFF ASCIZ1_SEM
		CALL	INIT_EAX

		PUSH	OFF MAIN_THREAD_ID
		PUSH	0				;DON'T CREATE SUSPENDED

		PUSH	0				;NUL PARAMETER
		PUSH	OFF MAIN_THREAD			;THREAD HEAD

		PUSH	8K				;STACK COMMIT SIZE
		PUSH	0				;SECURITY DESCRIPTOR

		CALL	CreateThread

		TEST	EAX,EAX
		JZ	NOT_THREADED

		MOV	MAIN_THREAD_HANDLE,EAX
		MOV	MAIN_THREAD_HANDLE_A,EAX
;		MOV	MULTIPLE_LIST,EAX

		MOV	EAX,OFF TOOL_DATA	;DISPLAY TOOL NAME, ETC
		CALL	REPORT_ACTIVITY
		;
		;NOW WAIT FOR SOMEONE TO REQUEST TERMINATION
		;
;		MOV	EAX,MAIN_THREAD_HANDLE
;		PUSH	-1

;		PUSH	EAX
;		CALL	WaitForSingleObject

L11$:
;		PUSH	200		;MILLISECONDS, .2 SECONDS, 5 TIMES A SECOND IF NOTHING ELSE TO DO...
;		PUSH	0		;RETURN IF ANY SIGNALLED

;		PUSH	OFF MULTIPLE_LIST
;		PUSH	2		;FOR NOW, JUST REPORT_ASCIZ AND TERMINATE ARE SUPPORTED

;		CALL	WaitForMultipleObjects

		MOV	EAX,MY_EVENT_HANDLE
		PUSH	200

		PUSH	EAX
		CALL	WaitForSingleObject
		;
		;HERE, WE HAVE ONE OR MORE OF THE FOLLOWING:
		;	1.)	A FILENAME TO REPORT, ITS IN REPORT_ASCIZ1
		;	2.)	AN ERROR MESSAGE TO REPORT, ITS IN ???
		;	3.)	TIME-OUT, BETTER YIELD FOR ARUBER AND CHECK STOP FLAG
		;	4.)	TERMINATION, GOOD-BYE
		;
		CMP	EAX,WAIT_TIMEOUT
		JZ	L18$
L12$:
		PUSH	MY_EVENT_HANDLE
		CALL	ResetEvent
		;
		;HIGHEST PRIORITY IS ERROR MESSAGE STUFF
		;
		BITT	ASCIZ1_WAITING
		JZ	L14$

		CALL	DO_ASCIZ1
L14$:
		BITT	ERROR1_WAITING
		JZ	L16$
L15$:
		CALL	DO_ERROR1
		JMP	L12$

L16$:
		MOV	EAX,MAIN_THREAD_HANDLE

		TEST	EAX,EAX
		JNZ	L18$

		BITT	ERROR1_WAITING
		JNZ	L15$

		JMP	DLL_TERMINATED

L18$:
		CALL	DO_TIME_OUT	;NOTHING TO DO, JUST CHECK STOP FLAG
		JMP	L11$

MAIN_THREAD:
		PUSHM	-1,0
		PUSH	OFF XCNOTIFY
		ASSUME	FS:NOTHING

		PUSH	DWORD PTR FS:[0]
		MOV	FS:[0],ESP

		JMP	MAIN_THREAD_CONT


NOT_THREADED:
		RESS	HOST_THREADED

		MOV	EAX,OFF TOOL_DATA	;DISPLAY TOOL NAME, ETC
		CALL	REPORT_ACTIVITY
MAIN_THREAD_CONT:
		MOV	EDX,MY_ARGC
		MOV	ESI,MY_ARGV		;ARGV[0]
		ASSUME	ESI:NOTHING

;		MOV	ERR_COUNT,1

;		DEBMSG	'Argument Count',DX
		;
		;SCAN ARGUMENTS, ADDING UP SIZES
		;
		XOR	EBX,EBX			;TOTAL LENGTH
L2$:
		MOV	EDI,[ESI]
		ADD	ESI,4

		MOV	ECX,-1
		XOR	EAX,EAX

		REPNE	SCASB

		INC	ECX

		SUB	EBX,ECX
		DEC	EDX

		JNZ	L2$

		LEA	EAX,[EBX+6]			;ADD ';', CR
		;
		;BX IS SEGMENT SIZE TO ALLOCATE
		;
;		DEBMSG	'CMDLINE Length',BX

		PUSH	PAGE_READWRITE
		PUSH	MEM_RESERVE+MEM_COMMIT

		PUSH	EAX
		PUSH	0

		CALL	VirtualAlloc

		TEST	EAX,EAX
		JZ	DLL_QUIT

		MOV	EDI,EAX
		MOV	CMDLINE_BLOCK,EAX

;		DEBMSG	'Copying CMDLINE'
		;
		;SCAN ARGUMENTS AGAIN, BUILDING COMMAND LINE AS YOU GO
		;
		MOV	ECX,MY_ARGC
		MOV	EBX,MY_ARGV
L3$:
		MOV	ESI,[EBX]			;NEXT PARAMETER
		ADD	EBX,4
L31$:
		MOV	AL,[ESI]			;COPY IT
		INC	ESI

		MOV	[EDI],AL
		INC	EDI

		OR	AL,AL
		JNZ	L31$

		MOV	BPTR [EDI-1],' '

		CMP	CMDLINE_PTR,0
		JNZ	L32$

		MOV	CMDLINE_PTR,EDI			;END OF NAME
L32$:
		DEC	ECX
		JNZ	L3$

;		ALLMSG	'CMDLINE Copied'
		;
		;SEE IF CMDLINE CALL IS WANTED
		;
		CMP	TOOL_CALLBACKS._TCB_REPORT_MESSAGE,0
		JZ	L35$
		;
		;NULL TERMINATE IT FOR HOST
		;
		PUSH	EDI
		XOR	AL,AL

		STOSB
		;
		;SET UP TOOL_MSG FOR CMDLINE CALL
		;
		MOV	EAX,OFF TOOL_MESSAGE
		ASSUME	EAX:PTR TOOL_MESSAGE_STRUCT
		XOR	ECX,ECX

		MOV	EDX,CMDLINE_BLOCK

		MOV	[EAX]._TMSG_VERSION,TOOLMSG_VERSION
		MOV	[EAX]._TMSG_MSGTYPE,EMSG_TOOL_CMDLINE
		MOV	[EAX]._TMSG_MSGTEXT,EDX
		MOV	[EAX]._TMSG_FILENAME,ECX
		MOV	[EAX]._TMSG_LINENUMBER,K_NOLINENUMBER
		MOV	[EAX]._TMSG_COLNUMBER,K_NOCOLNUMBER
		MOV	[EAX]._TMSG_MSGNUMBER,K_NOMSGNUMBER

;		ALLMSG	'Calling REPORT_MESSAGE'

		CALL	REPORT_MESSAGE
		ASSUME	EAX:NOTHING

		POP	EDI
L35$:
		MOV	EAX,';'+0DH*256

		STOSW

		SUB	EDI,CMDLINE_PTR

		MOV	CMDLINE_LENGTH,EDI

;		ALLMSG	'CMDLINE Reported'
		;
		;YIELD ONCE
		;
		MOV	YIELD_COUNT,K_YIELD_ON
		CALL	REPORT_PROGRESS1

;		ALLMSG	'YIELDed Once'

		TEST	EAX,EAX
		JNZ	DLL_TERMINATE
		;
		;GO LINK
		;
;		ALLMSG	'Calling OPTLINK'

		CALL	OPTLINK
		;
		;DONE LINK
		;
;		ALLMSG	'Back From OPTLINK'

DLL_QUIT:
;		BITT	HOST_THREADED
;		JZ	DLL_TERMINATED

;		PUSH	0
;		CALL	ExitThread



DLL_TERMINATE::


DLL_TERMINATED:
;		ALLMSG	'TERMINATE ALL THREADS'

		SETT	FINAL_ABORTING

		CALL	TERMINATE_ALL_THREADS	;MAKE SURE ALL THREADS BUT ME ARE TERMINATED

;		ALLMSG	'CLOSE SEMAPHORES'

		CALL	CLOSE_SEMAPHORES	;CLOSE ALL SEMAPHORES

;		ALLMSG	'CLOSE FILES'

		CALL	CLOSE_FILES		;CLOSE ALL OPEN FILE HANDLES

		CALL	CLOSE_MY_EVENTS		;
		;
		;RELEASE COMMAND LINE SEGMENT
		;
;		ALLMSG	'RELEASE CMDLINE'

		MOV	EAX,CMDLINE_BLOCK
		PUSH	MEM_RELEASE

		PUSH	0		;RELEASE ALL
		PUSH	EAX

		CALL	VirtualFree
		;
		;RELEASE ANY UNRELEASED MEMORY
		;
;		ALLMSG	'RELEASE ALL MEMORY'

		MOV	EDI,OFF GLOBAL_BLOCKS
		MOV	ECX,8K
L6$:
		XOR	EAX,EAX

		REPE	SCASB

		MOV	EDX,EDI
		JZ	L68$

		SUB	EDX,OFF GLOBAL_BLOCKS+1
		PUSH	ECX

		MOV	AL,[EDI-1]
		MOV	EBX,8
L61$:
		SHL	AL,1
		JNC	L67$

		PUSHM	EDX,EAX

		LEA	EAX,[EDX*8+EBX-1]
		PUSH	MEM_RELEASE

		SHL	EAX,16
		PUSH	0		;RELEASE ALL

		PUSH	EAX
		CALL	VirtualFree

		TEST	EAX,EAX
		JZ	RELEASE_ERROR

		POPM	EAX,EDX
L67$:
		DEC	EBX
		JNZ	L61$

		POP	ECX
		JMP	L6$

RELEASE_ERROR:
		ALLMSG	'MEMORY RELEASE ERROR'

		POPM	EAX,EDX,ECX

L68$:
		MOV	EAX,ENVIRONMENT_BLOCK

		PUSH	EAX
		CALL	FreeEnvironmentStrings

;		ALLMSG	'READY TO RETURN'


		ASSUME	FS:NOTHING

		POP	DPTR FS:0

		POPM	ECX,EDX,ECX
		MOV	EAX,ERR_COUNT

		POPM	EBX,ESI,EDI
		POP	EBP

		RET	12

DLL_ENTRY	ENDP


_NetSpawnVersion	PROC
		;
		;CALLED FROM DLLRUN
		;
		MOV	EAX,NETSPAWN_VERSION

		RET

_NetSpawnVersion	ENDP


_DllVersion	PROC
		;
		;CALLED FROM ????
		;
		MOV	EAX,RELEASE_NUM

		RET

_DllVersion	ENDP


DO_ERROR1	PROC
		;
		;
		;
;		CAPTURE	ERROR1_SEM		;MAKE SURE I OWN BUFFER

		XOR	EAX,EAX
		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_MESSAGE

		RESS	ERROR1_WAITING,AL
		PUSH	OFF MY_TOOL_MESSAGE_STRUCT

		CALL	ECX

		RELEASE_BUMP	ERROR1_SEM	;RELEASE BUFFER

		JMP	DO_TIME_OUT

DO_ERROR1	ENDP


REPORT_MESSAGE	PROC
		;
		;EAX IS TOOL_MESSAGE
		;
;		ALLMSG	'Report Message'

		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_MESSAGE
		GETT	DL,HOST_THREADED

		TEST	ECX,ECX
		JZ	L9$

		TEST	DL,DL
		JNZ	L1$

		PUSH	EAX

		CALL	ECX

;		ALLMSG	'Return From Report Message'
L9$:
		RET

L1$:
		CAPTURE	ERROR1_SEM		;CAPTURE ERROR BUFFER
		;
		;COPY STUFF...
		;
		PUSHM	EDI,ESI

		MOV	ESI,EAX
		MOV	EDI,OFF MY_TOOL_MESSAGE_STRUCT
		ASSUME	ESI:PTR TOOL_MESSAGE_STRUCT
		ASSUME	EDI:PTR TOOL_MESSAGE_STRUCT

		MOV	EAX,[ESI]._TMSG_VERSION
		MOV	ECX,[ESI]._TMSG_MSGTYPE

		MOV	[EDI]._TMSG_VERSION,EAX
		MOV	[EDI]._TMSG_MSGTYPE,ECX

		MOV	EAX,[ESI]._TMSG_LINENUMBER
		MOV	ECX,DPTR [ESI]._TMSG_COLNUMBER

		MOV	DPTR [EDI]._TMSG_COLNUMBER,ECX
		MOV	ECX,[ESI]._TMSG_FILENAME

		MOV	[EDI]._TMSG_LINENUMBER,EAX
		MOV	[EDI]._TMSG_FILENAME,ECX

		TEST	ECX,ECX
		JZ	L2$

		MOV	EAX,OFF MY_TMSG_FILENAME

		MOV	[EDI]._TMSG_FILENAME,EAX
		CALL	MOVE_ASCIZ_ECX_EAX
L2$:
		MOV	ECX,[ESI]._TMSG_MSGTEXT

		MOV	[EDI]._TMSG_MSGTEXT,ECX
		TEST	ECX,ECX

		JZ	L3$

		MOV	EAX,OFF MY_TMSG_MSGTEXT

		MOV	[EDI]._TMSG_MSGTEXT,EAX
		CALL	MOVE_ASCIZ_ECX_EAX
L3$:
		POPM	ESI,EDI

		SETT	ERROR1_WAITING

;		RELEASE	ERROR1_SEM

		PUSH	MY_EVENT_HANDLE

		CALL	SetEvent

		RET

		ASSUME	ESI:NOTHING,EDI:NOTHING

REPORT_MESSAGE	ENDP


REPORT_ACTIVITY	PROC
		;
		;EAX IS TOOL_DATA
		;
		PUSH	EAX
		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_ACTIVITY

		TEST	ECX,ECX
		JZ	L8$

		CALL	ECX

		RET

L8$:
		POP	EAX

		RET

REPORT_ACTIVITY	ENDP


DO_TIME_OUT	PROC
		;
		;YIELD TO SUPER SLOW BUILD SYSTEM
		;
		PUSHM	EDX,ECX,EAX
		CALL	REPORT_PROGRESS1

		OR	EAX,EAX
		JZ	L1$

		SETT	CANCEL_REQUESTED
L1$:
		POPM	EAX,ECX,EDX

		RET

DO_TIME_OUT	ENDP


REPORT_PROGRESS	PROC
		;
		;
		;
;		ALLMSG	'Report Progress'

		PUSHM	EDX,ECX,EAX
		GETT	AL,HOST_THREADED

		TEST	AL,AL
		JNZ	L5$

		CALL	REPORT_PROGRESS1

		OR	EAX,EAX
		JNZ	L9$
L1$:
		POPM	EAX,ECX,EDX

;		ALLMSG	'Return From Report Progress'

		RET

L5$:
		BITT	CANCEL_REQUESTED
		JZ	L1$

		CALL	GetCurrentThreadId

		CMP	MAIN_THREAD_ID,EAX	;IGNORE CANCEL FROM ANYTHING BUT MAIN THREAD
		JNZ	L7$
L9$:
		SETT	CANCEL_REQUESTED
		BITT	NO_CANCEL_FLAG		;ONLY ALLOW ONE CANCEL NOTIFICATION
		JNZ	L1$

		SETT	NO_CANCEL_FLAG
		JMP	CANCEL_TERMINATE

L7$:
		;
		;MUST BE MAP THREAD...
		;
		PUSH	0
		CALL	ExitThread

REPORT_PROGRESS	ENDP


REPORT_PROGRESS1	PROC

		MOV	ECX,TOOL_CALLBACKS._TCB_YIELD_MODE
		XOR	EAX,EAX

		CMP	ECX,YIELD_NEVER
		JZ	L8$

		CMP	ECX,YIELD_MODERATE
		JNZ	L2$

		DEC	YIELD_COUNT
		JNZ	L8$

		MOV	YIELD_COUNT,K_YIELD_ON
L2$:
		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_PROGRESS
		PUSH	K_NOLINENUMBER

		TEST	ECX,ECX
		JZ	L9$

		CALL	ECX
L8$:
		RET

L9$:
		POP	ECX

		RET

REPORT_PROGRESS1	ENDP


DO_ASCIZ1	PROC
		;
		;
		;
		CAPTURE	ASCIZ1_SEM		;MAKE SURE I OWN BUFFER

		MOV	ECX,OFF ASCIZ1
		MOV	EAX,OFF ASCIZ2

		RESS	ASCIZ1_WAITING

		CALL	MOVE_ASCIZ_ECX_EAX

;		PUSH	REPORT_ASCIZ_EVENT_HANDLE	;RESET PULSE EVENT
;		CALL	ResetEvent

		RELEASE_BUMP	ASCIZ1_SEM		;RELEASE BUFFER

		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_FILE

		PUSHM	1,OFF ASCIZ2

		CALL	ECX

		RET

DO_ASCIZ1	ENDP


REPORT_ASCIZ	PROC
		;
		;EAX IS ASCIZ STRING - FILENAME WE JUST OPENED FOR INPUT
		;
		PUSHM	EDX,ECX

		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_FILE
		GETT	DL,HOST_THREADED

		TEST	ECX,ECX
		JZ	L8$

		TEST	DL,DL
		JZ	L7$

		MOV	ECX,EAX
		MOV	EAX,OFF ASCIZ1

		CAPTURE	ASCIZ1_SEM

		CALL	MOVE_ASCIZ_ECX_EAX

		SETT	ASCIZ1_WAITING

		RELEASE	ASCIZ1_SEM

		PUSH	MY_EVENT_HANDLE		;FREE MASTER THREAD
		CALL	SetEvent

		JMP	L8$

L7$:

;		ALLMSG	'Report ASCIZ'

		PUSHM	1,EAX

		CALL	ECX
L8$:
		POPM	ECX,EDX

;		ALLMSG	'Return From Report ASCIZ'

		RET

REPORT_ASCIZ	ENDP


REPORT_OUT_ASCIZ	PROC
		;
		;ASCIZ IS OUTPUT FILENAME
		;
		RET

IF 0
		PUSHM	ES,DS,DX,CX,BX,AX
		FIXDS
		MOV	AX,TOOL_CALLBACKS._TCB_REPORT_FILE.OFFS
		MOV	BX,TOOL_CALLBACKS._TCB_REPORT_FILE.SEGM
		MOV	CX,SP
		OR	BX,BX
		JZ	8$
		MOV	SS,HOST_SS
		ASSUME	SS:NOTHING
		MOV	SP,HOST_SP
		PUSH	CX
		PUSHM	DS,OFF ASCIZ,0
		PUSHM	CS,OFF 5$
		PUSHM	BX,AX
		RETF

5$:
		POP	CX
		MOV	AX,DS
		MOV	SS,AX
		ASSUME	SS:DGROUP
		MOV	SP,CX
8$:
;		ALLMSG	'OUT FILE'
		POPM	AX,BX,CX,DX,DS,ES
		RET
ENDIF

REPORT_OUT_ASCIZ	ENDP


REPORT_CLOSE_ASCIZ	PROC
		;
		;ASCIZ IS OUTPUT FILENAME
		;
		RET

		PUSHM	EDX,ECX

		MOV	ECX,TOOL_CALLBACKS._TCB_REPORT_FILE

		TEST	ECX,ECX
		JZ	L8$

;		MOV	ASCIZ,0		;FOR 16-BIT, HAD TO SEND NUL FILENAME
;		PUSHM	OFF ASCIZ,1

		PUSHM	EAX,-1

		CALL	ECX
L8$:
		POPM	ECX,EDX

		RET

REPORT_CLOSE_ASCIZ	ENDP


TERMINATE_ALL_THREADS	PROC
		;
		;IF MAIN_THREAD STILL RUNNING, TERMINATE IT AND EXIT THIS THREAD
		;CAUSE WE WANT THIS TO HAPPEN ON HOST THREAD.
		;
		BITT	HOST_THREADED
		JNZ	L0$

		RET

L0$:
		XOR	EAX,EAX

		XCHG	EAX,MAIN_THREAD_HANDLE

		TEST	EAX,EAX
		JZ	L1$

		PUSH	EAX

		PUSH	MY_EVENT_HANDLE		;FREE HOST THREAD
		CALL	SetEvent		;IF IT STARTS, MAIN_THREAD_HANDLE ALREADY ZEROED...

		CALL	GetCurrentThreadId

		CMP	MAIN_THREAD_ID,EAX
		JZ	L05$

		POP	EAX

		PUSH	0		;THREAD EXIT CODE
		PUSH	EAX		;THIS IS ONLY ON FATAL ABORTS

		CALL	TerminateThread	;PROBABLY ME
L05$:
		PUSH	0
		CALL	ExitThread		;BUT NOT IF ERR_ABORT ON SOME OTHER THREAD...
L1$:
		SETT	CANCEL_REQUESTED	;MAP WILL EVENTUALLY STOP...
		;
		;FIRST STOP ANY MAP THREAD
		;
		XOR	EAX,EAX

		XCHG	EAX,MAP_THREAD_HANDLE

		TEST	EAX,EAX
		JZ	L2$

		PUSH	EAX		;THIS IS ONLY ON FATAL ABORTS & STOPS

		MOV	EAX,OFF SEGS_ORDERED_SEM	;MAKE SURE THREAD WAITS
		CALL	RELEASE_EAX

		MOV	EAX,OFF EXPS_DEFINED_SEM
		CALL	RELEASE_EAX

		MOV	EAX,OFF PUBS_DEFINED_SEM	;PUBLICS DEFINED
		CALL	RELEASE_EAX

		MOV	EAX,OFF MAPLINES_OK_SEM
		CALL	RELEASE_EAX

		MOV	EAX,OFF START_DEFINED_SEM	;START ADDRESS DEFINED
		CALL	RELEASE_EAX

		MOV	EAX,OFF XREF_OK_SEM		;DONE WITH SYMBOL ADDRESSES...
		CALL	RELEASE_EAX

if	any_overlays
		MOV	EAX,OFF SECTIONMAP_OK_SEM
		CALL	RELEASE_EAX
endif
		CALL	DO_DOSSLEEP_0

		CALL	CloseHandle
L2$:

		CALL	DO_DOSSLEEP_0
		CALL	DO_DOSSLEEP_0

		MOV	EAX,MAIN_THREAD_HANDLE_A

		TEST	EAX,EAX
		JZ	L15$

		PUSH	EAX
		CALL	CloseHandle
L15$:
		;
		;NEXT, TERMINATE ANY LIBRARY READER THREADS
		;
		BITT	OPREADS_DONE
		JNZ	L6$

		BITT	LIBS_DONE
		JNZ	L39$

		SETT	LIBS_DONE		;TELL LIB THREADS TO QUIT

		MOV	ESI,OFF LIB_THREAD_LOCALS
		MOV	EDI,N_R_THREADS
L21$:
		MOV	EBX,[ESI]
		ADD	ESI,4
		ASSUME	EBX:PTR MYL2_STRUCT

		TEST	EBX,EBX
		JZ	L219$
		;
		;DO WHATEVER IS NEEDED TO BUMP THIS THREAD TO CHECK LIBS_DONE FLAG
		;
		LEA	EAX,[EBX].MYL2_LIB_BLOCK_SEM
		CALL	RELEASE_EAX

		RELEASE	LIB_REQUEST_ORDER_SEM

		RELEASE	GLOBALALLOC_SEM			;IN CASE SOMEBODY STOPPED IN HERE...

L219$:
		DEC	EDI
		JNZ	L21$

		CALL	TERMINATE_OPREADS
		;
		;WAIT ON LIB_THREAD 'FINISHED' SEMAPHORES
		;
		MOV	ESI,OFF LIB_THREAD_LOCALS
		MOV	EBX,N_R_THREADS
L22$:
		LODSD

		TEST	EAX,EAX
		JZ	L229$

		MOV	EAX,[EAX].MYL2_STRUCT.MYL2_LIBREAD_THREAD_HANDLE

		PUSH	EAX		;XTRA HANDLE
		PUSH	-1		;FOREVER

		PUSH	EAX
		CALL	WaitForSingleObject

		CALL	CloseHandle	;CLOSE IT...
L229$:
		DEC	EBX
		JNZ	L22$
L39$:
		;
		;TERMINATE OPREAD THREADS ALSO
		;
		CALL	TERMINATE_OPREADS	;NORMALLY, SO THEY CLOSE FILES, RELEASE SEMAPHORES, ETC
		;
		;FINALLY, RELEASE THEIR STACKS...
		;
		MOV	ESI,OFF LIB_THREAD_LOCALS
		MOV	EBX,N_R_THREADS
L51$:
		XOR	ECX,ECX
		MOV	EDI,[ESI]

		MOV	[ESI],ECX
		ADD	ESI,4

		TEST	EDI,EDI
		JZ	L55$

		ASSUME	EDI:PTR MYL2_STRUCT
		MOV	EAX,[EDI].MYL2_LIB_BLOCK_SEM._SEM_ITSELF
		MOV	[EDI].MYL2_LIB_BLOCK_SEM._SEM_ITSELF,ECX

		TEST	EAX,EAX
		JZ	L52$

		PUSH	EAX
		CALL	CloseHandle
L52$:
		MOV	EAX,[EDI].MYL2_BLOCK_READ_SEM._SEM_ITSELF

		TEST	EAX,EAX
		JZ	L53$

		PUSH	EAX
		CALL	CloseHandle
L53$:
		MOV	EAX,EDI
		CALL	RELEASE_4K_SEGMENT
		ASSUME	EDI:NOTHING
L55$:
		DEC	EBX
		JNZ	L51$
L6$:
		RET


TERMINATE_ALL_THREADS	ENDP


CLOSE_FILES	PROC
		;
		;CLOSE ANY OPEN FILES
		;
		;WHAT MIGHT BE OPEN?  WE TERMINATED ALL READ THREADS.  MAYBE
		;LIBRARIES?
		;
		XOR	ECX,ECX
		MOV	EAX,EXE_DEVICE		;NOTHING THERE, DON'T NEED TO CLOSE IT...
		ASSUME	EAX:PTR MYO_STRUCT

		TEST	EAX,EAX
		JZ	L1$

		MOV	EDX,[EAX].MYO_HANDLE
		MOV	[EAX].MYO_HANDLE,ECX

		OR	EDX,EDX
		JZ	L1$

		MOV	EAX,EDX
		CALL	CLOSE_HANDLE
L1$:
		XOR	ECX,ECX
		MOV	EAX,MAP_DEVICE		;NOTHING THERE, DON'T NEED TO CLOSE IT...

		TEST	EAX,EAX
		JZ	L2$

		MOV	EDX,[EAX].MYO_HANDLE
		MOV	[EAX].MYO_HANDLE,ECX

		OR	EDX,EDX
		JZ	L2$

		MOV	EAX,EDX
		CALL	CLOSE_HANDLE
L2$:
		XOR	ECX,ECX
		MOV	EAX,OBJ_DEVICE		;NOTHING THERE, DON'T NEED TO CLOSE IT...
		ASSUME	EAX:PTR MYI_STRUCT

		TEST	EAX,EAX
		JZ	L3$

		MOV	EDX,[EAX].MYI_HANDLE
		MOV	[EAX].MYI_HANDLE,ECX

		OR	EDX,EDX
		JZ	L3$

		MOV	EAX,EDX
		CALL	CLOSE_HANDLE
L3$:
		ASSUME	EAX:NOTHING

		CALL	HANDLE_EOF

		CALL	END_OF_INDIRECT

		CALL	CLOSE_LIB_FILES

		RET

CLOSE_FILES	ENDP


CREATE_MANUAL_EVENT	PROC
		;
		;
		;
		PUSH	0		;NO NAME
		PUSH	0		;NOT SET INITIALLY
		PUSH	-1		;TRUE, MANUAL EVENT
		PUSH	0		;SECURITY

		CALL	CreateEvent

		RET

CREATE_MANUAL_EVENT	ENDP


CLOSE_MY_EVENTS	PROC

		XOR	ECX,ECX
		MOV	EAX,MY_EVENT_HANDLE

		TEST	EAX,EAX
		JZ	L1$

		MOV	MY_EVENT_HANDLE,ECX
		CALL	CLOSE_HANDLE
L1$:
		MOV	EAX,OFF ASCIZ1_SEM
		CALL	CLOSE_SEM

		MOV	EAX,OFF ERROR1_SEM
		CALL	CLOSE_SEM

		RET

CLOSE_MY_EVENTS	ENDP


CLOSE_SEM	PROC
		;
		;
		;
		MOV	EDX,EAX
		XOR	ECX,ECX

		ASSUME	EDX:PTR GLOBALSEM_STRUCT

		MOV	EAX,[EDX]._SEM_ITSELF

		TEST	EAX,EAX
		JZ	L5$

		MOV	[EDX]._SEM_ITSELF,ECX
		CALL	CLOSE_HANDLE
L5$:
		RET

CLOSE_SEM	ENDP


		.DATA

MAIN_THREAD_ID		DD	0
MAIN_THREAD_HANDLE	DD	0
MAIN_THREAD_HANDLE_A	DD	0
INITIALIZED_DATA_PTR	DD	0
MY_EVENT_HANDLE		DD	0
MY_TOOL_MESSAGE_STRUCT	TOOL_MESSAGE_STRUCT <>


		.DATA?

ASCIZ1			DB	512 DUP(?)
ASCIZ2			DB	512 DUP(?)
MY_TMSG_MSGTEXT		DB	512 DUP(?)
MY_TMSG_FILENAME	DB	512 DUP(?)

ASCIZ1_SEM		GLOBALSEM_STRUCT	<>
ERROR1_SEM		GLOBALSEM_STRUCT	<>


		END

