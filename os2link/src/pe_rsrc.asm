		TITLE	PE_RSRC - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS

if	fg_pe
		INCLUDE	EXES
		INCLUDE	PE_STRUC
		INCLUDE	RESSTRUC

		PUBLIC	PE_OUTPUT_RESOURCES


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE

		EXTERNDEF	PE_RSRC_OBJECT_GINDEX:DWORD,RESTYPE_BYNAME_GINDEX:DWORD,RESTYPE_BYORD_GINDEX:DWORD
		EXTERNDEF	RESTYPE_N_BYNAME:DWORD,RESTYPE_N_BYORD:DWORD,SEG_PAGE_SIZE_M1:DWORD,NOT_SEG_PAGE_SIZE_M1:DWORD
		EXTERNDEF	NEXT_RESOURCE_PTR:DWORD,NEXT_RESOURCE_MASTER_PTR:DWORD,PE_NEXT_OBJECT_RVA:DWORD,N_RTNLS:DWORD
		EXTERNDEF	FINAL_HIGH_WATER:DWORD,RESOURCE_NAME_OFFSET:DWORD,CURN_C_TIME:DWORD,RESOURCE_BLOCK_MASTER_PTRS:DWORD
		EXTERNDEF	N_RESTYPENAMES:DWORD,FIRST_RTNL_GINDEX:DWORD,RESOURCE_HASHES:DWORD
		EXTERNDEF	FIRST_RESNAME_GINDEX:DWORD

		EXTERNDEF	PEXEHEADER:PEXE,RTNL_GARRAY:STD_PTR_S,RESTYPE_GARRAY:STD_PTR_S,RES_TYPE_NAME_GARRAY:STD_PTR_S
		EXTERNDEF	RESNAME_GARRAY:STD_PTR_S,RESOURCE_STUFF:ALLOCS_STRUCT,PE_OBJECT_GARRAY:STD_PTR_S


		.CODE	PASS2_TEXT

		EXTERNDEF	CHANGE_PE_OBJECT:PROC,DO_OBJECT_ALIGN:PROC,MOVE_EAX_TO_FINAL_HIGH_WATER:PROC,RELEASE_GARRAY:PROC
		EXTERNDEF	MOVE_EAX_TO_EDX_FINAL:PROC,_release_minidata:proc,COPY_RESOURCE_TO_FINAL:PROC,ERR_ABORT:PROC
		EXTERNDEF	DWORD_ALIGN_FINAL:PROC,RELEASE_EAX_BUFFER:PROC,TQUICK_RESNAMES:PROC,TERMINATE_OPREADS:PROC
		EXTERNDEF	INIT_RES_SORT:PROC,RES_SORT:PROC,STORE_RES_ECXEAX:PROC,READ_SIZE_RESOURCES:PROC,SET_RESOURCE_PTR:PROC
		EXTERNDEF	RELEASE_RESOURCES:PROC,RELEASE_BLOCK:PROC

		EXTERNDEF	RES_CONV_ERR:ABS,VERSION_BIG_ERR:ABS


TDE_BUFSIZE		EQU	64
TNDE_BUFSIZE		EQU	128
TNLDE_BUFSIZE		EQU	128
RD_ENTRIES_BUFSIZE	EQU	256


RSRC_VARS	STRUC

QN_BUFFER_BP		DD	256K/(page_size/4) DUP(?)	;256K SYMBOLS SORTING

TDE_BUFFER_BP		DB	TDE_BUFSIZE DUP(?)
TNDE_BUFFER_BP		DB	TNDE_BUFSIZE DUP(?)
TNLDE_BUFFER_BP		DB	TNLDE_BUFSIZE DUP(?)
RD_ENTRIES_BUFFER_BP	DB	RD_ENTRIES_BUFSIZE DUP(?)

TDE_PTR_BP		DD	?
TDE_OUTPUT_FA_BP	DD	?

TNDE_PTR_BP		DD	?
TNDE_OUTPUT_FA_BP	DD	?
NEXT_TNDE_OFFSET_BP	DD	?

TNLDE_PTR_BP		DD	?
TNLDE_OUTPUT_FA_BP	DD	?
NEXT_TNLDE_OFFSET_BP	DD	?

RSTRINGS_OUTPUT_FA_BP	DD	?
RSTRINGS_OFFSET_BP	DD	?

RDENTRIES_PTR_BP	DD	?
RDENTRIES_OUTPUT_FA_BP	DD	?
RDENTRIES_OFFSET_BP	DD	?

RES_DATA_RVA_BP		DD	?
CURN_RTNL_GINDEX_BP	DD	?

RES_PUT_PTR_BP		DD	?
PUT_BYTES_LEFT_BP	DD	?
CONV_BYTES_LEFT_BP	DD	?
ITEM_COUNT_BP		DD	?

WM_BLK_PTR_BP		DD	?
WM_CNT_BP		DD	?
WM_PTR_BP		DD	?
WM_PTR_LIMIT_BP		DD	?

RSRC_VARS	ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE RSRC_VARS].(X&_BP))

	ENDM


FIX	QN_BUFFER
FIX	TDE_BUFFER
FIX	TNDE_BUFFER
FIX	TNLDE_BUFFER
FIX	RD_ENTRIES_BUFFER

FIX	TDE_PTR
FIX	TDE_OUTPUT_FA

FIX	TNDE_PTR
FIX	TNDE_OUTPUT_FA
FIX	NEXT_TNDE_OFFSET

FIX	TNLDE_PTR
FIX	TNLDE_OUTPUT_FA
FIX	NEXT_TNLDE_OFFSET

FIX	RSTRINGS_OUTPUT_FA
FIX	RSTRINGS_OFFSET

FIX	RDENTRIES_PTR
FIX	RDENTRIES_OUTPUT_FA
FIX	RDENTRIES_OFFSET

FIX	RES_DATA_RVA
FIX	CURN_RTNL_GINDEX

FIX	RES_PUT_PTR
FIX	PUT_BYTES_LEFT
FIX	CONV_BYTES_LEFT
FIX	ITEM_COUNT

FIX	WM_BLK_PTR
FIX	WM_CNT
FIX	WM_PTR
FIX	WM_PTR_LIMIT


PE_OUTPUT_RESOURCES	PROC
		;
		;IF THERE ARE ANY...
		;
		MOV	EAX,PE_RSRC_OBJECT_GINDEX

		OR	EAX,EAX
		JNZ	L1$

		RET

L1$:
		CALL	READ_SIZE_RESOURCES
if	fgh_inthreads
		CALL	TERMINATE_OPREADS	;TERMINATE ALL OPREAD THREADS
