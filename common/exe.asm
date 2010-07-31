		TITLE	-EXE - Copyright (c) SLR Systems 1994

		INCLUDE MACROS
		INCLUDE	SEGMENTS


		.DATA

		EXTERNDEF	FIX2_SEG_COMBINE:BYTE

		EXTERNDEF	FIX2_SEG_OFFSET:DWORD,FIX2_SM_START:DWORD,FIX2_STACK_DELTA:DWORD,FIX2_SKIP_BYTES:DWORD
		EXTERNDEF	FIRST_RELOC_GINDEX:DWORD

		EXTERNDEF	RELOC_GARRAY:STD_PTR_S

		EXTERNDEF	OUT_FLUSH_SEGMOD:DWORD


		.CODE	PASS2_TEXT

		EXTERNDEF	EXE_OUT_NEW_SEGMENT:PROC,EXE_OUT_NEW_SEGMOD:PROC,EXE_OUT_END_OF_SEGMENTS:PROC,EXE_FLUSH_SEGMOD:PROC
		EXTERNDEF	SEGM_OUT_INIT:PROC,EXE_FLUSH_SEGMENT:PROC,EXE_OUT_FLUSH_EXE:PROC,EXE_OUT_NEW_SECTION:PROC
		EXTERNDEF	EXE_OUT_END_OF_SECTION:PROC,PROT_OUT_NEW_SEGMENT:PROC,PROT_OUT_NEW_SEGMOD:PROC
		EXTERNDEF	PROT_FLUSH_SEGMOD:PROC,PROT_FLUSH_SEGMENT:PROC,OS2_OUT_FLUSH_EXE:PROC,SEGM_OUT_END_OF_SECTION:PROC
		EXTERNDEF	SEGM_OUT_NEW_SECTION:PROC,SPECIAL_RELOC_CHECK:PROC,PE_OUT_NEW_SECTION:PROC,PE_OUT_NEW_SEGMENT:PROC
		EXTERNDEF	PE_FLUSH_SEGMENT:PROC,PE_FLUSH_SEGMOD:PROC,PE_OUT_END_OF_SECTION:PROC,EXE_OUT_INIT:PROC


EXE_OUT_SEGMOD_FINISH	PROC
		;
		;FLUSH DATA UNLESS COMMON BLOCK
		;
		MOV	AL,FIX2_SEG_COMBINE

		CMP	AL,SC_COMMON
		JZ	L9$

		CMP	AL,SC_STACK
		JZ	L9$

		JMP	OUT_FLUSH_SEGMOD
L9$:
		RET

EXE_OUT_SEGMOD_FINISH	ENDP


EXE_OUT_SEGMENT_FINISH	PROC
		;
		;IF COMMON, DO WHAT SHOULD HAVE HAPPENED AT SEGMOD_FINISH
		;
		MOV	AL,FIX2_SEG_COMBINE
		MOV	ECX,FIX2_SEG_OFFSET

		CMP	AL,SC_COMMON
		JZ	L1$

		CMP	AL,SC_STACK
		JNZ	L2$

		MOV	EAX,FIRST_RELOC_GINDEX
		MOV	FIX2_SM_START,ECX
		;
		;MAKE SURE NO RELOCATIONS BELOW SKIP_BYTES
		;
		TEST	EAX,EAX
		JZ	L1$

		MOV	ECX,FIX2_SKIP_BYTES
		XOR	EAX,EAX

		TEST	ECX,ECX
		JZ	L1$

		CALL	SPECIAL_RELOC_CHECK
L1$:
		CALL	OUT_FLUSH_SEGMOD

		XOR	EAX,EAX

		MOV	FIX2_SKIP_BYTES,EAX
		MOV	FIX2_STACK_DELTA,EAX
L2$:
		RET

EXE_OUT_SEGMENT_FINISH	ENDP


		PUBLIC	EXE_OUT_TABLE

EXE_OUT_RETT	PROC

		RET

EXE_OUT_RETT	ENDP


		.DATA

		ALIGN	4

EXE_OUT_TABLE	LABEL	DWORD

		DCA	EXE_OUT_RETT		;NOTHING ON OUT_INIT
		DCA	EXE_OUT_NEW_SEGMENT
		DCA	EXE_OUT_NEW_SEGMOD
		DCA	EXE_OUT_SEGMOD_FINISH
		DCA	EXE_OUT_SEGMENT_FINISH
		DCA	EXE_OUT_END_OF_SEGMENTS
		DCA	EXE_FLUSH_SEGMOD
		DCA	EXE_FLUSH_SEGMENT
		DCA	EXE_OUT_FLUSH_EXE
		DCA	EXE_OUT_NEW_SECTION	;WHAT OUT_INIT DID
		DCA	EXE_OUT_END_OF_SECTION

if	fg_segm

		PUBLIC	SEGM_OUT_TABLE

SEGM_OUT_TABLE	LABEL	DWORD

		DCA	SEGM_OUT_INIT
		DCA	PROT_OUT_NEW_SEGMENT
		DCA	PROT_OUT_NEW_SEGMOD
		DCA	EXE_OUT_SEGMOD_FINISH
		DCA	EXE_OUT_SEGMENT_FINISH
		DCA	EXE_OUT_END_OF_SEGMENTS
		DCA	PROT_FLUSH_SEGMOD
		DCA	PROT_FLUSH_SEGMENT
		DCA	OS2_OUT_FLUSH_EXE
		DCA	SEGM_OUT_NEW_SECTION
		DCA	SEGM_OUT_END_OF_SECTION

endif

if	fg_pe

		PUBLIC	PE_OUT_TABLE

PE_OUT_TABLE	LABEL	DWORD

		DCA	SEGM_OUT_INIT
		DCA	PE_OUT_NEW_SEGMENT
		DCA	PROT_OUT_NEW_SEGMOD
		DCA	EXE_OUT_SEGMOD_FINISH
		DCA	EXE_OUT_SEGMENT_FINISH
		DCA	EXE_OUT_END_OF_SEGMENTS
		DCA	PE_FLUSH_SEGMOD
		DCA	PE_FLUSH_SEGMENT
		DCA	OS2_OUT_FLUSH_EXE
		DCA	PE_OUT_NEW_SECTION
		DCA	PE_OUT_END_OF_SECTION

endif

		END

