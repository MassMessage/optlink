		TITLE	PENDSECT - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SEGMENTS
		INCLUDE	GROUPS
		INCLUDE	IO_STRUC
		INCLUDE	SECTS
		INCLUDE	RESSTRUC
		INCLUDE	EXES
		INCLUDE	SEGMSYMS

if	fg_segm

		PUBLIC	SEGM_OUT_END_OF_SECTION,COPY_RESOURCE_TO_FINAL,RELEASE_RESOURCES


		.DATA

		EXTERNDEF	EXETYPE_FLAG:BYTE,TEMP_RECORD:BYTE

		EXTERNDEF	DONT_PACK:DWORD,FLAG_0C:DWORD,_ERR_COUNT:DWORD,SEG_PAGE_SHIFT:DWORD,SEGMENT_COUNT:DWORD
		EXTERNDEF	RESOURCE_BYTES_SO_FAR:DWORD,NEXT_RESOURCE_PTR:DWORD,NEXT_RESOURCE_MASTER_PTR:DWORD
		EXTERNDEF	LAST_SEG_OS2_NUMBER:DWORD,SEG_PAGE_SIZE_M1:DWORD,CURN_SECTION_GINDEX:DWORD,DGROUP_GINDEX:DWORD
		EXTERNDEF	CODEVIEW_SECTION_GINDEX:DWORD,CURN_OUTFILE_GINDEX:DWORD,SEGMENT_TABLE_PTR:DWORD,SEGMENT_TABLE:DWORD
		EXTERNDEF	FIRST_RESOURCE_TYPE:DWORD,RESOURCE_TABLE_SIZE:DWORD,HEAP_SIZE:DWORD,STACK_SIZE:DWORD
		EXTERNDEF	RESOURCE_BLOCK_MASTER_PTRS:DWORD,RESTYPE_HASH_TABLE_PTR:DWORD,FIRST_SECTION_GINDEX:DWORD
		EXTERNDEF	RESTYPE_BYNAME_GINDEX:DWORD,RESTYPE_N_BYNAME:DWORD,RESTYPE_N_BYORD:DWORD,RESTYPE_BYORD_GINDEX:DWORD
		EXTERNDEF	RESOURCE_HASHES:DWORD

		EXTERNDEF	OUT_FLUSH_SEGMENT:DWORD

		EXTERNDEF	RESOURCE_STUFF:ALLOCS_STRUCT,ENTRY_STUFF:ALLOCS_STRUCT,OUTFILE_GARRAY:STD_PTR_S
		EXTERNDEF	GROUP_GARRAY:STD_PTR_S,ENTRY_GARRAY:STD_PTR_S,RTNL_GARRAY:STD_PTR_S,RESTYPE_GARRAY:STD_PTR_S
		EXTERNDEF	RESNAME_GARRAY:STD_PTR_S,RES_TYPE_NAME_GARRAY:STD_PTR_S,NEXEHEADER:NEXE


		.CODE	PASS2_TEXT

		EXTERNDEF	FLUSH_OUTFILE_CLOSE:PROC,FLUSH_EXESTR:PROC,MOVE_EAX_TO_EDX_NEXE:PROC,ERR_RET:PROC,ERR_ABORT:PROC
		EXTERNDEF	EO_CV:PROC,_release_minidata:proc,DO_OS2_PAGE_ALIGN:PROC,MOVE_EAX_TO_FINAL_HIGH_WATER:PROC
		EXTERNDEF	RELEASE_BLOCK:PROC,RELEASE_GARRAY:PROC,WARN_RET:PROC,RELEASE_IO_BLOCK:PROC

		EXTERNDEF	HEAP_STACK_DGROUP_ERR:ABS,HEAP_NO_DGROUP_ERR:ABS


SEGM_OUT_END_OF_SECTION	PROC
		;
		;END OF A SECTION
		;
		CALL	OUT_FLUSH_SEGMENT		;FLUSHES BUFFERED EXEPACK STUFF

		MOV	EAX,CURN_SECTION_GINDEX
		MOV	ECX,FIRST_SECTION_GINDEX

		CMP	EAX,ECX
		JZ	L1$

		CMP	CODEVIEW_SECTION_GINDEX,EAX
		JZ	EO_CV

		MOV	AL,0
		JMP	ERR_ABORT

