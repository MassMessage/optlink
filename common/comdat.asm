		TITLE	COMDAT - Copyright (c) SLR Systems 1994
		SUBTTL	Contains Confidential and Proprietary material

		INCLUDE MACROS
		INCLUDE	SYMBOLS
		INCLUDE	SEGMENTS
		INCLUDE	CDDATA

		PUBLIC	COMDAT,COMDAT32,FLUSH_COMDAT,HANDLE_COMDAT,COMDAT_VIRDEF_CONT


		.DATA

		EXTERNDEF	COMDAT_ATTRIB:BYTE,COMDAT_ALIGN:BYTE,COMDAT_FLAGS:BYTE,COMDAT_TYPE:BYTE,MCD_FLAGS:BYTE
		EXTERNDEF	LDATA_TYPE:BYTE,CLASS_TYPE:BYTE,REFERENCE_FLAGS:BYTE,COMDAT_REF_FLAGS:BYTE

		EXTERNDEF	COMDAT_CV:DWORD,END_OF_RECORD:DWORD,COMDAT_GINDEX:DWORD,TYPDEF_ANDER:DWORD,LDATA_SEGMOD_GINDEX:DWORD
		EXTERNDEF	COMDAT_SEGMOD_GINDEX:DWORD,CURNMOD_GINDEX:DWORD,MYCOMDAT_LINDEX:DWORD,COMDAT_GROUP_LINDEX:DWORD
		EXTERNDEF	COMDAT_SEGMOD_LINDEX:DWORD,COMDAT_PARENT_SEGMOD_GINDEX:DWORD,COMDAT_OFFSET:DWORD,PREV_DATA_PTR:DWORD
		EXTERNDEF	LAST_DATA_PTR:DWORD,LDATA_LOC:DWORD,COMDAT_DATA_PTR:DWORD

		EXTERNDEF	COMDAT_VARS:QWORD,SEGMOD_LARRAY:LARRAY_STRUCT,GROUP_LARRAY:LARRAY_STRUCT,SEGMOD_GARRAY:STD_PTR_S
		EXTERNDEF	SEGMENT_GARRAY:STD_PTR_S,SYMBOL_GARRAY:STD_PTR_S


		.CODE	PASS1_TEXT

		EXTERNDEF	MYCOMDAT_INSTALL:PROC,OBJ_PHASE:PROC,_err_abort:proc,COMDAT_INSTALL:PROC,FAKE_LEDATA_COMDAT:PROC
		EXTERNDEF	MULT_32:PROC,ADD_TO_COMDAT_LIST:PROC,REMOVE_FROM_LIBSYM_LIST:PROC,REMOVE_FROM_LIBRARY_LIST:PROC
		EXTERNDEF	REMOVE_FROM_COMMUNAL_LIST:PROC,REMOVE_FROM_EXTERNAL_LIST:PROC,REMOVE_FROM_ALIASED_LIST:PROC
		EXTERNDEF	PREV_DEF_FAIL:PROC,REMOVE_FROM_WEAK_LIST:PROC,REMOVE_FROM_WEAK_DEFINED_LIST:PROC,FIX_MY_CSEG:PROC
		EXTERNDEF	REMOVE_FROM_ALIAS_DEFINED_LIST:PROC,REMOVE_FROM_LAZY_LIST:PROC,REMOVE_FROM_LAZY_DEFINED_LIST:PROC
		EXTERNDEF	REMOVE_FROM__IMP__LIST:PROC

		EXTERNDEF	COMDAT_CONT_ERR:ABS,COMDAT_SYNTAX_ERR:ABS

;
;		DB	FLAGS		01H - CLEAR == NEW INSTANCE, SET == CONTINUATION
;					02H - CLEAR == LEDATA, SET == LIDATA
;					04H - CLEAR == NORMAL, SET == LOCAL
;					08H - CLEAR == NORMAL, SET == DATA IN CODESEG, NO FARCALLTRANSLATE, FORCE TO ROOT
;
;		DB	ATTRIB		(HIGH 4 BITS == SELECTION CRITERIA)
;					00H	-	NO MATCHING, ONLY ONE INSTANCE ALLOWED
;					10H	-	PICK ANY INSTANCE OF THIS COMDAT
;					20H	-	PICK ANY, BUT ALL SIZES MUST MATCH
;					30H	-	PICK ANY, BUT SIZE AND CHECKSUM MUST MATCH
;					40-F0	RESERVED
;
;					(LOW 4 BITS == ALLOCATION TYPE)
;					00H	-	EXPLICIT, PUBLIC BASE FIELD EXISTS, USE IT
;					01H	-	FAR CODE - ALLOCATE AS CODE16
;					02H	-	FAR DATA - ALLOCATE AS DATA16
;					03H	-	CODE32
;					04H	-	DATA32
;					05-0F	RESERVED
;
;		DB	ALIGN		SAME AS SEGMENT ALIGN TYPES
;
;	  DW OR DD	ENUM DATA OFFSET	OFFSET RELATIVE TO SYMBOL SPECIFIED
;
;	  	INDEX	TYPE		CODEVIEW INFO INDEX
;
;			PUBLIC BASE	BASE GROUP, BASE SEGMENT FOR EXPLICIT ALLOCATION
;
;	  	INDEX	PUBLIC NAME	LNAME REFERENCE TO THIS GUY
;
;					NEXT UP TO 1024 BYTES OF DATA
;


COMDAT32	PROC
		;
		;
		;
		MOV	AL,MASK BIT_32
		JMP	COMDAT1

COMDAT32	ENDP


COMDAT_FAIL:
		MOV	AL,COMDAT_SYNTAX_ERR
		push	EAX
		call	_err_abort


