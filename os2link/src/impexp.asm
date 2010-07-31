		TITLE	IMPEXP - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SYMBOLS
		INCLUDE	SEGMSYMS
		INCLUDE	CDDATA
		INCLUDE	EXES

		PUBLIC	DEFINE_EXPORT,DEFINE_IMPORT


		.DATA

		EXTERNDEF	EXP_PWORDS:BYTE,EXP_FLAGS:BYTE,EXP_FLAGS_EXT:WORD,SYMBOL_TEXT:BYTE,EXETYPE_FLAG:BYTE

		EXTERNDEF	IMPEXP_MOD:DWORD,IMPEXP_NAM:DWORD,IMP_ORDNUM:DWORD,IMPEXP_INTNAM:DWORD,EXP_ORDNUM:DWORD
		EXTERNDEF	SYMBOL_LENGTH:DWORD,IMP_MODNUM:DWORD,N_EXPORTS:DWORD,EXEPACK_TAIL_LIMIT:DWORD,FLAG_0C_MASK:DWORD
		EXTERNDEF	FLAG_0C:DWORD,DEF_SEGMENT_GINDEX:DWORD,CURNMOD_GINDEX:DWORD,PACK_DEFAULT_SIZE:DWORD,PACKCODE:DWORD
		EXTERNDEF	N_EXPORTS:DWORD,N_EXPORTS_BYNAME:DWORD,LOWEST_ORDINAL:DWORD,HIGHEST_ORDINAL:DWORD
		EXTERNDEF	ENTRYNAME_BITS:DWORD,FIRST_FARCALL:DWORD,LAST_FARCALL:DWORD,EXPORT_TEXT_SIZE:DWORD
		EXTERNDEF	FIRST_UNDECORATED_GINDEX:DWORD,EXP_BOTH_FLAGS:WORD

		EXTERNDEF	SEGMOD_GARRAY:STD_PTR_S,IMPNAME_GARRAY:STD_PTR_S,SYMBOL_GARRAY:STD_PTR_S,IMPMOD_GARRAY:STD_PTR_S
		EXTERNDEF	NEXEHEADER:NEXE

		EXTERNDEF	OPTI_MOVE:DWORD,OPTI_HASH:DWORD


		.CODE	ROOT_TEXT

		EXTERNDEF	FAR_INSTALL:PROC,ADD_TO_EXTERNAL_LIST:PROC,INSTALL_ENTRYNAME:PROC,ERR_SYMBOL_TEXT_RET:PROC
		EXTERNDEF	IMPNAME_INSTALL:PROC,REMOVE_FROM_WEAK_LIST:PROC,REMOVE_FROM_LIBSYM_LIST:PROC,TRY_UNDECORATED:PROC
		EXTERNDEF	REMOVE_FROM_EXTERNAL_LIST:PROC,OPTI_MOVE_UPPER_IGNORE:PROC,OPTI_MOVE_PRESERVE_SIGNIFICANT:PROC
		EXTERNDEF	RELEASE_BLOCK:PROC,LOC_11_RETT:PROC,REMOVE_FROM_ALIASED_LIST:PROC,REMOVE_FROM_WEAK_DEFINED_LIST:PROC
		EXTERNDEF	REMOVE_FROM_LAZY_LIST:PROC,REMOVE_FROM_ALIAS_DEFINED_LIST:PROC,REMOVE_FROM_LAZY_DEFINED_LIST:PROC
		EXTERNDEF	ADD_TO_COMMUNAL_LIST:PROC,ADD_TO_LAZY_LIST:PROC,ADD_TO_ALIASED_LIST:PROC,ADD_TO_WEAK_LIST:PROC
		EXTERNDEF	REFERENCE_COMDAT:PROC,REFERENCE_LIBSYM:PROC,SET_LOC_11_RET:PROC,PREV_DEF_FAIL:PROC
		EXTERNDEF	STRIP_PATH_EXT:PROC,IMPMOD_INSTALL:PROC,REMOVE_FROM__IMP__LIST:PROC,UNDECO_INSTALL:PROC
		EXTERNDEF	ADD_TO_UNDECORATED_LIST:PROC,MOVE_ASCIZ_ECX_EAX:PROC

		EXTERNDEF	DUP_ENT_ORD_ERR:ABS,EXPORT_CONFLICT_ERR:ABS,PREV_DEF_ERR:ABS,EXP_CONST_ERR:ABS


DEFINE_EXPORT	PROC
		;
		;FIRST FIND INTERNAL NAME IN SYMBOL TABLE
		;
		PUSHM	EDI,ESI

		MOV	ESI,OFF IMPEXP_INTNAM
		MOV	EAX,DPTR IMPEXP_INTNAM+4

		TEST	EAX,EAX			;DOES IT EXIST?
		JNZ	L1$

		MOV	ESI,OFF IMPEXP_NAM	;EXTERNAL NAME IS SAME...
