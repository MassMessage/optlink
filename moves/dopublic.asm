		TITLE DOPUBLIC - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SYMBOLS
		INCLUDE	SEGMENTS
		INCLUDE	CDDATA

		PUBLIC	FIX_COMMUNAL_ENTRY,DO_PUBLIC,PREV_DEF_FAIL,FIX_VIRDEF_ENTRY,FIX_COMDAT_ENTRY


		.DATA

		EXTERNDEF	PUB_SEGMOD_GINDEX:DWORD,PUB_GROUP_GINDEX:DWORD,MOD_FIRST_PUBLIC_GINDEX:DWORD
		EXTERNDEF	LAST_PUBDEF_GINDEX:DWORD,SYMBOL_LENGTH:DWORD,FIRST_WEP_GINDEX:DWORD,LAST_EXTDEF_GINDEX:DWORD
		EXTERNDEF	CURNMOD_GINDEX:DWORD

		EXTERNDEF	PUB_OFFSET:DWORD,PUB_TYPE:DWORD,PUB_CV:DWORD

		EXTERNDEF	SEGMOD_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S,SYMBOL_GARRAY:STD_PTR_S,SYMBOL_TPTR:TPTR_STRUCT

		EXTERNDEF	OPTI_MOVE:DWORD


		.CODE	PASS1_TEXT

		EXTERNDEF	FAR_INSTALL:PROC,REMOVE_FROM_LIBSYM_LIST:PROC,REMOVE_FROM_WEAK_LIST:PROC
		EXTERNDEF	REMOVE_FROM_EXTERNAL_LIST:PROC,ERR_SYMBOL_TEXT_RET:PROC,REMOVE_FROM_VIRDEF_LIST:PROC
		EXTERNDEF	REMOVE_FROM_ALIASED_LIST:PROC,REMOVE_FROM_COMMUNAL_LIST:PROC,REMOVE_FROM_WEAK_DEFINED_LIST:PROC
		EXTERNDEF	REMOVE_FROM_LAZY_LIST:PROC,REMOVE_FROM_LAZY_DEFINED_LIST:PROC,REMOVE_FROM_ALIAS_DEFINED_LIST:PROC
		EXTERNDEF	REMOVE_FROM_COMDAT_LIST:PROC,WARN_SYMBOL_TEXT_RET:PROC,REMOVE_FROM__IMP__LIST:PROC

		EXTERNDEF	PREV_DEF_ERR:ABS


WEP_HASH	EQU	9E2AH


DO_PUBLIC	PROC
		;
		;EDX IS HASH
		;
		PUSH	ESI

if	fg_td
		MOV	ESI,OFF SYMBOL_TPTR
		ASSUME	ESI:PTR TPTR_STRUCT
		CMP	EDX,WEP_HASH
		JZ	WEP_SPEC
WEP__WEP:
endif
		CALL	FAR_INSTALL		;EAX IS GINDEX, ECX IS PHYS
		ASSUME	ECX:PTR SYMBOL_STRUCT
WEP_FINISH:
		MOV	EDX,DPTR [ECX]._S_NSYM_TYPE

		AND	EDX,NSYM_ANDER
		PUSH	EBX
if	fg_td
		MOV	LAST_PUBDEF_GINDEX,EAX	;FOR BORLAND DEBUG INFO
endif
		JMP	DO_PUBLIC_TABLE[EDX*2]

if	fg_td
WEP_SPEC:
		CMP	[ESI]._TP_LENGTH,3
		JNZ	WEP__WEP
		CMP	DPTR [ESI]._TP_TEXT,'PEW'
		JNZ	WEP__WEP
		CMP	FIRST_WEP_GINDEX,0
		JNZ	WEP_DO__WEP
		CALL	FAR_INSTALL
		MOV	FIRST_WEP_GINDEX,EAX
		JMP	WEP_FINISH

WEP_DO__WEP:
		;
		;REPLACE NAME WITH __WEP
		;
		PUSHM	EDI,ESI
		MOV	EDI,ESI
		ASSUME	EDI:PTR TPTR_STRUCT
		MOV	ESI,OFF __WEP_TEXT
		GET_NAME_HASH
		POPM	ESI,EDI
		JMP	WEP__WEP

endif

DP__IMP:
		CALL	REMOVE_FROM__IMP__LIST
		JMP	DP_11

