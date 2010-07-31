		TITLE	COMDATS - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SYMBOLS
		INCLUDE	SEGMENTS
		INCLUDE	MODULES
		INCLUDE	CDDATA
if	fg_segm
		INCLUDE	SEGMSYMS
endif

		PUBLIC	ASSIGN_COMDATS


		.DATA

		EXTERNDEF	SEG_COMBINE:BYTE,PUB_SIZE:BYTE,PUB_TYPE:BYTE,SEG32_FLAGS:BYTE

		EXTERNDEF	NEXT_COMDAT_SEGNUM:DWORD,FIRST_COMDAT_GINDEX:DWORD,COMDAT_CODE_16_SEGMENT_GINDEX:DWORD,PUB_CV:DWORD
		EXTERNDEF	LINNUM_ADDER:DWORD,PACKCODE:DWORD,PACKDATA:DWORD,COMDAT_DATA_16_SEGMENT_GINDEX:DWORD
		EXTERNDEF	PUB_SEGMOD_GINDEX:DWORD,CURNMOD_GINDEX:DWORD,COMDAT_GINDEX:DWORD,MOD_FIRST_PUBLIC_GINDEX:DWORD
		EXTERNDEF	CLASS_NAME_LINDEX:DWORD,SEG_NAME_LINDEX:DWORD,PUB_GROUP_GINDEX:DWORD
		EXTERNDEF	COMDAT_CODE_32_SEGMENT_GINDEX:DWORD,COMDAT_DATA_32_SEGMENT_GINDEX:DWORD,PUB_OFFSET:DWORD
		EXTERNDEF	CODE_16_SEG_LEN:DWORD,DATA_16_SEG_LEN:DWORD,CODE_32_SEG_LEN:DWORD,DATA_32_SEG_LEN:DWORD

		EXTERNDEF	COMDAT_SEGNNNNN_TPTR:TPTR_STRUCT,CODE_TPTR:TPTR_STRUCT,FAR_DATA_TPTR:TPTR_STRUCT
		EXTERNDEF	MODULE_GARRAY:STD_PTR_S,SYMBOL_GARRAY:STD_PTR_S,SEGMOD_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S
		EXTERNDEF	CSEG_GARRAY:STD_PTR_S,PENT_GARRAY:STD_PTR_S,SEGMOD_COMDATS_GARRAY:STD_PTR_S,MDB_PARRAY:STD_PTR_S
		EXTERNDEF	SYMBOL_TPTR:TPTR_STRUCT

		EXTERNDEF	OPTI_MOVE:DWORD


		.CODE	MIDDLE_TEXT

		EXTERNDEF	DO_ECX_ALIGN:PROC,MAKE_TPTR_LINDEX:PROC,GET_SEGMENT_ENTRY:PROC,CBTA16:PROC,_err_abort:proc
		EXTERNDEF	GET_SM_MODULE:PROC,INIT_LOCAL_STORAGE:PROC,RELEASE_LOCAL_STORAGE:PROC,FIX_COMDAT_ENTRY:PROC
		EXTERNDEF	RELEASE_SEGMENT:PROC,INIT_PARALLEL_ARRAY:PROC,RELEASE_PARALLEL_ARRAY:PROC

		EXTERNDEF	BAD_CD_ALLOC_ERR:ABS


ASSIGN_COMDATS	PROC
		;
		;ASSIGN REFERENCED COMDATS (AND UNREFERENCED IF NOPACKFUNCTIONS)
		;
		XOR	EAX,EAX

		MOV	PUB_SIZE,AL
		MOV	PUB_CV,EAX

		MOV	PUB_TYPE,NSYM_RELOC

		CALL	INIT_LOCAL_STORAGE
		
		MOV	ECX,FIRST_COMDAT_GINDEX
		JMP	L6$

L1$:
		MOV	EAX,ECX
		CONVERT	ECX,ECX,SYMBOL_GARRAY
		ASSUME	ECX:PTR SYMBOL_STRUCT
		MOV	ESI,[ECX]._S_NEXT_SYM_GINDEX

		MOV	DL,[ECX]._S_REF_FLAGS
		GETT	BL,PACKFUNCTIONS_FLAG

		AND	DL,MASK S_REFERENCED
		JNZ	L2$

		TEST	BL,BL
		JNZ	L3$