L1$:
		CALL	MOVE_TO_SYMBOL_LENGTH_INT

		GETT	AL,DEF_IN_PROGRESS
		MOV	EDI,OFF SYMBOL_TEXT

		OR	AL,AL
		JZ	L11$
		;
		;SPECIAL HANDLING ONLY FOR GUYS IN THE .DEF FILE
		;
		;SEE_IF_DECORATED
		;
		;ANY '@' SIGNS IN THIS GUY?
		;
		MOV	ECX,SYMBOL_LENGTH
		MOV	AL,'@'

		REPNE	SCASB

		JZ	L11$			;YES, HANDLE LIKE OLD DAYS

		PUSH	EBX
		CALL	UNDECO_INSTALL		;SEPARATE HASH & ADDR SPACE
		ASSUME	ECX:PTR SYMBOL_STRUCT	;SAME FORMAT AS REAL SYMBOLS

		MOV	DL,[ECX]._S_NSYM_TYPE

		OR	DL,DL
		JNZ	L10$

		CALL	ADD_TO_UNDECORATED_LIST

L10$:
		JMP	L19$

L11$:
		PUSH	EBX
		CALL	FAR_INSTALL		;EAX IS INDEX, ECX IS PHYS
		ASSUME	ECX:PTR SYMBOL_STRUCT
		;
		;IF USE_EXT NOT SELECTED, AND THERE ARE UNDECORATED, DO TRY_UNDECORATED
		;
		MOV	ESI,DPTR [ECX]._S_NSYM_TYPE
		MOV	EDX,FIRST_UNDECORATED_GINDEX

		AND	ESI,NSYM_ANDER
		MOV	BL,EXP_FLAGS

		TEST	EDX,EDX
		JZ	L119$

		AND	BL,MASK ENT_USE_EXTNAM
		JNZ	L119$

		GETT	DL,OUTPUT_PE

		TEST	DL,DL
		JZ	L119$

		SETT	FUZZY_JUST_CHECK,DL
		CALL	TRY_UNDECORATED		;DOES THIS MATCH AN UNDECORATED EXPORT?

		RESS	FUZZY_JUST_CHECK

		TEST	EDX,EDX
		JZ	L119$

		PUSHM	ECX,EAX

		LEA	ECX,[EDX]._S_NAME_TEXT
		MOV	EAX,OFF IMPEXP_NAM+8

		CALL	MOVE_ASCIZ_ECX_EAX

		MOV	DPTR [EAX],0
		SUB	EAX,OFF IMPEXP_NAM+8

		MOV	IMPEXP_NAM+4,EAX

		POPM	EAX,ECX
L119$:
		JMP	DEF_EXP_TABLE[ESI*2]

L12$:
		;
		;NCOMM_UNREF
		;FCOMM_UNREF
		;
		SUB	[ECX]._S_NSYM_TYPE,NSYM_NCOMM_UNREF-NSYM_COMM_NEAR
		CALL	ADD_TO_COMMUNAL_LIST

		JMP	L19$

L13$:
		;
		;LAZY_UNREF
		;
		CALL	ADD_TO_LAZY_LIST
		JMP	L19$

L14$:
		;
		;ALIAS_UNREF
		;
		CALL	ADD_TO_ALIASED_LIST
		JMP	L19$

L15$:
		;
		;WEAK_UNREF
		;
		CALL	ADD_TO_WEAK_LIST
		JMP	L19$

L16$:
		;
		;COMDAT
		;
		;IF S_HARD_REF OR S_REFERENCED, DON'T WORRY
		;
		;IF JUST BUILDING COMDAT, MARK IT S_HARD_REF
		;ELSE DO REFERENCE_COMDAT
		;
		MOV	DL,[ECX]._S_REF_FLAGS
		MOV	EBX,[ECX]._S_CD_SEGMOD_GINDEX

		AND	DL,MASK S_REFERENCED+MASK S_HARD_REF
		JNZ	L2$

		CONVERT	EBX,EBX,SEGMOD_GARRAY

		MOV	DL,[EBX].CDSEGMOD_STRUCT._CDSM_CDFLAGS

		AND	DL,MASK MCD_FLUSHED
		JZ	L165$

		PUSH	EAX
		CALL	REFERENCE_COMDAT

		POP	EAX
		JMP	L2$

L165$:
		OR	[ECX]._S_REF_FLAGS,MASK S_HARD_REF
		JMP	L2$