endif
		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBP,ESP
		SUB	ESP,SIZE RSRC_VARS
		ASSUME	EBP:PTR RSRC_VARS

		LEA	EAX,TDE_BUFFER
		LEA	ECX,TNDE_BUFFER

		MOV	TDE_PTR,EAX
		MOV	TNDE_PTR,ECX

		LEA	EAX,TNLDE_BUFFER
		LEA	ECX,RD_ENTRIES_BUFFER

		MOV	TNLDE_PTR,EAX
		MOV	RDENTRIES_PTR,ECX

		CALL	CHANGE_PE_OBJECT
		ASSUME	EAX:PTR PE_OBJECT_STRUCT

		MOV	DPTR [EAX]._PEOBJECT_NAME,'rsr.'

		MOV	BPTR [EAX]._PEOBJECT_NAME+4,'c'

		MOV	[EAX]._PEOBJECT_FLAGS,MASK PEL_INIT_DATA_OBJECT + MASK PEH_READABLE

		MOV	ECX,PE_NEXT_OBJECT_RVA
		MOV	EBX,RESTYPE_N_BYNAME

		MOV	[EAX]._PEOBJECT_RVA,ECX
		MOV	EAX,FINAL_HIGH_WATER
		ASSUME	EAX:NOTHING

		MOV	PEXEHEADER._PEXE_RESOURCE_RVA,ECX
		MOV	ECX,RESTYPE_N_BYORD
		;
		;CALCULATE HEADER SIZE, SO WE KNOW WHERE TO START WRITING RESOURCES
		;
		MOV	TDE_OUTPUT_FA,EAX
		ADD	EBX,ECX

		SHL	EBX,3				;SIZE OF LEVEL 1 STUFF IS 8*N_TYPES + 16*1
		MOV	EAX,TDE_OUTPUT_FA

		ADD	EBX,SIZE RES_DIRTABLE_STRUCT	;EBX IS OFFSET TO LEVEL 2 ENTRIES
		MOV	ECX,80000000H

		ADD	EAX,EBX
		ADD	ECX,EBX

		MOV	TNDE_OUTPUT_FA,EAX
		MOV	EAX,RESTYPE_N_BYNAME		;SIZE OF LEVEL 2 STUFF IS 16*N_TYPES + 8*N_TYPENAMES

		ADD	EAX,RESTYPE_N_BYORD

		SHL	EAX,4
		MOV	NEXT_TNDE_OFFSET,ECX

		ADD	EBX,EAX
		MOV	EAX,N_RESTYPENAMES

		SHL	EAX,3
		MOV	ECX,80000000H

		ADD	EBX,EAX				;EBX IS SIZE OF LEVEL 1 + LEVEL 2
		MOV	EAX,TDE_OUTPUT_FA

		ADD	ECX,EBX
		ADD	EAX,EBX

		MOV	NEXT_TNLDE_OFFSET,ECX
		MOV	TNLDE_OUTPUT_FA,EAX

		MOV	EAX,N_RESTYPENAMES		;SIZE OF LEVEL 3 STUFF IS 16*N_TYPENAMES + 8*N_RTNLS

		SHL	EAX,4
		MOV	ECX,N_RTNLS

		SHL	ECX,3
		ADD	EBX,EAX

		MOV	EAX,TDE_OUTPUT_FA
		ADD	EBX,ECX				;EBX IS SIZE OF LEVEL 1 + LEVEL 2 + LEVEL 3

		ADD	EAX,EBX
		MOV	ECX,80000000H

		MOV	RSTRINGS_OUTPUT_FA,EAX
		MOV	EAX,RESOURCE_NAME_OFFSET	;LENGTH OF STRINGS IF ASCIZ

		ADD	ECX,EBX
		ADD	EAX,EAX				;TIMES 2 FOR UNICODE

		MOV	RSTRINGS_OFFSET,ECX
		ADD	EAX,3				;DWORD ALIGN

		AND	AL,0FCH
		MOV	ECX,TDE_OUTPUT_FA

		ADD	EBX,EAX
		MOV	EAX,N_RTNLS

		ADD	ECX,EBX
		MOV	RDENTRIES_OFFSET,EBX

		SHL	EAX,4
		MOV	RDENTRIES_OUTPUT_FA,ECX

		ADD	EBX,EAX				;TOTAL SIZE BEFORE RESOURCES THEMSELVES
		MOV	EAX,TDE_OUTPUT_FA

		MOV	EDX,PEXEHEADER._PEXE_RESOURCE_RVA
		ADD	EAX,EBX

		ADD	EDX,EBX
		MOV	FINAL_HIGH_WATER,EAX

		MOV	RES_DATA_RVA,EDX
		CALL	OUTPUT_RESOURCES

		MOV	EAX,FINAL_HIGH_WATER
		MOV	EDX,TDE_OUTPUT_FA

		SUB	EAX,EDX
		MOV	ESI,PE_RSRC_OBJECT_GINDEX

		MOV	PEXEHEADER._PEXE_RESOURCE_SIZE,EAX

		DO_FILE_ALIGN_EAX

		CONVERT	ESI,ESI,PE_OBJECT_GARRAY
		ASSUME	ESI:PTR PE_OBJECT_STRUCT

		MOV	[ESI]._PEOBJECT_VSIZE,EAX
		MOV	EDX,PEXEHEADER._PEXE_RESOURCE_RVA

		ADD	EAX,EDX
		CALL	DO_OBJECT_ALIGN

		MOV	PE_NEXT_OBJECT_RVA,EAX
		CALL	OUTPUT_HEADER

		CALL	RELEASE_RESOURCES		;BEFORE RESOURCE_STUFF
	
		MOV	EAX,OFF RESOURCE_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF RESTYPE_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RESNAME_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RES_TYPE_NAME_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RTNL_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,RESOURCE_HASHES
		CALL	RELEASE_BLOCK

		MOV	ESP,EBP

		POPM	EBX,ESI,EDI,EBP

		RET

PE_OUTPUT_RESOURCES	ENDP


OUTPUT_RESOURCES	PROC	NEAR
		;
		;START WITH FIRST RTNL, OUTPUT TO FINAL
		;
		MOV	ESI,FIRST_RTNL_GINDEX
		JMP	L8$

L1$:
		MOV	CURN_RTNL_GINDEX,ESI
		CONVERT	ESI,ESI,RTNL_GARRAY
		ASSUME	ESI:PTR RTNL_STRUCT
		MOV	ECX,RES_DATA_RVA

		MOV	EAX,[ESI]._RTNL_FILE_ADDRESS
		MOV	[ESI]._RTNL_FILE_ADDRESS,ECX

		MOV	ECX,[ESI]._RTNL_FILE_SIZE
		MOV	EDX,[ESI]._RTNL_FLAGS

		AND	DL,1
		JNZ	L3$			;NORMAL 32-BIT, NO CONVERSION NECESSARY
		;
		;SEE IF IT IS ONE I KNOW HOW TO CONVERT
		;
		CALL	COPY_16_TO_32
		JMP	L4$

L3$:
		PUSH	ECX
		CALL	COPY_RESOURCE_TO_FINAL

		POP	EAX			;RESOURCE SIZE
L4$:
		ADD	EAX,3			;DWORD ALIGN IT
		MOV	ECX,RES_DATA_RVA

		AND	AL,0FCH
		MOV	ESI,[ESI]._RTNL_NEXT_GINDEX

		ADD	EAX,ECX

		MOV	RES_DATA_RVA,EAX
		CALL	DWORD_ALIGN_FINAL
L8$:
		TEST	ESI,ESI
		JNZ	L1$

		RET

OUTPUT_RESOURCES	ENDP


COPY_16_TO_32	PROC	NEAR
		;
		;ESI IS RTNL
		;ECX IS SIZE IN INPUT FILE
		;EAX IS FILE ADDRESS
		;
		MOV	RES_PUT_PTR,OFF TEMP_RECORD

		MOV	PUT_BYTES_LEFT,MAX_RECORD_LEN

		PUSHM	EDI,ESI,EBX
		MOV	EDI,[ESI]._RTNL_TYPE_ID

		MOV	CONV_BYTES_LEFT,ECX
		MOV	ECX,FINAL_HIGH_WATER

		PUSH	ECX
		CALL	SET_RESOURCE_PTR	;EAX+ECX POINTS

		CMP	EDI,16
		JBE	L1$

		XOR	EDI,EDI
L1$:
		MOV	EBX,EAX
		MOV	ESI,ECX

		CALL	COPY_16_32_TBL[EDI*4]

		MOV	ESI,CURN_RTNL_GINDEX
		CONVERT	ESI,ESI,RTNL_GARRAY
		ASSUME	ESI:PTR RTNL_STRUCT

		CALL	FLUSH_PUT_BUFFER
		;
		;NOW, UPDATE LENGTH IN RTNL STRUCTURE
		;
		POP	ECX
		MOV	EAX,FINAL_HIGH_WATER

		SUB	EAX,ECX
		POP	EBX

		MOV	[ESI]._RTNL_FILE_SIZE,EAX
		POP	ESI

		POP	EDI

		RET

		ASSUME	ESI:NOTHING

