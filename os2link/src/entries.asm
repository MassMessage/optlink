		TITLE	ENTRIES - Copyright (c) SLR Systems 1994

		INCLUDE MACROS
		INCLUDE	SYMBOLS
		INCLUDE	SEGMSYMS
		INCLUDE	IO_STRUC
		INCLUDE	RESSTRUC
		INCLUDE	SEGMENTS
		INCLUDE	GROUPS
		INCLUDE	EXES

		PUBLIC	BUILD_FLUSH_ENTRIES,EXEHDR_ERROR


		.DATA

		EXTERNDEF	SYMBOL_TEXT:BYTE,TEMP_RECORD:BYTE,ZEROS_16:BYTE,CASE_TYPE:BYTE,EXPORT_TABLE_USE:BYTE
		EXTERNDEF	IMPORT_TABLE_USE:BYTE,MODULE_NAME:BYTE

		EXTERNDEF	ENTRY_TABLE:DWORD,SYMBOL_LENGTH:DWORD,SEGMENT_COUNT:DWORD,MOVABLE_MASK:DWORD,FLAG_0C:DWORD
		EXTERNDEF	LOWEST_SEGMENT:DWORD,HIGHEST_SEGMENT:DWORD,_OUTFILE_GINDEX:DWORD,N_IMPMODS:DWORD
		EXTERNDEF	EXE_DESCRIPTION:DWORD,ENTRY_OFFSET:DWORD,OS2_EXEHDR_START:DWORD,OMF_NAME:DWORD,ENTRYNAME_BITS:DWORD
		EXTERNDEF	CURRENT_OFFSET:DWORD,RESOURCE_TABLE_SIZE:DWORD,RESNAMES_SIZE:DWORD,IMPNAMES_SIZE:DWORD
		EXTERNDEF	NONRESNAMES_SIZE:DWORD,RESOURCE_NAMES_SIZE:DWORD,FIRST_ENTRYNAME_GINDEX:DWORD,LAST_PENT_GINDEX:DWORD
		EXTERNDEF	FIRST_IMPMOD_GINDEX:DWORD,FIRST_RESNAME_GINDEX:DWORD

		EXTERNDEF	RESIDENT_STRUCTURE:SEQ_STRUCT,NONRESIDENT_STRUCTURE:SEQ_STRUCT,ENTRYNAME_STUFF:ALLOCS_STRUCT
		EXTERNDEF	IMPNAME_STUFF:ALLOCS_STRUCT,PENT_STUFF:ALLOCS_STRUCT,RESNAME_GARRAY:STD_PTR_S
		EXTERNDEF	STUB_OLD_DONE_SEM:GLOBALSEM_STRUCT,ENTRYNAME_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S
		EXTERNDEF	SYMBOL_GARRAY:STD_PTR_S,IMPNAME_GARRAY:STD_PTR_S,PENT_GARRAY:STD_PTR_S,SEGMOD_GARRAY:STD_PTR_S
		EXTERNDEF	OUTFILE_GARRAY:STD_PTR_S,_FILE_LIST_GARRAY:STD_PTR_S,GROUP_GARRAY:STD_PTR_S,IMPMOD_GARRAY:STD_PTR_S

		EXTERNDEF	NEXEHEADER:NEXE,SEGMENT_TABLE:SEGTBL_STRUCT

		EXTERNDEF	LOUTALL:DWORD


		.CODE	PASS2_TEXT

		EXTERNDEF	_capture_eax:proc
		EXTERNDEF	GET_NEW_LOG_BLK:PROC,RELEASE_BLOCK:PROC,MOVE_EXEHDR_TO_FINAL:PROC,CONVERT_SUBBX_TO_EAX:PROC
		EXTERNDEF	READ_SIZE_RESOURCES:PROC,DOT:PROC,CAPTURE_EAX:PROC,CONVERT_SUBBX_TO_EAX_NOZERO:PROC,ERR_ABORT:PROC
		EXTERNDEF	INSTALL_ENTRY:PROC,TERMINATE_OPREADS:PROC,WARN_ASCIZ_RET:PROC,MOVE_EAX_TO_EDX_FINAL:PROC
		EXTERNDEF	RELEASE_SEGMENT:PROC,ABORT:PROC,ERR_ASCIZ_RET:PROC,RELEASE_GARRAY:PROC,STORE_EAXECX_EDX_SEQ:PROC
		EXTERNDEF	OUT5:PROC,ERR_RET:PROC,LOUTALL_CON:PROC,OUTPUT_DIN:PROC,OUTPUT_LIB:PROC,_release_minidata:proc
		EXTERNDEF	STORE_EAXECX_EDXEBX_RANDOM:PROC,MOVE_EAX_TO_EDX_NEXE:PROC,ERR_SYMBOL_TEXT_ABORT:PROC
		EXTERNDEF	UNUSE_ENTRYNAMES:PROC,UNUSE_IMPORTS:PROC,MOVE_ASCIZ_ECX_EAX:PROC

		EXTERNDEF	TOO_ENTRIES_ERR:ABS,EXP_CONST_ERR:ABS,EXEHDR_ERR:ABS,EXP_TEXT_ERR:ABS,EXPORT_TOO_LONG_ERR:ABS
		EXTERNDEF	IMPORT_TOO_LONG_ERR:ABS,RES_TOO_LONG_ERR:ABS


BUILD_FLUSH_ENTRIES	PROC
		;
		;THIS BUILDS THE ENTRY TABLE, RESIDENT AND NON-RESIDENT NAMES
		;
		BITT	OUTPUT_SEGMENTED
		JZ	L9$

if	fgh_inthreads
		;
		;WAIT FOR STUB AND OLD THREADS TO COMPLETE
		;
;		MOV	EAX,OFF STUB_OLD_DONE_SEM
;		CALL	CAPTURE_EAX
endif

		XOR	EAX,EAX

		XCHG	EAX,ENTRYNAME_BITS

		TEST	EAX,EAX
		JZ	L0$

		CALL	RELEASE_BLOCK
L0$:
		MOV	EAX,SEGMENT_COUNT
		MOV	ECX,SIZE NEXE

		MOV	NEXEHEADER._NEXE_NSEGS,AX

		MOV	NEXEHEADER._NEXE_SEGTBL_OFFSET,CX
		LEA	EAX,[EAX*8+ECX]		;8 BYTES PER SEGMENT ENTRY

		MOV	NEXEHEADER._NEXE_RSRCTBL_OFFSET,AX

		MOV	NEXEHEADER._NEXE_RESNAM_OFFSET,AX

		MOV	RESIDENT_STRUCTURE._SEQ_TARGET,OFF NEXEHEADER._NEXE_RESNAM_OFFSET
		MOV	RESIDENT_STRUCTURE._SEQ_NEXT_TARGET,OFF NEXEHEADER._NEXE_MODREF_OFFSET
		;
		;FIRST, PUT MODULE-NAME IN RESIDENT_NAME_TABLE, AND COMMENT
		;STRING IN NONRESIDENT_NAME_TABLE
		;
		MOV	EAX,_OUTFILE_GINDEX
		CONVERT	EAX,EAX,OUTFILE_GARRAY

		MOV	EAX,[EAX].OUTFILE_STRUCT._OF_FILE_LIST_GINDEX
		CONVERT	EAX,EAX,_FILE_LIST_GARRAY
		ASSUME	EAX:PTR FILE_LIST_STRUCT

		MOV	ESI,[EAX].FILE_LIST_NFN.NFN_PATHLEN
		MOV	ECX,[EAX].FILE_LIST_NFN.NFN_PRIMLEN

		LEA	EAX,[EAX+ESI].FILE_LIST_NFN.NFN_TEXT
		ASSUME	EAX:NOTHING
		CALL	FIX_RESNAM_1
		;
		;WAS AN ALTERNATE NAME PROVIDED?
		;
		MOV	EAX,OMF_NAME

		TEST	EAX,EAX
		JZ	L1$
		;
		;YEP, MOVE IT TO SYMBOL_LENGTH
		;
		CALL	FIX_RESNAM
		;
		;REMOVE EXTENSION
		;
		MOV	ECX,SYMBOL_LENGTH
		XOR	EDX,EDX

		ADD	ECX,OFF SYMBOL_TEXT