L17$:
		;
		;LIBRARY
		;
		OR	[ECX]._S_REF_FLAGS,MASK S_REFERENCED
		CALL	REFERENCE_LIBSYM

		JMP	L2$

L50$:
		CALL	REMOVE_FROM__IMP__LIST
L18$:
		CALL	ADD_TO_EXTERNAL_LIST
L19$:
		OR	[ECX]._S_REF_FLAGS,MASK S_REFERENCED
L2$:
		;
		;NOW EXPORTED NAME (CALLED ENTRY POINTS...)
		;
		PUSH	EAX
		MOV	ESI,OFF IMPEXP_NAM

		CALL	MOVE_TO_SYMBOL_LENGTH_EXT

		CALL	INSTALL_ENTRYNAME	;EAX IS INDEX, ECX IS PHYS
		ASSUME	ECX:PTR ENT_STRUCT

		POP	EDX
		MOV	EBX,[ECX]._ENT_INTERNAL_NAME_GINDEX

		TEST	EBX,EBX			;ALREADY DECLARED?
		JNZ	L4$
		;
		;NEW ENTRY DECLARATION
		;
		MOV	EBX,N_EXPORTS
		MOV	AL,EXP_FLAGS

		INC	EBX
		TEST	AL,MASK ENT_BYNAME		;IF EXPORTING THIS BY NAME, ADD IN THIS NAME SIZE

		MOV	N_EXPORTS,EBX
		JNZ	L33$

		TEST	AL,MASK ENT_NONAME
		JNZ	L38$

		GETT	BL,ALL_EXPORTS_BY_ORDINAL
		GETT	AH,KILL_NONRESIDENT_NAMES

		OR	BL,BL
		JNZ	L32$

		TEST	AL,MASK ENT_ORD_SPECIFIED
		JZ	L33$
L32$:
		OR	AH,AH
		JNZ	L38$
L33$:
		MOV	EAX,SYMBOL_LENGTH
		MOV	EBX,EXPORT_TEXT_SIZE

		ADD	EBX,EAX
		MOV	EAX,N_EXPORTS_BYNAME

		INC	EBX				;COUNT TRAILING ZERO
		INC	EAX

		MOV	EXPORT_TEXT_SIZE,EBX
		MOV	N_EXPORTS_BYNAME,EAX
L38$:

		MOV	AX,EXP_BOTH_FLAGS
		MOV	[ECX]._ENT_INTERNAL_NAME_GINDEX,EDX

		MOV	[ECX]._ENT_FLAGS,AL
		MOV	[ECX]._ENT_FLAGS_EXT,AH
		MOV	AL,EXP_PWORDS

		MOV	EDX,EXP_ORDNUM
		MOV	[ECX]._ENT_PWORDS,AL

		OR	EDX,EDX
		JNZ	NEW_ORDNUM

		JMP	L9$

L4$:
		;
		;ENTRY ALREADY DECLARED, CHECK FOR MATCH
		;
		MOV	EBX,[ECX]._ENT_INTERNAL_NAME_GINDEX
		MOV	AL,EXP_FLAGS

		CMP	EBX,EDX ;DOES INTERNAL NAME
		JZ	L40$
		;
		;IF OLD IS UNDECORATED, AND NEW IS DECORATED, AND THEY FUZZY MATCH???
		;
		CONVERT	EBX,EBX,SYMBOL_GARRAY
		ASSUME	EBX:PTR SYMBOL_STRUCT
		CONVERT	EAX,EDX,SYMBOL_GARRAY
		ASSUME	EAX:PTR SYMBOL_STRUCT

		CMP	[EBX]._S_NSYM_TYPE,NSYM_UNDECORATED
		JNZ	L8$

		CMP	[EAX]._S_NSYM_TYPE,NSYM_UNDECORATED
		JZ	L8$

		CMP	[EBX]._S_LAST_NCPP_MATCH,EDX		;ONLY OR EXACT MATCH ?
		JZ	L401$

		TEST	[EBX]._S_REF_FLAGS,MASK UNDECO_EXACT
		JNZ	L8$

		CMP	[EBX]._S_LAST_CPP_MATCH,EDX
		JNZ	L8$

		OR	[EBX]._S_REF_FLAGS,MASK UNDECO_EXACT
		MOV	[EBX]._S_LAST_NCPP_MATCH,EDX
L401$:
		MOV	[ECX]._ENT_INTERNAL_NAME_GINDEX,EDX
		MOV	AL,EXP_FLAGS

		ASSUME	EAX:NOTHING,EBX:NOTHING