L2$:
		PUSH	ESI
		CALL	PROC_COMDAT		;PROCESS THIS COMDAT

		POP	ECX
		JMP	L6$

L3$:
		PUSH	ESI
		CALL	PROC_UNCOMDAT		;PROCESS UNREFERENCED COMDAT

		POP	ECX
L6$:
		TEST	ECX,ECX
		JNZ	L1$

		CALL	RELEASE_LOCAL_STORAGE

		RET

ASSIGN_COMDATS	ENDP


PROC_UNCOMDAT	PROC	NEAR
		;
		;ECX IS SYMBOL, EAX IS GINDEX
		;
		MOV	ESI,[ECX]._S_CD_SEGMOD_GINDEX	;SEGMOD OF MINE
		XOR	EDI,EDI

		PUSH	ESI
		CONVERT	ESI,ESI,SEGMOD_GARRAY
		ASSUME	ESI:PTR CDSEGMOD_STRUCT

		MOV	[ESI]._CDSM_BASE_SEG_GINDEX,EDI	;MARK IT UNKEPT
		;
		;RELEASE ANY LEDATA-LIDATA-FIXUPP-FORREF STUFF OF MINE
		;
		MOV	ESI,[ESI]._CDSM_FIRST_DAT
		JMP	L18$

		ASSUME	ESI:PTR LDATA_HEADER_TYPE
L1$:
		MOV	EAX,[ESI]._LD_BLOCK_BASE
		MOV	DL,[ESI]._LD_TYPE

		MOV	ESI,[ESI]._LD_NEXT_LDATA
		AND	DL,MASK BIT_CONT

		MOV	EBX,[EAX]
		JNZ	L16$
L169$:
		DEC	EBX
		JZ	L15$

		MOV	[EAX],EBX
L159$:
L18$:
		TEST	ESI,ESI
		JNZ	L1$

		JMP	L2$

L15$:
		CALL	RELEASE_SEGMENT
		JMP	L159$

L16$:
		MOV	ECX,[EAX+4]

		DEC	DPTR [ECX]
		JNZ	L169$

		PUSH	EAX
		MOV	EAX,ECX

		CALL	RELEASE_SEGMENT

		POP	EAX
		JMP	L169$

L2$:
		;
		;RELEASE ANY LINNUM STUFF OF MINE
		;
		POP	ESI
		MOV	EDI,LINNUM_ADDER

if	fg_segm
		PUSH	ESI
endif
L20$:
		CONVERT	ESI,ESI,SEGMOD_GARRAY
		ASSUME	ESI:PTR CDSEGMOD_STRUCT

		MOV	AL,[ESI]._CDSM_FLAGS_2
		INC	EDI

		TEST	AL,MASK SM2_CSEG_DONE
		JZ	L3$

		MOV	ESI,[ESI]._CDSM_MODULE_CSEG_GINDEX
		CONVERT	ESI,ESI,CSEG_GARRAY
		ASSUME	ESI:PTR CSEG_STRUCT

		MOV	EAX,[ESI]._CSEG_NEXT_CSEGMOD_GINDEX
		MOV	ESI,[ESI]._CSEG_FIRST_LINNUM

		PUSH	EAX
		JMP	L28$

		ASSUME	ESI:PTR LINNUM_HEADER_TYPE
L22$:
		MOV	EAX,[ESI]._LN_BLOCK_BASE
		MOV	DL,[ESI]._LN_TYPE

		MOV	ESI,[ESI]._LN_NEXT_LINNUM
		AND	DL,MASK BIT_CONT

		MOV	EBX,[EAX]
		JNZ	L26$
L269$:
		SUB	EBX,EDI
		JZ	L25$

		MOV	[EAX],EBX
L259$:
L28$:
		TEST	ESI,ESI
		JNZ	L22$

		POP	ESI

		TEST	ESI,ESI
		JNZ	L20$

		JMP	L3$

L25$:
		CALL	RELEASE_SEGMENT
		JMP	L259$

L26$:
		MOV	ECX,[EAX+4]

		SUB	DPTR [ECX],EDI
		JNZ	L269$

		PUSH	EAX
		MOV	EAX,ECX

		CALL	RELEASE_SEGMENT

		POP	EAX
		JMP	L269$

L3$:
if	fg_segm
		GETT	DL,OUTPUT_SEGMENTED
		POP	EAX

		TEST	DL,DL
		JZ	L4$

		CALL	COMDAT_PENT_UNREF