COPY_16_TO_32	ENDP


		.CONST

		ALIGN	4

COPY_16_32_TBL	LABEL	DWORD

		DD	COPY_STRAIGHT		;TYPE 0, UNKNOWN
		DD	COPY_STRAIGHT		;TYPE 1, CURSOR, NO CHANGE
		DD	COPY_STRAIGHT		;TYPE 2, BITMAPS, NO CHANGE
		DD	COPY_STRAIGHT		;TYPE 3, ICONS, NO CHANGE
		DD	COPY_MENU_1632		;TYPE 4, MENU, TRANSLATE
		DD	COPY_DIALOG_1632	;TYPE 5, DIALOG BOX, TRANSLATE
		DD	COPY_STRINGS_1632	;TYPE 6, STRINGS, TRANSLATE
		DD	COPY_STRAIGHT		;TYPE 7, FONTDIR, NO CHANGE
		DD	COPY_STRAIGHT		;TYPE 8, FONT, TRANSLATE
		DD	COPY_ACCELERATORS_1632	;TYPE 9, ACCELERATORS, TRANSLATE
		DD	COPY_STRAIGHT		;TYPE 10, RCDATA, NO CHANGE
		DD	COPY_STRAIGHT		;TYPE 11, ERRTABLE, NO CHANGE
		DD	COPY_STRAIGHT		;ACCORDING TO WALTER;COPY_CURSOR_HEADER_1632	;TYPE 12, GROUP CURSOR, TRANSLATE
		DD	COPY_STRAIGHT		;TYPE 13, ???, NO CHANGE
		DD	COPY_STRAIGHT		;ACCORDING TO WALTER;ICON_HEADER_1632	;TYPE 14, GROUP ICON, TRANSLATE
		DD	COPY_STRAIGHT		;TYPE 15, NAME TABLE, NO CHANGE
		DD	COPY_VERSION_1632	;TYPE 16, VERSION, TRANSLATE


		.CODE	PASS2_TEXT

COPY_STRAIGHT	PROC	NEAR
		;
		;JUST MOVE THEM INTACT
		;
		MOV	EAX,CONV_BYTES_LEFT
		JMP	MOVE_EAX_BYTES_FINAL_1632

COPY_STRAIGHT	ENDP


COPY_MENU_1632	PROC	NEAR
		;
		;
		;
		CALL	MOVE_DWORD_1632
		JMP	L5$

L1$:
		CALL	GET_WORD_1632

		CALL	PUT_WORD_1632

		TEST	AL,10H		;IS IT A POPUP?
		JNZ	L2$

		CALL	MOVE_WORD_1632
L2$:
		CALL	MOVE_ASCIZ_1632
L5$:
		MOV	EAX,CONV_BYTES_LEFT

		OR	EAX,EAX
		JNZ	L1$

		RET

COPY_MENU_1632	ENDP


COPY_DIALOG_1632	PROC	NEAR
		;
		;
		;
		CALL	GET_DWORD_1632

		PUSH	EAX
		CALL	PUT_DWORD_1632	;STYLE

		XOR	EAX,EAX
		CALL	PUT_DWORD_1632	;EXTENDED STYLE

		XOR	EAX,EAX
		CALL	GET_BYTE_1632

		MOV	ITEM_COUNT,EAX
		CALL	PUT_WORD_1632	;NUMBER OF ITEMS

		CALL	MOVE_DWORD_1632	;X, Y
		CALL	MOVE_DWORD_1632	;CX, CY

		CALL	MOVE_NAMEORD_1632	;MENU NAME
		CALL	MOVE_NAMEORD_1632	;CLASS NAME

		CALL	MOVE_ASCIZ_1632	;CAPTION

		POP	EAX

		TEST	AL,40H		;FONT?
		JZ	L1$

		CALL	MOVE_WORD_1632	;POINTSIZE
		CALL	MOVE_ASCIZ_1632	;FONTNAME
L1$:
		MOV	EAX,ITEM_COUNT

		OR	EAX,EAX
		JZ	L9$
L2$:
		CALL	PUT_DWORD_BOUNDARY	;ASSURE DWORD BOUNDARY

		CALL	GET_DWORD_1632

		MOV	DPTR TDE_BUFFER,EAX
		CALL	GET_DWORD_1632

		MOV	DPTR TDE_BUFFER+4,EAX
		CALL	GET_WORD_1632

		MOV	DPTR TDE_BUFFER+8,EAX
		CALL	MOVE_DWORD_1632		;STYLE

		XOR	EAX,EAX
		CALL	PUT_DWORD_1632		;EXTENDED STYLE

		MOV	EAX,DPTR TDE_BUFFER
		CALL	PUT_DWORD_1632		;X, Y

		MOV	EAX,DPTR TDE_BUFFER+4
		CALL	PUT_DWORD_1632		;CX, CY

		MOV	EAX,DPTR TDE_BUFFER+8
		CALL	PUT_WORD_1632		;ID

		XOR	EAX,EAX
		CALL	GET_BYTE_1632		;USUALLY 8XH

		TEST	AL,80H
		JZ	L3$

		SHL	EAX,16

		OR	EAX,0FFFFH
		CALL	PUT_DWORD_1632

		JMP	L4$

L3$:
		CALL	UNGET_BYTE_1632

		CALL	MOVE_ASCIZ_1632
L4$:
		CALL	MOVE_NAMEORD_1632	;TEXT

		CALL	GET_BYTE_1632

		XOR	AH,AH
		CALL	PUT_WORD_1632		;N EXTRA BYTES

		DEC	ITEM_COUNT
		JNZ	L2$
L9$:
		RET

COPY_DIALOG_1632	ENDP


COPY_STRINGS_1632	PROC	NEAR
		;
		;COPY 16 STRINGS
		;
		MOV	EDI,16
L1$:
		CALL	MOVE_PASCAL_1632

		DEC	EDI
		JNZ	L1$

		RET

COPY_STRINGS_1632	ENDP


COPY_ACCELERATORS_1632	PROC	NEAR
		;
		;CHANGE 5 BYTES TO 8
		;
		JMP	L8$

L1$:
		CALL	GET_BYTE_1632

		XOR	AH,AH
		CALL	PUT_WORD_1632

		CALL	MOVE_DWORD_1632

		XOR	EAX,EAX
		CALL	PUT_WORD_1632
L8$:
		MOV	EAX,CONV_BYTES_LEFT

		OR	EAX,EAX
		JNZ	L1$

		RET

COPY_ACCELERATORS_1632	ENDP


COPY_VERSION_1632	PROC	NEAR
		;
		;
		;
		MOV	AL,VERSION_BIG_ERR
		CALL	ERR_ABORT
		RET

COPY_VERSION_1632	ENDP


MOVE_EAX_BYTES_FINAL_1632	PROC	NEAR
		;
		;NEED TO MOVE SMALLER OF EAX AND PAGE_SIZE-ESI
		;
		MOV	ECX,CONV_BYTES_LEFT
		MOV	EDX,EAX

		SUB	ECX,EAX
		JC	L9$

		MOV	CONV_BYTES_LEFT,ECX
L1$:
		PUSH	EDX
		MOV	ECX,PAGE_SIZE

		SUB	ECX,ESI
		LEA	EAX,[EBX+ESI]

		CMP	ECX,EDX
		JB	L5$

		MOV	ECX,EDX
L5$:
		PUSH	ECX
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POP	ECX			;# ACTUALLY MOVED
		POP	EDX

		ADD	ESI,ECX
		SUB	EDX,ECX

		JNZ	L3$

		RET

L3$:
		;
		;GET NEXT BLOCK
		;
		PUSH	EDX
		CALL	ADJUST_RESOURCE_PTR

		POP	EDX
		JMP	L1$

L9$:
CONV_FAIL::
		MOV	AL,RES_CONV_ERR
		CALL	ERR_ABORT

MOVE_EAX_BYTES_FINAL_1632	ENDP