L2$:
		AND	EBX,NOT 3
		JMP	L21$

L11$:
		;
		;OK, NEED TO CALCULATE GANGLOAD LENGTH
		;
		SUB	AX,NEXEHEADER._NEXE_GANGSTART

		MOV	NEXEHEADER._NEXE_GANGLENGTH,AX

		RET

L1$:
		;
		;WRITE OUT RESOURCES
		;
		CALL	WRITE_RESOURCES

		BITT	RC_PRELOADS
		JNZ	L11$

		MOV	EAX,OFF ENTRY_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF ENTRY_GARRAY
		CALL	RELEASE_GARRAY
		;
		;WRITE OUT RESOURCE TABLE
		;
		CALL	WRITE_RESOURCE_TABLE

		;
		;DO NEXEHEADER
		;
		MOV	ESI,DGROUP_GINDEX
		MOV	EBX,FLAG_0C

		TEST	ESI,ESI
		JZ	L2$

		CONVERT	ESI,ESI,GROUP_GARRAY
		ASSUME	ESI:PTR GROUP_STRUCT

		MOV	EAX,[ESI]._G_LEN
		MOV	ECX,[ESI]._G_OFFSET

		OR	EAX,EAX
		JZ	L2$

		SUB	EAX,ECX
		JZ	L2$

		MOV	EAX,[ESI]._G_OS2_NUMBER

		MOV	NEXEHEADER._NEXE_DGROUP,AX
		CONV_EAX_SEGTBL_ECX

		MOV	EAX,[ECX]._SEGTBL_LSIZE
		;
		;EAX IS DGROUP SIZE WITHOUT STACK OR HEAP
		;
		ADD	EAX,STACK_SIZE
		;
		;BX:AX IS DGROUP SIZE WITHOUT HEAP
		;
		CMP	EAX,64K
		JAE	L205$

		BITT	HEAP_MAXVAL
		JZ	L205$
		;
		;SET HEAP_SIZE TO 64K MINUS AX
		;
		MOV	ECX,64K-16		;MINUS 16 FOR WINDOWS...
		XOR	EDX,EDX

		SUB	ECX,EAX

		MOV	HEAP_SIZE,ECX
		JNC	L205$

		MOV	HEAP_SIZE,EDX

L205$:
		ADD	EAX,HEAP_SIZE

		CMP	EAX,0FFF0H
		JB	L21$

		MOV	AL,HEAP_STACK_DGROUP_ERR
		CALL	ERR_RET
L21$:
		BITT	HANDLE_EXE_ERRORFLAG
		JZ	L215$

		MOV	EAX,_ERR_COUNT

		OR	EAX,EAX
		JZ	L215$

		OR	EBX,MASK APPERRORS
L215$:
		MOV	NEXEHEADER._NEXE_FLAGS,BX
		MOV	EAX,HEAP_SIZE

		MOV	NEXEHEADER._NEXE_HEAPSIZE,AX

		OR	EAX,EAX
		JZ	L217$

		CMP	NEXEHEADER._NEXE_DGROUP,0
		JNZ	L217$

		MOV	AL,HEAP_NO_DGROUP_ERR
		CALL	WARN_RET
L217$:
;		MOV	AX,STACK_SIZE			;THIS HAPPENS AT STROE_STACK_SEGMENT (PASS2)
;		MOV	NEXEHEADER._NEXE_STACKSIZE,AX

		MOV	EAX,SEG_PAGE_SHIFT

		MOV	NEXEHEADER._NEXE_LSECTOR_SHIFT,AX
		MOV	AL,EXETYPE_FLAG

		XOR	AH,AH

		CMP	AL,UNKNOWN_SEGM_TYPE
		JNZ	L218$

		XOR	AL,AL
L218$:
		CMP	AL,WIN_SEGM_TYPE	;WINDOWS
		JZ	L22$

		BITT	LONGNAMES_FLAG
		JZ	L22$

		MOV	AH,1