endif

L4$:
		RET

PROC_UNCOMDAT	ENDP


if	fg_segm

COMDAT_PENT_UNREF	PROC	NEAR
		;
		;DO PENT COUNT SUBTRACTING
		;
		;EAX IS SEGMOD GINDEX
		;
		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR CDSEGMOD_STRUCT

		MOV	ESI,[EAX]._CDSM_SOFT_PENT_BLOCK
		ASSUME	ESI:NOTHING
		JMP	L38$

L31$:
		MOV	ECX,[ESI]		;# OF PENTS THIS BLOCK
		ADD	ESI,4

		MOV	EDX,ECX
L32$:
		MOV	EAX,[ESI]
		MOV	EBX,4[ESI]

		ADD	ESI,8
		INC	EBX

		CONVERT	EAX,EAX,PENT_GARRAY
		ASSUME	EAX:PTR PENT_STRUCT

		SUB	[EAX]._PENT_REF_COUNT,EBX
		DEC	ECX

		JNZ	L32$

		CMP	EDX,SOFT_PER_BLK
		JNZ	L39$

		MOV	ESI,[ESI]
L38$:
		TEST	ESI,ESI
		JNZ	L31$
L39$:
		RET

COMDAT_PENT_UNREF	ENDP

endif


PROC_COMDAT	PROC	NEAR
		;
		;EAX IS SYMBOL GINDEX, ECX IS PHYS
		;
		;WE MUST -
		;
		;	1.	LINK MY SEGMOD TO CORRECT SEGMENT OR SECTION
		;	2.	LINK MY CSEG_RECORD TO CORRECT MODULE
		;	3.	DEFINE THIS SYMBOL, LINK TO CORRECT MODULE
		;
		ASSUME	ECX:PTR SYMBOL_STRUCT

		MOV	COMDAT_GINDEX,EAX
		MOV	EAX,[ECX]._S_CD_SEGMOD_GINDEX

		MOV	PUB_SEGMOD_GINDEX,EAX
		CONVERT	EAX,EAX,SEGMOD_GARRAY
		MOV	ESI,EAX
		ASSUME	ESI:PTR CDSEGMOD_STRUCT

		CALL	GET_SM_MODULE

		MOV	ECX,[ESI]._CDSM_BASE_SEG_GINDEX
		MOV	CURNMOD_GINDEX,EAX

		TEST	ECX,ECX				;OWNING SEGMENT DEFINED?
		JNZ	L1$

		MOV	BL,[ESI]._CDSM_ATTRIB
		CALL	PROCURE_SEGMENT				;GET PROPER SEGMENT FOR ME...

if	fg_segm
		;
		;IF PROTMODE, SEGMENTED, ETC, ONLY ENTRIES POSSIBLE ARE TO IOPL-NONCONFORMING-CODE
		;	FROM SOMETHING ELSE...
		;
		GETT	AL,ENTRIES_POSSIBLE
		GETT	CL,OUTPUT_SEGMENTED

		AND	AL,CL
		JZ	L1$

		GETT	AL,PROTMODE
		MOV	EDI,[ESI]._CDSM_BASE_SEG_GINDEX

		OR	AL,AL
		JZ	L1$
		;
		;SEE IF WE JUST BECAME IOPL-NONCONFORMING-CODE
		;
		CONVERT	EDI,EDI,SEGMENT_GARRAY
		ASSUME	EDI:PTR SEGMENT_STRUCT

		MOV	EAX,[EDI]._SEG_OS2_FLAGS

		TEST	EAX,MASK SR_CONF+1
		JNZ	L1$			;IF CONFORMING OR DATA, KEEP RELOCS

		TEST	EAX,1 SHL SR_DPL
		JZ	L1$			;NON-IOPL, JUMP

		MOV	EAX,PUB_SEGMOD_GINDEX
		CALL	COMDAT_PENT_UNREF

		MOV	ESI,PUB_SEGMOD_GINDEX
		CONVERT	ESI,ESI,SEGMOD_GARRAY

endif