L05$:
		INC	EDX
		MOV	AL,[ECX-1]

		DEC	ECX

		CMP	AL,'.'
		JNZ	L05$

		MOV	DPTR [ECX],0

		SUB	SYMBOL_LENGTH,EDX
L1$:
		;
		;FOR USE BY /IMPLIB
		;
		MOV	ESI,OFF SYMBOL_LENGTH
		MOV	EDI,OFF MODULE_NAME

		LODSD
		STOSD

		MOV	ECX,EAX

		REP	MOVSB

		XOR	EAX,EAX
		STOSD

		MOV	EAX,OFF RESIDENT_STRUCTURE
		CALL	STR_2		;MOVE STRING AT SYMBOL_LENGTH
		;
		;DEFAULT DESCRIPTION IS FILENAME WITH EXTENSION
		;
		MOV	EAX,_OUTFILE_GINDEX
		CONVERT	EAX,EAX,OUTFILE_GARRAY

		MOV	EAX,[EAX].OUTFILE_STRUCT._OF_FILE_LIST_GINDEX
		CONVERT	EAX,EAX,_FILE_LIST_GARRAY
		ASSUME	EAX:PTR FILE_LIST_STRUCT

		MOV	ESI,[EAX].FILE_LIST_NFN.NFN_PATHLEN
		MOV	ECX,[EAX].FILE_LIST_NFN.NFN_PRIMLEN

		MOV	EDX,[EAX].FILE_LIST_NFN.NFN_EXTLEN

		ADD	ECX,EDX
		LEA	EAX,[EAX+ESI].FILE_LIST_NFN.NFN_TEXT
		ASSUME	EAX:NOTHING

		CALL	FIX_RESNAM_1
		;
		;WAS AN ALTERNATE DESCRIPTION PROVIDED?
		;
		MOV	EAX,EXE_DESCRIPTION

		TEST	EAX,EAX
		JZ	L4$
		;
		;YEP, MOVE IT TO SYMBOL_LENGTH
		;
		CALL	FIX_RESNAM
L4$:
		MOV	EAX,OFF NONRESIDENT_STRUCTURE
		CALL	STR_2		;MOVE STRING AT SYMBOL_LENGTH
		;
		;NOW SCAN ENTRYNAME_HASH_TABLE FOR DECLARED ENTRY POINTS...
		;
		MOV	EAX,FIRST_ENTRYNAME_GINDEX

		TEST	EAX,EAX
		JZ	NO_PREDEFINED_ENTRIES

		CALL	DO_PREDEFINED_ORDED	;OUTPUT ALL THAT HAVE ORDINAL #'S ASSIGNED

		CALL	DO_BYNAMES		;OUTPUT ALL THAT DO NOT HAVE ORDINAL #'S ASSIGNED

NO_PREDEFINED_ENTRIES:

		CALL	OUTPUT_DIN		;IF REQUESTED

		CALL	OUTPUT_LIB		;IF REQUESTED

		CALL	UNUSE_ENTRYNAMES	;FREE UP THAT STORAGE IF .MAP DOESN'T NEED IT...

		;
		;READ .RES FILES, BUILD RESOURCE-TABLE, ADJUST RESNAM OFFSET BY RESOURCE-TABLE SIZE
		;
		CALL	READ_SIZE_RESOURCES	;READ RESOURCES
if	fgh_inthreads
		CALL	TERMINATE_OPREADS	;TERMINATE ALL OPREAD THREADS
endif
		;
		;FLUSH RESIDENT NAME TABLE
		;
		CALL	FLUSH_RESIDENT_NAMES	;GO AHEAD,THEN WE CAN USE RESIDENT_TABLE
		CALL	DO_RESOURCE_NAMES	;WRITE NAMES TO STRUCTURE, RELEASE NAMES
		CALL	FLUSH_RESOURCE_NAMES	;FLUSH STRUCTURE TO .EXE
		CALL	BUILD_FLUSH_IMPORTS	;DUMP MODULES AND IMPORTED NAMES
		CALL	DO_PENTS		;HANDLE FORWARD REFS WE WERE UNSURE OF...
		CALL	FLUSH_ENTRY_TABLE	;FINALLY...
		CALL	FLUSH_NONRESIDENT_NAMES
		;
		;FINALLY FINISHED WITH HEADER...
		;
		BITT	EXEHDR_ERROR_FLAG
		JZ	L9$
		CALL	FLUSH_EXEHDR_ERROR
L9$:
		RET

BUILD_FLUSH_ENTRIES	ENDP


FIX_RESNAM	PROC	NEAR	PRIVATE
		;
		;
		;
		MOV	ECX,[EAX]
		ADD	EAX,4
FIX_RESNAM_1::
		;
		;EAX IS STRING POINTER
		;ECX IS LENGTH
		;
		PUSH	EDI
		MOV	EDI,OFF SYMBOL_TEXT

		PUSH	ESI
		MOV	ESI,EAX

		MOV	[EDI-4],ECX

		REP	MOVSB

		MOV	[EDI],ECX
		POPM	ESI,EDI

		RET

FIX_RESNAM	ENDP


DO_PREDEFINED_ORDED	PROC	NEAR
		;
		;EAX IS FIRST_ENTRYNAME_GINDEX
		;
L1$:
		MOV	ECX,EAX
		CONVERT	EAX,EAX,ENTRYNAME_GARRAY
		ASSUME	EAX:PTR ENT_STRUCT
		MOV	EDX,[EAX]._ENT_NEXT_ENT_GINDEX

		PUSH	EDX
		CALL	HANDLE_ENTRY	;EAX IS PHYS, ECX IS INDEX

		POP	EAX

		TEST	EAX,EAX
		JNZ	L1$

		RET

		ASSUME	EAX:NOTHING

DO_PREDEFINED_ORDED	ENDP


DO_BYNAMES	PROC	NEAR
		;
		;OK, SCAN ENTRY_TABLE FOR HOLES, FILLING IN STUFF FROM SEGMENT
		;TABLE AS WE GO...
		;
		MOV	LOWEST_SEGMENT,0	;SEGMENT RANGE TO USE FOR

		MOV	HIGHEST_SEGMENT,255

		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBX,OFF ENTRY_TABLE
		MOV	ESI,12			;ZERO NOT USED... - POINTING TO SEG # & FLAGS
L0$:
		CALL	CONVERT_SUBBX_TO_EAX

		MOV	EBP,EAX
L1$:
		MOV	ECX,[EBP+ESI] 		;LOOK FOR FIRST EMPTY ORDINAL #
		ADD	ESI,8

		TEST	ECX,ECX
		JZ	L2$
L3$:
		CMP	ESI,PAGE_SIZE+4
		JNZ	L1$
		;
		;BLOCK FULL, TRY ANOTHER BLOCK
		;
		ADD	EBX,4
		MOV	ESI,4

if	page_size EQ 16K
		CMP	EBX,OFF ENTRY_TABLE+64
else
		CMP	EBX,OFF ENTRY_TABLE+128
endif
		JNZ	L0$

		MOV	AL,TOO_ENTRIES_ERR	;NO HOLES OUT OF 64K POSSIBLE...
		CALL	ERR_ABORT

L2$:
		LEA	ECX,[ESI-8]		;CONVERT ECX TO ORDINAL #
		MOV	EAX,EBX

		SHR	ECX,3
		SUB	EAX,OFF ENTRY_TABLE

		SHL	EAX,PAGE_BITS-3-2
		MOV	DL,[EBP+ESI-8]		;FOR LATER MOVABLE TEST

		ADD	ECX,EAX			;ECX IS FIRST AVAILABLE ORDINAL NUMBER
		XOR	EAX,EAX			;FAKE SEGMENT 0 IF MOVABLE

		CMP	ECX,1
		JZ	TAKE_ANY

		CMP	ESI,12
		JB	TAKE_ANY		;NO PREVIOUS THIS BLOCK TO CHECK...
		;
		;TRY TO USE PREVIOUS SEGMENT, ELSE TAKE ANY...
		;
		AND	DL,4		;MOVABLE?
		JNZ	L25$

		MOV	AL,[EBP+ESI-7]

		SHL	EAX,SEGTBL_BITS
L25$:
		MOV	EDI,EAX
		MOV	EAX,SEGMENT_TABLE[EAX]._SEGTBL_PSIZE	;ONE HERE?

		TEST	EAX,EAX
		JZ	TAKE_ANY