DP_LAZY:
		CALL	REMOVE_FROM_LAZY_LIST
		JMP	DP_11

DP_LAZY_DEFINED:
		CALL	REMOVE_FROM_LAZY_DEFINED_LIST
		JMP	DP_11

DP_ALIAS_DEFINED:
		CALL	REMOVE_FROM_ALIAS_DEFINED_LIST
		JMP	DP_11

DP_ALIASED:
		CALL	REMOVE_FROM_ALIASED_LIST
		JMP	DP_11

DP_5:
		;
		;IN LIBRARY LIST, REMOVE IT
		;
		CALL	REMOVE_FROM_LIBSYM_LIST

		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF			;WAS THIS ORIGINALLY A COMDEF?
		JZ	DP_11					;NO, OK

		JMP	DP_COMM_UNREF				;YES, CHECK DATA-CODE

DP_4:
		;
		;IN WEAK_EXTRN LIST, REMOVE IT PLEASE
		;
		CALL	REMOVE_FROM_WEAK_LIST
		JMP	DP_11

DP_4A:
		;
		;IN WEAK_DEFINED LIST, REMOVE IT PLEASE
		;
		CALL	REMOVE_FROM_WEAK_DEFINED_LIST
		JMP	DP_11

DP_1:
		CALL	REMOVE_FROM_EXTERNAL_LIST
DP_11:
DP_3:
DP_2::
		;
		;ECX IS SYMBOL, EAX IS GINDEX
		;
		;
		;ADD TO SEGMENT...
		;
		MOV	EDX,EAX
		MOV	EAX,PUB_SEGMOD_GINDEX

		MOV	EBX,CURNMOD_GINDEX
		MOV	[ECX]._S_SEG_GINDEX,EAX

		MOV	EAX,PUB_OFFSET
		MOV	[ECX]._S_MOD_GINDEX,EBX

		MOV	[ECX]._S_OFFSET,EAX
		MOV	EBX,PUB_CV

		MOV	[ECX]._S_CV_TYPE3,BX
		MOV	EAX,PUB_TYPE

		MOV	EBX,PUB_GROUP_GINDEX
if	any_overlays
		CMP	AL,NSYM_CONST
		JZ	PN_5
		CMP	AL,NSYM_ASEG
		JNZ	PN_9
PN_5:
		OR	[ECX]._S_PLTYPE,MASK LEVEL_0_SECTION
PN_9:
endif
		MOV	[ECX]._S_NSYM_TYPE,AL		;PUB_TYPE
		;
		;NEED TO LINK THIS INTO PUBLIC LIST
		;
		MOV	EAX,MOD_FIRST_PUBLIC_GINDEX
		MOV	MOD_FIRST_PUBLIC_GINDEX,EDX

		MOV	[ECX]._S_NEXT_SYM_GINDEX,EAX
		TEST	EBX,EBX

		POPM	EBX,ESI

		JNZ	L9$

		RET

L9$:
		OR	[ECX]._S_REF_FLAGS,MASK S_USE_GROUP

		RET

PREV_COMDAT:
		;
		;SAFELY OVERIDES A PICK-ANY COMDAT
		;
		MOV	EDX,[ECX]._S_CD_SEGMOD_GINDEX
		CONVERT	EDX,EDX,SEGMOD_GARRAY
		ASSUME	EDX:PTR CDSEGMOD_STRUCT

		MOV	DL,[EDX]._CDSM_ATTRIB

		AND	DL,0F0H

		CMP	DL,10H			;PICK ANY, DON'T EVEN CHECK SIZE
		JNZ	PREV_DEF_FAIL_A

		CALL	REMOVE_FROM_COMDAT_LIST
		JMP	DP_11

		ASSUME	ECX:PTR SYMBOL_STRUCT
PREV_CONST:
		;
		;MUST BE CONSTANT
		;
		MOV	EAX,PUB_TYPE
		MOV	EBX,PUB_OFFSET

		CMP	AL,NSYM_CONST
		JNZ	PREV_DEF_FAIL_A

		CMP	EBX,[ECX]._S_OFFSET
		JNZ	PREV_DEF_FAIL_A

		POPM	EBX,ESI

		RET

PREV_ASEG:
		MOV	EAX,PUB_TYPE

		CMP	AL,NSYM_ASEG
		JZ	PR_0

		JMP	PREV_DEF_FAIL_A