L1$:
		MOV	EDI,[ESI]._CDSM_BASE_SEG_GINDEX

		MOV	EDX,EDI
		CONVERT	EDI,EDI,SEGMENT_GARRAY

		MOV	AL,[EDI]._SEG_32FLAGS
		XOR	ECX,ECX

		OR	AL,MASK SEG32_NONZERO

		ASSUME	ESI:PTR SEGMOD_STRUCT
		MOV	[ESI]._SM_NEXT_SEGMOD_GINDEX,ECX
		ASSUME	ESI:PTR CDSEGMOD_STRUCT

		MOV	[EDI]._SEG_32FLAGS,AL
		MOV	AL,[ESI]._CDSM_FLAGS_2

		MOV	ECX,COMDAT_GINDEX
		OR	AL,MASK SM2_COMDAT

		MOV	[ESI]._CDSM_COMDAT_GINDEX,ECX
		MOV	[ESI]._CDSM_FLAGS_2,AL
		;
		;LINK ME TO BASE_SEG, SETTING MAX_ALIGN, SEG_LEN.LW, ETC
		;
		MOV	BL,[ESI]._CDSM_SMFLAGS
		MOV	CL,[EDI]._SEG_TYPE

		MOV	AL,[ESI]._CDSM_SMALIGN	;SET MAX ALIGN
		OR	BL,CL

		MOV	AH,[EDI]._SEG_MAX_ALIGN
		MOV	[ESI]._CDSM_SMFLAGS,BL

		CMP	AH,AL
		JZ	L34$

		JB	L32$

		CMP	AH,SA_DWORD
		JNZ	L34$

		CMP	AL,SA_PARA
		JB	L34$

		JMP	L33$

L32$:
		CMP	AL,SA_DWORD
		JNZ	L33$

		CMP	AH,SA_PARA
		JAE	L34$
L33$:
		MOV	[EDI]._SEG_MAX_ALIGN,AL
L34$:
		MOV	AL,[EDI]._SEG_COMBINE
		MOV	[EDI]._SEG_TYPE,BL

		CMP	AL,SC_UNDEFINED
		JNZ	L39$

		MOV	AL,SC_PUBLIC
		MOV	[EDI]._SEG_COMBINE,AL
L39$:
		MOV	EAX,[ESI]._CDSM_SEGMOD_GINDEX		;SEGMOD SUPPLIED?

		TEST	EAX,EAX
		JNZ	L5$

		MOV	ECX,PUB_SEGMOD_GINDEX
		MOV	EAX,[EDI]._SEG_LAST_SEGMOD_GINDEX

		MOV	[EDI]._SEG_LAST_SEGMOD_GINDEX,ECX

		TEST	EAX,EAX
		JZ	L48$

		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT

		MOV	[EAX]._SM_NEXT_SEGMOD_GINDEX,ECX
L44$:
		;
		;NOW LINK IN CSEG DATA TO MODULE...
		;CX IS CURRENT SEGMOD
		;
		MOV	AL,[ESI]._CDSM_FLAGS_2
		MOV	ESI,[ESI]._CDSM_MODULE_CSEG_GINDEX

		TEST	AL,MASK SM2_CSEG_DONE
		JZ	L59$

		CONVERT	ESI,ESI,CSEG_GARRAY
		ASSUME	ESI:PTR CSEG_STRUCT

		MOV	EDI,[ESI]._CSEG_PARENT_MOD_GINDEX
		CONVERT	EDI,EDI,MODULE_GARRAY
		ASSUME	EDI:PTR MODULE_STRUCT

		MOV	EDI,[EDI]._M_MDB_GINDEX

		TEST	EDI,EDI
		JZ	L59$

		CONVERT	EDI,EDI,MDB_GARRAY
		ASSUME	EDI:PTR MDB_STRUCT

		MOV	EAX,[EDI]._MD_FIRST_CSEGMOD_GINDEX
		MOV	[EDI]._MD_FIRST_CSEGMOD_GINDEX,ECX

		MOV	[ESI]._CSEG_NEXT_CSEGMOD_GINDEX,EAX
		INC	[EDI]._MD_CSEG_COUNT
L59$:
		;
		;OK, NOW MAKE THIS SYMBOL PUBLIC...
		;
		CALL	DO_FIX_COMDAT
		RET

		ASSUME	EDI:PTR SEGMENT_STRUCT
L48$:
		MOV	[EDI]._SEG_FIRST_SEGMOD_GINDEX,ECX
		JMP	L44$