L22$:
		OR	WPTR (NEXEHEADER._NEXE_EXETYPE),AX
		;
		;
		;
		MOV	EAX,OFF NEXEHEADER
		MOV	ECX,40H

		XOR	EDX,EDX
		CALL	MOVE_EAX_TO_EDX_NEXE
		;
		;NOW SEND SEGMENT TABLE TOO...
		;
		MOV	ESI,SEGMENT_TABLE_PTR
		MOV	ECX,SEGMENT_COUNT

		ADD	ESI,SIZE SEGTBL_STRUCT
		MOV	EDI,OFF TEMP_RECORD
		ASSUME	ESI:PTR SEGTBL_STRUCT

		OR	ECX,ECX
		JZ	L6$
L23$:
		MOV	EDX,[ESI]._SEGTBL_PSIZE
		MOV	EBX,[ESI]._SEGTBL_FADDR

		SHL	EDX,16
		MOV	EAX,[ESI]._SEGTBL_FLAGS

		OR	EDX,EBX
		MOV	EBX,[ESI]._SEGTBL_LSIZE

		SHL	EBX,16
		XOR	EAX,MASK SR_DPL			;FLIP THESE

		MOV	[EDI],EDX
		OR	EAX,EBX
		;
		;IF CODE SEG, THEN MOVABLE OR DISCARDABLE == BOTH
		;
		TEST	AL,1			;1 = DATA
		JNZ	L24$
;		TEST	WPTR 4[SI],MASK SR_MOVABLE+MASK SR_DISCARD
;		JZ	4$
;		OR	WPTR 4[SI],MASK SR_MOVABLE+MASK SR_DISCARD
;4$:
		;
		;IF IOPL, SET MOVABLE ALSO
		;
		MOV	EBX,EAX

		AND	BH,MASK SR_DPL SHR 8

		CMP	BH,8
		JNZ	L5$

		OR	EAX,MASK SR_MOVABLE
L5$:

L24$:
		AND	AL,NOT MASK SR_MULTIPLE
		ADD	ESI,SIZE SEGTBL_STRUCT

		MOV	[EDI+4],EAX
		ADD	EDI,8

		DEC	ECX
		JNZ	L23$
L6$:
		MOV	EAX,OFF TEMP_RECORD
		MOV	ECX,SEGMENT_COUNT

		MOVZX	EDX,NEXEHEADER._NEXE_SEGTBL_OFFSET

		SHL	ECX,3
		CALL	MOVE_EAX_TO_EDX_NEXE

		CALL	FLUSH_EXESTR

		XOR	EAX,EAX

		RESS	EXEPACK_SELECTED,AL
		RESS	EXEPACK_BODY,AL
if	fg_slrpack
		RESS	SLRPACK_FLAG,AL
endif
		MOV	DONT_PACK,EAX

		MOV	EAX,CURN_OUTFILE_GINDEX
		CONVERT	EAX,EAX,OUTFILE_GARRAY
		ASSUME	EAX:PTR OUTFILE_STRUCT

		DEC	[EAX]._OF_SECTIONS	;# OF SECTIONS USING THIS FILE
		JNZ	L25$
		;
		;LAST SECTION TO USE THIS FILE, FLUSH AND CLOSE
		;
		CALL	FLUSH_OUTFILE_CLOSE

		XOR	EAX,EAX

		MOV	CURN_OUTFILE_GINDEX,EAX
L25$:
		RET

		ASSUME	EAX:NOTHING

SEGM_OUT_END_OF_SECTION	ENDP


WRITE_RESOURCE_TABLE	PROC	NEAR
		;
		;IF RC MODE, BUILD AND WRITE RESOURCE TABLE TO HEADER
		;
		MOV	EAX,RESTYPE_N_BYNAME
		MOV	EDI,OFF TEMP_RECORD

		ADD	EAX,RESTYPE_N_BYORD
		JZ	L9$

		MOV	EAX,SEG_PAGE_SHIFT	;

		MOV	[EDI],EAX
		ADD	EDI,2

		CALL	FLUSH_RESOURCE_TABLE_CHUNK

		MOV	ESI,RESTYPE_BYORD_GINDEX
		CALL	WRITE_TABLE_1

		MOV	ESI,RESTYPE_BYNAME_GINDEX
		CALL	WRITE_TABLE_1

		XOR	EAX,EAX

		STOSW				;NUL RESOURCE TYPE

		CALL	FLUSH_RESOURCE_TABLE_CHUNK

		CALL	RELEASE_RESOURCES

		MOV	EAX,OFF RESNAME_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RESTYPE_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RES_TYPE_NAME_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RTNL_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF RESOURCE_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,RESOURCE_HASHES
		CALL	RELEASE_BLOCK