L40$:
		TEST	AL,MASK ENT_RESIDENTNAME+MASK ENT_NODATA+MASK ENT_NONAME
		JZ	L42$

		MOV	BL,[ECX]._ENT_FLAGS

		CMP	BL,AL
		JZ	L42$

		AND	BL,MASK ENT_RESIDENTNAME+MASK ENT_NODATA+MASK ENT_NONAME
		JNZ	L8$
L41$:
		MOV	[ECX]._ENT_FLAGS,AL
L42$:
		MOV	AL,EXP_PWORDS
		MOV	BL,[ECX]._ENT_PWORDS

		OR	AL,AL
		JZ	L46$

		CMP	BL,AL
		JZ	L46$

		OR	BL,BL
		JNZ	L8$

		MOV	[ECX]._ENT_PWORDS,AL
L46$:
		MOV	EDX,EXP_ORDNUM
		MOV	EBX,[ECX]._ENT_ORD

		OR	EDX,EDX
		JZ	L9$

		CMP	EBX,EDX
		JZ	L9$

		OR	EBX,EBX
		JZ	NEW_ORDNUM
L8$:
		MOV	AL,EXPORT_CONFLICT_ERR
L81$:
		CALL	ERR_SYMBOL_TEXT_RET

		JMP	L9$

NEW_ORDNUM:
		MOV	AL,[ECX]._ENT_FLAGS
		MOV	[ECX]._ENT_ORD,EDX

		OR	AL,MASK ENT_ORD_SPECIFIED
		MOV	EBX,LOWEST_ORDINAL
		;
		;UPDATE LOW AND HIGH ORDINAL NUMBERS
		;
		MOV	[ECX]._ENT_FLAGS,AL
		CMP	EBX,EDX

		MOV	EBX,HIGHEST_ORDINAL
		JB	L82$

		MOV	LOWEST_ORDINAL,EDX
L82$:
		CMP	EBX,EDX
		JA	L83$

		MOV	HIGHEST_ORDINAL,EDX
L83$:

		;
		;NOW SET FLAG IN BITMAP
		;
		MOV	ESI,ENTRYNAME_BITS
		MOV	ECX,EDX

		SHR	EDX,3		;THAT BYTE
		AND	ECX,7

		MOV	BL,[ESI+EDX]
		MOV	AL,1

		SHL	AL,CL		;THAT BIT...

		TEST	BL,AL
		JNZ	L87$

		OR	BL,AL

		MOV	[ESI+EDX],BL
L9$:
		POP	EBX

		POPM	ESI,EDI

		RET

L87$:
		MOV	AL,DUP_ENT_ORD_ERR
		JMP	L81$

L88$:
		MOV	AL,EXP_CONST_ERR	;CANNOT EXPORT AN IMPORTED SYMBOL
		JMP	L81$


		.CONST

		ALIGN	4

DEF_EXP_TABLE	LABEL	DWORD

		DD	L18$		;UNDEF, MAKE EXTERNAL
		DD	L19$		;ASEG, JUST MARK REFERENCED
		DD	L19$		;RELOC, JUST MARK REFERENCED
		DD	L2$		;NCOMM, ALREADY REFERENCED
		DD	L2$		;FCOMM, ALREADY REFERENCED
		DD	L2$		;HCOMM, ALREADY REFERENCED
		DD	L19$		;CONST, JUST MARK REFERENCED
		DD	L17$		;LIBRARY, REFERENCE_LIBSYM
		DD	L88$		;CANNOT EXPORT IMPORTED SYMBOL
		DD	L2$		;PROMISED, ??
		DD	L2$		;EXTERNAL, IGNORE
		DD	L2$		;WEAK, IGNORE
		DD	L19$		;POS-WEAK, JUST MARK REFERENCED
		DD	L2$		;LIB-LIST, IGNORE
		DD	L18$		;__imp__UNREF, MARK REFERENCED
		DD	L2$		;ALIASED, IGNORE
		DD	L16$		;COMDAT, MAY NEED WORK
		DD	L2$		;WEAK-DEFINED, IGNORE
		DD	L15$		;WEAK-UNREF, REFERENCE IT
		DD	L14$		;ALIAS-UNREF, REFERENCE IT
		DD	L19$		;POS-LAZY, MARK IT REFERENCED
		DD	L2$		;LAZY, IGNORE
		DD	L13$		;LAZY-UNREF, REFERENCE IT
		DD	L2$		;ALIAS-DEFINED, IGNORE
		DD	L2$		;LAZY-DEFINED, IGNORE
		DD	L12$		;NCOMM-UNREF, REFERENCE IT
		DD	L12$		;FCOMM-UNREF, REFERENCE IT
		DD	L12$		;HCOMM-UNREF, REFERENCE IT
		DD	L50$		;__imp__, REMOVE FROM LIST, MAKE EXTERN
		DD	L18$		;UNDECORATED, CANNOT HAPPEN

