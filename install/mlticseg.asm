		TITLE MLTICSEG - Copyright (c) 1992 by SLR Systems

		INCLUDE MACROS
		INCLUDE	SEGMENTS
		INCLUDE	MODULES

		PUBLIC	FIX_MULTI_CSEGS,FIX_LIN_CSEG


		.DATA

		EXTERNDEF	CURNMOD_GINDEX:DWORD,LIN_SEGMOD_GINDEX:DWORD,MOD_FIRST_CSEGMOD_GINDEX:DWORD,MOD_CSEG_COUNT:DWORD

		EXTERNDEF	SEGMOD_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S,MODULE_GARRAY:STD_PTR_S,CSEG_GARRAY:STD_PTR_S


		.CODE	PASS1_TEXT

		EXTERNDEF	WARN_ASCIZ_RET:PROC

		EXTERNDEF	LIN_NONCODE_ERR:ABS


FIX_LIN_CSEG	PROC
		;
		;RETURN EAX GINDEX, ECX PHYS POINTING TO _CSEG_ STRUCTURE
		;
		MOV	EAX,LIN_SEGMOD_GINDEX
		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT

		MOV	DL,[EAX]._SM_FLAGS_2
		MOV	ECX,[EAX]._SM_MODULE_CSEG_GINDEX

		AND	DL,MASK SM2_CSEG_DONE
		JZ	L1$

		MOV	EAX,ECX
		CONVERT	ECX,ECX,CSEG_GARRAY

		RET

L1$:
		;
		;WARN ABOUT LINE #'S FOR NON-CODE SEGMENTS
		;
if	fg_td
		BITT	TD_FLAG
		JNZ	L11$
endif
		MOV	ECX,[EAX]._SM_BASE_SEG_GINDEX
		CONVERT	ECX,ECX,SEGMENT_GARRAY
		ASSUME	ECX:PTR SEGMENT_STRUCT
		MOV	AL,LIN_NONCODE_ERR

		LEA	ECX,[ECX]._SEG_TEXT
		CALL	WARN_ASCIZ_RET
L11$:
		MOV	EAX,LIN_SEGMOD_GINDEX

		CONVERT	ECX,EAX,SEGMOD_GARRAY
		CALL	FIX_MULTI_CSEGS
		JMP	FIX_LIN_CSEG

FIX_LIN_CSEG	ENDP


FIX_MULTI_CSEGS PROC
		;
		;ECX IS SEGMOD PHYSICAL, EAX IS GINDEX
		;
		;ADD SEGMOD TO LIST OF CODE SEGMENTS FOR THIS MODULE
		;
		ASSUME	ECX:PTR SEGMOD_STRUCT

		MOV	EDX,EAX
		MOV	AL,[ECX]._SM_FLAGS_2

		PUSH	EDI
		OR	AL,MASK SM2_CSEG_DONE

		PUSH	EBX
		MOV	[ECX]._SM_FLAGS_2,AL

		MOV	EAX,SIZE CSEG_STRUCT
		TILLP2_POOL_ALLOC		;EAX IS PHYS

		MOV	EBX,EAX
		MOV	EDI,EAX

		INSTALL_POINTER_GINDEX	CSEG_GARRAY

		MOV	[ECX]._SM_MODULE_CSEG_GINDEX,EAX
		MOV	AL,-1

		MOV	ECX,SIZE CSEG_STRUCT/4
		SETT	NEED_MDB_RECORD,AL

		XOR	EAX,EAX

		REP	STOSD

		ASSUME	EBX:PTR CSEG_STRUCT

		MOV	EAX,MOD_FIRST_CSEGMOD_GINDEX
		MOV	MOD_FIRST_CSEGMOD_GINDEX,EDX		;MODULE POINTS TO CURRENT CODE SEGMOD

		MOV	ECX,CURNMOD_GINDEX
		MOV	EDX,MOD_CSEG_COUNT

		MOV	[EBX]._CSEG_NEXT_CSEGMOD_GINDEX,EAX
		INC	EDX

		MOV	[EBX]._CSEG_PARENT_MOD_GINDEX,ECX
		POP	EBX

		POP	EDI
		MOV	MOD_CSEG_COUNT,EDX

		RET

FIX_MULTI_CSEGS ENDP


		END