MOVE_EAX_BYTES_1632	PROC	NEAR
		;
		;NEED TO MOVE SMALLER OF DX:AX AND PAGE_SIZE-SI
		;
		MOV	ECX,CONV_BYTES_LEFT
		MOV	EDX,EAX

		SUB	ECX,EAX
		JC	CONV_FAIL

		MOV	CONV_BYTES_LEFT,ECX

L1$:
		PUSH	EDX
		MOV	ECX,PAGE_SIZE

		SUB	ECX,ESI
		LEA	EAX,[ESI+EBX]

		CMP	ECX,EDX
		JB	L5$

		MOV	ECX,EDX
L5$:
		PUSH	ECX
		CALL	MOVE_EAX_TO_PUT_PTR

		POP	ECX			;# ACTUALLY MOVED
		POP	EDX

		ADD	ESI,ECX
		SUB	EDX,ECX

		JNZ	L3$

		RET

L3$:
		;
		;GET NEXT BLOCK
		;
		PUSH	EDX
		CALL	ADJUST_RESOURCE_PTR

		POP	EDX
		JMP	L1$

MOVE_EAX_BYTES_1632	ENDP


GET_DWORD_1632	PROC	NEAR
		;
		;
		;
		CMP	ESI,PAGE_SIZE-4
		JA	L5$

		MOV	ECX,CONV_BYTES_LEFT
		MOV	EAX,[EBX+ESI]

		ADD	ESI,4
		SUB	ECX,4

		MOV	CONV_BYTES_LEFT,ECX
		JC	L9$

		RET

L5$:
		XOR	EAX,EAX
		CALL	GET_WORD_1632

		PUSH	EAX
		CALL	GET_WORD_1632

		SHL	EAX,16
		POP	ECX

		OR	EAX,ECX

		RET

L9$:
		JMP	CONV_FAIL

GET_DWORD_1632	ENDP


GET_WORD_1632	PROC	NEAR

		CMP	ESI,PAGE_SIZE-2
		JA	L5$

		MOV	ECX,CONV_BYTES_LEFT
		MOV	AL,[EBX+ESI]

		MOV	AH,[EBX+ESI+1]
		ADD	ESI,2

		SUB	ECX,2
		JC	L9$

		MOV	CONV_BYTES_LEFT,ECX

		RET

L5$:
		XOR	AH,AH
		CALL	GET_BYTE_1632

		PUSH	EAX
		CALL	GET_BYTE_1632

		MOV	AH,AL
		POP	ECX

		MOV	AL,CL

		RET

L9$:
		JMP	CONV_FAIL

GET_WORD_1632	ENDP


GET_BYTE_1632	PROC	NEAR
		;
		;
		;
L1$:
		CMP	ESI,PAGE_SIZE-1
		JA	L5$

		MOV	AL,[EBX+ESI]
		MOV	ECX,CONV_BYTES_LEFT

		INC	ESI
		DEC	ECX

		MOV	CONV_BYTES_LEFT,ECX
		JS	L9$

		RET

L5$:
		PUSH	EAX
		CALL	ADJUST_RESOURCE_PTR

		POP	EAX
		JMP	L1$

L9$:
		JMP	CONV_FAIL

GET_BYTE_1632	ENDP


UNGET_BYTE_1632	PROC	NEAR
		;
		;
		;
		ADD	CONV_BYTES_LEFT,1
		DEC	ESI

		RET

UNGET_BYTE_1632	ENDP


MOVE_BYTE_1632	PROC	NEAR
		;
		;
		;
		CALL	GET_BYTE_1632
;		CALL	PUT_BYTE_1632
;		RET

MOVE_BYTE_1632	ENDP


PUT_BYTE_1632	PROC	NEAR
		;
		;
		;
L1$:
		MOV	ECX,PUT_BYTES_LEFT
		MOV	EDX,RES_PUT_PTR

		DEC	ECX
		JS	L5$

		MOV	[EDX],AL
		INC	EDX

		MOV	PUT_BYTES_LEFT,ECX
		MOV	RES_PUT_PTR,EDX

		RET

L5$:
		PUSH	EAX
		CALL	FLUSH_PUT_BUFFER

		POP	EAX
		JMP	L1$

PUT_BYTE_1632	ENDP


MOVE_WORD_1632	PROC	NEAR
		;
		;
		;
		CALL	GET_WORD_1632
;		CALL	PUT_WORD_1632
;		RET

MOVE_WORD_1632	ENDP


PUT_WORD_1632	PROC	NEAR
		;
		;
		;
L1$:
		MOV	ECX,PUT_BYTES_LEFT
		MOV	EDX,RES_PUT_PTR

		SUB	ECX,2
		JC	L5$

		MOV	[EDX],AX
		ADD	EDX,2

		MOV	PUT_BYTES_LEFT,ECX
		MOV	RES_PUT_PTR,EDX

		RET

L5$:
		PUSH	EAX
		CALL	FLUSH_PUT_BUFFER

		POP	EAX
		JMP	L1$

PUT_WORD_1632	ENDP


MOVE_DWORD_1632	PROC	NEAR
		;
		;
		;
		CALL	GET_DWORD_1632
;		CALL	PUT_DWORD_1632
;		RET

MOVE_DWORD_1632	ENDP


PUT_DWORD_1632	PROC	NEAR
		;
		;
		;
L1$:
		MOV	ECX,PUT_BYTES_LEFT
		MOV	EDX,RES_PUT_PTR

		SUB	ECX,4
		JC	L5$

		MOV	[EDX],EAX
		ADD	EDX,4

		MOV	PUT_BYTES_LEFT,ECX
		MOV	RES_PUT_PTR,EDX

		RET

L5$:
		PUSH	EAX
		CALL	FLUSH_PUT_BUFFER

		POP	EAX
		JMP	L1$

PUT_DWORD_1632	ENDP


MOVE_EAX_TO_PUT_PTR	PROC	NEAR
		;
		;
		;
L1$:
		MOV	EDX,PUT_BYTES_LEFT
		PUSH	EDI

		SUB	EDX,ECX
		JC	L5$

		PUSH	ESI
		MOV	PUT_BYTES_LEFT,EDX

		MOV	EDI,RES_PUT_PTR
		MOV	ESI,EAX

		OPTI_MOVSB

		MOV	RES_PUT_PTR,EDI

		POPM	ESI,EDI

		RET

L5$:
		POP	EDI
		PUSH	ECX

		PUSH	EAX
		CALL	FLUSH_PUT_BUFFER

		POPM	EAX,ECX

		JMP	L1$

MOVE_EAX_TO_PUT_PTR	ENDP


MOVE_ASCIZ_1632	PROC	NEAR
		;
		;
		;
L1$:
		XOR	EAX,EAX
		CALL	GET_BYTE_1632

		OR	AL,AL
		JZ	PUT_WORD_1632

		CALL	PUT_WORD_1632

		JMP	L1$

MOVE_ASCIZ_1632	ENDP


MOVE_PASCAL_1632	PROC	NEAR
		;
		;
		;
		XOR	EAX,EAX
		CALL	GET_BYTE_1632		;FIRST COMES LENGTH IN BYTES

		PUSH	EDI
		MOV	EDI,EAX

		CALL	PUT_WORD_1632		;BECOMES WORD LENGTH IN WORDS

		OR	EDI,EDI
		JZ	L9$
L1$:
		CALL	GET_BYTE_1632

		XOR	AH,AH
		CALL	PUT_WORD_1632

		DEC	EDI
		JNZ	L1$
L9$:
		POP	EDI

		RET

MOVE_PASCAL_1632	ENDP


MOVE_NAMEORD_1632	PROC	NEAR
		;
		;
		;
		XOR	EAX,EAX
		CALL	GET_BYTE_1632

		CMP	AL,-1
		JNZ	L5$

		MOV	AH,-1
		CALL	PUT_WORD_1632

		JMP	MOVE_WORD_1632

