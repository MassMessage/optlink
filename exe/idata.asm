		TITLE	IDATA - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
if	fg_pe
		INCLUDE	SYMBOLS
		INCLUDE	SEGMENTS

		PUBLIC	CREATE_IDATA_DATA


		.DATA

		EXTERNDEF	FIX2_LD_TYPE:BYTE,TEMP_RECORD:BYTE

		EXTERNDEF	FIX2_LD_LENGTH:WORD

		EXTERNDEF	FIRST_HELPER_BLOCK:DWORD,IDATA_SEGMOD_GINDEX:DWORD,PE_THUNKS_RVA:DWORD,FIX2_LDATA_PTR:DWORD
		EXTERNDEF	FIX2_LDATA_LOC:DWORD,FIX2_SM_START:DWORD,PE_BASE:DWORD

		EXTERNDEF	SYMBOL_GARRAY:STD_PTR_S,SEGMOD_GARRAY:STD_PTR_S


		.CODE	PASS2_TEXT

		EXTERNDEF	DO_PE_RELOC:PROC,EXE_OUT_LDATA:PROC,RELEASE_SEGMENT:PROC


ICODE_VARS		STRUC

MY_RELOC_ADDR_BP	DD	?
MY_THUNKS_ADDR_BP	DD	?
BYTES_SO_FAR_BP		DD	?
TABLE_PTR_BP		DD	?
TABLE_CNT_BP		DD	?

ICODE_VARS		ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE ICODE_VARS].(X&_BP))

	ENDM


FIX	MY_RELOC_ADDR
FIX	MY_THUNKS_ADDR
FIX	BYTES_SO_FAR
FIX	TABLE_PTR
FIX	TABLE_CNT


CREATE_IDATA_DATA	PROC
		;
		;BUILD STRUCTURES IN TEMP_RECORD THAT HANDLE IMPORT REFERENCES TO NON-IMPORTED DATA...
		;
		PUSHM	EBP,EDI,ESI,EBX

		MOV	EAX,IDATA_SEGMOD_GINDEX
		MOV	EBP,ESP
		ASSUME	EBP:PTR ICODE_VARS

		SUB	ESP,SIZE ICODE_VARS
		MOV	ESI,OFF TEMP_RECORD

		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT

		MOV	EAX,[EAX]._SM_START
		MOV	FIX2_LDATA_PTR,ESI

		MOV	MY_RELOC_ADDR,EAX		;POINT TO ADDRESS
		MOV	TABLE_PTR,ESI

		MOV	FIX2_LD_TYPE,MASK BIT_LE

		MOV	TABLE_CNT,MAX_RECORD_LEN/4

		MOV	ESI,FIRST_HELPER_BLOCK
		XOR	EAX,EAX

		TEST	ESI,ESI
		JZ	L9$

		MOV	FIRST_HELPER_BLOCK,EAX
		MOV	BYTES_SO_FAR,EAX
L0$:
		LEA	EDI,[ESI+PAGE_SIZE]
		JMP	L3$

L1$:
		CALL	HANDLE_IMPREF		;AX IS SYMBOL BEING REFERENCED...
L3$:
		MOV	EAX,[ESI]
		ADD	ESI,4

		CMP	ESI,EDI
		JZ	L4$

		TEST	EAX,EAX
		JNZ	L1$

		LEA	EAX,[EDI - PAGE_SIZE]
		CALL	RELEASE_SEGMENT

		CALL	FLUSH_TABLE
L9$:
		MOV	ESP,EBP
		XOR	EAX,EAX

		MOV	FIX2_LDATA_PTR,EAX

		POPM	EBX,ESI,EDI,EBP

		RET

L4$:
		MOV	ESI,EAX
		LEA	EAX,[EDI - PAGE_SIZE]

		CALL	RELEASE_SEGMENT

		JMP	L0$

CREATE_IDATA_DATA	ENDP


HANDLE_IMPREF	PROC	NEAR
		;
		;STORE ADDRESS OF THIS SYMBOL
		;
		;
		;STORE A RELOCATION ENTRY
		;
		PUSH	EBX
		MOV	EBX,EAX

		MOV	EDX,MY_RELOC_ADDR

		MOV	EAX,EDX
		ADD	EDX,4

		MOV	MY_RELOC_ADDR,EDX
		CALL	DO_PE_RELOC
		;
		;STORE A DWORD POINTING TO THIS SYMBOL
		;
		CONVERT	EBX,EBX,SYMBOL_GARRAY
		ASSUME	EBX:PTR SYMBOL_STRUCT

		MOV	EDX,TABLE_PTR
		MOV	ECX,TABLE_CNT

		MOV	EAX,[EBX]._S_OFFSET
		DEC	ECX

		MOV	[EDX],EAX
		LEA	EDX,[EDX+4]

		MOV	TABLE_PTR,EDX
		MOV	TABLE_CNT,ECX

		POP	EBX
		JZ	FLUSH_TABLE

		RET

HANDLE_IMPREF	ENDP


FLUSH_TABLE	PROC	NEAR	PRIVATE
		;
		;
		;
		MOV	ECX,TABLE_PTR
		MOV	EAX,OFF TEMP_RECORD

		SUB	ECX,EAX
		JZ	L9$

		MOV	FIX2_LD_LENGTH,CX
		MOV	TABLE_PTR,ESI

		MOV	EAX,BYTES_SO_FAR
		MOV	EDX,FIX2_SM_START

		ADD	ECX,EAX
		ADD	EAX,EDX

		MOV	BYTES_SO_FAR,ECX
		MOV	FIX2_LDATA_LOC,EAX

		MOV	TABLE_CNT,MAX_RECORD_LEN/4

		JMP	EXE_OUT_LDATA

L9$:
		RET

FLUSH_TABLE	ENDP

endif

		END