L4$:
		PUSHM	ESI
		MOV	ESI,EAX
		;
		;USE FIRST (ACTUALLY LAST..) FROM THIS SEGMENT
		;
		CONVERT	EAX,EAX,ENTRYNAME_GARRAY
		ASSUME	EAX:PTR ENT_STRUCT

		MOV	EDX,[EAX]._ENT_NEXT_HASH_GINDEX
		MOV	[EAX]._ENT_ORD,ECX		;CALLED ELSEWHERE...

		MOV	SEGMENT_TABLE[EDI]._SEGTBL_PSIZE,EDX
		GETT	DL,ALL_EXPORTS_BY_ORDINAL

		OR	DL,DL
		JZ	L45$

		TEST	[EAX]._ENT_FLAGS,MASK ENT_BYNAME
		JNZ	L45$

		OR	[EAX]._ENT_FLAGS,MASK ENT_ORD_SPECIFIED
		;
		;CHECK FOR WEP
		;
		CMP	DPTR [EAX]._ENT_TEXT,'PEW'
		JZ	L44$
L43$:
		MOV	EDI,ESI
		CALL	OO_NONRESIDENT		;MAYBE STORED NOWHERE... (/Gn)

		POP	ESI
		JMP	L3$

L44$:
		OR	[EAX]._ENT_FLAGS,MASK ENT_RESIDENTNAME
L45$:
		MOV	EDI,ESI
		CALL	OO_RESIDENT

		POP	ESI
		JMP	L3$

TAKE_NEXT:
		INC	LOWEST_SEGMENT
TAKE_ANY:
		ASSUME	EAX:NOTHING
		;
		;HERE IS A HOLE, SCAN SEGMENT_TABLE FOR SOME NEEDY SOUL.
		;IF NONE IS FOUND, DO_BYNAMES IS COMPLETE...
		;
		;CX IS ORDINAL, DX:DS:SI IS _ENT ITEM
		;
		;
		;GO FROM LOWEST_SEGMENT TO HIGHEST SEGMENT LOOKING...
		;
		MOV	EDI,LOWEST_SEGMENT
		MOV	EAX,HIGHEST_SEGMENT

		CMP	EAX,EDI
		JZ	BYNAMES_DONE

		SHL	EDI,SEGTBL_BITS

		MOV	EAX,SEGMENT_TABLE[EDI]._SEGTBL_PSIZE

		TEST	EAX,EAX
		JZ	TAKE_NEXT

		JMP	L4$

BYNAMES_DONE:
		POPM	EBX,ESI,EDI,EBP

		RET

DO_BYNAMES	ENDP


HANDLE_ENTRY	PROC	NEAR	PRIVATE
		;
		;EAX IS ENTRY POINT, NO REGS NEED SAVED
		;ECX IS INDEX
		;
		ASSUME	EAX:PTR ENT_STRUCT

		PUSHM	EDI,ESI,EBX
		MOV	EDX,[EAX]._ENT_ORD	;WAS ORDINAL # SPECIFIED?

		MOV	ESI,EAX
		MOV	EDI,ECX
		ASSUME	ESI:PTR ENT_STRUCT

		TEST	EDX,EDX
		JZ	L5$
		;
		;ORDINAL IS SPECIFIED, STORE IN ENTRY-POINT TABLE
		;
		MOV	DL,[EAX]._ENT_FLAGS
		MOV	EBX,DPTR [EAX]._ENT_TEXT

		AND	DL,MASK ENT_RESIDENTNAME + MASK ENT_BYNAME
		JNZ	O_RESIDENT
		;
		;FORCE RESIDENT ON 'WEP'
		;
		CMP	EBX,'PEW'
		JNZ	O_NONRESIDENT

		OR	DL,MASK ENT_RESIDENTNAME

		MOV	[EAX]._ENT_FLAGS,DL
		JMP	O_RESIDENT

OO_NONRESIDENT::
		PUSHM	EDI,ESI,EBX
		MOV	ESI,EAX
O_NONRESIDENT:
		GETT	BL,KILL_NONRESIDENT_NAMES
		MOV	DL,[EAX]._ENT_FLAGS

		OR	BL,BL
		JZ	O_NON_1

		OR	DL,MASK ENT_NONAME

		MOV	[EAX]._ENT_FLAGS,DL
O_NON_1:
		ASSUME	EAX:NOTHING

		AND	DL,MASK ENT_NONAME	;MAYBE PUT TEXT NOWHERE...
		JNZ	O_RET
		;
		;PUT TEXT IN NON-RESIDENT NAME TABLE
		;
		MOV	ECX,[ESI]._ENT_ORD
		CALL	STORE_NONRESIDENT	;PRESERVE EAX
O_RET:
		MOV	THIS_ENTRY_GINDEX,EDI
		MOV	DL,[ESI]._ENT_PWORDS	;

		SHL	DL,3
		MOV	EBX,[ESI]._ENT_ORD

		MOV	EAX,FLAG_0C
		MOV	CL,[ESI]._ENT_FLAGS

		TEST	EAX,MASK APPSOLO	;SET SHARED_DATA FLAG ONLY IF .DLL, ETC
		JZ	L49$

		AND	CL,MASK ENT_NODATA
		JNZ	L49$
		;
		;ONLY MARK THIS IF A .DLL
		;
		AND	EAX,MASK APPTYPE	;SET IF LIBRARY
		JZ	L49$

		OR	DL,2			;SHARED DATA
L49$:
		;
		;NOW PUT STUFF IN ENTRY_TABLE AND HASHED_ENTRY_TABLE
		;
		MOV	ESI,[ESI]._ENT_INTERNAL_NAME_GINDEX
		OR	DL,1			;EXPORTED

		CONVERT	ESI,ESI,SYMBOL_GARRAY
		ASSUME	ESI:PTR SYMBOL_STRUCT
		;
		;SYMBOL MUST BE SYM_RELOC
		;
		MOV	AL,[ESI]._S_NSYM_TYPE
		MOV	ECX,[ESI]._S_OFFSET	;TOTAL OFFSET

		CMP	AL,NSYM_RELOC
		JNZ	L2$

		MOV	DH,BPTR [ESI]._S_OS2_NUMBER
		MOV	EAX,[ESI]._S_OS2_FLAGS
L12$:
		TEST	EAX,1 SHL SR_DPL 	;IF IOPL, KEEP PARAM #
		JNZ	L11$

		AND	DL,NOT (31 SHL 3)
L11$:
		CALL	INSTALL_ENTRIES		;DH=SEG#, DL=FLAGS, EBX=ORD#, EAX=OS2_FLAGS, ECX=OFFSET

		POPM	EBX,ESI,EDI

		RET

OO_RESIDENT::
		PUSHM	EDI,ESI,EBX
		MOV	ESI,EAX
O_RESIDENT:
		ASSUME	ESI:PTR ENT_STRUCT
		MOV	ECX,[ESI]._ENT_ORD
		CALL	STORE_RESIDENT
		JMP	O_RET

L2$:
		CMP	AL,NSYM_CONST
		JZ	L21$

		CMP	AL,NSYM_ASEG
		JNZ	L29$
		;
		;CONSTANT ISSUES JUST A WARNING, FAKE SEGMENT TO A 1
		;
L21$:
;		PUSHM	EDX
;		LEA	ECX,[ESI]._S_NAME_TEXT

;		MOV	AL,EXP_CONST_ERR
;		CALL	WARN_ASCIZ_RET

;		POP	EDX
		XOR	ECX,ECX		;OFFSET 0

		MOV	DH,0FEH		;SEGMENT 254
		JMP	L12$

L5$:
		;
		;NO ORDINAL # SPECIFIED, LINK THIS TO ITS SEGMENT FOR NOW...
		;(MOVABLES LINK TO IMAGINARY SEGMENT 0)
		;
		;ESI IS ENTRY POINT... EDI IS INDEX
		;
		MOV	EDX,[ESI]._ENT_INTERNAL_NAME_GINDEX
		CONVERT	EDX,EDX,SYMBOL_GARRAY
		ASSUME	EDX:PTR SYMBOL_STRUCT

		MOV	AL,[EDX]._S_NSYM_TYPE
		MOV	ECX,[EDX]._S_OS2_NUMBER

		CMP	AL,NSYM_RELOC
		JNZ	L7$

		SHL	ECX,SEGTBL_BITS
		MOV	EAX,[EDX]._S_OS2_FLAGS

		AND	EAX,MOVABLE_MASK
		JNZ	L62$