L4$:
		CALL	PUT_WORD_1632

		CALL	GET_BYTE_1632
L5$:
		OR	AL,AL
		JNZ	L4$

		JMP	PUT_WORD_1632

MOVE_NAMEORD_1632	ENDP


PUT_DWORD_BOUNDARY	PROC	NEAR
		;
		;MAKE SURE FINAL_HIGH_WATER + PUT_BUFFER CONTENTS == DWORD BOUND
		;
		MOV	EAX,FINAL_HIGH_WATER
		MOV	EDX,RES_PUT_PTR

		XOR	ECX,ECX
		ADD	EAX,EDX

		SUB	ECX,EAX
		XOR	EAX,EAX

		AND	ECX,3
		JZ	L9$

		SHR	ECX,1
		JNC	L2$
		CALL	PUT_BYTE_1632
L2$:
		SHR	ECX,1
		JNC	L1$
		CALL	PUT_WORD_1632
L1$:
L9$:
		RET

PUT_DWORD_BOUNDARY	ENDP


FLUSH_PUT_BUFFER	PROC	NEAR
		;
		;
		;
		MOV	ECX,RES_PUT_PTR
		MOV	EAX,OFF TEMP_RECORD

		SUB	ECX,EAX
		JZ	L9$

		MOV	PUT_BYTES_LEFT,MAX_RECORD_LEN

		MOV	RES_PUT_PTR,EAX
		JMP	MOVE_EAX_TO_FINAL_HIGH_WATER

L9$:
		RET

FLUSH_PUT_BUFFER	ENDP


ADJUST_RESOURCE_PTR	PROC	NEAR
		;
		;
		;
		MOV	EBX,NEXT_RESOURCE_PTR
		MOV	ESI,RESOURCE_BLOCK_MASTER_PTRS

		MOV	EAX,NEXT_RESOURCE_MASTER_PTR
		ADD	EBX,4

		CMP	EBX,256
		JZ	L6$
L5$:
		MOV	ESI,[ESI+EAX]
		MOV	NEXT_RESOURCE_PTR,EBX

		MOV	EBX,[ESI+EBX]
		XOR	ESI,ESI

		RET

L6$:
		ADD	EAX,4
		XOR	EBX,EBX

		MOV	NEXT_RESOURCE_MASTER_PTR,EAX
		JMP	L5$

ADJUST_RESOURCE_PTR	ENDP


OUTPUT_HEADER	PROC	NEAR
		;
		;OUTPUT RESOURCE HEADER
		;
		MOV	EDI,TDE_PTR		;TYPE DIRECTORY-STUFF BUFFER
		MOV	EAX,RESTYPE_N_BYNAME

		MOV	ECX,RESTYPE_N_BYORD
		CALL	STORE_DIRECTORY_TABLE	;

		CALL	UPDATE_TDE_PTR		;

		CALL	SORT_RESNAMES		;FIRST SORT RESNAMES

		CALL	SORT_RESTYPES		;NOW, SORT RESTYPES

		MOV	EAX,RESTYPE_BYNAME_GINDEX
		CALL	DO_OUTPUT_TYPES		;OUTPUT ALL BYNAME TYPES

		MOV	EAX,RESTYPE_BYORD_GINDEX
		CALL	DO_OUTPUT_TYPES		;OUTPUT ALL BYORD TYPES

		CALL	FLUSH_TDE_BUFFER
		CALL	FLUSH_TNDE_BUFFER
		CALL	FLUSH_TNLDE_BUFFER
		CALL	FLUSH_RDENTRIES_BUFFER

;		CALL	DO_OUTPUT_STRINGS

;		RET

OUTPUT_HEADER	ENDP


DO_OUTPUT_STRINGS	PROC	NEAR
		;
		;USE ALL BUFFERS TO BUFFER STRINGS
		;
		MOV	ESI,FIRST_RESNAME_GINDEX
		JMP	L8$

L1$:
		CONVERT	ESI,ESI,RESNAME_GARRAY
		ASSUME	ESI:PTR RESNAME_STRUCT

		LEA	EBX,[ESI]._RN_UNITEXT
		LEA	EDI,TDE_BUFFER+2
L2$:
		MOV	EAX,[EBX]
		ADD	EBX,4

		MOV	[EDI],AX
		ADD	EDI,2

		TEST	EAX,0FFFFH
		JZ	L3$

		SHR	EAX,16

		MOV	[EDI],AX
		ADD	EDI,2

		OR	EAX,EAX
		JNZ	L2$
L3$:
		LEA	ECX,[EDI-2]
		LEA	EAX,TDE_BUFFER

		MOV	EDX,RSTRINGS_OUTPUT_FA
		SUB	ECX,EAX

		MOV	EBX,ECX
		MOV	EDI,ECX

		SHR	EBX,1
		ADD	EDI,EDX

		DEC	EBX
		MOV	RSTRINGS_OUTPUT_FA,EDI

		MOV	[EAX],BL
		MOV	ESI,[ESI]._RN_NEXT_RN_GINDEX

		MOV	[EAX+1],BH
		CALL	MOVE_EAX_TO_EDX_FINAL
L8$:
		TEST	ESI,ESI
		JNZ	L1$
		;
		;DWORD ALIGN STRINGS
		;
		XOR	ECX,ECX
		MOV	EDX,RSTRINGS_OUTPUT_FA

		SUB	ECX,EDX
		LEA	EAX,TDE_BUFFER

		AND	ECX,3
		JZ	L9$

		XOR	ESI,ESI

		MOV	[EAX],ESI
		JMP	MOVE_EAX_TO_EDX_FINAL
L9$:
		RET

DO_OUTPUT_STRINGS	ENDP


UPDATE_TDE_PTR	PROC	NEAR
		;
		;
		;
		LEA	EAX,TDE_BUFFER+TDE_BUFSIZE-16	;MAKE SURE ROOM FOR 16 MORE BYTES
		MOV	TDE_PTR,EDI

		CMP	EAX,EDI
		JB	FLUSH_TDE_BUFFER

		RET

UPDATE_TDE_PTR	ENDP


FLUSH_TDE_BUFFER	PROC	NEAR
		;
		;TDE_BUFFER IS FULL, EMPTY IT
		;
		MOV	ECX,TDE_PTR
		LEA	EAX,TDE_BUFFER

		SUB	ECX,EAX
		JZ	L9$

		MOV	TDE_PTR,EAX
		MOV	EDX,TDE_OUTPUT_FA

		ADD	TDE_OUTPUT_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_TDE_BUFFER	ENDP


STORE_DIRECTORY_TABLE	PROC	NEAR
		;
		;EDI POINTS TO DESTINATION
		;EAX:ECX ARE BYNAMES:BYORDS
		;
		ASSUME	EDI:PTR RES_DIRTABLE_STRUCT

		SHL	ECX,16

		OR	EAX,ECX
		XOR	ECX,ECX

		MOV	DPTR [EDI]._RDIRT_N_BYNAME,EAX
		MOV	[EDI]._RDIRT_CHARACTER,ECX

		MOV	EAX,CURN_C_TIME
		MOV	DPTR [EDI]._RDIRT_VERSION_MAJOR,ECX

		MOV	[EDI]._RDIRT_TIME_DATE,EAX
		ADD	EDI,SIZE RES_DIRTABLE_STRUCT

		RET

		ASSUME	EDI:NOTHING

STORE_DIRECTORY_TABLE	ENDP


DO_OUTPUT_TYPES	PROC	NEAR
		;
		;EAX IS GINDEX OF TYPE-LIST TO WRITE OUT
		;
		;FOR EACH TYPE IN THE LIST:
		;	OUTPUT A DIRECTORY ENTRY
		;	SORT MY TYPENAMES
		;	OUTPUT MY TYPENAMES
		;
		PUSHM	ESI,EBX

		MOV	ESI,EAX
		JMP	L8$