L5$:
		;
		;SEGMOD WAS SUPPLIED, STICK THIS COMDAT AFTER LAST COMDAT ALREADY ON THIS SEGMOD
		;
		;ES:DI:DX IS BASE SEGMENT
		;DS:SI:CX IS THIS COMDAT SEGMOD
		;AX IS PARENT SEGMOD
		;
		MOV	ESI,EAX
		MOV	EBX,EAX
		CONVERT	ESI,ESI,SEGMOD_GARRAY
		ASSUME	ESI:PTR SEGMOD_STRUCT

		MOV	ECX,PUB_SEGMOD_GINDEX

		MOV	EAX,[ESI]._SM_COMDAT_LINK	;LAST COMDAT ASSIGNED
		MOV	[ESI]._SM_COMDAT_LINK,ECX	;THIS ONE IS NOW LAST ONE

		TEST	EAX,EAX
		JNZ	L51$

		MOV	EAX,EBX
L51$:
		;
		;SEGMOD (AX) MUST POINT TO SEGMOD (CX)
		;SEGMOD (CX) MUST POINT TO NEXT_SEGMOD OF SEGMOD(AX)
		;
		CMP	[EDI]._SEG_LAST_SEGMOD_GINDEX,EAX
		JNZ	L52$
		MOV	[EDI]._SEG_LAST_SEGMOD_GINDEX,ECX
L52$:
		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT
		CONVERT	ESI,ECX,SEGMOD_GARRAY
		ASSUME	ESI:PTR SEGMOD_STRUCT

		MOV	EBX,[EAX]._SM_NEXT_SEGMOD_GINDEX
		MOV	[EAX]._SM_NEXT_SEGMOD_GINDEX,ECX


		MOV	[ESI]._SM_NEXT_SEGMOD_GINDEX,EBX
		JMP	L44$

PROC_COMDAT	ENDP


		ASSUME	ESI:PTR CDSEGMOD_STRUCT

PROCURE_SEGMENT	PROC	NEAR
		;
		;ESI IS SEGMOD.  ASSIGN SEGMENT
		;
		AND	EBX,0FH			;1 MEANS 16-BIT CODE, 2 MEANS FAR_DATA, OTHERS FOR 32-BIT...

		JMP	PS_TABLE[EBX*4]


		.DATA

		ALIGN	4

PS_TABLE	DD	PS_ERROR
		DD	PS_CODE_16
		DD	PS_DATA_16
		DD	PS_CODE_32
		DD	PS_DATA_32
		DD	11 DUP(PS_ERROR)


		.CODE	MIDDLE_TEXT

PS_DATA_16:
		MOV	EAX,COMDAT_DATA_16_SEGMENT_GINDEX
		MOV	ECX,DATA_16_SEG_LEN

		PUSH	EAX
		TEST	EAX,EAX

		MOV	EDI,PACKDATA
		JZ	PS_D_FRESH_A		;FORCE A NEW DATA SEGMENT
		;
		;MAKE SURE I DON'T SEND IT PAST PACKDATA
		;
		;FIRST DO ALIGNMENT
		;
		MOV	AL,[ESI]._CDSM_CDALIGN
		CALL	DO_ECX_ALIGN

		CMP	ECX,EDI			;PACKDATA
		JAE	PS_D_FRESH_A		;FORCE A NEW DATA SEGMENT

		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	DATA_16_SEG_LEN,ECX
		;
		;NOW CHECK SIZE OF SEGMOD
		;
		CMP	EAX,EDI
		JAE	PS_D_FRESH		;FORCE A NEW DATA SEGMENT UNLESS CURRENT ONE IS NEW...
		;
		;NOW CHECK SIZES ADDED TOGETHER
		;
		ADD	ECX,EAX			;WILL TOTAL EXCEED 65536-16?

		CMP	ECX,EDI
		JAE	PS_D_FRESH_A		;FORCE A NEW DATA SEGMENT

PS_D_OK:
		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	ECX,DATA_16_SEG_LEN

		POP	EDX
		ADD	EAX,ECX

		MOV	[ESI]._CDSM_BASE_SEG_GINDEX,EDX
		MOV	DATA_16_SEG_LEN,EAX

		CMP	EAX,EDI
		JAE	CLEAR_DSEG

		RET

PS_D_FRESH:
		MOV	EAX,DATA_16_SEG_LEN

		TEST	EAX,EAX
		JZ	PS_D_OK