PREV_RELOC:
		MOV	EAX,PUB_TYPE

		CMP	AL,NSYM_RELOC
		JNZ	PREV_DEF_FAIL_A
PR_0:
		;
		;EAX IS GINDEX, ECX IS SYMBOL
		;
		;FIRST, GROUP INFO MUST MATCH
		;
		MOV	EBX,PUB_GROUP_GINDEX
		MOV	AL,[ECX]._S_REF_FLAGS

		TEST	EBX,EBX
		JZ	PR_NOG

		TEST	AL,MASK S_USE_GROUP
		JNZ	PREV_G_OK
PREV_DEF_FAIL_A:
		CALL	PREV_DEF_FAIL

		POPM	EBX,ESI

		RET

PR_NOG:
		TEST	AL,MASK S_USE_GROUP
		JNZ	PREV_DEF_FAIL_A
PREV_G_OK:
		MOV	EAX,PUB_OFFSET
		MOV	EDX,[ECX]._S_OFFSET

		CMP	EAX,EDX
		JNZ	PREV_DEF_FAIL_A
		;
		;SEGMENT BASES, NOT SEGMODS, MUST MATCH...
		;
		MOV	ECX,[ECX]._S_SEG_GINDEX
		CONVERT	ECX,ECX,SEGMOD_GARRAY
		ASSUME	ECX:PTR SEGMOD_STRUCT
		MOV	EAX,PUB_SEGMOD_GINDEX

		MOV	ECX,[ECX]._SM_BASE_SEG_GINDEX

		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT

		CMP	[EAX]._SM_BASE_SEG_GINDEX,ECX
		JNZ	PREV_DEF_FAIL_A

		CONVERT	ECX,ECX,SEGMENT_GARRAY
		ASSUME	ECX:PTR SEGMENT_STRUCT

		CMP	[ECX]._SEG_COMBINE,SC_COMMON	;MUST BE COMMON
		JNZ	PREV_DEF_FAIL_A

		POPM	EBX,ESI

		RET

		ASSUME	ECX:PTR SYMBOL_STRUCT
DP_LIB:
		;
		;ECX IS PHYS, AX IS LOG
		;
		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF			;WAS THIS COMDEF?
		JNZ	DP_COMM_UNREF				;YES, CHECK DATA-CODE

		JMP	DP_2

DP_COMM_UNREF:
		;
		;UNREFERENCED COMMUNAL
		;
		MOV	EBX,PUB_SEGMOD_GINDEX

		TEST	EBX,EBX					;MICROSOFT ALLOWS...
		JZ	DP_2

		CONVERT	EBX,EBX,SEGMOD_GARRAY
		ASSUME	EBX:PTR SEGMOD_STRUCT

		MOV	EBX,[EBX]._SM_BASE_SEG_GINDEX
		CONVERT	EBX,EBX,SEGMENT_GARRAY
		ASSUME	EBX:PTR SEGMENT_STRUCT

		MOV	BL,[EBX]._SEG_TYPE

		AND	BL,MASK SEG_CLASS_IS_CODE
		JZ	DP_2
PREV_DEF_FAIL_B:
		JMP	PREV_DEF_FAIL_A


		ASSUME	ECX:PTR SYMBOL_STRUCT

PREV_COMMUNAL:
		;
		;IS CURRENT SEG A CODE SEG?
		;
		MOV	EBX,PUB_SEGMOD_GINDEX

		TEST	EBX,EBX
		JZ	FIX_COMMUNAL_ENTRY1

		CONVERT	EBX,EBX,SEGMOD_GARRAY
		ASSUME	EBX:PTR SEGMOD_STRUCT

		MOV	EBX,[EBX]._SM_BASE_SEG_GINDEX
		CONVERT	EBX,EBX,SEGMENT_GARRAY
		ASSUME	EBX:PTR SEGMENT_STRUCT

		MOV	BL,[EBX]._SEG_TYPE

		AND	BL,MASK SEG_CLASS_IS_CODE
		JNZ	PREV_DEF_FAIL_B
FIX_COMMUNAL_ENTRY1:
		;
		;ECX IS PHYSICAL, EAX IS GINDEX
		;
		CALL	REMOVE_FROM_COMMUNAL_LIST
		JMP	DP_2