L63$:
		MOV	EAX,SEGMENT_TABLE[ECX]._SEGTBL_PSIZE
		MOV	SEGMENT_TABLE[ECX]._SEGTBL_PSIZE,EDI

		MOV	[ESI]._ENT_NEXT_HASH_GINDEX,EAX
		POPM	EBX,ESI,EDI

		RET

L29$:
if	fg_td
		BITT	TLINK_DEFAULT_MODE
		JNZ	L291$
endif
		ASSUME	ESI:PTR SYMBOL_STRUCT

		LEA	ECX,[ESI]._S_NAME_TEXT
		MOV	AL,EXP_CONST_ERR

		CALL	ERR_ASCIZ_RET
L291$:
		MOV	EAX,THIS_ENTRY_GINDEX
		POPM	EBX,ESI,EDI

		CONVERT	EAX,EAX,ENTRYNAME_GARRAY
		ASSUME	EAX:PTR ENT_STRUCT

		OR	[EAX]._ENT_FLAGS,MASK ENT_UNDEFINED

		RET

		ASSUME	EAX:NOTHING
L62$:
		XOR	ECX,ECX
		JMP	L63$

		ASSUME	ESI:PTR ENT_STRUCT
L7$:
		CMP	AL,NSYM_CONST
		JZ	L71$

		CMP	AL,NSYM_ASEG
		JNZ	L79$
		;
		;CONSTANT ISSUES JUST A WARNING, FAKE SEGMENT TO A 1
		;
L71$:
;		CALL	WARN_PNAME_ESDI_RET

		MOV	ECX,0FEH SHL 3		;SEGMENT 1
		JMP	L63$

L79$:
if	fg_td
		BITT	TLINK_DEFAULT_MODE
		JNZ	L791$
endif
		LEA	ECX,[EDX]._S_NAME_TEXT
		MOV	AL,EXP_CONST_ERR

		CALL	ERR_ASCIZ_RET
L791$:
		OR	[ESI]._ENT_FLAGS,MASK ENT_UNDEFINED
		POPM	EBX,ESI,EDI

		RET

		ASSUME	ESI:NOTHING

HANDLE_ENTRY	ENDP


INSTALL_ENTRIES PROC	NEAR
		;
		;DH IS SEGMENT #, DL IS FLAGS
		;EBX IS ORDINAL #
		;EAX IS OS2_FLAGS
		;ECX IS OFFSET
		;
		;FIRST PUT IT IN ENTRY_TABLE
		;
		PUSHM	EDI,ESI

		MOV	EDI,EBX
		PUSH	EBX

		SHR	EBX,PAGE_BITS-3
		AND	EDI,(PAGE_SIZE-1) SHR 3

		MOV	ESI,EAX

		LEA	EBX,ENTRY_TABLE[EBX*4]
		CALL	CONVERT_SUBBX_TO_EAX

		MOV	[EAX+EDI*8],ECX
		MOV	[EAX+EDI*8+4],EDX
		;
		;NOW INSTALL IN HASHED_ENTRY_TABLE FOR LATER USE...
		;(IF PROTMODE, ONLY DO IT IF IOPL, ELSE DO IT IF IOPL OR
		; MOVABLE OR DISCARDABLE)
		;
		AND	ESI,MOVABLE_MASK
		JNZ	L5$

		POPM	EBX,ESI,EDI

		RET

L5$:
		;
		;
		;
		OR	BPTR [EAX+EDI*8+4],4	;MARK IT MOVABLE...
		MOV	DL,DH

		MOV	EAX,ECX
		POP	ECX

		POPM	ESI,EDI

		JMP	INSTALL_ENTRY		;EAX IS OFFSET, ECX IS ORDINAL, DL IS SEGMENT

INSTALL_ENTRIES ENDP


STORE_NONRESIDENT:
		MOV	EDX,OFF NONRESIDENT_STRUCTURE
		JMP	STR_1


STORE_RESIDENT	PROC	NEAR
		;
		;EAX IS _ENT_ STRUCTURE, SEND TEXT AND ORD # (IN ECX) TO
		;RESIDENT NAME TABLE
		;
		ASSUME	EAX:PTR ENT_STRUCT

		MOV	EDX,OFF RESIDENT_STRUCTURE
STR_1::
		PUSHM	EDX,ECX
		;
		;FIRST, COPY STUFF TO SYMBOL_
		;
		LEA	ECX,[EAX]._ENT_TEXT
		MOV	EAX,OFF SYMBOL_TEXT
		ASSUME	EAX:NOTHING

		CALL	MOVE_ASCIZ_ECX_EAX	;RETURNS EAX POINTING TO ZERO

		POP	ECX

		MOV	[EAX],ECX		;ORD #
		SUB	EAX,OFF SYMBOL_TEXT

		MOV	SYMBOL_LENGTH,EAX
STR_3:
		MOV	EAX,OFF SYMBOL_LENGTH+3
		MOV	ECX,SYMBOL_LENGTH

		OR	CH,CH
		JNZ	STR_8

		POP	EDX
		MOV	[EAX],CL

		PUSH	ESI
		MOV	ESI,EDX

		ADD	ECX,3
		CALL	STORE_EAXECX_EDX_SEQ

		MOV	EAX,[ESI].SEQ_STRUCT._SEQ_PTR
		POP	ESI

		CMP	EAX,64K
		JAE	STR_9

		RET

STR_2::
		PUSH	EAX
		JMP	STR_3

STR_8:
		MOV	AL,EXPORT_TOO_LONG_ERR
		CALL	ERR_SYMBOL_TEXT_ABORT

STR_9:
		MOV	AL,EXP_TEXT_ERR
		CALL	ERR_ABORT

STORE_RESIDENT	ENDP


FLUSH_RESIDENT_NAMES	PROC	NEAR

		MOV	EDX,OFF RESIDENT_STRUCTURE
		MOV	EAX,OFF SYMBOL_LENGTH		;NEED A ZERO AT END OF RESIDENT NAMES...

		MOV	ECX,1

		MOV	[EAX],CH
		CALL	STORE_EAXECX_EDX_SEQ

		MOV	EAX,OFF RESIDENT_STRUCTURE
		ASSUME	EAX:PTR SEQ_STRUCT

		MOV	ECX,[EAX]._SEQ_PTR

		MOV	RESNAMES_SIZE,ECX
		JMP	FLUSH_NAMES

		ASSUME	EAX:NOTHING

FLUSH_RESIDENT_NAMES	ENDP


FLUSH_NONRESIDENT_NAMES PROC	NEAR

		MOV	EDX,OFF NONRESIDENT_STRUCTURE
		MOV	EAX,OFF SYMBOL_LENGTH

		MOV	ECX,1

		MOV	[EAX],CH
		CALL	STORE_EAXECX_EDX_SEQ

		MOV	EAX,OFF NONRESIDENT_STRUCTURE
		CALL	FLUSH_NAMES_A

		MOV	EAX,OS2_EXEHDR_START

		ADD	NEXEHEADER._NEXE_NRESNAM_OFFSET,EAX

		RET

FLUSH_NONRESIDENT_NAMES ENDP


FLUSH_NAMES_A:
		ASSUME	EAX:PTR SEQ_STRUCT

		MOV	EDX,NEXEHEADER._NEXE_NRESNAM_OFFSET
		MOV	ECX,[EAX]._SEQ_PTR

		MOV	NEXEHEADER._NEXE_NONRES_LENGTH,CX
		MOV	NONRESNAMES_SIZE,ECX

		CMP	ECX,64K
		JB	FN_1

		CALL	EXEHDR_ERROR

		JMP	FN_1


FLUSH_NAMES	PROC	NEAR
		;
		;EAX IS NAMES STRUCTURE.
		;
		;FLUSH ANY DATA TO OUTPUT FILE, RELEASING STORAGE, UPDATE
		;NECESSARY INFO IN NEXEHEADER
		;
		MOV	ECX,[EAX]._SEQ_TARGET	;LIKE RESNAM_OFFSET
		XOR	EDX,EDX

		MOV	DX,[ECX] 		;TARGET ADDRESS
		MOV	ECX,[EAX]._SEQ_PTR

		ADD	ECX,EDX			;NEXT GUY'S TARGET ADDR
		PUSH	EDI

		CMP	ECX,64K
		JB	L0$

		CALL	EXEHDR_ERROR		;SET FLAG TO REPORT LATER...