COMDAT		PROC
		;
		;ESI IS DATA RECORD
		;
		XOR	EAX,EAX
COMDAT1::
		MOV	CL,AL
		MOV	AL,[ESI]

		MOV	COMDAT_TYPE,CL
		MOV	BL,[ESI+1]

		MOV	COMDAT_FLAGS,AL
		MOV	AL,[ESI+2]

		MOV	COMDAT_ATTRIB,BL
		MOV	EDX,[ESI+3]

		MOV	COMDAT_ALIGN,AL
		ADD	ESI,7

		OR	CL,CL
		JNZ	L1$

		AND	EDX,0FFFFH
		SUB	ESI,2

L1$:
		XOR	ECX,ECX
		MOV	COMDAT_OFFSET,EDX

		SKIP_INDEX

;		NEXT_INDEXI		;CODEVIEW TYPE INDEX

;		AND	EAX,TYPDEF_ANDER	;CODEVIEW ON FOR THIS MODULE?
		MOV	COMDAT_GROUP_LINDEX,ECX

;		MOV	COMDAT_CV_TYPE,EAX
		MOV	COMDAT_SEGMOD_LINDEX,ECX
		;
		;IF EXPLICIT ALLOCATION, HERE COMES GROUP, SEGMENT, MAYBE ASEG ADDRESS
		;
		AND	BL,0FH		;COMDAT_ATTRIB
		JNZ	L2$

		NEXT_INDEX	L1	;GET GROUP_INDEX
		MOV	COMDAT_GROUP_LINDEX,EAX

		NEXT_INDEX	L2	;GET SEGMENT_INDEX
		MOV	COMDAT_SEGMOD_LINDEX,EAX

		OR	EAX,COMDAT_GROUP_LINDEX
		JNZ	L21$
		JMP	COMDAT_FAIL	;ASEG NOT SUPPORTED

		DOLONG	L1
		DOLONG	L2
		DOLONG	L3

L2$:
		;
		;NOT EXPLICIT, MAKE SURE ALIGNMENT IS AT LEAST BYTE
		;
		MOV	AL,COMDAT_ALIGN
		MOV	BL,1

		CMP	AL,1
		JAE	L21$
		MOV	COMDAT_ALIGN,BL
L21$:
		;
		;HERE COMES LNAME REFERENCE TO NAME
		;
		NEXT_INDEX	L3

		MOV	COMDAT_DATA_PTR,ESI
		CALL	MYCOMDAT_INSTALL			;EAX = LINDEX, ECX IS PHYSICAL
		;
		;OK, PROCESS 'CONTINUATION' BIT
		;
		MOV	DL,COMDAT_FLAGS
		MOV	MYCOMDAT_LINDEX,EAX

		AND	DL,MASK CD_CONTINUATION		;IF CONTINUATION, JUMP
		MOV	EBX,[ECX]._MCD_SYMBOL_GINDEX

		MOV	DL,[ECX]._MCD_FLAGS
		JNZ	L5$
		;
		;NEW INSTANCE, IF ALREADY THERE, FLUSH OLD ONE
		;
		AND	DL,MASK MCD_ACTIVE
		JZ	L23$

		TEST	EBX,EBX
		JZ	L23$

		CALL	FLUSH_COMDAT				;ANOTHER INSTANCE, FLUSH OLD ONE

L23$:
		;
		;DEFINE ITEMS IN MYCOMDAT
		;
		MOV	AX,WPTR COMDAT_ATTRIB		;_ALIGN
		MOV	EDX,COMDAT_SEGMOD_LINDEX

		MOV	WPTR [ECX]._MCD_ATTRIB,AX
		MOV	AL,COMDAT_FLAGS

		MOV	[ECX]._MCD_SEGMOD_LINDEX,EDX
		AND	AL,MASK CD_DATA_IN_CODE+MASK CD_LOCAL	;SAVE THESE FLAGS

		MOV	EDX,COMDAT_GROUP_LINDEX
		OR	AL,MASK MCD_ACTIVE

		MOV	[ECX]._MCD_GROUP_LINDEX,EDX
		MOV	[ECX]._MCD_FLAGS,AL

		MOV	MCD_FLAGS,AL
		;
		;OK, NEW, INSTALL REAL COMDAT
		;
		MOV	EAX,[ECX]._MCD_LNAME_LINDEX
		CALL	COMDAT_INSTALL				;INSTALL IT IN SYMBOL TABLE - HANDLE LOCAL TOO

		CALL	HANDLE_COMDAT
		JMP	COMDAT_CONT

COMDAT_FAIL1:
L59$:
		MOV	AL,COMDAT_CONT_ERR
		push	EAX
		call	_err_abort

L8$:
		XOR	EAX,EAX			;CLEAR ALL THIS SO FIXUPP

		RESS	LAST_DATA_KEEP,AL	;GETS IGNORED TOO
		MOV	LAST_DATA_PTR,EAX

		RET

L5$:
		;
		;CONTINUATION, MAKE SURE EVERYTHING MATCHES...
		;
		TEST	EBX,EBX				;CONTINUATION PROBLEM
		JZ	COMDAT_FAIL1

		MOV	EAX,COMDAT_SEGMOD_LINDEX
		MOV	EBX,COMDAT_GROUP_LINDEX

		MOV	EDX,[ECX]._MCD_SEGMOD_LINDEX
		MOV	EDI,[ECX]._MCD_GROUP_LINDEX

		SUB	EAX,EDX
		SUB	EBX,EDI

		OR	EBX,EAX

		MOV	DX,WPTR COMDAT_ATTRIB
		MOV	AL,[ECX]._MCD_FLAGS

		SUB	DX,WPTR [ECX]._MCD_ATTRIB
		MOV	MCD_FLAGS,AL

		OR	BX,DX
		XOR	AL,COMDAT_FLAGS

		AND	AL,MASK CD_DATA_IN_CODE+MASK CD_LOCAL

		OR	EBX,EAX
		JNZ	L59$