PS_D_FRESH_A:
		POP	EDX
		CALL	CREATE_DATA_16_SEGMENT

		JMP	PS_DATA_16

CLEAR_DSEG:
		XOR	EAX,EAX

		MOV	COMDAT_DATA_16_SEGMENT_GINDEX,EAX

		RET

PS_CODE_16:
		MOV	EAX,COMDAT_CODE_16_SEGMENT_GINDEX
		MOV	ECX,CODE_16_SEG_LEN

		PUSH	EAX
		TEST	EAX,EAX

		MOV	EDI,PACKCODE
		JZ	PS_C_FRESH_A		;FORCE A NEW CODE SEGMENT
		;
		;MAKE SURE I DON'T SEND IT PAST PACKCODE
		;
		;FIRST DO ALIGNMENT
		;
		MOV	AL,[ESI]._CDSM_CDALIGN
		CALL	DO_ECX_ALIGN

		CMP	ECX,EDI			;PACKCODE
		JAE	PS_C_FRESH_A		;FORCE A NEW CODE SEGMENT

		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	CODE_16_SEG_LEN,ECX
		;
		;NOW CHECK SIZE OF SEGMOD
		;
		CMP	EAX,EDI
		JAE	PS_C_FRESH		;FORCE A NEW CODE SEGMENT UNLESS CURRENT ONE IS NEW...
		;
		;NOW CHECK SIZES ADDED TOGETHER
		;
		ADD	ECX,EAX			;WILL TOTAL EXCEED 65536-16?

		CMP	ECX,EDI
		JAE	PS_C_FRESH_A		;FORCE A NEW CODE SEGMENT

PS_C_OK:
		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	ECX,CODE_16_SEG_LEN

		POP	EDX
		ADD	EAX,ECX

		MOV	[ESI]._CDSM_BASE_SEG_GINDEX,EDX
		MOV	CODE_16_SEG_LEN,EAX

		CMP	EAX,EDI
		JAE	CLEAR_CSEG

		RET

PS_C_FRESH:
		MOV	EAX,CODE_16_SEG_LEN

		TEST	EAX,EAX
		JZ	PS_C_OK
PS_C_FRESH_A:
		POP	EDX
		CALL	CREATE_CODE_16_SEGMENT

		JMP	PS_CODE_16

CLEAR_CSEG:
		XOR	EAX,EAX

		MOV	COMDAT_CODE_16_SEGMENT_GINDEX,EAX

		RET


PS_ERROR:
		MOV	AL,BAD_CD_ALLOC_ERR
		push	EAX
		call	_err_abort

PROCURE_SEGMENT	ENDP


PS_DATA_32	PROC	NEAR
		;
		;RETURN SEGMENT GINDEX FOR 32-BIT DATA
		;
		MOV	EAX,COMDAT_DATA_32_SEGMENT_GINDEX	;FIRST MAKE SURE SEGMENT EXISTS
		MOV	ECX,DATA_32_SEG_LEN

		TEST	EAX,EAX
		JZ	L5$
		;
		;FIRST DO ALIGNMENT
		;
		MOV	AL,[ESI]._CDSM_CDALIGN
		CALL	DO_ECX_ALIGN

		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	DATA_32_SEG_LEN,ECX

		ADD	EAX,ECX
		MOV	EDX,COMDAT_DATA_32_SEGMENT_GINDEX

		MOV	DATA_32_SEG_LEN,EAX
		MOV	[ESI]._CDSM_BASE_SEG_GINDEX,EDX

		RET

L5$:
		CALL	CREATE_DATA_32_SEGMENT

		JMP	PS_DATA_32

PS_DATA_32	ENDP


PS_CODE_32	PROC	NEAR
		;
		;RETURN SEGMENT GINDEX FOR 32-BIT CODE
		;
		MOV	EAX,COMDAT_CODE_32_SEGMENT_GINDEX	;FIRST MAKE SURE SEGMENT EXISTS
		MOV	ECX,CODE_32_SEG_LEN

		TEST	EAX,EAX
		JZ	L5$
		;
		;FIRST DO ALIGNMENT
		;
		MOV	AL,[ESI]._CDSM_CDALIGN
		CALL	DO_ECX_ALIGN

		MOV	EAX,[ESI]._CDSM_SIZE
		MOV	CODE_32_SEG_LEN,ECX

		ADD	EAX,ECX
		MOV	EDX,COMDAT_CODE_32_SEGMENT_GINDEX

		MOV	CODE_32_SEG_LEN,EAX
		MOV	[ESI]._CDSM_BASE_SEG_GINDEX,EDX

		RET