L9$:
		RET

WRITE_RESOURCE_TABLE	ENDP


WRITE_TABLE_1	PROC

		TEST	ESI,ESI
		JZ	L9$
L1$:
		CONVERT	ESI,ESI,RESTYPE_GARRAY
		ASSUME	ESI:PTR RESTYPE_STRUCT

		MOV	EBX,[ESI]._RT_N_RTN_BYNAME
		MOV	ECX,[ESI]._RT_N_RTN_BYORD

		MOV	EAX,[ESI]._RT_ID_GINDEX
		ADD	EBX,ECX

		SHL	EBX,16
		CALL	CONVERT_EAX_ID_GINDEX_16

		XOR	ECX,ECX
		OR	EAX,EBX

		MOV	[EDI+4],ECX
		MOV	[EDI],EAX

		ADD	EDI,8
		MOV	EAX,[ESI]._RT_RTN_BYORD_GINDEX

		MOV	ESI,[ESI]._RT_NEXT_RT_GINDEX
		CALL	TABLE_HELPER

		TEST	ESI,ESI
		JNZ	L1$
L9$:
		RET

WRITE_TABLE_1	ENDP


CONVERT_EAX_ID_GINDEX_16	PROC	NEAR
		;
		;
		;
		CMP	EAX,64K
		JAE	L1$

		OR	AH,80H

		RET

L1$:
		CONVERT	EAX,EAX,RESNAME_GARRAY
		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	EAX,[EAX]._RN_OFFSET
		MOV	EDX,RESOURCE_TABLE_SIZE

		ADD	EAX,EDX

		RET

		ASSUME	EAX:NOTHING

CONVERT_EAX_ID_GINDEX_16	ENDP


TABLE_HELPER	PROC	NEAR
		;
		;
		;
		PUSH	ESI
		MOV	ESI,EAX
L0$:
		TEST	ESI,ESI
		JZ	L9$
L1$:
		CONVERT	ESI,ESI,RES_TYPE_NAME_GARRAY
		ASSUME	ESI:PTR RES_TYPE_NAME_STRUCT

		MOV	EAX,[ESI]._RTN_ID_GINDEX

		MOV	EBX,[ESI]._RTN_RTNL_GINDEX	;TAKE LAST LANGUAGE IF MULTIPLE...
		CALL	CONVERT_EAX_ID_GINDEX_16

		SHL	EAX,16
		CONVERT	EBX,EBX,RTNL_GARRAY
		ASSUME	EBX:PTR RTNL_STRUCT
		MOV	ECX,[EBX]._RTNL_FLAGS

		AND	ECX,0FFFFH
		MOV	ESI,[ESI]._RTN_NEXT_RTN_GINDEX

		OR	ECX,EAX
		MOV	EAX,SEG_PAGE_SIZE_M1

		MOV	[EDI+4],ECX
		MOV	EDX,[EBX]._RTNL_FILE_SIZE

		ADD	EDX,EAX
		MOV	ECX,SEG_PAGE_SHIFT

		SHR	EDX,CL

		SHL	EDX,16
		MOV	EAX,[EBX]._RTNL_FILE_ADDRESS	;CONVERTED TO OUTPUT FILE PAGE WHEN RESOURCE WRITTEN

		OR	EAX,EDX
		XOR	ECX,ECX

		MOV	[EDI],EAX
		MOV	[EDI+8],ECX

		ADD	EDI,12

		CMP	EDI,OFF TEMP_RECORD+TEMP_SIZE-20
		JB	L0$

		CALL	FLUSH_RESOURCE_TABLE_CHUNK

		JMP	L0$

L9$:
		POP	ESI

		RET

TABLE_HELPER	ENDP