.ERRNZ ($-DEF_EXP_TABLE)- NSYM_SIZE*2


		.CODE	ROOT_TEXT

DEFINE_EXPORT	ENDP


DEFINE_IMPORT	PROC
		;
		;FIRST, DO MODULE NAME
		;
		PUSHM	EDI,ESI

		MOV	ESI,OFF IMPEXP_MOD
		CALL	MOVE_TO_SYMBOL_LENGTH_EXT

		PUSH	EBX
		CALL	ADD_DLL

		CALL	IMPMOD_INSTALL		;EAX IS INDEX, ECX IS PHYS

		MOV	ECX,IMPEXP_INTNAM+4
		MOV	ESI,OFF IMPEXP_INTNAM

		OR	ECX,ECX			;DOES IT EXIST?
		JNZ	L61$

		MOV	ESI,OFF IMPEXP_NAM	;EXTERNAL NAME IS SAME...
L61$:
		MOV	IMP_MODNUM,EAX		;MODULE NUMBER
		CALL	MOVE_TO_SYMBOL_LENGTH_INT

		CALL	FAR_INSTALL		;EAX IS INDEX, ECX IS PHYS
		ASSUME	ECX:PTR SYMBOL_STRUCT
		;
		;FIRST DETERMINE IF WE NEED TO REMOVE THIS GUY FROM ANY
		;LINKED LIST...
		;
		MOV	ESI,DPTR [ECX]._S_NSYM_TYPE

		AND	ESI,NSYM_ANDER

		JMP	DO_IMPORT_TABLE[ESI*2]


IMP_UNLAZY:
		CALL	REMOVE_FROM_LAZY_LIST
		JMP	ID_11

IMP_UNLAZY_DEF:
		CALL	REMOVE_FROM_LAZY_DEFINED_LIST
		JMP	ID_11

IMP_UNALIAS_DEF:
		CALL	REMOVE_FROM_ALIAS_DEFINED_LIST
		JMP	ID_11

IMP_UNALIAS:
		CALL	REMOVE_FROM_ALIASED_LIST
		JMP	ID_11

IMP_UNLIB:
		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF	;WAS THIS A COMMUNAL?
		JNZ	PREV_DEF

		CALL	REMOVE_FROM_LIBSYM_LIST
		JMP	ID_11

IMP_UNWEAK:
		CALL	REMOVE_FROM_WEAK_LIST
		JMP	ID_11

IMP_UNWEAKDEF:
		CALL	REMOVE_FROM_WEAK_DEFINED_LIST
		JMP	ID_11

IMP_LIB:
		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF
		JZ	IMP_DEFINE
PREV_DEF:
		CALL	PREV_DEF_FAIL
		JMP	L9$

IMP_UNEXTRN:
		CALL	REMOVE_FROM_EXTERNAL_LIST
ID_11:
IMP_DEFINE:
		;
		;HMM, STORE PTR TO MODULE AND TO IMPNAME
		;
		MOV	EDX,EAX
		MOV	EAX,IMP_MODNUM

		MOV	[ECX]._S_NSYM_TYPE,NSYM_IMPORT

		MOV	[ECX]._S_IMP_MODULE,EAX			;FOR SEGMENTED
		MOV	EAX,CURNMOD_GINDEX

		GETT	BL,IMP_BY_NAME
		MOV	[ECX]._S_DEFINING_MOD,EAX

		OR	BL,BL
		JNZ	L4$

		MOV	BL,[ECX]._S_REF_FLAGS
		MOV	EAX,IMP_ORDNUM

		OR	BL,MASK S_IMP_ORDINAL
		MOV	EDI,IMP_MODNUM		;MODULE

		MOV	[ECX]._S_IMP_ORDINAL,EAX	;ORDINAL #
		MOV	[ECX]._S_REF_FLAGS,BL

		CONVERT	EDI,EDI,IMPMOD_GARRAY
		ASSUME	EDI:PTR IMPMOD_STRUCT

		MOV	EBX,[EDI]._IMPM_ORD_SYM_GINDEX
		MOV	[EDI]._IMPM_ORD_SYM_GINDEX,EDX

		MOV	[ECX]._S_IMP_NEXT_GINDEX,EBX
L9$:
		POP	EBX

		POPM	ESI,EDI

		RET

		ASSUME	EDI:NOTHING