L1$:
		CONVERT	ESI,ESI,RESTYPE_GARRAY
		ASSUME	ESI:PTR RESTYPE_STRUCT

		MOV	EDI,TDE_PTR		;TYPE DIRECTORY_ENTRY PTR
		MOV	EAX,[ESI]._RT_ID_GINDEX

		MOV	EBX,NEXT_TNDE_OFFSET
		CALL	STORE_NAME_OR_ID
		;
		;STORE PTR TO TYPE-NAME DIRECTORY-TABLE
		;
		MOV	[EDI],EBX
		ADD	EDI,4

		CALL	UPDATE_TDE_PTR

		MOV	EDI,TNDE_PTR
		MOV	EAX,[ESI]._RT_N_RTN_BYNAME

		MOV	ECX,[ESI]._RT_N_RTN_BYORD
		CALL	STORE_DIRECTORY_TABLE

		MOV	EAX,SIZE RES_DIRTABLE_STRUCT
		CALL	UPDATE_TNDE_PTR

		MOV	EAX,ESI				;AX IS TYPE GINDEX
		CALL	SORT_RES_TYPENAMES		;RETURNS ECX & EAX AS TOP OF LISTS

		PUSH	ECX
		CALL	DO_OUTPUT_TYPENAMES

		POP	EAX
		CALL	DO_OUTPUT_TYPENAMES

		MOV	ESI,[ESI]._RT_NEXT_RT_GINDEX
L8$:
		TEST	ESI,ESI
		JNZ	L1$

		POPM	EBX,ESI

		RET

DO_OUTPUT_TYPES	ENDP


STORE_NAME_OR_ID	PROC	NEAR
		;
		;
		;
		CMP	EAX,64K
		JB	L3$

		CONVERT	EAX,EAX,RESNAME_GARRAY
		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	EAX,[EAX]._RN_OFFSET
		MOV	EDX,RSTRINGS_OFFSET

		LEA	EAX,[EDX+EAX*2]

L3$:
		MOV	[EDI],EAX
		ADD	EDI,4

		RET

STORE_NAME_OR_ID	ENDP


UPDATE_TNDE_PTR	PROC	NEAR
		;
		;
		;
		MOV	EDX,NEXT_TNDE_OFFSET
		MOV	TNDE_PTR,EDI

		ADD	EDX,EAX
		LEA	EAX,TNDE_BUFFER+TNDE_BUFSIZE-16	;MAKE SURE ROOM FOR 16 MORE BYTES

		MOV	NEXT_TNDE_OFFSET,EDX
		CMP	EAX,EDI

		JB	FLUSH_TNDE_BUFFER

		RET

UPDATE_TNDE_PTR	ENDP


FLUSH_TNDE_BUFFER	PROC	NEAR
		;
		;TNDE_BUFFER IS FULL, EMPTY IT
		;
		MOV	ECX,TNDE_PTR
		LEA	EAX,TNDE_BUFFER

		SUB	ECX,EAX
		JZ	L9$

		MOV	TNDE_PTR,EAX
		MOV	EDX,TNDE_OUTPUT_FA

		ADD	TNDE_OUTPUT_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_TNDE_BUFFER	ENDP


UPDATE_TNLDE_PTR	PROC	NEAR
		;
		;
		;
		MOV	EDX,NEXT_TNLDE_OFFSET
		MOV	TNLDE_PTR,EDI

		ADD	EDX,EAX
		LEA	EAX,TNLDE_BUFFER+TNLDE_BUFSIZE-16	;MAKE SURE ROOM FOR 16 MORE BYTES

		MOV	NEXT_TNLDE_OFFSET,EDX
		CMP	EAX,EDI

		JB	FLUSH_TNLDE_BUFFER

		RET

UPDATE_TNLDE_PTR	ENDP


FLUSH_TNLDE_BUFFER	PROC	NEAR
		;
		;TNDE_BUFFER IS FULL, EMPTY IT
		;
		MOV	ECX,TNLDE_PTR
		LEA	EAX,TNLDE_BUFFER

		SUB	ECX,EAX
		JZ	L9$

		MOV	TNLDE_PTR,EAX
		MOV	EDX,TNLDE_OUTPUT_FA

		ADD	TNLDE_OUTPUT_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_TNLDE_BUFFER	ENDP


UPDATE_RDENTRIES_PTR	PROC	NEAR
		;
		;
		;
		MOV	EDX,RDENTRIES_OFFSET
		MOV	RDENTRIES_PTR,EDI

		ADD	EDX,EAX
		LEA	EAX,RD_ENTRIES_BUFFER+RD_ENTRIES_BUFSIZE-16	;MAKE SURE ROOM FOR 16 MORE BYTES

		MOV	RDENTRIES_OFFSET,EDX
		CMP	EAX,EDI

		JB	FLUSH_RDENTRIES_BUFFER

		RET

UPDATE_RDENTRIES_PTR	ENDP


FLUSH_RDENTRIES_BUFFER	PROC	NEAR
		;
		;TNDE_BUFFER IS FULL, EMPTY IT
		;
		LEA	EAX,RD_ENTRIES_BUFFER
		MOV	ECX,RDENTRIES_PTR

		SUB	ECX,EAX
		JZ	L9$

		MOV	RDENTRIES_PTR,EAX
		MOV	EDX,RDENTRIES_OUTPUT_FA

		ADD	RDENTRIES_OUTPUT_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_RDENTRIES_BUFFER	ENDP


DO_OUTPUT_TYPENAMES	PROC	NEAR
		;
		;AX IS GINDEX OF TYPENAME-LIST TO WRITE OUT
		;
		;FOR EACH TYPENAME IN THE LIST:
		;	OUTPUT A DIRECTORY ENTRY
		;	SORT MY TYPENAMELANGS
		;	OUTPUT MY TYPENAMELANGS
		;
		PUSH	ESI
		MOV	ESI,EAX

		TEST	ESI,ESI
		JZ	L9$
L1$:
		CONVERT	ESI,ESI,RES_TYPE_NAME_GARRAY
		ASSUME	ESI:PTR RES_TYPE_NAME_STRUCT

		MOV	EDI,TNDE_PTR		;TYPENAME DIRECTORY_ENTRY PTR
		MOV	EAX,[ESI]._RTN_ID_GINDEX

		MOV	EBX,NEXT_TNLDE_OFFSET
		CALL	STORE_NAME_OR_ID
		;
		;STORE PTR TO TYPE-NAME DIRECTORY-TABLE
		;
		MOV	[EDI],EBX
		ADD	EDI,4

		MOV	EAX,8
		CALL	UPDATE_TNDE_PTR

		MOV	EDI,TNLDE_PTR
		XOR	EAX,EAX				;ZERO BY NAME

		MOV	ECX,[ESI]._RTN_N_RTNL		;BY ID
		CALL	STORE_DIRECTORY_TABLE

		MOV	EAX,SIZE RES_DIRTABLE_STRUCT
		CALL	UPDATE_TNLDE_PTR

		MOV	EAX,ESI				;AX IS TYPENAME GINDEX
		CALL	SORT_RTNLS

		MOV	ESI,[ESI]._RTN_NEXT_RTN_GINDEX
		CALL	DO_OUTPUT_RTNLS

		TEST	ESI,ESI
		JNZ	L1$
L9$:
		POP	ESI

		RET

DO_OUTPUT_TYPENAMES	ENDP


SORT_RTNLS	PROC	NEAR
		;
		;
		;
		PUSHM	ESI,EBX

		CONVERT	EAX,EAX,RES_TYPE_NAME_GARRAY
		ASSUME	EAX:PTR RES_TYPE_NAME_STRUCT

		MOV	EBX,[EAX]._RTN_N_RTNL
		MOV	EAX,[EAX]._RTN_RTNL_GINDEX

		CMP	EBX,1
		JBE	L9$

		MOV	EBX,EAX
		LEA	EAX,QN_BUFFER

		CALL	INIT_RES_SORT