COMDAT_CONT:
		MOV	AL,MCD_FLAGS

		TEST	AL,MASK MCD_IGNORE_THIS	;PICK ANY, OR PREV_DEF
		JNZ	L8$
		;
		;UPDATE SIZE AND CHECKSUM FOR THIS MCD RECORD
		;
		CALL	LEDATA_CHECKSUM			;EAX IS SIZE, CL IS CHECKSUM

		MOV	ESI,EAX
		MOV	EAX,MYCOMDAT_LINDEX
		MOV	EBX,ECX
		CONVERT_MYCOMDAT_EAX_ECX
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		MOV	EAX,COMDAT_OFFSET
		MOV	EDX,[ECX]._MCD_SIZE

		ADD	ESI,EAX
		MOV	AL,[ECX]._MCD_CHECKSUM

		CMP	EDX,ESI
		JAE	L7$

		MOV	[ECX]._MCD_SIZE,ESI
L7$:
		ADD	BL,AL
		MOV	AL,[ECX]._MCD_FLAGS

		MOV	[ECX]._MCD_CHECKSUM,BL
		GETT	BL,PACKFUNCTIONS_FLAG

		TEST	AL,MASK MCD_KEEPING_THIS
		JZ	L8$
		;
		;KEEPING THIS, SET UP APPROPRIATE STUFF
		;
		MOV	DL,MASK S_HARD_REF

		TEST	BL,BL
		JZ	L70$

		TEST	AL,MASK MCD_HARD_REF
		JNZ	L70$

		MOV	DL,MASK S_SOFT_REF
L70$:
		MOV	AL,COMDAT_FLAGS
		MOV	REFERENCE_FLAGS,DL

		TEST	AL,MASK CD_LIDATA
		MOV	DL,COMDAT_TYPE

		MOV	AL,MASK BIT_LI
		JNZ	L71$

		MOV	AL,MASK BIT_LE
L71$:
		OR	AL,DL				;16 OR 32 BIT
		MOV	EDX,[ECX]._MCD_SEGMOD_GINDEX

		MOV	LDATA_TYPE,AL

COMDAT_VIRDEF_CONT	LABEL	PROC

		MOV	EBX,LDATA_SEGMOD_GINDEX
		XOR	EAX,EAX
		;
		;IF SAME SEGMOD AS LAST LEDATA, SAVE LAST_DATA_PTR
		;
		CMP	EBX,EDX
		JNZ	L72$

		MOV	EAX,LAST_DATA_PTR	;USED BY FARCALLTRANSLATE
L72$:
		MOV	PREV_DATA_PTR,EAX
		MOV	LDATA_SEGMOD_GINDEX,EDX	;FOR USE BY FIXUPP AND FAKELEDA FOR LINKING DATA RECORD

		CONVERT	EDX,EDX,SEGMOD_GARRAY
		MOV	CL,[EDX].SEGMOD_STRUCT._SM_FLAGS
		MOV	AL,-1

		MOV	CLASS_TYPE,CL
		SETT	LAST_DATA_KEEP,AL

		MOV	EBX,COMDAT_OFFSET
		SETT	LAST_DATA_COMDAT,AL

		MOV	LDATA_LOC,EBX
		MOV	EAX,COMDAT_DATA_PTR

		CALL	FAKE_LEDATA_COMDAT

		RET


		.CONST

		ALIGN	4

COMDAT_TABLE	LABEL	DWORD

		DD	CD_DEFINE		;UNDEFINED NEW SYMBOL
		DD	CD_ERROR		;ASEG SYMBOL, DUP SYMBOL
		DD	CD_MAYBE_PICKANY	;RELOC ALREADY DEFINED, DUP SYMBOL
		DD	CD_ERROR		;NEAR COMDEF,UNDO, USE COMDAT...
		DD	CD_ERROR		;FAR COMMUNAL
		DD	CD_ERROR		;HUGE COMMUNAL
		DD	CD_ERROR		;CONSTANT, ERROR
		DD	CD_LIB			;IN LIBRARY, NOT REFERENCED
		DD	CD_MAYBE_PICKANY	;IMPORTED, ERROR
		DD	CD_ERROR		;PROMISED
		DD	CD_EXTERN		;REFERENCED EXTERNAL...
		DD	CD_WEAK			;UNWEAK, THEN DEFINE? OR WAIT FOR REAL EXTERN?
		DD	CD_DEFINE		;POS WEAK - JUST DEFINE
		DD	CD_LIBRARY		;IN LIBRARY REFERENCED LIST
		DD	CD_DEFINE		;__imp__UNREF
		DD	CD_ALIASED		;ALIASED, THIS OVERIDES
		DD	CD_COMDAT		;ALREADY A COMDAT IN COMDAT LIST
		DD	CD_WEAK_DEFINED		;UNWEAK, THEN DEFINE
		DD	CD_DEFINE		;WEAK-UNREF, JUST DEFINE
		DD	CD_DEFINE		;ALIASED-UNREF, JUST DEFINE
		DD	CD_DEFINE		;POS-LAZY, JUST DEFINE
		DD	CD_LAZY			;LAZY, UNDO, THEN DEFINE
		DD	CD_DEFINE		;LAZY-UNREF, JUST DEFINE
		DD	CD_ALIAS_DEFINED	;ALIAS-DEFINED, UNDO, THEN DEFINE
		DD	CD_LAZY_DEFINED		;LAZY-DEFINED, UNDO, THEN DEFINE
		DD	CD_ERROR		;NCOMM-UNREF, CHECK CODE-DATA, THEN DEFINE
		DD	CD_ERROR		;FCOMM-UNREF, CHECK CODE-DATA, THEN DEFINE
		DD	CD_ERROR		;HCOMM-UNREF
		DD	CD__IMP__		;__imp__
		DD	CD_ERROR		;UNDECORATED, CANNOT