FLUSH_RESOURCE_TABLE_CHUNK	PROC	NEAR
		;
		;IF DI !=TEMP_RECORD, FLUSH IT TO NEXE
		;
		MOV	EAX,OFF TEMP_RECORD
		MOV	ECX,EDI

		SUB	ECX,EAX
		JZ	L9$

		MOVZX	EDX,NEXEHEADER._NEXE_RSRCTBL_OFFSET

		MOV	EDI,RESOURCE_BYTES_SO_FAR

		ADD	EDX,EDI
		ADD	EDI,ECX

		MOV	RESOURCE_BYTES_SO_FAR,EDI
		MOV	EDI,EAX

		JMP	MOVE_EAX_TO_EDX_NEXE

L9$:
		RET

FLUSH_RESOURCE_TABLE_CHUNK	ENDP


WRITE_RESOURCES	PROC	NEAR
		;
		;SCAN RESOURCE TABLE, OUTPUTING RESOURCES AS WE GO
		;
		MOV	EAX,SEGMENT_COUNT
		MOV	ECX,LAST_SEG_OS2_NUMBER

		INC	EAX
		PUSH	ECX

		MOV	LAST_SEG_OS2_NUMBER,EAX
		MOV	ESI,RESTYPE_BYORD_GINDEX

		TEST	ESI,ESI
		JZ	L3$
L1$:
		CONVERT	ESI,ESI,RESTYPE_GARRAY
		ASSUME	ESI:PTR RESTYPE_STRUCT

		MOV	EAX,[ESI]._RT_RTN_BYORD_GINDEX
		CALL	WRITE_RESOURCES_1

		MOV	ESI,[ESI]._RT_NEXT_RT_GINDEX

		TEST	ESI,ESI
		JNZ	L1$
L3$:
		MOV	ESI,RESTYPE_BYNAME_GINDEX

		TEST	ESI,ESI
		JZ	L9$
L4$:
		CONVERT	ESI,ESI,RESTYPE_GARRAY
		ASSUME	ESI:PTR RESTYPE_STRUCT

		MOV	EAX,[ESI]._RT_RTN_BYORD_GINDEX
		CALL	WRITE_RESOURCES_1

		MOV	ESI,[ESI]._RT_NEXT_RT_GINDEX

		TEST	ESI,ESI
		JNZ	L4$
L9$:
		POP	ESI
		CALL	DO_OS2_PAGE_ALIGN	;EAX IS PAGE ADDRESS

		MOV	LAST_SEG_OS2_NUMBER,ESI

		RET

WRITE_RESOURCES	ENDP


WRITE_RESOURCES_1	PROC	NEAR
		;
		;
		;
		PUSH	ESI
		MOV	ESI,EAX
L0$:
		TEST	ESI,ESI
		JZ	L9$
L1$:
		CONVERT	ESI,ESI,RES_TYPE_NAME_GARRAY
		ASSUME	ESI:PTR RES_TYPE_NAME_STRUCT

		MOV	EBX,[ESI]._RTN_RTNL_GINDEX
		CONVERT	EBX,EBX,RTNL_GARRAY
		ASSUME	EBX:PTR RTNL_STRUCT
		GETT	AL,RC_REORDER

		OR	AL,AL
		JZ	L4$

		GETT	AL,RC_PRELOADS
		MOV	ECX,[EBX]._RTNL_FLAGS

		OR	AL,AL
		JNZ	L35$

		AND	ECX,MASK SR_PRELOAD
		JNZ	L5$
		JMP	L4$

L9$:
		POP	ESI

		RET

L35$:
		AND	ECX,MASK SR_PRELOAD
		JZ	L5$
L4$:
		CALL	DO_OS2_PAGE_ALIGN	;EAX RETURNS PAGE ADDRESS

		MOV	ECX,EAX
		MOV	EAX,[EBX]._RTNL_FILE_ADDRESS	;ADDRESS IN .RES FILE

		MOV	[EBX]._RTNL_FILE_ADDRESS,ECX
		;
		;EAX IS SOURCE ADDRESS IN RESOURCE FILE
		;
		MOV	ECX,[EBX]._RTNL_FILE_SIZE

		CALL	COPY_RESOURCE_TO_FINAL
L5$:
		MOV	ESI,[ESI]._RTN_NEXT_RTN_GINDEX
		JMP	L0$

WRITE_RESOURCES_1	ENDP

		ASSUME	ESI:NOTHING,EBX:NOTHING