L4$:
		MOV	AL,[ECX]._S_REF_FLAGS
		PUSH	EDX			;SYMBOL_GINDEX
		;
		;IMPORT BY NAME...
		;
		AND	AL,NOT MASK S_IMP_ORDINAL
		MOV	EBX,IMPEXP_NAM+4
		;
		;INSTALL NAME IN IMPNAME TABLE
		;
		MOV	[ECX]._S_REF_FLAGS,AL
		MOV	ESI,OFF IMPEXP_NAM	;EXTERNAL NAME

		TEST	EBX,EBX			;DOES IT EXIST?
		JNZ	L41$

		MOV	ESI,OFF IMPEXP_INTNAM	;INTERNAL NAME IS SAME...
L41$:
		CALL	MOVE_TO_SYMBOL_LENGTH_EXT

		CALL	IMPNAME_INSTALL		;EAX IS INDEX, ECX IS PHYS
		ASSUME	ECX:PTR IMPNAME_STRUCT
		;
		;LINK THIS TO MODULE, ALSO POINT TO IMPNAME
		;
		MOV	EBX,IMP_ORDNUM		;HINT IF AVAILABLE
		POP	EDX

		MOV	[ECX]._IMP_HINT,EBX
		MOV	EDI,IMP_MODNUM

		MOV	EBX,EDX
		CONVERT	EDX,EDX,SYMBOL_GARRAY
		ASSUME	EDX:PTR SYMBOL_STRUCT
		MOV	[EDX]._S_IMP_IMPNAME_GINDEX,EAX

		CONVERT	EDI,EDI,IMPMOD_GARRAY
		ASSUME	EDI:PTR IMPMOD_STRUCT

		MOV	EAX,[EDI]._IMPM_NAME_SYM_GINDEX
		MOV	[EDI]._IMPM_NAME_SYM_GINDEX,EBX

		MOV	[EDX]._S_IMP_NEXT_GINDEX,EAX
		POP	EBX

		POPM	ESI,EDI

		RET

		ASSUME	EDI:NOTHING


		.CONST

		ALIGN	4

DO_IMPORT_TABLE	LABEL	DWORD

		DD	IMP_DEFINE		;FRESH SYMBOL, JUST DEFINE
		DD	PREV_DEF		;ALREADY ASEG, ERROR
		DD	PREV_DEF		;ALREADY RELOC, ERROR
		DD	PREV_DEF		;ALREADY NEAR COMMUNAL,ERROR
		DD	PREV_DEF		;ALREADY FAR COMMNAL, ERROR
		DD	PREV_DEF		;ALREADY HUGE COMMUNAL, ERROR
		DD	PREV_DEF		;ALREADY CONSTANT,ERROR
		DD	IMP_LIB			;IN LIB, UNREFERENCED, JUST DEFINE
		DD	PREV_DEF		;ALREADY IMPORTED, SOMEDAY COMPARE...
		DD	IMP_DEFINE		;PROMISED,SPECIAL LATER...
		DD	IMP_UNEXTRN		;REMOVE FROM EXTERN LIST
		DD	IMP_UNWEAK		;WEAK EXTRN, REMOVE FROM LIST
		DD	IMP_DEFINE		;POSSIBLE WEAK, JUST DEFINE
		DD	IMP_UNLIB		;REMOVE FROM LIBRARY REQUEST LIST
		DD	PREV_DEF		;__imp__UNREF, ERROR
		DD	IMP_UNALIAS		;ALIAS
		DD	PREV_DEF		;ALREADY COMDAT, ERROR
		DD	IMP_UNWEAKDEF		;WEAKEXTRN-DEFINED, REMOVE FROM LIST
		DD	IMP_DEFINE		;UNREF-WEAK, JUST DEFINE
		DD	IMP_DEFINE		;UNREF-ALIAS, JUST DEFINE
		DD	IMP_DEFINE		;POSSIBLE LAZY, JUST DEFINE
		DD	IMP_UNLAZY		;LAZY, REMOVE FROM LIST
		DD	IMP_DEFINE		;UNREF-LAZY, JUST DEFINE
		DD	IMP_UNALIAS_DEF		;ALIAS-DEFINED, REMOVE FROM LIST
		DD	IMP_UNLAZY_DEF		;LAZY-DEFINED, REMOVE FROM LIST
		DD	PREV_DEF		;UNREFERENCED NEAR COMMUNAL, ERROR
		DD	PREV_DEF		;UNREFERENCED FAR COMMUNAL, ERROR
		DD	PREV_DEF		;UNREFERENCED HUGE COMMUNAL, ERROR
		DD	PREV_DEF		;__imp__, ERROR
		DD	PREV_DEF		;UNDECORATED, CANNOT HAPPEN

.ERRNZ	($-DO_IMPORT_TABLE)- NSYM_SIZE*2


		.CODE	ROOT_TEXT