.ERRNZ	($-COMDAT_TABLE)-NSYM_SIZE*2

		.CODE	PASS1_TEXT

COMDAT		ENDP


HANDLE_COMDAT	PROC
		;
		;EAX IS COMDAT GINDEX, ECX IS PHYSICAL
		;
		ASSUME	ECX:PTR SYMBOL_STRUCT

		MOV	ESI,DPTR [ECX]._S_NSYM_TYPE

		AND	ESI,NSYM_ANDER
		MOV	COMDAT_GINDEX,EAX

		JMP	COMDAT_TABLE[ESI*2]

;		RET

HANDLE_COMDAT	ENDP


CD_COMDAT	PROC	NEAR
		;
		;THIS GUY ALREADY A COMDAT, CHECK ATTRIBUTES TO DETERMINE NEXT STEP
		;
		MOV	ESI,[ECX]._S_CD_SEGMOD_GINDEX
		CONVERT	ESI,ESI,SEGMOD_GARRAY
		MOV	DL,COMDAT_ATTRIB

		MOV	DH,[ESI].CDSEGMOD_STRUCT._CDSM_ATTRIB

		AND	EDX,0F0F0H
		JZ	CD_ERROR		;IF ZERO, ONLY ONE INSTANCE ALLOWED

		CMP	DL,10H			;PICK ANY, DON'T EVEN CHECK SIZE
		JZ	CD_IGNORE

		CMP	DH,10H
		JZ	CD_UNDO

		CMP	DL,DH
		JNZ	CD_ERROR		;SELECTION CRITERIA MUST MATCH
		;
		;WE NEED TO SIZE-CHECK THIS AND POSSIBLY CHECKSUM, OTHERWISE WE ARE DISCARDING INFO...
		;
		MOV	EAX,MYCOMDAT_LINDEX
		CONVERT_MYCOMDAT_EAX_ECX
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		MOV	EAX,COMDAT_GINDEX

		MOV	[ECX]._MCD_SYMBOL_GINDEX,EAX

		RET

CD_UNDO:
		ASSUME	ECX:PTR SYMBOL_STRUCT

		MOV	EBX,COMDAT_GROUP_LINDEX

		TEST	EBX,EBX
		JZ	L1$

		OR	[ECX]._S_REF_FLAGS,MASK S_USE_GROUP
L1$:
		MOV	ESI,ECX
		ASSUME	ESI:PTR SYMBOL_STRUCT
		MOV	EBX,[ECX]._S_CD_SEGMOD_GINDEX

		MOV	COMDAT_SEGMOD_GINDEX,EBX
		CONVERT	EBX,EBX,SEGMOD_GARRAY

		MOV	ECX,(SIZE CDSEGMOD_STRUCT+3)/4
		MOV	EDI,EBX

		XOR	EAX,EAX
		MOV	DL,[ESI]._S_REF_FLAGS		;FOR HARD VS SOFT REFERENCE

		REP	STOSD

		JMP	CD_DEFINE_CONT

CD_COMDAT	ENDP


		ASSUME	ECX:PTR SYMBOL_STRUCT

CD_MAYBE_PICKANY	PROC	NEAR
		;
		;LET IT SLIDE IF A PICK_ANY
		;
		MOV	AL,COMDAT_ATTRIB

		AND	AL,0F0H

		CMP	AL,010H			;PICK ANY
		JZ	CD_IGNORE

		JMP	CD_ERROR

CD_MAYBE_PICKANY	ENDP


CD_LIB		PROC	NEAR
		;
		;EAX IS GINDEX, ECX IS PHYSICAL
		;
		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF	;WAS THIS ORIGINALLY A COMDEF?
		JZ	CD_DEFINE

		JMP	CD_ERROR

CD_LIB		ENDP


CD_LIBRARY	PROC	NEAR
		;
		;REMOVE FROM LIBSYM LIST, THEN MAKE THIS A COMDAT
		;
		MOV	DL,[ECX]._S_REF_FLAGS

		AND	DL,MASK S_DATA_REF
		JNZ	CD_ERROR

		CALL	REMOVE_FROM_LIBSYM_LIST

		JMP	CD_DEFINE

CD_LIBRARY	ENDP


CD_ERROR	PROC	NEAR
		;
		;ISSUE PREVIOUSLY DEFINED MESSAGE AND THEN SET NECESSARY FLAGS...
		;
		CALL	PREV_DEF_FAIL
CD_IGNORE::
		;
		;SET FLAGS TO TOTALLY IGNORE THIS COMDAT
		;
		MOV	EAX,MYCOMDAT_LINDEX
		CONVERT_MYCOMDAT_EAX_ECX
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		MOV	BL,[ECX]._MCD_FLAGS
		MOV	AL,MCD_FLAGS

		OR	BL,MASK MCD_IGNORE_THIS
		OR	AL,MASK MCD_IGNORE_THIS

		MOV	[ECX]._MCD_FLAGS,BL
		MOV	EBX,COMDAT_GINDEX

		MOV	MCD_FLAGS,AL
		MOV	[ECX]._MCD_SYMBOL_GINDEX,EBX

		RET

		ASSUME	ECX:PTR SYMBOL_STRUCT


CD_ERROR	ENDP