L5$:
		CALL	CREATE_CODE_32_SEGMENT

		JMP	PS_CODE_32

PS_CODE_32	ENDP


CREATE_CODE_16_SEGMENT	PROC	NEAR
		;
		;SET UP NEXT CODE:COMDAT_SEGn SEGMENT...
		;
		MOV	AL,MASK SEG32_USE16
		MOV	ECX,302H

		PUSH	ESI
		MOV	SEG32_FLAGS,AL

		MOV	WPTR SEG_COMBINE,CX	;PARA PUBLIC

		MOV	EAX,OFF CODE_TPTR	;FIRST, SET CLASS TO 'CODE'
		CALL	MAKE_TPTR_LINDEX	;CONVERT TO LNAME INDEX

		MOV	CLASS_NAME_LINDEX,EAX
		CALL	SET_NEXT_COMDAT_SEGNAME	;NEXT, SET SEGMENT NAME

		CALL	GET_SEGMENT_ENTRY	;EAX IS GINDEX, ECX IS PHYS
		ASSUME	ECX:PTR SEGMENT_STRUCT
		;
		;FORCE MAX_ALIGN TO AT LEAST PARAGRAPH
		;
		MOV	COMDAT_CODE_16_SEGMENT_GINDEX,EAX
		MOV	AL,[ECX]._SEG_32FLAGS

		MOV	DL,SA_PARA
		OR	AL,MASK SEG32_NONZERO

		MOV	[ECX]._SEG_MAX_ALIGN,DL
		POP	ESI

		XOR	EDX,EDX
		MOV	[ECX]._SEG_32FLAGS,AL

		MOV	CODE_16_SEG_LEN,EDX

		RET

CREATE_CODE_16_SEGMENT	ENDP


CREATE_CODE_32_SEGMENT	PROC	NEAR
		;
		;SET UP NEXT CODE:COMDAT_SEGn SEGMENT...
		;
		PUSH	ESI

		MOV	WPTR SEG_COMBINE,302H	;PARA PUBLIC

		MOV	EAX,OFF CODE_TPTR	;FIRST, SET CLASS TO 'CODE'
		CALL	MAKE_TPTR_LINDEX	;CONVERT TO LNAME INDEX

		MOV	CLASS_NAME_LINDEX,EAX
		CALL	SET_NEXT_COMDAT_SEGNAME	;NEXT, SET SEGMENT NAME

		MOV	SEG32_FLAGS,MASK SEG32_USE32
		CALL	GET_SEGMENT_ENTRY	;EAX IS GINDEX, ECX IS PHYS
		;
		;FORCE MAX_ALIGN TO AT LEAST PARAGRAPH
		;
		MOV	[ECX]._SEG_MAX_ALIGN,SA_PARA
		MOV	COMDAT_CODE_32_SEGMENT_GINDEX,EAX
		XOR	EAX,EAX
		OR	[ECX]._SEG_32FLAGS,MASK SEG32_NONZERO

		MOV	CODE_32_SEG_LEN,EAX
		POP	ESI

		RET

CREATE_CODE_32_SEGMENT	ENDP


CREATE_DATA_16_SEGMENT	PROC	NEAR
		;
		;SET UP NEXT FAR_DATA:COMDAT_SEGn SEGMENT...
		;
		PUSH	ESI

		MOV	WPTR SEG_COMBINE,302H	;PARA PUBLIC

		MOV	EAX,OFF FAR_DATA_TPTR	;FIRST, SET CLASS TO 'FAR_DATA'
		CALL	MAKE_TPTR_LINDEX	;CONVERT TO LNAME INDEX

		MOV	CLASS_NAME_LINDEX,EAX
		CALL	SET_NEXT_COMDAT_SEGNAME	;NEXT, SET SEGMENT NAME
		;
		MOV	SEG32_FLAGS,MASK SEG32_USE16
		CALL	GET_SEGMENT_ENTRY	;AX IS GINDEX, DS:BX IS PHYS
		;
		;FORCE MAX_ALIGN TO AT LEAST PARAGRAPH
		;
		MOV	COMDAT_DATA_16_SEGMENT_GINDEX,EAX
		XOR	EAX,EAX

		MOV	[ECX]._SEG_MAX_ALIGN,SA_PARA

		OR	[ECX]._SEG_32FLAGS,MASK SEG32_NONZERO

		MOV	DATA_16_SEG_LEN,EAX
		POP	ESI

		RET