L0$:
		MOV	EDI,[EAX]._SEQ_NEXT_TARGET

		MOV	[EDI],CX
		POP	EDI

		SUB	ECX,EDX
FN_1::
		PUSHM	EDI,EBX

		MOV	EDI,EAX
		LEA	EBX,[EAX]._SEQ_TABLE
		;
		;ECX IS NUMBER OF BYTES TO WRITE
		;
		TEST	ECX,ECX
		JZ	L5$
L1$:
		MOV	EAX,[EBX]
		;
		;IF CX > PAGE_SIZE, WRITE PAGE_SIZE
		;
		PUSH	ECX

		CMP	ECX,PAGE_SIZE
		JB	L2$

		MOV	ECX,PAGE_SIZE
L2$:
		PUSHM	ECX,EDX

		CALL	MOVE_EAX_TO_EDX_NEXE

		XOR	ECX,ECX
		MOV	EAX,[EBX]

		MOV	[EBX],ECX		;SO CANCEL WORKS?
		CALL	RELEASE_SEGMENT

		POPM	EDX,EAX

		ADD	EBX,4
		POP	ECX

		ADD	EDX,EAX			;UPDATE OUTPUT POINTER
		SUB	ECX,EAX			;UPDATE COUNTER

		JNZ	L1$
L5$:
		XOR	EAX,EAX
		MOV	ECX,(SIZE SEQ_STRUCT)/4

		REP	STOSD

		POPM	EBX,EDI

		RET

		ASSUME	EAX:NOTHING

FLUSH_NAMES	ENDP


FLUSH_RESOURCE_NAMES	PROC	NEAR
		;
		;RESOURCE NAMES ARE IN RESIDENT_STRUCTURE, WRITE THEM OUT NOW...
		;
		XOR	EDX,EDX
		MOV	EAX,OFF RESIDENT_STRUCTURE
		ASSUME	EAX:PTR SEQ_STRUCT

		MOV	DX,NEXEHEADER._NEXE_RSRCTBL_OFFSET
		MOV	ECX,RESOURCE_TABLE_SIZE

		ADD	EDX,ECX
		MOV	ECX,[EAX]._SEQ_PTR

		MOV	RESOURCE_NAMES_SIZE,ECX
		JMP	FN_1

		ASSUME	EAX:NOTHING

FLUSH_RESOURCE_NAMES	ENDP


BUILD_FLUSH_IMPORTS	PROC	NEAR
		;
		;THIS BUILDS MODREF_TABLE AND IMPORT_NAMES TABLE AND SENDS
		;THEM TO THE .EXE OR .DLL FILE
		;
		;I THINK WE WILL WRITE MODULE NAMES DIRECTLY TO EXE...
		;
		MOV	EAX,N_IMPMODS
		XOR	ECX,ECX

		MOV	CX,NEXEHEADER._NEXE_MODREF_OFFSET
		PUSH	EBX

		MOV	NEXEHEADER._NEXE_NMODS,AX
		LEA	EAX,[EAX*2+ECX]			;2 BYTES PER MODULE REFERENCED

		CMP	EAX,64K
		JB	L0$

		CALL	EXEHDR_ERROR
L0$:
		MOV	NEXEHEADER._NEXE_IMPNAM_OFFSET,AX

		MOV	RESIDENT_STRUCTURE._SEQ_TARGET,OFF NEXEHEADER._NEXE_IMPNAM_OFFSET

		MOV	RESIDENT_STRUCTURE._SEQ_NEXT_TARGET,OFF NEXEHEADER._NEXE_ENTRY_OFFSET
		;
		;SCAN THROUGH HASH TABLE LOOKING FOR ITEMS...
		;THANKS.
		;
		MOV	EAX,N_IMPMODS

		TEST	EAX,EAX
		JZ	NO_IMPORTS		;SEMI-RARE...

		MOV	EAX,OFF ZEROS_16	;NEED LEADING ZERO
		XOR	EBX,EBX

		MOV	ECX,1
		MOV	EDX,OFF RESIDENT_STRUCTURE

		CALL	STORE_EAXECX_EDXEBX_RANDOM

		MOV	EAX,FIRST_IMPMOD_GINDEX
IMPMOD_LOOP:
		CONVERT	EAX,EAX,IMPMOD_GARRAY
		ASSUME	EAX:PTR IMPMOD_STRUCT

		MOV	EDX,[EAX]._IMPM_NEXT_GINDEX		;NEXT IMPMOD
		MOV	ECX,[EAX]._IMPM_NUMBER			;MODULE #

		PUSH	EDX
		MOV	EDX,[EAX]._IMPM_NAME_SYM_GINDEX		;FIRST SYMBOL IMPORTED BY NAME

		PUSHM	EDX,EDX
		CALL	DO_IMP_MODULE

		POP	EAX
		JMP	TEST_SYMBOL

NEXT_ELEMENT:
		CONVERT	EAX,EAX,SYMBOL_GARRAY
		ASSUME	EAX:PTR SYMBOL_STRUCT

		MOV	ECX,[EAX]._S_IMP_NEXT_GINDEX
		MOV	DL,[EAX]._S_REF_FLAGS

		PUSH	ECX
		MOV	DH,DL

		AND	DL,MASK S_IMP_ORDINAL	;1 IS BY ORDINAL...
		JNZ	L4$

		AND	DH,MASK S_REFERENCED
		JZ	L4$

		CALL	HANDLE_IMPORT
L4$:
		POP	EAX
TEST_SYMBOL:
		TEST	EAX,EAX
		JNZ	NEXT_ELEMENT

		POP	EAX
		CALL	DO_CLEAR_OFFSETS

		POP	EAX

		TEST	EAX,EAX
		JNZ	IMPMOD_LOOP
		;
		;FIRST RELEASE DATA USED BY IMPORTS
		;
		CALL	UNUSE_IMPORTS
		;
		;MODULE REFS ALREADY WRITTEN, NOW WRITE NAMES TO FILE
		;THEN ADJUST ENTRY-POINT OFFSET
		;
NO_IMPORTS:
		MOV	ECX,RESIDENT_STRUCTURE._SEQ_PTR
		MOV	EAX,OFF RESIDENT_STRUCTURE

		MOV	IMPNAMES_SIZE,ECX
		POP	EBX
		CALL	FLUSH_NAMES
;		CALL	FLUSH_RESIDENT_NAMES
		RET

		ASSUME	EAX:NOTHING

BUILD_FLUSH_IMPORTS	ENDP


DO_CLEAR_OFFSETS	PROC	NEAR
		;
		;AX = INDEX, IF DUP_MODNAMS, CLEAR OFFSET FOR ALL SYMBOL THIS MOD
		;
		GETT	DL,DUP_MODNAMS_PLEASE

		OR	DL,DL
		JNZ	L3$

		RET

NEXT_ELEMENT:
		CONVERT	EAX,EAX,SYMBOL_GARRAY
		ASSUME	EAX:PTR SYMBOL_STRUCT

		MOV	ECX,[EAX]._S_IMP_IMPNAME_GINDEX
		MOV	DL,[EAX]._S_REF_FLAGS

		MOV	EAX,[EAX]._S_IMP_NEXT_GINDEX
		AND	DL,MASK S_IMP_ORDINAL	;1 IS BY ORDINAL...

		JNZ	L3$

		CONVERT	ECX,ECX,IMPNAME_GARRAY
		ASSUME	ECX:PTR IMPNAME_STRUCT

		MOV	[ECX]._IMP_OFFSET,0
L3$:
		TEST	EAX,EAX
		JNZ	NEXT_ELEMENT

		RET

		ASSUME	EAX:NOTHING

DO_CLEAR_OFFSETS	ENDP


DO_IMP_MODULE	PROC	NEAR
		;
		;EAX IS _IMPM_ STRUCTURE, ECX IS MODULE #
		;
		ADD	EAX,IMPMOD_STRUCT._IMPM_OFFSET
		GETT	DL,DUP_MODNAMS_PLEASE		;ALWAYS OUTPUT NAME?

		OR	DL,DL
		JNZ	L1$
		;
		;SEE IF MODNAME OFFSET ALREADY DEFINED
		;
		MOV	EDX,[EAX]				;NO, JUST IF NOT ALREADY DONE...

		TEST	EDX,EDX
		JNZ	L2$

		MOV	EDX,RESIDENT_STRUCTURE._SEQ_PTR

		MOV	[EAX],EDX