CD_ALIAS_DEFINED	PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM_ALIAS_DEFINED_LIST

		JMP	CD_DEFINE

CD_ALIAS_DEFINED	ENDP


CD_LAZY_DEFINED	PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM_LAZY_DEFINED_LIST

		JMP	CD_DEFINE

CD_LAZY_DEFINED	ENDP


CD_LAZY		PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM_LAZY_LIST

		JMP	CD_DEFINE

CD_LAZY		ENDP


CD__IMP__	PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM__IMP__LIST
		JMP	CD_DEFINE

CD__IMP__	ENDP


CD_WEAK		PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM_WEAK_LIST

		JMP	CD_DEFINE

CD_WEAK		ENDP


CD_WEAK_DEFINED	PROC	NEAR
		;
		;
		;
		CALL	REMOVE_FROM_WEAK_DEFINED_LIST

		JMP	CD_DEFINE

CD_WEAK_DEFINED	ENDP


CD_ALIASED	PROC	NEAR
		;
		;UNDO ALIAS, THEN ASSIGN COMDAT
		;
		CALL	REMOVE_FROM_ALIASED_LIST

		JMP	CD_DEFINE

CD_ALIASED	ENDP


CD_EXTERN	PROC	NEAR
		;
		;REMOVE FROM EXTERNAL LIST, THEN MAKE THIS A COMDAT
		;
		CALL	REMOVE_FROM_EXTERNAL_LIST

;		JMP	CD_DEFINE

CD_EXTERN	ENDP


CD_DEFINE	PROC	NEAR
		;
		;EAX IS GINDEX, ECX IS SYMBOL TO BECOME A COMDAT
		;
		MOV	EBX,COMDAT_GROUP_LINDEX
		CALL	ADD_TO_COMDAT_LIST	;THIS SYMBOL GOES IN COMDAT LIST

		TEST	EBX,EBX
		JZ	L1$

		OR	[ECX]._S_REF_FLAGS,MASK S_USE_GROUP
L1$:
		MOV	EAX,SIZE CDSEGMOD_STRUCT	;ALLOCATE A SEGMOD TO USE
		SEGMOD_POOL_ALLOC

		MOV	ESI,ECX
		MOV	EBX,EAX
		ASSUME	ESI:PTR SYMBOL_STRUCT

		MOV	EDI,EAX
		;
		;INITIALIZE SEGMOD STRUCTURE
		;
		MOV	ECX,(SIZE CDSEGMOD_STRUCT+3)/4
		XOR	EAX,EAX				;ZERO COMPLETE STRUCTURE

		REP	STOSD

		MOV	EAX,EBX
		INSTALL_POINTER_GINDEX	SEGMOD_GARRAY
		MOV	DL,[ESI]._S_REF_FLAGS		;FOR HARD VS SOFT REFERENCE

		MOV	[ESI]._S_CD_SEGMOD_GINDEX,EAX	;STORE POINTER TO EXTENT STRUCTURE
		MOV	COMDAT_SEGMOD_GINDEX,EAX
		;
		;DEFINE PARENT SEGMENT IF KNOWN
		;
		; CONVERT INDEXES TO POINTERS
		;
CD_DEFINE_CONT::
		MOV	COMDAT_REF_FLAGS,DL
		MOV	EAX,COMDAT_SEGMOD_LINDEX

		TEST	EAX,EAX
		JZ	L2$

		CONVERT_LINDEX_EAX_EAX	SEGMOD_LARRAY,ESI

		MOV	COMDAT_PARENT_SEGMOD_GINDEX,EAX
		CONVERT	ESI,EAX,SEGMOD_GARRAY
		ASSUME	ESI:PTR SEGMOD_STRUCT

		MOV	AL,COMDAT_ALIGN		;IF TYPE ZERO, USE ALIGN FROM SEGMOD

		OR	AL,AL
		JNZ	L16$

		MOV	AL,[ESI]._SM_ALIGN

		MOV	COMDAT_ALIGN,AL
L16$:
		MOV	EBX,[ESI]._SM_BASE_SEG_GINDEX
		;
		;MAKE SURE GROUP MEMBERSHIP MATCHES
		;
		CONVERT	ESI,EBX,SEGMENT_GARRAY
		ASSUME	ESI:PTR SEGMENT_STRUCT
		MOV	EDI,COMDAT_SEGMOD_GINDEX
		CONVERT	EDI,EDI,SEGMOD_GARRAY
		ASSUME	EDI:NOTHING

		MOV	ECX,[ESI]._SEG_GROUP_GINDEX
		MOV	DL,[ESI]._SEG_TYPE

		MOV	EAX,COMDAT_PARENT_SEGMOD_GINDEX
		MOV	[EDI].SEGMOD_STRUCT._SM_BASE_SEG_GINDEX,EBX

		MOV	[EDI].CDSEGMOD_STRUCT._CDSM_SEGMOD_GINDEX,EAX
		MOV	EBX,EDI

		MOV	AL,DL
		JMP	L3$

CD_ERROR1:	JMP	CD_ERROR

		ASSUME	EBX:PTR SEGMOD_STRUCT
L2$:
		;
		;ELSE, USE SEG_RELOC AND SET SEG_CLASS_IS_CODE BASED ON ATTRIB
		;
		MOV	CL,COMDAT_ATTRIB
		MOV	AL,MASK SEG_RELOC

		AND	CL,1			;SET IF CODE
		JZ	L3$

		MOV	AL,MASK SEG_RELOC+MASK SEG_CLASS_IS_CODE