DEFINE_IMPORT	ENDP


MOVE_TO_SYMBOL_LENGTH_INT	PROC	NEAR
		;
		;MOVE [SI] TO SYMBOL_LENGTH, CONVERT LIKE OTHER INTERNAL SYMBOLS
		;
		MOV	EAX,4[ESI]	;STRING_LENGTH
		MOV	EDI,OFF SYMBOL_TEXT

		ADD	ESI,8
		GETT	DL,DEF_IN_PROGRESS

		MOV	[EDI-4],EAX
		OR	DL,DL

		GETT	DL,PRESERVE_IMPEXP_CASE
		JZ	L9$

		OR	DL,DL
		JZ	OPTI_MOVE_UPPER_IGNORE
L9$:
		JMP	OPTI_MOVE

MOVE_TO_SYMBOL_LENGTH_INT	ENDP


MOVE_TO_SYMBOL_LENGTH_EXT	PROC	NEAR
		;
		;MOVE [SI] TO SYMBOL_LENGTH, CONVERT PER IMPORT AND EXPORT SPECS
		;
		MOV	EDI,OFF SYMBOL_TEXT
		GETT	CL,PRESERVE_IMPEXP_CASE

		MOV	EAX,4[ESI]	;THIS IS STRING LENGTH
		ADD	ESI,8

		OR	CL,CL
		MOV	[EDI-4],EAX

		JNZ	OPTI_MOVE_PRESERVE_SIGNIFICANT	;BASICALLY, JUST HASH IT PLEASE...

		JMP	OPTI_MOVE_UPPER_IGNORE

MOVE_TO_SYMBOL_LENGTH_EXT	ENDP


ADD_DLL		PROC	NEAR
		;
		;ADD EXTENSION IF NONE FOUND
		;
		MOV	ESI,OFF SYMBOL_TEXT
		MOV	ECX,SYMBOL_LENGTH
L1$:
		MOV	AL,[ESI]
		INC	ESI

		CMP	AL,'.'
		JZ	L9$

		DEC	ECX
		JNZ	L1$

		MOV	DPTR [ESI],'LLD.'

		ADD	SYMBOL_LENGTH,4
		MOV	4[ESI],ECX
L9$:
		RET

ADD_DLL		ENDP


if	fg_segm

		PUBLIC	SELECT_OUTPUT_SEGMENTED


SELECT_OUTPUT_SEGMENTED PROC
		GETT	AL,OUTPUT_SEGMENTED

		OR	AL,AL
		JZ	L1$

		RET

L1$:
		;
		;MAKE SURE NOTHING HAS BEEN DONE TO MAKE SEGMENTED ILLEGAL
		;
		RESS	FORCE_DOS_MODE,AL
		RESS	OUTPUT_COM,AL
		RESS	OUTPUT_SYS,AL
		RESS	OUTPUT_COM_SYS,AL
if	fg_pe
		RESS	OUTPUT_PE,AL
endif
		RESS	OUTPUT_ABS,AL

if	fg_norm_exe

		CALL	SET_LOC_11_RET

		CALL	UNDO_FARCALL
endif
		;
		;SET UP DEFAULTS FOR SEGMENTED OUTPUT
		;
		MOV	EAX,MASK APPWINFLAGS	;DEFAULT WINDOW MODE IS NOW WINDOWAPI FOR WINDOWS

		TEST	FLAG_0C,EAX
		JNZ	L12$

		OR	FLAG_0C_MASK,EAX

		CMP	EXETYPE_FLAG,OS2_SEGM_TYPE
		JNZ	L11$

		MOV	EAX,200H			;OS2 DEFAULTS TO VIO
L11$:
		OR	FLAG_0C,EAX
L12$:
		CMP	EXETYPE_FLAG,0		;UNDEFINED?
		JNZ	L3$
		MOV	EXETYPE_FLAG,WIN_SEGM_TYPE	;WINDOWS_TYPE BY DEFAULT

		BITT	WINVER_SELECTED
		JNZ	L3$

		MOV	NEXEHEADER._NEXE_WINVER_INT,3
		MOV	NEXEHEADER._NEXE_WINVER_FRAC,10
L3$:
		SETT	OUTPUT_SEGMENTED
		SETT	GROUPASSOCIATION_FLAG
		CMP	EXETYPE_FLAG,WIN_SEGM_TYPE	;WINDOWS APPS NOW PROTMODE BY DEFAULT
		JNZ	L33$
		TEST	FLAG_0C_MASK,MASK APPPROT
		JNZ	L33$
		SETT	PROTMODE
		OR	FLAG_0C_MASK,MASK APPPROT
		OR	FLAG_0C,MASK APPPROT