L1$:
		PUSH	EAX
		MOV	EAX,OFF RESIDENT_STRUCTURE._SEQ_PTR

		CALL	STORE_MODINDEX

		POP	EAX

		ADD	EAX,IMPMOD_STRUCT._IMPM_TEXT-IMPMOD_STRUCT._IMPM_OFFSET
		;
		;STICK 0 AT DOT PLEASE FOR BORLAND
		;
		PUSHM	EAX,ECX

		XOR	ECX,ECX
L11$:
		MOV	DL,[EAX]
		INC	EAX

		CMP	DL,'.'
		JZ	L12$

		OR	DL,DL
		JNZ	L11$

		TEST	ECX,ECX
		JZ	L13$

		MOV	[ECX-1],DL
		JMP	L13$

L12$:
		MOV	ECX,EAX
		JMP	L11$

L13$:
		POPM	ECX,EAX

STORE_NAME_RESIDENT::
		MOV	ECX,EAX
		MOV	EAX,OFF SYMBOL_TEXT

		CALL	MOVE_ASCIZ_ECX_EAX

		SUB	EAX,OFF SYMBOL_TEXT
		MOV	EDX,OFF RESIDENT_STRUCTURE

		MOV	ECX,EAX
		MOV	EAX,OFF SYMBOL_TEXT-1

		OR	CH,CH
		JNZ	L18$
		;
		;EAX IS IMPORTED SYMBOL TEXT, WRITE IT TO IMPORT-TABLE
		;
		MOV	[EAX],CL
		INC	ECX

		JMP	STORE_EAXECX_EDX_SEQ

L18$:
		MOV	AL,IMPORT_TOO_LONG_ERR
		CALL	ERR_SYMBOL_TEXT_ABORT



L2$:
STORE_MODINDEX:
		XOR	EDX,EDX
		DEC	ECX

		MOV	DX,NEXEHEADER._NEXE_MODREF_OFFSET
		ADD	ECX,ECX

		ADD	EDX,ECX
		MOV	ECX,2

		JMP	MOVE_EAX_TO_EDX_NEXE

DO_IMP_MODULE	ENDP


HANDLE_IMPORT	PROC	NEAR
		;
		;EAX IS SYMBOL PHYSICAL ADDRESS
		;
		ASSUME	EAX:PTR SYMBOL_STRUCT

		MOV	ECX,[EAX]._S_IMP_IMPNAME_GINDEX
		CONVERT	ECX,ECX,IMPNAME_GARRAY
		ASSUME	ECX:PTR IMPNAME_STRUCT
		PUSH	EBX

		MOV	EDX,[ECX]._IMP_OFFSET
		MOV	EBX,RESIDENT_STRUCTURE._SEQ_PTR

		TEST	EDX,EDX
		JNZ	L5$

		MOV	[ECX]._IMP_OFFSET,EBX
		MOV	[EAX]._S_IMP_NOFFSET,EBX
		;
		;DS:SI IS IMPORTED SYMBOL TEXT, WRITE IT TO IMPORT-TABLE
		;
		POP	EBX
		LEA	EAX,[ECX]._IMP_TEXT

		JMP	STORE_NAME_RESIDENT

L5$:
		POP	EBX
		MOV	[EAX]._S_IMP_NOFFSET,EDX

		RET

		ASSUME	EAX:NOTHING

HANDLE_IMPORT	ENDP


DO_PENTS	PROC	NEAR
		;
		;FIRST, SCAN TABLE OF POSSIBLE-ENTRIES, LINKING THEM TO THEIR
		;SEGMENT IF IT IS A REAL ENTRY..., ELSE IT IS IGNORED.
		;
		PUSH	ESI
		MOV	ESI,LAST_PENT_GINDEX

		TEST	ESI,ESI
		JZ	NO_PENTS		;QUITE COMMON IF NO IOPL AND
NEXT_ELEMENT:
		MOV	EDX,ESI
		CONVERT	ESI,ESI,PENT_GARRAY
		ASSUME	ESI:PTR PENT_STRUCT
		MOV	EAX,[ESI]._PENT_REF_COUNT	;THIS CAN BE ZERO FROM FARCALLTRANSLATE AND DELETED COMDATS

		MOV	ECX,ESI
		MOV	ESI,[ESI]._PENT_NEXT_GINDEX

		TEST	EAX,MASK P_REF_COUNT
		JZ	L2$

		CALL	HANDLE_PENT
L2$:
		TEST	ESI,ESI
		JNZ	NEXT_ELEMENT

		POP	ESI
		JMP	ENTER_PENTS

NO_PENTS:
		POP	ESI

		RET

		ASSUME	ESI:NOTHING

DO_PENTS	ENDP


HANDLE_PENT	PROC	NEAR
		;
		;EDX IS PENT GINDEX, ECX IS PENT, EAX IS FLAGS
		;
		ASSUME	ECX:PTR PENT_STRUCT

		PUSHM	EBX,EDX

		MOV	EDX,[ECX]._PENT_SEGM_GINDEX	;SEGMENT OR SYMBOL...
		MOV	EBX,[ECX]._PENT_OFFSET
		;
		;0=SEGMOD, 1=SYMBOL, 2=GROUP
		;
		CMP	EAX,40000000H
		JB	SEGMENTT

		CMP	EAX,80000000H
		JAE	GROUPP
L2$:
		;
		;SYMBOL
		;
		;MUST BE RELOCATABLE, CONVERT TO SEGMENT-OFFSET
		;
		CONVERT	EDX,EDX,SYMBOL_GARRAY
		ASSUME	EDX:PTR SYMBOL_STRUCT

		MOV	AL,[EDX]._S_NSYM_TYPE

		CMP	AL,NSYM_RELOC
		JNZ	L9$				;IGNORE IF NOT RELOCATABLE

		ADD	EBX,[EDX]._S_OFFSET		;OFFSET FROM SEGMENT
		MOV	ECX,[EDX]._S_OS2_FLAGS

		MOV	EDX,[EDX]._S_OS2_NUMBER
		JMP	L31$

SEGMENTT:
		;
		;SEGMOD
		;
		CONVERT	EDX,EDX,SEGMOD_GARRAY
		ASSUME	EDX:PTR SEGMOD_STRUCT

		ADD	EBX,[EDX]._SM_START
		MOV	EAX,[EDX]._SM_BASE_SEG_GINDEX		;WHAT IF UNUSED COMDAT?

		TEST	EAX,EAX					;UNASSIGNED COMDAT?
		JZ	L9$

L3$:
		CONVERT	EAX,EAX,SEGMENT_GARRAY
		ASSUME	EAX:PTR SEGMENT_STRUCT

		MOV	ECX,[EAX]._SEG_OS2_FLAGS			;MUST BE MOVABLE
		MOV	EDX,[EAX]._SEG_OS2_NUMBER
L31$:
		MOV	EAX,MOVABLE_MASK
		ASSUME	EAX:NOTHING

		AND	EAX,ECX
		JZ	L9$

		TEST	EAX,MASK SR_MOVABLE+MASK SR_DISCARD	;MOVABLE-DISCARDABLE, ALWAYS ENTRY
		JNZ	L0$
		;
		;MUST BE IOPL.  ONLY USE IT IF CODE SEGMENT, NONCONFORMING
		;
		AND	ECX,MASK SR_CONF+1
		JNZ	L9$
		;
		;INSTALL IT IN ENTRY-POINT HASH TABLE.	IF ALREADY THERE, SKIP
		;LINKING IT TO SEGMENT...
		;
		;NEED SEGMENT #, OFFSET, THATS IT?
		;
L0$:
L1$:
		XOR	ECX,ECX				;NO ORDINAL # YET...
		MOV	EAX,EBX

		PUSH	EDX
		CALL	INSTALL_ENTRY			;DL:AX IS SEG:OFFSET, CX IS ORDINAL #

		POP	EAX
		JC	L9$				;CARRY MEANS ALREADY THERE
		;
		;NEW ONE, LINK IT IN TO CORRECT SEGMENT
		;
		;	*** ALL MOVABLE, SO USE SEGMENT 0 ***
		;
		POP	EDX

		MOV	ECX,EDX
		CONVERT	EDX,EDX,PENT_GARRAY
		ASSUME	EDX:PTR PENT_STRUCT

		MOV	[EDX]._PENT_OFFSET,EBX
		MOV	[EDX]._PENT_OS2_NUMBER,EAX

		MOV	EAX,SEGMENT_TABLE._SEGTBL_PSIZE
		MOV	SEGMENT_TABLE._SEGTBL_PSIZE,ECX

		POP	EBX
		MOV	[EDX]._PENT_NEXT_HASH_GINDEX,EAX

		RET