L3$:
		MOV	[EBX]._SM_FLAGS,AL
		MOV	CLASS_TYPE,AL

		MOV	EAX,CURNMOD_GINDEX
		MOV	CL,MCD_FLAGS

		MOV	[EBX]._SM_MODULE_CSEG_GINDEX,EAX
		AND	CL,MASK MCD_DATA_IN_CODE

		MOV	AL,[EBX]._SM_FLAGS_2
		JZ	L32$

		OR	AL,MASK SM2_DATA_IN_CODE

		MOV	[EBX]._SM_FLAGS_2,AL
L32$:
		MOV	AL,COMDAT_ALIGN

		MOV	[EBX]._SM_ALIGN,AL
		;
		;IF A CODE_SEGMENT, AND WE ARE KEEPING LINENUMBES
		;
if	fg_td
		GETT	AL,TD_FLAG			;NOT YET IF TURBO DEBUG

		TEST	AL,AL
		JNZ	L39$
endif
		GETT	AL,KEEPING_LINNUMS
		MOV	CL,[EBX]._SM_FLAGS

		TEST	AL,AL
		JZ	L39$

		AND	CL,MASK SEG_CLASS_IS_CODE
		JZ	L39$

		MOV	EAX,EBX
		CALL	FIX_MY_CSEG
L39$:
		;
		;DEFINE ALIAS SYMBOL IF IT EXISTS
		;
		MOV	EAX,MYCOMDAT_LINDEX
		CONVERT_MYCOMDAT_EAX_ECX
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		MOV	DL,COMDAT_REF_FLAGS
		MOV	AL,[ECX]._MCD_FLAGS

		AND	DL,MASK S_REFERENCED		;HAS SYMBOL BEEN HARD-REFERENCED?
		JZ	L4$
		OR	AL,MASK MCD_HARD_REF
L4$:
		MOV	EDX,COMDAT_GINDEX
		OR	AL,MASK MCD_KEEPING_THIS

		MOV	[ECX]._MCD_SYMBOL_GINDEX,EDX
		MOV	[ECX]._MCD_FLAGS,AL

		MOV	EDX,COMDAT_SEGMOD_GINDEX
		MOV	MCD_FLAGS,AL

		MOV	[ECX]._MCD_SEGMOD_GINDEX,EDX

		RET

		ASSUME	ESI:NOTHING

CD_DEFINE	ENDP


FLUSH_COMDAT	PROC
		;
		;ECX IS MCD_COMDAT, EAX IS LINDEX, RETURN SAME...
		;
		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		PUSHM	EDI,ESI

		MOV	EDX,EAX
		PUSH	EBX

		MOV	AL,[ECX]._MCD_FLAGS

		TEST	AL,MASK MCD_KEEPING_THIS
		JNZ	L5$

		TEST	AL,MASK MCD_IGNORE_THIS
		JNZ	L3$
		;
		;NOT KEEPING, ALREADY DEFINED.  JUST COMPARE SIZE AND MAYBE CHECKSUM
		;
		MOV	AL,[ECX]._MCD_ATTRIB
		MOV	EDI,[ECX]._MCD_SEGMOD_GINDEX

		TEST	EDI,EDI
		JZ	L3$			;NEVER GOT DEFINED...

		CONVERT	EDI,EDI,SEGMOD_GARRAY
		ASSUME	EDI:PTR CDSEGMOD_STRUCT

		CMP	AL,30H	;IF <30H, WE DON'T NEED CHECKSUM
		JB	L2$

		MOV	AL,[ECX]._MCD_CHECKSUM
		MOV	BL,[EDI]._CDSM_CHECKSUM

		CMP	BL,AL
		JNZ	L29$
L2$:
		;
		;COMPARE SIZES
		;
		MOV	EAX,[ECX]._MCD_SIZE
		MOV	EBX,[EDI]._CDSM_SIZE

		SUB	EAX,EBX
		JZ	L3$
L29$:
		CALL	PREV_DEF_FAIL		;OR SOMETHING SIMILAR
L3$:
		;
		;CLEAN UP MCD
		;
		LEA	EDI,[ECX]._MCD_ATTRIB	;FROM ATTRIBUTES ON GETS ZEROED OUT
		MOV	EBX,ECX

		MOV	ECX,(SIZE MYCOMDAT_STRUCT-MYCOMDAT_STRUCT._MCD_ATTRIB)/4
		XOR	EAX,EAX

		REP	STOSD

		MOV	ECX,EBX
		MOV	EAX,EDX

		POPM	EBX,ESI,EDI
		RET


FCD_BUF_SIZE	EQU	64


FCD_VARS	STRUC

FCD_BUFFER_BP		DB	FCD_BUF_SIZE DUP(?)
FCD_MCD_GINDEX_BP	DD	?
FCD_SEGMOD_GINDEX_BP	DD	?
FCD_LAST_SOFT_BP	DD	?
FCD_FIRST_SOFT_BP	DD	?
FCD_LIMIT_BP		DD	?
FCD_COUNT_BP		DD	?

FCD_VARS	ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE FCD_VARS].(X&_BP))

	ENDM


FIX	FCD_BUFFER
FIX	FCD_MCD_GINDEX
FIX	FCD_SEGMOD_GINDEX
FIX	FCD_LAST_SOFT
FIX	FCD_FIRST_SOFT
FIX	FCD_LIMIT
FIX	FCD_COUNT