L33$:

		CMP	EXETYPE_FLAG,OS2_SEGM_TYPE	;OS/2  1
		JZ	L35$
		CMP	EXETYPE_FLAG,UNKNOWN_SEGM_TYPE	;WINDOWS & DOS4 GET PACKCODE
		JZ	L4$
		;
		;PACKCODE IF NO SEGMENTS DIRECTIVE?
		;
		BITT	PACKCODE_NO_SEGMENTS
		JZ	L4$
		CMP	DEF_SEGMENT_GINDEX,0
		JNZ	L4$
L35$:
		;
		;FOR OS2, DO PACKCODE AND FARCALLTRANSLATION BY DEFAULT
		;
		BITT	NOPACKCODE_FLAG
		JNZ	L41$
		BITT	PACKCODE_FLAG
		JNZ	L41$
		SETT	PACKCODE_FLAG
		MOV	EAX,PACK_DEFAULT_SIZE
		MOV	PACKCODE,EAX
L41$:
		CMP	EXETYPE_FLAG,WIN_SEGM_TYPE	;SKIP IF WINDOWS
		JZ	L42$
		BITT	NOFARCALLTRANSLATION_FLAG
		JNZ	L42$
		SETT	FARCALLTRANSLATION_FLAG
		SETT	CHECK_RELOCATIONS
L42$:

L4$:
		MOV	EXEPACK_TAIL_LIMIT,11

		RET

SELECT_OUTPUT_SEGMENTED ENDP

endif

if	fg_segm OR fg_pe

UNDO_FARCALL	PROC	NEAR

		PUSH	ESI
		MOV	ESI,FIRST_FARCALL

		TEST	ESI,ESI
		JZ	L29$

		ASSUME	ESI:PTR FARCALL_HEADER_TYPE

		MOV	EDX,[ESI]._FC_BLOCK_BASE
L20$:
		MOV	ECX,[ESI]._FC_BLOCK_BASE
		MOV	ESI,[ESI]._FC_NEXT_FARCALL

		CMP	ECX,EDX
		JZ	L25$

		MOV	EAX,EDX
		CALL	RELEASE_BLOCK

		MOV	EDX,ECX
L25$:
		TEST	ESI,ESI
		JNZ	L20$

		MOV	EAX,EDX
		CALL	RELEASE_BLOCK

		MOV	FIRST_FARCALL,ESI
		MOV	LAST_FARCALL,ESI
L29$:
		POP	ESI

		RET

UNDO_FARCALL	ENDP

endif

if	fg_pe

		PUBLIC	SELECT_OUTPUT_PE

SELECT_OUTPUT_PE	PROC
		;
		;
		;
		GETT	AL,OUTPUT_PE

		OR	AL,AL
		JZ	L1$

		RET

L1$:
		;
		;MAKE SURE NOTHING HAS BEEN DONE TO MAKE SEGMENTED ILLEGAL
		;
		RESS	FORCE_DOS_MODE,AL
		RESS	OUTPUT_COM,AL
		RESS	OUTPUT_SYS,AL
		RESS	OUTPUT_COM_SYS,AL
		RESS	OUTPUT_SEGMENTED,AL
		RESS	OUTPUT_ABS,AL
		RESS	EXEPACK_SELECTED,AL
		RESS	RC_REORDER,AL
if	fg_winpack
		RESS	WINPACK_SELECTED,AL
		RESS	SEGPACK_SELECTED,AL
endif
if	fg_dospack
		RESS	SLRPACK_SELECTED,AL
endif

if	fg_norm_exe

		CALL	SET_LOC_11_RET

		CALL	UNDO_FARCALL

endif
		;
		;SET UP DEFAULTS FOR PE OUTPUT
		;
		MOV	AX,0FFH

		MOV	EXETYPE_FLAG,PE_EXE_TYPE
		SETT	OUTPUT_PE,AL
		SETT	OUTPUT_32BITS,AL
		SETT	GROUPASSOCIATION_FLAG,AL
		SETT	PROTMODE,AL
		RESS	FARCALLTRANSLATION_FLAG,AH
		RESS	CHECK_RELOCATIONS,AH	;NO RELOCATION CHECKING..
		SETT	REORDER_ALLOWED,AL
		BITT	NOPACKCODE_FLAG,AH
		JNZ	L2$
		SETT	PACKCODE_FLAG,AL
L2$:
		BITT	NOPACKDATA_FLAG,AH
		JNZ	L21$
		SETT	PACKDATA_FLAG,AL
L21$:
		RET

SELECT_OUTPUT_PE	ENDP

endif


		END