CREATE_DATA_16_SEGMENT	ENDP


CREATE_DATA_32_SEGMENT	PROC	NEAR
		;
		;SET UP NEXT FAR_DATA:COMDAT_SEGn SEGMENT...
		;
		PUSH	ESI

		MOV	WPTR SEG_COMBINE,302H	;PARA PUBLIC

		MOV	EAX,OFF FAR_DATA_TPTR	;FIRST, SET CLASS TO 'FAR_DATA'
		CALL	MAKE_TPTR_LINDEX	;CONVERT TO LNAME INDEX

		MOV	CLASS_NAME_LINDEX,EAX
		CALL	SET_NEXT_COMDAT_SEGNAME	;NEXT, SET SEGMENT NAME
		;
		MOV	SEG32_FLAGS,MASK SEG32_USE32

		CALL	GET_SEGMENT_ENTRY	;AX IS GINDEX, DS:BX IS PHYS
		;
		;FORCE MAX_ALIGN TO AT LEAST PARAGRAPH
		;
		MOV	COMDAT_DATA_32_SEGMENT_GINDEX,EAX
		XOR	EAX,EAX
		MOV	[ECX]._SEG_MAX_ALIGN,SA_PARA
		OR	[ECX]._SEG_32FLAGS,MASK SEG32_NONZERO

		MOV	DATA_32_SEG_LEN,EAX
		POP	ESI
		RET

CREATE_DATA_32_SEGMENT	ENDP


SET_NEXT_COMDAT_SEGNAME	PROC	NEAR
		;
		;DEFINED SEG_NAME_VPTR PLEASE
		;
		MOV	EAX,NEXT_COMDAT_SEGNUM
		MOV	ECX,OFF COMDAT_SEGNNNNN_TPTR._TP_TEXT+10

		INC	EAX

		MOV	NEXT_COMDAT_SEGNUM,EAX
		CALL	CBTA16

		XOR	ECX,ECX
		MOV	ESI,OFF COMDAT_SEGNNNNN_TPTR._TP_LENGTH
		ASSUME	ESI:NOTHING,EDI:NOTHING

		MOV	DPTR [EAX],ECX
		SUB	EAX,OFF COMDAT_SEGNNNNN_TPTR

		MOV	[ESI],EAX
		MOV	EDI,ESI

		GET_NAME_HASHD			;HASH THIS THING

		MOV	COMDAT_SEGNNNNN_TPTR._TP_HASH,EDX
		MOV	EAX,OFF COMDAT_SEGNNNNN_TPTR
		CALL	MAKE_TPTR_LINDEX

		MOV	SEG_NAME_LINDEX,EAX
		RET

SET_NEXT_COMDAT_SEGNAME	ENDP


DO_FIX_COMDAT	PROC	NEAR
		;
		;SET UP FOR PUBDEF STUFF
		;
		MOV	ECX,COMDAT_GINDEX
		MOV	ESI,CURNMOD_GINDEX

		XOR	EBX,EBX
		MOV	EAX,ECX

		CONVERT	ESI,ESI,MODULE_GARRAY
		ASSUME	ESI:PTR MODULE_STRUCT
		CONVERT	ECX,ECX,SYMBOL_GARRAY
		ASSUME	ECX:PTR SYMBOL_STRUCT

		MOV	PUB_GROUP_GINDEX,EBX
		MOV	ESI,[ESI]._M_FIRST_PUB_GINDEX

		MOV	PUB_OFFSET,EBX
		MOV	MOD_FIRST_PUBLIC_GINDEX,ESI

		CALL	FIX_COMDAT_ENTRY	;DS:BX IS PHYSICAL, AX IS GINDEX

		MOV	ESI,CURNMOD_GINDEX
		CONVERT	ESI,ESI,MODULE_GARRAY
		ASSUME	ESI:PTR MODULE_STRUCT
		MOV	EAX,MOD_FIRST_PUBLIC_GINDEX

		MOV	[ESI]._M_FIRST_PUB_GINDEX,EAX

		RET

DO_FIX_COMDAT	ENDP


		END