L1$:
		CONVERT	EBX,EBX,RTNL_GARRAY
		ASSUME	EBX:PTR RTNL_STRUCT

		MOV	ECX,EBX
		ASSUME	ECX:PTR RTNL_STRUCT
		XOR	EDX,EDX

		MOV	EAX,[EBX]._RTNL_LANG_ID
		MOV	EBX,[EBX]._RTNL_NEXT_LANG_GINDEX

		MOV	[ECX]._RTNL_NEXT_LANG_GINDEX,EDX
		CALL	STORE_RES_ECXEAX

		TEST	EBX,EBX
		JNZ	L1$

		LEA	EAX,QN_BUFFER
		CALL	RES_SORT		;DOES RES_TBLINIT

		CALL	RELINK_RTNL
L9$:
		POPM	EBX,ESI

		RET

SORT_RTNLS	ENDP


DO_OUTPUT_RTNLS	PROC	NEAR
		;
		;AX IS GINDEX OF TYPENAMELANG-LIST TO WRITE OUT
		;
		;FOR EACH TYPENAMELANG IN THE LIST:
		;	OUTPUT A DIRECTORY ENTRY
		;	OUTPUT MY TYPENAMELANGS
		;
		PUSHM	ESI,EBX

		MOV	ESI,EAX

		TEST	ESI,ESI
		JZ	L9$
L1$:
		CONVERT	ESI,ESI,RTNL_GARRAY
		ASSUME	ESI:PTR RTNL_STRUCT

		MOV	EDI,TNLDE_PTR		;TYPENAME DIRECTORY_ENTRY PTR
		MOV	EAX,[ESI]._RTNL_LANG_ID

		MOV	EBX,RDENTRIES_OFFSET
		CALL	STORE_NAME_OR_ID
		;
		;STORE PTR TO TYPE-NAME DIRECTORY-TABLE
		;
		MOV	[EDI],EBX
		ADD	EDI,4

		MOV	EAX,8
		CALL	UPDATE_TNLDE_PTR

		MOV	EDI,RDENTRIES_PTR
		MOV	ECX,[ESI]._RTNL_FILE_ADDRESS

		MOV	EDX,[ESI]._RTNL_FILE_SIZE
		XOR	EAX,EAX

		MOV	[EDI],ECX
		MOV	[EDI+4],EDX

		MOV	[EDI+8],EAX
		MOV	[EDI+12],EAX

		MOV	AL,16
		MOV	ESI,[ESI]._RTNL_NEXT_LANG_GINDEX

		ADD	EDI,EAX
		CALL	UPDATE_RDENTRIES_PTR

		TEST	ESI,ESI
		JNZ	L1$
L9$:
		POPM	EBX,ESI

		RET

DO_OUTPUT_RTNLS	ENDP
		

SORT_RESNAMES	PROC	NEAR
		;
		;SORT RESNAMES ALPHABETICALLY, DEFINING RN_ALPHA_ORDER
		;
		XOR	ECX,ECX
		LEA	EAX,QN_BUFFER

		MOV	QN_BUFFER,ECX
		CALL	TQUICK_RESNAMES

		PUSH	EBX
		CALL	TBLINIT

		XOR	EBX,EBX
		JMP	L2$

L1$:
		CONVERT	EAX,EAX,RESNAME_GARRAY
		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	[EAX]._RN_ALPHA_ORDER,EBX
L2$:
		CALL	TBLNEXT

		LEA	EBX,[EBX+1]
		JNZ	L1$

		POP	EBX
		LEA	EAX,QN_BUFFER

		JMP	RELEASE_EAX_BUFFER

SORT_RESNAMES	ENDP


SORT_RES_TYPENAMES	PROC	NEAR
		;
		;EAX IS RESTYPE
		;
		;RETURNS EAX IS FIRST BYNAME GINDEX
		;	ECX IS FIRST BYORD GINDEX
		;
		PUSH	ESI
		CONVERT	EAX,EAX,RESTYPE_GARRAY
		ASSUME	EAX:PTR RESTYPE_STRUCT
		MOV	ESI,EAX
		ASSUME	ESI:PTR RESTYPE_STRUCT

		MOV	ECX,[EAX]._RT_N_RTN_BYNAME
		MOV	EAX,[EAX]._RT_RTN_BYNAME_GINDEX

		CMP	ECX,1
		JBE	L5$

;		PUSH	EAX
;		CALL	REP_RTN_NAMES

;		POP	EAX
		CALL	SORT_RES_TYPENAME_1
L5$:
		MOV	EDX,[ESI]._RT_N_RTN_BYORD
		MOV	ECX,[ESI]._RT_RTN_BYORD_GINDEX

		CMP	EDX,1
		JBE	L9$

		PUSH	EAX
		MOV	EAX,ECX

		CALL	SORT_RES_TYPENAME_1

		MOV	ECX,EAX
		POP	EAX
L9$:
		POP	ESI

		RET

SORT_RES_TYPENAMES	ENDP


SORT_RES_TYPENAME_1	PROC	NEAR
		;
		;
		;
		PUSH	ESI
		MOV	ESI,EAX

		LEA	EAX,QN_BUFFER
		CALL	INIT_RES_SORT
L1$:
		MOV	ECX,ESI
		ASSUME	ESI:PTR RES_TYPE_NAME_STRUCT,ECX:PTR RES_TYPE_NAME_STRUCT
		XOR	EDX,EDX

		MOV	EAX,[ESI]._RTN_ID_GINDEX
		MOV	ESI,[ESI]._RTN_NEXT_RTN_GINDEX

		CMP	EAX,64K
		JB	L3$

		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	EAX,[EAX]._RN_ALPHA_ORDER

		ASSUME	EAX:NOTHING
L3$:
		MOV	[ECX]._RTN_NEXT_RTN_GINDEX,EDX
		CALL	STORE_RES_ECXEAX

		TEST	ESI,ESI
		JNZ	L1$

		LEA	EAX,QN_BUFFER
		CALL	RES_SORT		;DOES RES_TBLINIT

		POP	ESI
		JMP	RELINK_RES_TYPENAME

SORT_RES_TYPENAME_1	ENDP


SORT_RESTYPES	PROC	NEAR
		;
		;
		;
		MOV	ECX,RESTYPE_N_BYNAME

		CMP	ECX,1
		JBE	L5$

;		MOV	EAX,RESTYPE_BYNAME_GINDEX
;		CALL	REP_RESTYPE_NAMES

		MOV	EAX,RESTYPE_BYNAME_GINDEX
		CALL	SORT_RESTYPE_1

		MOV	RESTYPE_BYNAME_GINDEX,EAX
L5$:
		MOV	ECX,RESTYPE_N_BYORD

		CMP	ECX,1
		JBE	L9$

		MOV	EAX,RESTYPE_BYORD_GINDEX
		CALL	SORT_RESTYPE_1

		MOV	RESTYPE_BYORD_GINDEX,EAX
L9$:
		RET

SORT_RESTYPES	ENDP


SORT_RESTYPE_1	PROC	NEAR
		;
		;
		;
		PUSH	ESI
		MOV	ESI,EAX

		LEA	EAX,QN_BUFFER
		CALL	INIT_RES_SORT
L1$:
		MOV	ECX,ESI
		ASSUME	ESI:PTR RESTYPE_STRUCT,ECX:PTR RESTYPE_STRUCT
		XOR	EDX,EDX

		MOV	EAX,[ESI]._RT_ID_GINDEX
		MOV	ESI,[ESI]._RT_NEXT_RT_GINDEX

		CMP	EAX,64K
		JB	L3$

		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	EAX,[EAX]._RN_ALPHA_ORDER

		ASSUME	EAX:NOTHING