L5$:
		;
		;INITIAL COMDAT DEFINITION, STORE MISCELLANEOUS STUFF FROM MCD TO COMDAT AND ITS SEGMOD
		;
		;IF SOFT REFERENCED, STORE INFO ABOUT SOFT EXTERNS I REFERENCE...
		;
		PUSH	EBP
		MOV	EBP,ESP
		ASSUME	EBP:PTR FCD_VARS

		SUB	ESP,SIZE FCD_VARS
		MOV	EDI,[ECX]._MCD_SEGMOD_GINDEX

		MOV	FCD_MCD_GINDEX,EDX
		MOV	FCD_SEGMOD_GINDEX,EDI

		CONVERT	EDI,EDI,SEGMOD_GARRAY
		ASSUME	EDI:PTR CDSEGMOD_STRUCT

		MOV	BX,WPTR [ECX]._MCD_FLAGS		;BH IS CHECKSUM
		MOV	EAX,[ECX]._MCD_SIZE

		MOV	EDX,DPTR [ECX]._MCD_ATTRIB
		OR	BL,MASK MCD_FLUSHED

		MOV	WPTR [EDI]._CDSM_ATTRIB,DX		;ATTRIB & CDALIGN
		MOV	[EDI]._CDSM_SIZE,EAX

		MOV	WPTR [EDI]._CDSM_CDFLAGS,BX		;CDFLAGS AND CHECKSUM
		;
		;PROCESS SOFT EXTRN REFERENCES
		;
		LEA	EDI,FCD_BUFFER
		ASSUME	EDI:NOTHING

		MOV	EBX,FCD_BUF_SIZE
		XOR	EAX,EAX

		ADD	EBX,EDI
		MOV	FCD_LAST_SOFT,EAX

		MOV	FCD_LIMIT,EBX
		MOV	ESI,[ECX]._MCD_FIRST_SOFT_BLOCK	;THESE ALLOCATED IN LOCAL MEMORY
		;
		;
		;
		PUSH	ECX

L50$:
		TEST	ESI,ESI
		JZ	L59$				;NO MORE, JUMP

		MOV	ECX,[ESI]
		ADD	ESI,4

		MOV	FCD_COUNT,ECX
L52$:
		MOV	EDX,[ESI]
		ADD	ESI,4

		MOV	EBX,EDX				;SAVE GINDEX
		CONVERT	EDX,EDX,SYMBOL_GARRAY

		MOV	EAX,DPTR [EDX].SYMBOL_STRUCT._S_NSYM_TYPE
		MOV	DL,MASK S_HARD_REF+MASK S_REFERENCED

		TEST	AH,DL				;SKIP IF SYMBOL SINCE REFERENCED
		JNZ	L54$

		MOV	[EDI],EAX
		MOV	[EDI+4],EBX

		ADD	EDI,8
		MOV	EBX,FCD_LIMIT

		CMP	EDI,EBX
		JZ	L57$
L54$:
		DEC	ECX
		JNZ	L52$
		;
		;WAS THERE AN ARRAY FULL?
		;
		CMP	FCD_COUNT,SOFT_PER_BLK
		JNZ	L59$

		MOV	ESI,[ESI]
		JMP	L50$

L57$:
		CALL	FLUSH_FCD
		JMP	L54$

L59$:
		CALL	FLUSH_FCD
		;
		;NOW STORE LINK
		;
		MOV	ECX,FCD_LAST_SOFT
		MOV	EAX,FCD_SEGMOD_GINDEX

		TEST	ECX,ECX
		JZ	L595$
		CONVERT	EAX,EAX,SEGMOD_GARRAY

		MOV	[EAX].CDSEGMOD_STRUCT._CDSM_SOFT_BLOCK,ECX
L595$:
		;
		;NOW SEE IF ANY PENTS NEED STORED
		;
		XOR	EAX,EAX
		POP	ECX				;MYCOMDAT

		MOV	FCD_LAST_SOFT,EAX
		MOV	FCD_FIRST_SOFT,EAX

		ASSUME	ECX:PTR MYCOMDAT_STRUCT

		MOV	ESI,[ECX]._MCD_FIRST_SOFT_PENT_BLOCK	;THESE ALLOCATED IN LOCAL MEMORY
		PUSH	ECX

L60$:
		TEST	ESI,ESI
		JZ	L64$				;NO MORE, JUMP

		MOV	EAX,[ESI]

		MOV	ECX,EAX
		MOV	FCD_COUNT,EAX

		LEA	EAX,[EAX*8 + 4]

		CMP	ECX,SOFT_PER_BLK
		JNZ	L62$
		ADD	EAX,4
L62$:
		P1ONLY_POOL_ALLOC
		;
		;LINK POINTER
		;
		MOV	EDI,EAX
		MOV	EAX,FCD_LAST_SOFT

		MOV	FCD_LAST_SOFT,EDI
		ADD	ECX,ECX

		TEST	EAX,EAX
		JZ	L63$

		MOV	[EAX+SOFT_PER_BLK*8+4],EDI

L639$:
		;
		;MOVE THE DATA PLEASE
		;
		INC	ECX
		MOV	EAX,FCD_COUNT

		REP	MOVSD

		CMP	EAX,SOFT_PER_BLK
		JNZ	L64$

		MOV	[EDI],ECX
		MOV	ESI,[ESI]

		JMP	L60$

L63$:
		MOV	FCD_FIRST_SOFT,EDI
		JMP	L639$

L64$:
		;
		;NOW STORE LINK
		;
		MOV	ECX,FCD_FIRST_SOFT
		MOV	EAX,FCD_SEGMOD_GINDEX

		TEST	ECX,ECX
		JZ	L695$

		CONVERT	EAX,EAX,SEGMOD_GARRAY

		MOV	[EAX].CDSEGMOD_STRUCT._CDSM_SOFT_PENT_BLOCK,ECX
L695$:
		POP	ECX
		MOV	EDX,FCD_MCD_GINDEX

		MOV	ESP,EBP

		POP	EBP
		JMP	L3$

FLUSH_COMDAT	ENDP