RELEASE_RESOURCES	PROC
		;
		;
		;
		PUSHM	EDI,ESI

		MOV	ESI,RESOURCE_BLOCK_MASTER_PTRS

		TEST	ESI,ESI
		JZ	L9$

		PUSH	EBX
		MOV	ECX,64
L1$:
		MOV	EBX,[ESI]
		ADD	ESI,4

		TEST	EBX,EBX
		JZ	L5$

		MOV	EDI,64
L2$:
		MOV	EAX,[EBX]

		TEST	EAX,EAX
		JZ	L5$

		ADD	EBX,4
		CALL	RELEASE_IO_BLOCK

		DEC	EDI
		JNZ	L2$
L5$:
		DEC	ECX
		JNZ	L1$

		POP	EBX
L9$:
		POPM	ESI,EDI

		RET

RELEASE_RESOURCES	ENDP


COPY_RESOURCE_TO_FINAL	PROC
		;
		;EAX IS RESOURCE FILE ADDRESS
		;ECX IS # OF BYTES TO MOVE
		;
		PUSHM	ESI,EBX

		MOV	EDX,EAX
		MOV	ESI,EAX

		SHR	EDX,PAGE_BITS		;BLOCK # IN EDX, OFFSET IN ESI
		AND	ESI,PAGE_SIZE-1

		MOV	EAX,EDX
		PUSH	ECX

		SHR	EDX,6
		AND	EAX,63

		SHL	EDX,2
		ADD	EAX,EAX

		MOV	NEXT_RESOURCE_MASTER_PTR,EDX
		ADD	EAX,EAX

		MOV	NEXT_RESOURCE_PTR,EAX
		POP	ECX
L3$:
		;
		;GET BLOCK
		;
		MOV	EBX,RESOURCE_BLOCK_MASTER_PTRS
		MOV	EDX,NEXT_RESOURCE_MASTER_PTR

		PUSHM	ECX
		MOV	EAX,PAGE_SIZE

		MOV	EBX,[EBX+EDX]
		MOV	EDX,NEXT_RESOURCE_PTR

		PUSH	ESI
		SUB	EAX,ESI

		MOV	EBX,[EBX+EDX]
		;
		;NEED TO MOVE SMALLER OF DX:CX AND PAGE_SIZE-SI
		;
		CMP	EAX,ECX
		JB	L5$

		MOV	EAX,ECX
L5$:
		PUSH	EAX
		MOV	ECX,EAX

		LEA	EAX,[ESI+EBX]
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POP	EAX			;# ACTUALLY MOVED
		POP	ESI

		ADD	ESI,EAX

		CMP	ESI,PAGE_SIZE
		JNZ	L6$

		MOV	ECX,NEXT_RESOURCE_PTR
		XOR	ESI,ESI

		ADD	ECX,4

		CMP	ECX,256
		JNZ	L55$

		ADD	NEXT_RESOURCE_MASTER_PTR,4
		MOV	ECX,ESI
L55$:
		MOV	NEXT_RESOURCE_PTR,ECX
L6$:
		POP	ECX

		SUB	ECX,EAX
		JNZ	L3$

		POPM	EBX,ESI

		RET

COPY_RESOURCE_TO_FINAL	ENDP


		PUBLIC	SET_RESOURCE_PTR


SET_RESOURCE_PTR	PROC			;9
		;
		;EAX IS FILE ADDRESS
		;
		MOV	EDX,EAX
		MOV	ECX,EAX

		SHR	EDX,PAGE_BITS		;BLOCK # IN EDX, OFFSET IN ESI
		AND	ECX,PAGE_SIZE-1

		MOV	EAX,EDX
		PUSH	EBX

		SHR	EDX,6
		AND	EAX,63

		SHL	EDX,2
		MOV	EBX,RESOURCE_BLOCK_MASTER_PTRS

		SHL	EAX,2
		MOV	NEXT_RESOURCE_MASTER_PTR,EDX

		MOV	EBX,[EBX+EDX]
		MOV	NEXT_RESOURCE_PTR,EAX
		;
		;GET BLOCK
		;
		MOV	EAX,[EBX+EAX]
		POP	EBX

		RET

SET_RESOURCE_PTR	ENDP

endif

		END