L3$:
		MOV	[ECX]._RT_NEXT_RT_GINDEX,EDX
		CALL	STORE_RES_ECXEAX

		TEST	ESI,ESI
		JNZ	L1$

		LEA	EAX,QN_BUFFER
		CALL	RES_SORT		;DOES RES_TBLINIT

		POP	ESI
		JMP	RELINK_RESTYPE


		ASSUME	ECX:NOTHING

SORT_RESTYPE_1	ENDP


if	0

REP_RESTYPE_NAMES	PROC	NEAR
		;
		;EAX IS TYPE GINDEX
		;
		ASSUME	EAX:PTR RESTYPE_STRUCT
		PUSH	EBX
L1$:
		MOV	ECX,[EAX]._RT_ID_GINDEX
		ASSUME	ECX:PTR RESNAME_STRUCT
		MOV	EBX,EAX
		ASSUME	EBX:PTR RESTYPE_STRUCT

		MOV	EAX,[EAX]._RT_NEXT_RT_GINDEX

		MOV	EDX,[ECX]._RN_ALPHA_ORDER
		TEST	EAX,EAX

		MOV	[EBX]._RT_ALPHA_ORDER,EDX
		JNZ	L1$

		POP	EBX

		RET

REP_RESTYPE_NAMES	ENDP


REP_RTN_NAMES	PROC	NEAR
		;
		;EAX IS TYPENAME GINDEX
		;
		ASSUME	EAX:PTR RES_TYPE_NAME_STRUCT
		PUSH	EBX
L1$:
		MOV	ECX,[EAX]._RTN_ID_GINDEX
		ASSUME	ECX:PTR RESNAME_STRUCT
		MOV	EBX,EAX
		ASSUME	EBX:PTR RES_TYPE_NAME_STRUCT

		MOV	EAX,[EAX]._RTN_NEXT_RTN_GINDEX

		MOV	EDX,[ECX]._RN_ALPHA_ORDER
		TEST	EAX,EAX

		MOV	[EBX]._RTN_ALPHA_ORDER,EDX
		JNZ	L1$

		POP	EBX

		RET

		ASSUME	ECX:NOTHING

REP_RTN_NAMES	ENDP

endif

RELINK_RESTYPE	PROC	NEAR
		;
		;RETURNS FIRST IN EAX
		;
		PUSH	EBX
		CALL	RES_TBLINIT

		CALL	RES_TBLNEXT

		PUSH	EAX
		JZ	L9$
L2$:
		MOV	EBX,EAX
		CALL	RES_TBLNEXT
		ASSUME	EBX:PTR RESTYPE_STRUCT

		MOV	[EBX]._RT_NEXT_RT_GINDEX,EAX
		JNZ	L2$
L9$:
		LEA	EAX,QN_BUFFER
		CALL	RELEASE_EAX_BUFFER

		POPM	EAX,EBX

		RET

RELINK_RESTYPE	ENDP


RELINK_RES_TYPENAME	PROC	NEAR
		;
		;RETURNS FIRST IN EAX
		;
		PUSH	EBX
		CALL	RES_TBLINIT

		CALL	RES_TBLNEXT

		PUSH	EAX
		JZ	L9$
L2$:
		MOV	EBX,EAX
		CALL	RES_TBLNEXT
		ASSUME	EBX:PTR RES_TYPE_NAME_STRUCT

		MOV	[EBX]._RTN_NEXT_RTN_GINDEX,EAX
		JNZ	L2$

		LEA	EAX,QN_BUFFER
		CALL	RELEASE_EAX_BUFFER
L9$:
		POPM	EAX,EBX

		RET

RELINK_RES_TYPENAME	ENDP


RELINK_RTNL	PROC	NEAR
		;
		;RETURNS FIRST IN AX
		;
		PUSH	EBX
		CALL	RES_TBLINIT

		CALL	RES_TBLNEXT

		PUSH	EAX
		JZ	L9$
L2$:
		MOV	EBX,EAX
		CALL	RES_TBLNEXT
		ASSUME	EBX:PTR RTNL_STRUCT

		MOV	[EBX]._RTNL_NEXT_LANG_GINDEX,EAX
		JNZ	L2$

		LEA	EAX,QN_BUFFER
		CALL	RELEASE_EAX_BUFFER
L9$:
		POPM	EAX,EBX

		RET

RELINK_RTNL	ENDP


RES_TBLINIT 	PROC
		;
		;
		;
		MOV	EAX,QN_BUFFER+4		;FIRST BLOCK
		LEA	ECX,QN_BUFFER+8		;TABLE OF BLOCKS OF INDEXES

		TEST	EAX,EAX
		JZ	L9$
		;
		MOV	WM_PTR,EAX		;PHYSICAL POINTER TO NEXT INDEX TO PICK
		ADD	EAX,PAGE_SIZE

		MOV	WM_PTR_LIMIT,EAX
		MOV	WM_BLK_PTR,ECX		;POINTER TO NEXT BLOCK

		RET

L9$:
		MOV	WM_PTR_LIMIT,ECX
		SUB	ECX,4

		MOV	WM_PTR,ECX
		MOV	WM_BLK_PTR,ECX

		RET

RES_TBLINIT 	ENDP


RES_TBLNEXT 	PROC
		;
		;GET NEXT SYMBOL INDEX IN AX, DS:SI POINTS
		;
		MOV	ECX,WM_PTR
		MOV	EDX,WM_PTR_LIMIT

		ADD	ECX,8

		MOV	WM_PTR,ECX		;UPDATE POINTER
		CMP	ECX,EDX			;TIME FOR NEXT BLOCK?

		MOV	EAX,[ECX-4]
		JZ	L5$

		TEST	EAX,EAX
L9$:
		RET

L5$:
		TEST	EAX,EAX
		JZ	L9$
		;
		;NEXT BLOCK
		;
		MOV	EDX,WM_BLK_PTR

		MOV	ECX,[EDX]
		ADD	EDX,4

		MOV	WM_PTR,ECX
		ADD	ECX,PAGE_SIZE

		MOV	WM_BLK_PTR,EDX
		MOV	WM_PTR_LIMIT,ECX

		RET

RES_TBLNEXT 	ENDP


TBLINIT		PROC	PRIVATE

		LEA	ECX,QN_BUFFER+8		;TABLE OF BLOCKS OF INDEXES
		MOV	EAX,QN_BUFFER+4	;FIRST BLOCK

		MOV	WM_BLK_PTR,ECX		;POINTER TO NEXT BLOCK

		TEST	EAX,EAX
		JZ	L9$
		;
		MOV	ECX,PAGE_SIZE/4
		MOV	WM_PTR,EAX		;PHYSICAL POINTER TO NEXT INDEX TO PICK

		MOV	WM_CNT,ECX
		OR	AL,1
L9$:
		RET

TBLINIT 	ENDP


TBLNEXT		PROC	NEAR	PRIVATE
		;
		;GET NEXT SYMBOL INDEX IN AX, DS:SI POINTS
		;
		MOV	EDX,WM_CNT
		MOV	ECX,WM_PTR

		DEC	EDX			;LAST ONE?
		JZ	L5$

		MOV	EAX,[ECX]		;NEXT INDEX
		ADD	ECX,4

		TEST	EAX,EAX
		JZ	L9$

		MOV	WM_PTR,ECX		;UPDATE POINTER
		MOV	WM_CNT,EDX		;UPDATE COUNTER

L9$:
		RET

L5$:
		;
		;NEXT BLOCK
		;
		MOV	EAX,[ECX]
		MOV	ECX,WM_BLK_PTR

		MOV	WM_CNT,PAGE_SIZE/4

		MOV	EDX,[ECX]
		ADD	ECX,4

		MOV	WM_PTR,EDX
		MOV	WM_BLK_PTR,ECX

		TEST	EAX,EAX

		RET


TBLNEXT 	ENDP


;		.DATA?
;
;WM_PTR		DD	?
;WM_PTR_LIMIT	DD	?
;WM_BLK_PTR	DD	?
;

endif

		END