FLUSH_FCD	PROC	NEAR
		;
		;FLUSH JUNK FROM FCD_BUFFER TO P1ONLY-SPACE
		;
		LEA	EAX,FCD_BUFFER

		SUB	EDI,EAX
		JZ	L9$

		PUSHM	ESI,ECX

		MOV	EDX,EDI
		LEA	EAX,[EDI+8]		;# OF BYTES WE NEED

		P1ONLY_POOL_ALLOC
		;
		;LINK TO LAST GUY
		;
		MOV	ECX,FCD_LAST_SOFT
		MOV	FCD_LAST_SOFT,EAX

		SHR	EDX,2
		MOV	[EAX],ECX

		MOV	ECX,EDX
		LEA	EDI,[EAX+8]

		SHR	EDX,1
		LEA	ESI,FCD_BUFFER

		MOV	[EDI-4],EDX

		REP	MOVSD

		POPM	ECX,ESI
L9$:
		LEA	EDI,FCD_BUFFER
		RET

FLUSH_FCD	ENDP


LEDATA_CHECKSUM	PROC	NEAR
		;
		;CALCULATE CHECKSUM ON RECORD.  ALSO CALCULATE SIZE
		;
		;RETURNS SIZE IN EAX, CHECKSUM IN BL
		;
		MOV	ESI,COMDAT_DATA_PTR
		MOV	ECX,END_OF_RECORD

		XOR	EBX,EBX
		SUB	ECX,ESI			;# OF DATA BYTES

		MOV	AL,COMDAT_FLAGS
		JBE	L3$

		MOV	EDX,ECX
		TEST	AL,MASK CD_LIDATA

		MOV	AL,COMDAT_ATTRIB
		JNZ	L5$			;GO DO HARD ONE...

		CMP	AL,30H	;IF <30H, WE DON'T NEED CHECKSUM, JUST SIZE
		JB	L2$

		PUSH	ECX
		XOR	EAX,EAX

		SHR	ECX,2
		JZ	L15$
L1$:
		ADD	BL,AL
		MOV	AL,[ESI]

		ADD	BL,AH
		MOV	AH,[ESI+1]

		ADD	BL,AL
		MOV	AL,[ESI+2]

		ADD	BL,AH
		MOV	AH,[ESI+3]

		ADD	ESI,4
		DEC	ECX

		JNZ	L1$

		ADD	BL,AL
		ADD	BL,AH
L15$:
		POP	ECX

		AND	ECX,3
		JZ	L2$
L17$:
		ADD	BL,[ESI]
		INC	ESI

		DEC	ECX
		JZ	L17$
L2$:
		MOV	EAX,EDX			;SIZE IN EAX
		RET

L3$:
		XOR	EAX,EAX
		RET

L5$:
		;
		;TRICKY CAUSE IT IS AN LIDATA RECORD...
		;
		PUSH	EBP
		MOV	AL,COMDAT_TYPE

		XOR	EDX,EDX		;CHECKSUM
		AND	EAX,MASK BIT_32

		XOR	EDI,EDI		;BYTE COUNT
		MOV	EBP,EAX
L500$:
		PUSHM	EDX,EDI

		CALL	L50$

		POPM	EAX,EBX

		ADD	EDI,EAX
		ADD	DL,BL

		CMP	END_OF_RECORD,ESI
		JA	L500$

		MOV	ECX,EDX
		POP	EBP

		MOV	EAX,EDI

		RET

L50$:
		MOV	ECX,1		;INITIAL LEVEL BLOCK COUNT
		XOR	EDI,EDI		;EDI IS # OF BYTES SO FAR

		MOV	EBX,ECX		;EBX IS REPEAT COUNT OF 1
		XOR	EDX,EDX		;DL IS CHECKSUM
L51$:
		PUSHM	EDX,EDI		;SAVE CHECKSUM AND BYTE COUNT

		PUSH	EBX		;SAVE REPEAT COUNT
		XOR	EDI,EDI		;BYTE COUNT THIS LEVEL

		XOR	EDX,EDX		;CHECKSUM THIS LEVEL
		TEST	ECX,ECX

		JZ	GENERATE
L52$:
		PUSH	ECX		;BLOCK COUNT
		MOV	EBX,[ESI]	;NEXT REPEAT_FACTOR

		ADD	ESI,4
		XOR	ECX,ECX

		TEST	EBP,EBP
		JNZ	LARGE_REPEAT

		SUB	ESI,2
		AND	EBX,0FFFFH
LARGE_REPEAT:
		MOV	CX,WPTR [ESI]
		ADD	ESI,2		;NEW BLOCK COUNT

		CALL	L51$

		POP	ECX		;BLOCK COUNT

		DEC	ECX
		JNZ	L52$		;DO LOOP AGAIN
GENERATE_RET:
		POPM	EBX		;REPEAT COUNT
		;
		;ADJUST BYTE COUNT AND CHECKSUM BY REPEAT COUNT
		;
		MOV	AL,DL

		MUL	BL

		MOV	DL,AL		;ONLY LOW BYTE AFFECTS CHECKSUM
		POP	EAX		;NOW NEED EDI == EDI * EAX

		PUSH	EDX		;SAVE CHECKSUM

		MUL	EDI

		MOV	EDI,EAX
		POP	EDX

		POPM	EAX,EBX		;OLD BYTE COUNT, OLD CHECKSUM

		ADD	EDI,EAX
		ADD	DL,AL

		RET

GENERATE:
		MOV	AL,[ESI]	;CHECKSUM THESE BYTES
		INC	ESI

		AND	EAX,0FFH

		MOV	EDI,EAX		;COUNT OF BYTES
L8$:
		ADD	DL,[ESI]
		INC	ESI

		DEC	EAX
		JNZ	L8$

		JMP	GENERATE_RET

LEDATA_CHECKSUM	ENDP


		END