L9$:
		POPM	ECX,EBX

		RET

GROUPP:
		CONVERT	EDX,EDX,GROUP_GARRAY
		ASSUME	EDX:PTR GROUP_STRUCT

		MOV	EAX,[EDX]._G_OS2_FLAGS
		MOV	ECX,MOVABLE_MASK

		AND	EAX,ECX
		JZ	L9$

		TEST	EAX,MASK SR_MOVABLE+MASK SR_DISCARD
		JNZ	GROUP_5

		TEST	[EDX]._G_OS2_FLAGS,MASK SR_CONF+1
		JNZ	L9$
GROUP_5:
		ADD	EBX,[EDX]._G_OFFSET
		MOV	EDX,[EDX]._G_OS2_NUMBER

		JMP	L1$

HANDLE_PENT	ENDP


ENTER_PENTS	PROC	NEAR
		;
		;LIKE OTHER ENTRIES, SCAN THESE BUGGERS LOOKING FOR THE
		;BEST PLACE IN ENTRY_TABLE FOR OUR INFO
		;
;		CALL	INIT_ENTRY_TABLE
		;
		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBX,OFF ENTRY_TABLE
		MOV	ESI,12			;ZERO NOT USED...
L0$:
		CALL	CONVERT_SUBBX_TO_EAX

		MOV	EBP,EAX
L1$:
		MOV	ECX,[EBP+ESI]	 	;LOOK FOR FIRST EMPTY ORDINAL #
		ADD	ESI,8

		TEST	ECX,ECX
		JZ	L2$
L3$:
		CMP	ESI,PAGE_SIZE+4
		JNZ	L1$
		;
		;BLOCK FULL, TRY ANOTHER BLOCK
		;
		ADD	EBX,4
		MOV	ESI,4

if	page_size EQ 16K
		CMP	EBX,OFF ENTRY_TABLE+64
else
		CMP	EBX,OFF ENTRY_TABLE+128
endif
		JNZ	L0$
		;
		;TOO MANY ENTRIES
		;
		MOV	AL,TOO_ENTRIES_ERR
		CALL	ERR_ABORT

L2$:
		MOV	EAX,SEGMENT_TABLE._SEGTBL_PSIZE
		MOV	EDX,EBX

		TEST	EAX,EAX
		JZ	BYNAMES_DONE
		;
		;USE FIRST (ACTUALLY LAST..) FROM THIS SEGMENT
		;
		LEA	ECX,[ESI-8]
		SUB	EDX,OFF ENTRY_TABLE

		SHR	ECX,3
		CONVERT	EAX,EAX,PENT_GARRAY
		ASSUME	EAX:PTR PENT_STRUCT
		PUSH	EBX

		SHL	EDX,PAGE_BITS-3-2
		MOV	EBX,[EAX]._PENT_NEXT_HASH_GINDEX

		ADD	ECX,EDX			;ECX IS FIRST AVAILABLE ORDINAL NUMBER
		MOV	SEGMENT_TABLE._SEGTBL_PSIZE,EBX

		POP	EBX
		CALL	ENTER_PENT		;ECX IS ORDINAL #, EAX IS PENT

		JMP	L3$

BYNAMES_DONE:
		POPM	EBX,ESI,EDI,EBP

		MOV	EAX,OFF PENT_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF PENT_GARRAY
		JMP	RELEASE_GARRAY

ENTER_PENTS	ENDP


ENTER_PENT	PROC	NEAR
		;
		;ECX IS ORDINAL, EAX IS PENT
		;
		PUSH	EBX
		MOV	EBX,ECX

		MOV	DH,BPTR [EAX]._PENT_OS2_NUMBER
		MOV	ECX,[EAX]._PENT_OFFSET

		XOR	DL,DL
		MOV	EAX,-1

		CALL	INSTALL_ENTRIES		;DH=SEG#, DL=FLAGS, EBX=ORD#, EAX=OS2_FLAGS, ECX=OFFSET

		POP	EBX

		RET

		ASSUME	EAX:NOTHING

ENTER_PENT	ENDP


FLUSH_ENTRY_TABLE	PROC	NEAR
		;
		;
		;
		PUSHM	EBP,EDI,ESI,EBX

		XOR	EAX,EAX

		MOV	NEXEHEADER._NEXE_NMOVABLE_ENTS,AX

		MOV	AX,NEXEHEADER._NEXE_ENTRY_OFFSET

		MOV	ENTRY_OFFSET,EAX
		MOV	EBX,OFF ENTRY_TABLE
		;
		;OK, START AT HEAD OF ENTRY TABLE, STORING BUNDLES AS COMPACT
		;AS POSSIBLE
		;
		;USE TEMP_RECORD FOR BUILDING EACH BUNDLE
		;
		XOR	ECX,ECX		;CH = CURRENT SEGMENT, CL = COUNT MAX PER BUNDLE
		XOR	EDX,EDX		;# OF ENTRIES TO SKIP
		;
		;OFFSET DW	?
		;FLAGS	DB	?	;3-7=PWORDS, BIT2 MEANS MOVABLE
		;SEGNUM DB	?
		;
		XOR	ESI,ESI
		JMP	L286$

L1$:
		CALL	CONVERT_SUBBX_TO_EAX

		MOV	EBP,EAX
L2$:
		INC	EDX		;COUNT ITEMS SKIPPED
		ADD	ESI,8

		CMP	ESI,PAGE_SIZE	;HANDLE BLOCK CHANGE
		JZ	L28$

		CMP	BPTR 5[EBP+ESI],0	;NOTHING THERE, DO NEXT
		JZ	L2$

		DEC	EDX
		JNZ	L3$		;GO FLUSH UP TO THIS NUMBER
L39$:
		TEST	BPTR 4[EBP+ESI],4	;MOVABLE?
		JNZ	L4$		;YES, CHECK FOR MOVABLE

		CMP	5[EBP+ESI],CH	;SEGMENTS MATCH?
		JNZ	L5$		;NOPE, SET UP NEW SEGMENT
L59$:
		MOV	AL,4[EBP+ESI]	;FLAGS

		STOSB

		MOV	EAX,[EBP+ESI] 	;OFFSET

		STOSW
L21$:
		INC	ECX		;UPDATE COUNT

		CMP	CL,-1		;MAX OF 255 PER BUNDLE
		JNZ	L2$

		CALL	FLUSH_ENTRY_TEMP;
		JMP	L1$		;MAKE SURE TO MRU THIS BLOCK

L28$:
		DEC	EDX
		XOR	EAX,EAX

		XCHG	EAX,[EBX]

		OR	EAX,EAX
		JZ	L281$

		CALL	RELEASE_BLOCK
L281$:
		ADD	EBX,4
if	page_size EQ 16K
		CMP	EBX,OFF ENTRY_TABLE+64
else
		CMP	EBX,OFF ENTRY_TABLE+128
endif
		JZ	L29$

		MOV	ESI,-8
L286$:
		CMP	DPTR [EBX],0
		JNZ	L1$

		ADD	EDX,PAGE_SIZE/8
		JMP	L281$

L29$:
		JMP	L8$

L3$:
		;
		;EDX IS # OF ENTRIES TO SKIP
		;
		CALL	FLUSH_ENTRY_TEMP

		MOV	EAX,EDX		;AX IS # OF ENTRIES TO SKIP...
L31$:
		OR	AH,AH
		JZ	L33$
L32$:
		PUSH	EAX
		MOV	ECX,0FFH

		CALL	FLUSH_ENTRY_TEMP

		POP	EAX

		SUB	EAX,0FFH
		JMP	L31$

L33$:
		MOV	ECX,EAX
		CALL	FLUSH_ENTRY_TEMP

		XOR	EDX,EDX
		JMP	L39$

L4$:
		;
		;CHECK FOR MOVABLE
		;
		INC	NEXEHEADER._NEXE_NMOVABLE_ENTS

		CMP	CH,-1
		JNZ	L48$