FIX_COMMUNAL_ENTRY::
		;
		;ECX IS PHYSICAL, EAX IS GINDEX
		;
		PUSH	ESI
		CALL	REMOVE_FROM_COMMUNAL_LIST

		PUSH	EBX
		JMP	DP_2


FIX_VIRDEF_ENTRY::
		;
		;ECX IS PHYSICAL, AX IS GINDEX
		;
		PUSH	ESI
		CALL	REMOVE_FROM_VIRDEF_LIST

		PUSH	EBX
		JMP	DP_2

FIX_COMDAT_ENTRY::
		;
		;ECX IS PHYSICAL, AX IS GINDEX
		;
		PUSH	ESI
		CALL	REMOVE_FROM_COMDAT_LIST

		PUSH	EBX
		JMP	DP_2


		.CONST

		ALIGN	4

DO_PUBLIC_TABLE	LABEL	DWORD

		DD	DP_2			;FRESH SYMBOL, JUST DEFINE
		DD	PREV_ASEG		;ALREADY ASEG, COMPARE
		DD	PREV_RELOC		;ALREADY RELOCATABLE, COMMON?
		DD	PREV_COMMUNAL		;NEAR COMMUNAL
		DD	PREV_COMMUNAL		;FAR COMMUNAL
		DD	PREV_COMMUNAL		;HUGE COMMUNAL
		DD	PREV_CONST		;ALREADY CONSTANT, COMPARE
		DD	DP_LIB			;IN A LIB, NOT REFERENCED, JUST DEFINE
		DD	PREV_DEF_FAIL_A		;IMPORTED, CANNOT BE DEFINED
		DD	DP_3			;PROMISED, JUST DEFINE
		DD	DP_1			;EXTERNAL, REMOVE FROM LIST
		DD	DP_4			;WEAK EXTRN, REMOVE FROM LIST
		DD	DP_2			;POSSIBLE WEAK, JUST DEFINE
		DD	DP_5			;IN LIBRARY LIST, REMOVE IT
		DD	DP_2			;__imp__UNREF, JUST DEFINE
		DD	DP_ALIASED		;DEFINING AN ALIASED SYMBOL
		DD	PREV_COMDAT		;ALREADY A COMDAT
		DD	DP_4A			;WEAK_DEFINED
		DD	DP_2			;WEAK-UNREF, JUST DEFINE
		DD	DP_2			;ALIASED-UNREF, JUST DEFINE
		DD	DP_2			;POS-LAZY, JUST DEFINE
		DD	DP_LAZY			;LAZY, UNDO, THEN DEFINE
		DD	DP_2			;LAZY-UNREF, JUST DEFINE
		DD	DP_ALIAS_DEFINED	;ALIAS-DEFINED, UNDO, THEN DEFINE
		DD	DP_LAZY_DEFINED		;LAZY-DEFINED, UNDO, THEN DEFINE
		DD	DP_COMM_UNREF		;NCOMM-UNREF, CHECK CODE-DATA, THEN DEFINE
		DD	DP_COMM_UNREF		;FCOMM-UNREF, CHECK CODE-DATA, THEN DEFINE
		DD	DP_COMM_UNREF		;HCOMM-UNREF
		DD	DP__IMP
		DD	DP_3			;UNDECORATED, CANNOT

.ERRNZ	($-DO_PUBLIC_TABLE)/2-NSYM_SIZE

if	fg_td

__WEP_TEXT	DB	5,'__WEP'

endif

		.CODE	PASS1_TEXT

DO_PUBLIC	ENDP


PREV_DEF_FAIL	PROC
		;
		;
		;
		XOR	EAX,EAX
		MOV	LAST_PUBDEF_GINDEX,EAX		;DON'T KEEP ANY PUBLIC TYPE INFO
		MOV	LAST_EXTDEF_GINDEX,EAX		;DON'T KEEP ANY EXTRN TYPE INFO
		MOV	AL,PREV_DEF_ERR

		BITT	LIB_OR_NOT		;ALWAYS AN ERROR IF NOT IN A
		JZ	PDF_5			;LIBRARY
		BITT	PREV_DEF_IS_ERROR
		JZ	PDF_9
PDF_5:
		CALL	ERR_SYMBOL_TEXT_RET
		RET

PDF_9:
		CALL	WARN_SYMBOL_TEXT_RET
		RET

PREV_DEF_FAIL	ENDP


		END