L41$:
		MOV	AL,4[EBP+ESI]

		AND	AL,NOT 4	;CLEAR MOVABLE FLAG

		STOSB

		MOV	EAX,3FCDH

		STOSW

		MOV	AL,5[EBP+ESI]

		STOSB

		MOV	EAX,[EBP+ESI]

		STOSW

		JMP	L21$

L5$:
		;
		;SEGMENTS DON'T MATCH...
		;
		CALL	FLUSH_ENTRY_TEMP

		MOV	CH,5[EBP+ESI]
		JMP	L59$

L48$:
		CALL	FLUSH_ENTRY_TEMP

		MOV	CH,-1		;DOING MOVABLES
		JMP	L41$

L8$:
		CALL	FLUSH_ENTRY_TEMP

		CALL	FLUSH_ENTRY_FINAL

		MOV	EAX,ENTRY_OFFSET
		XOR	ECX,ECX

		MOV	NEXEHEADER._NEXE_NRESNAM_OFFSET,EAX

		MOV	CX,NEXEHEADER._NEXE_ENTRY_OFFSET

		SUB	EAX,ECX

		MOV	NEXEHEADER._NEXE_ENTRY_LENGTH,AX
		MOV	ENTRY_OFFSET,EAX

		CMP	EAX,64K
		JB	L9$

		CALL	EXEHDR_ERROR
L9$:
		POPM	EBX,ESI,EDI,EBP

		RET

FLUSH_ENTRY_TABLE	ENDP


FLUSH_ENTRY_TEMP	PROC	NEAR
		;
		;RETURNS
		;
		OR	CL,CL
		JZ	L9$
FLUSH_ENTRY_FINAL::
		PUSHM	EDX
		MOV	EAX,OFF TEMP_RECORD

		MOV	[EAX],CX 	;# OF ENTRIES THIS BUNDLE
		MOV	ECX,EDI

		SUB	ECX,EAX		;CX IS # OF BYTES TO WRITE
		MOV	EDX,ENTRY_OFFSET	;OFFSET FROM NEXEHEADER

		ADD	ENTRY_OFFSET,ECX
		CALL	MOVE_EAX_TO_EDX_NEXE

		POPM	EDX
L9$:
		XOR	ECX,ECX
		MOV	EDI,OFF TEMP_RECORD+2

		RET

FLUSH_ENTRY_TEMP	ENDP


DO_RESOURCE_NAMES	PROC	NEAR
		;
		;STORE RESOURCE NAMES IN RESIDENT STRUCTURE
		;
		MOV	EAX,FIRST_RESNAME_GINDEX

		TEST	EAX,EAX
		JZ	L9$
L1$:
		CONVERT	EAX,EAX,RESNAME_GARRAY
		ASSUME	EAX:PTR RESNAME_STRUCT

		MOV	ECX,[EAX]._RN_NEXT_RN_GINDEX
		ADD	EAX,RESNAME_STRUCT._RN_UNITEXT
		;
		;FIRST, COPY STUFF TO SYMBOL_TEXT
		;
		PUSH	ECX
		MOV	EDX,OFF SYMBOL_TEXT
		ASSUME	EAX:NOTHING

		XOR	ECX,ECX
L2$:
		MOV	CX,[EAX]		;UNICODE
		ADD	EAX,2

		MOV	[EDX],CL		;ASCII
		INC	EDX

		TEST	ECX,ECX
		JNZ	L2$

		SUB	EDX,OFF SYMBOL_TEXT+1
		MOV	EAX,OFF SYMBOL_LENGTH+3

		MOV	SYMBOL_LENGTH,EDX
		MOV	ECX,EDX

		OR	DH,DH
		JNZ	L8$

		MOV	[EAX],CL
		MOV	EDX,OFF RESIDENT_STRUCTURE

		INC	ECX
		CALL	STORE_EAXECX_EDX_SEQ

		POP	EAX

		TEST	EAX,EAX
		JNZ	L1$
L9$:
		RET

L8$:
		MOV	AL,RES_TOO_LONG_ERR
		CALL	ERR_SYMBOL_TEXT_ABORT

DO_RESOURCE_NAMES	ENDP


EXEHDR_ERROR	PROC
		;
		;
		;
		SETT	EXEHDR_ERROR_FLAG
		RET

EXEHDR_ERROR	ENDP


FLUSH_EXEHDR_ERROR	PROC	NEAR
		;
		;HEADER TOO BIG, PRINT DETAIL PLEASE
		;
		MOV	CURRENT_OFFSET,40

		MOV	EAX,SEGMENT_COUNT
		MOV	EDI,OFF SEGTBL_SIZE

		SHL	EAX,3
		CALL	DO_SIZE

		MOV	EDI,OFF RESTBL_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,RESOURCE_TABLE_SIZE
		MOV	EDI,OFF RESTBL_SIZE

		ADD	EAX,RESOURCE_NAMES_SIZE
		CALL	DO_SIZE

		MOV	EDI,OFF RESNAM_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,RESNAMES_SIZE
		MOV	EDI,OFF RESNAM_SIZE

		CALL	DO_SIZE

		MOV	EDI,OFF MODREF_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,N_IMPMODS
		MOV	EDI,OFF MODREF_SIZE

		ADD	EAX,EAX
		CALL	DO_SIZE

		MOV	EDI,OFF IMPNAM_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,IMPNAMES_SIZE
		MOV	EDI,OFF IMPNAM_SIZE

		CALL	DO_SIZE

		MOV	EDI,OFF ENTTBL_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,ENTRY_OFFSET		;ACTUALLY ENTRY TABLE SIZE
		MOV	EDI,OFF ENTTBL_SIZE

		CALL	DO_SIZE

		MOV	EDI,OFF NONTBL_OFFSET
		CALL	DO_OFFSET

		MOV	EAX,NONRESNAMES_SIZE
		MOV	EDI,OFF NONTBL_SIZE

		CALL	DO_SIZE
		;
		;NOW PRINT IT OUT
		;
		MOV	EAX,OFF EXEHDR_DATA
		MOV	ECX,EXEHDR_DATA_SIZE

		PUSHM	ECX,EAX

		CALL	LOUTALL_CON

		POPM	EAX,ECX

		CALL	LOUTALL

		MOV	AL,EXEHDR_ERR
		JMP	ERR_RET

FLUSH_EXEHDR_ERROR	ENDP


DO_OFFSET	PROC	NEAR
		;
		;
		;
		MOV	EAX,CURRENT_OFFSET
		JMP	OUT5

DO_OFFSET	ENDP


DO_SIZE		PROC	NEAR
		;
		;
		;
		ADD	CURRENT_OFFSET,EAX
		CALL	OUT5

		MOV	BPTR [EDI-1],0DH

		RET

DO_SIZE		ENDP


.DATA

EXEHDR_DATA	DB	'New .EXE Header     '
		DB	'00000H  00040H',0dh,0ah
		DB	'Segment Table       '
SEGTBL_OFFSET	DB	'00040H  00000H',0DH,0AH
SEGTBL_SIZE	EQU	SEGTBL_OFFSET+8
		DB	'Resource Table      '
RESTBL_OFFSET	DB	'00000H  00000H',0DH,0AH
RESTBL_SIZE	EQU	RESTBL_OFFSET+8
		DB	'Resident Names      '
RESNAM_OFFSET	DB	'00000H  00000H',0DH,0AH
RESNAM_SIZE	EQU	RESNAM_OFFSET+8
		DB	'Module Reference    '
MODREF_OFFSET	DB	'00000H  00000H',0DH,0AH
MODREF_SIZE	EQU	MODREF_OFFSET+8
		DB	'Imported Names      '
IMPNAM_OFFSET	DB	'00000H  00000H',0DH,0AH
IMPNAM_SIZE	EQU	IMPNAM_OFFSET+8
		DB	'Entry Table         '
ENTTBL_OFFSET	DB	'00000H  00000H',0DH,0AH
ENTTBL_SIZE	EQU	ENTTBL_OFFSET+8
		DB	'NonResident Names   '
NONTBL_OFFSET	DB	'00000H  00000H',0DH,0AH
NONTBL_SIZE	EQU	NONTBL_OFFSET+8

EXEHDR_DATA_SIZE	EQU	$-EXEHDR_DATA


.DATA?

THIS_ENTRY_GINDEX	DD	?


		END

