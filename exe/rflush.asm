		TITLE	RFLUSH - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SEGMENTS
		INCLUDE	IO_STRUC
		INCLUDE	SECTS


		PUBLIC	COM_FLUSH_SEGMOD,EXE_FLUSH_SEGMOD,EXE_FLUSH_SEGMENT,FLUSH_EAX_TO_FINAL,EXE_OUT_FLUSH_EXE


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE

		EXTERNDEF	EXETABLE:DWORD,_EXE_DEVICE:DWORD,CURN_TIME_DD:DWORD,CURN_DATE_DD:DWORD,HIGH_WATER:DWORD
		EXTERNDEF	SYS_BASE:DWORD,OLD_HIGH_WATER:DWORD,VECTOR_SECTION_FILE_ADDRESS:DWORD,EXEHDR_ADDR:DWORD
		EXTERNDEF	CURN_SECTION_FILE_ADDRESS:DWORD,CURN_OUTFILE_BASE_ADDRESS:DWORD,FINAL_HIGH_WATER:DWORD
		EXTERNDEF	FIX2_SKIP_BYTES:DWORD,EXEPACK_STRUCTURE:DWORD,FIX2_SM_START:DWORD,FIX2_SM_LEN:DWORD

		EXTERNDEF	OUT_FLUSH_SEGMOD:DWORD


		.CODE	PASS2_TEXT

		EXTERNDEF	ZERO_EAX_FINAL_HIGH_WATER:PROC,RELEASE_EXETABLE_5:PROC,WARN_RET:PROC,RELEASE_BLOCK:PROC
		EXTERNDEF	CONVERT_SUBBX_TO_EAX:PROC,REAL_EXEPACK:PROC,MOVE_EAX_TO_FINAL_HIGH_WATER:PROC
		EXTERNDEF	ZERO_EAX_EXEPACK_HIGH_WATER:PROC,STORE_EAXECX_EDX_SEQ:PROC
		EXTERNDEF	FLUSH_ERROR_LINENUMBERS:PROC,EXE_OUT_NEW_SECTION:PROC,REAL_RELOC_FLUSH:PROC,REAL_EXEPACK_FLUSH:PROC
		EXTERNDEF	FLUSH_OUTFILE:PROC,FLUSH_ALMOST_FINAL:PROC,DOSPOSITION_A:PROC,REAL_RELOC_F1_NOPACK:PROC,FF_1:PROC
		EXTERNDEF	CODEVIEW_HERE:PROC,FLUSH_OUTFILE_2:PROC,FLUSH_PACKED_DEBUG:PROC

		EXTERNDEF	COM_BELOW_100_ERR:ABS


COM_FLUSH_SEGMOD	PROC
		;
		;FLUSH STUFF FROM THIS SEGMOD
		;
		;
		;FIRST SEE IF ANY DATA APPEARED IN THE SEGMOD
		;
		MOV	EAX,HIGH_WATER
		MOV	ECX,FIX2_SM_START

		SUB	EAX,ECX
		JBE	L9$			;IT'S AN EMPTY SEGMENT
		;
		;IS ANY DATA ABOVE SYS_BASE?
		;
		MOV	EAX,HIGH_WATER
		MOV	ECX,SYS_BASE

		SUB	EAX,ECX
		JBE	L8$			;NOPE, GO RELEASE WHATEVER

		MOV	OUT_FLUSH_SEGMOD,OFF EXE_FLUSH_SEGMOD
		;
		;USUALLY SM STARTS AT 0, WE NEED TO SKIP UP TO SYS_BASE
		;
		MOV	EAX,FIX2_SM_START

		SUB	EAX,ECX
		JC	L2$
		;
		;SM IS ABOVE OR EQUAL SYS_BASE, WRITE SOME ZEROS
		;
		CALL	ZERO_EAX_FINAL_HIGH_WATER
		;
		;NOW JUST FLUSH DATA
		;
		JMP	REAL_DATA_FLUSH

L9$:
		RET

L2$:
		;
		;GO AHEAD AND WRITE, BUT DON'T START AT BEGINNING.  COMPLAIN
		;IF BEGINNING NOT ZERO
		;
		MOV	EAX,ECX
		MOV	ECX,FIX2_SM_START

		SUB	EAX,ECX

		PUSH	EAX
		CALL	VERIFY_ZERO		;CHECK EAX BYTES FOR ZERO

		MOV	EAX,HIGH_WATER
		POP	ECX

		MOV	EDX,FIX2_SM_START
		MOV	OLD_HIGH_WATER,EAX

		SUB	EAX,EDX

		SUB	EAX,ECX
		CALL	MOVE_HELPER_REAL

		JMP	RELEASE_EXETABLE_5

L8$:
		;
		;RELEASE ANY BLOCKS HELD, WARN IF NOT ZERO...
		;
		MOV	EAX,HIGH_WATER
		MOV	ECX,FIX2_SM_START

		SUB	EAX,ECX
		CALL	VERIFY_ZERO

		JMP	RELEASE_EXETABLE_5

COM_FLUSH_SEGMOD	ENDP


VERIFY_ZERO	PROC	NEAR
		;
		;VERIFY EAX BYTES AS BEING ZERO, RELEASE AS YOU GO...
		;
		PUSHM	EDI,EBX

		MOV	EBX,OFF EXETABLE
		MOV	EDX,EAX
L1$:
		;
		;NEED TO CHECK SMALLER OF SI:CX AND PAGE_SIZE
		;
		MOV	EDI,[EBX]
		MOV	ECX,PAGE_SIZE

		CMP	EDX,ECX
		JA	L2$
		MOV	ECX,EDX

		TEST	EDX,EDX
		JZ	L9$
L2$:
		TEST	EDI,EDI
		JZ	L7$

		PUSH	ECX
		XOR	EAX,EAX

		SHR	ECX,2

		REPE	SCASD

		POP	ECX
		JNZ	L5$

		PUSH	ECX
		AND	ECX,3

		JZ	L3$

		REPE	SCASB
		JNZ	L51$
L3$:
		POP	ECX
L31$:
		CMP	ECX,PAGE_SIZE
		JNZ	L7$

		XCHG	EAX,[EBX]

		CALL	RELEASE_BLOCK
L7$:
		ADD	EBX,4
		SUB	EDX,ECX

		JMP	L1$

L51$:
		POP	ECX
L5$:
		BITT	BELOW_100_WARNED
		JNZ	L31$

		SETT	BELOW_100_WARNED

		PUSHM	EDX,ECX

		MOV	AL,COM_BELOW_100_ERR
		CALL	WARN_RET

		POPM	ECX,EDX

		XOR	EAX,EAX
		JMP	L31$

L9$:
		POPM	EBX,EDI

		RET

VERIFY_ZERO	ENDP


MOVE_HELPER_REAL	PROC	NEAR
		;
		;MOVE EAX BYTES FROM EXETABLE[ECX] TO FINAL_HIGH_WATER
		;
		TEST	EAX,EAX
		JZ	L9$

		PUSH	EBX
		MOV	EBX,ECX

		SHR	EBX,PAGE_BITS
		AND	ECX,PAGE_SIZE-1

		PUSH	ESI
		MOV	ESI,ECX

		MOV	ECX,EAX
		LEA	EBX,EXETABLE[EBX*4]
L1$:
		;
		;NOW MOVE SMALLER OF PAGE_SIZE-SI AND CX
		;
		MOV	EAX,ECX
		MOV	ECX,PAGE_SIZE

		PUSH	EAX
		SUB	ECX,ESI

		CMP	ECX,EAX
		JB	L2$

		MOV	ECX,EAX
L2$:
		PUSH	ECX
		CALL	CONVERT_SUBBX_TO_EAX

		ADD	EAX,ESI
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POPM	EAX

		ADD	ESI,EAX
		POP	ECX

		CMP	ESI,PAGE_SIZE
		JNZ	L3$

		PUSH	EAX
		XOR	EDX,EDX

		MOV	EAX,[EBX]
		MOV	[EBX],EDX

		CALL	RELEASE_BLOCK

		POP	EAX
L3$:
		ADD	EBX,4
		XOR	ESI,ESI

		SUB	ECX,EAX
		JNZ	L1$

		POPM	ESI,EBX
L9$:
		RET

MOVE_HELPER_REAL	ENDP


EXE_FLUSH_SEGMOD	PROC
		;
		;FLUSH STUFF FROM THIS SEGMOD, OR SEGMENT IF COMMON OR STACK
		;
		;
		;FIRST SEE IF ANY DATA APPEARED IN THE SEGMOD
		;
		MOV	EAX,HIGH_WATER
		MOV	ECX,FIX2_SM_START

		SUB	EAX,ECX
		JC	L9$

		GETT	DL,DOING_DEBUG		;FOR DEBUG, OUTPUT EVEN IF NOTHING THERE (COMPILER BUGS)
		GETT	CL,EXEPACK_BODY

		TEST	DL,DL
		JNZ	L8$

		TEST	EAX,EAX
		JZ	L9$			;IT'S AN EMPTY SEGMENT

		TEST	CL,CL
		JNZ	L7$
		;
		;MAY NEED TO FILL IN ZEROS UP TO HERE...
		;
		MOV	EAX,FIX2_SM_START
		MOV	ECX,OLD_HIGH_WATER

		SUB	EAX,ECX
if	fg_slrpack
		GETT	CL,SLRPACK_FLAG

		OR	CL,CL
		JNZ	L6$
endif
		CALL	ZERO_EAX_FINAL_HIGH_WATER
L8$:
		CALL	REAL_DATA_FLUSH

		GETT	AL,PACKING_RELOCS
		GETT	CL,CHAINING_RELOCS

		OR	AL,CL
		JNZ	L89$

		JMP	REAL_RELOC_FLUSH	;THESE WERE BUFFERED TILL
L89$:
		RET

L9$:
		;
		;EMPTY SEGMOD
		;
		JMP	RELEASE_EXETABLE_5

if	fg_slrpack
L6$:
		CALL	ZERO_EAX_EXEPACK_HIGH_WATER	;FOR COMPRESSED OVERLAYS

		JMP	REAL_DATA_TO_EXEPACK

endif

L7$:
		JMP	REAL_EXEPACK		;OUTPUTS DATA

EXE_FLUSH_SEGMOD	ENDP


EXE_FLUSH_SEGMENT	PROC
		;
		;FLUSH INFO ABOUT LAST SEGMENT.
		;
		;FIRST SEE IF ANY DATA APPEARED IN THE SEGMENT
		;
		GETT	AL,EXEPACK_BODY

		OR	AL,AL
		JZ	L1$

		CALL	REAL_EXEPACK_FLUSH
L1$:
		GETT	AL,CHAINING_RELOCS
		GETT	CL,PACKING_RELOCS

		OR	AL,CL
		JNZ	L5$
		RET

L5$:
		;
		;NEED TO SET UP A NEW 8K BLOCK
		;

L7$:
		JMP	REAL_RELOC_FLUSH	;OUTPUTS DATA AND RELOCS

EXE_FLUSH_SEGMENT	ENDP


if	fg_slrpack OR fg_winpack

REAL_DATA_TO_EXEPACK	PROC
		;
		;
		;
		SETT	SPECIAL_ZERO_AXCX

		CALL	REAL_DATA_FLUSH

		RESS	SPECIAL_ZERO_AXCX

		RET

REAL_DATA_TO_EXEPACK	ENDP

endif

if	fg_winpack

		PUBLIC	PROT_DATA_TO_WINPACK

PROT_DATA_TO_WINPACK	EQU	REAL_DATA_TO_EXEPACK

endif

REAL_DATA_FLUSH PROC
		;
		;
		;

		MOV	EAX,HIGH_WATER		;# OF BYTES TO WRITE
		MOV	ECX,FIX2_SM_START

		MOV	OLD_HIGH_WATER,EAX	;FOR FILLING ZEROES
		SUB	EAX,ECX

;		CALL	FLUSH_EAX_TO_FINAL
;		RET

REAL_DATA_FLUSH ENDP


FLUSH_EAX_TO_FINAL	PROC
		;
		;NEED TO SUPPORT SKIPPING FIX2_SKIP_BYTES
		;
		PUSHM	EBX

		PUSH	EAX
		MOV	EDX,FIX2_SKIP_BYTES
		MOV	EBX,OFF EXETABLE
		JMP	L03$

L01$:
		XOR	ECX,ECX
		SUB	EDX,PAGE_SIZE

		MOV	EAX,[EBX]
		MOV	[EBX],ECX

		TEST	EAX,EAX
		JZ	L02$

		CALL	RELEASE_BLOCK
L02$:
		ADD	EBX,4
L03$:
		CMP	EDX,PAGE_SIZE
		JAE	L01$
L05$:
		;
		;EDX IS INITIAL OFFSET TO USE
		;
		POP	ECX
L1$:
		;
		;IF ECX > (PAGE_SIZE-EDX), WRITE (PAGE_SIZE-EDX)
		;
		PUSH	ECX
		MOV	EAX,PAGE_SIZE

		SUB	EAX,EDX

		CMP	ECX,EAX
		JB	L3$

		MOV	ECX,EAX
L3$:
		PUSH	ECX
		CALL	CONVERT_SUBBX_TO_EAX

		ADD	EAX,EDX
if	fg_slrpack OR fg_winpack
		GETT	DL,SPECIAL_ZERO_AXCX

		OR	DL,DL
		JNZ	L4$
endif
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
if	fg_slrpack OR fg_winpack
		JMP	L5$

L4$:
		MOV	EDX,OFF EXEPACK_STRUCTURE
		CALL	STORE_EAXECX_EDX_SEQ
L5$:
endif
		XOR	EDX,EDX
		MOV	EAX,[EBX]

		MOV	[EBX],EDX
		CALL	RELEASE_BLOCK

		POPM	EAX,ECX

		ADD	EBX,4
		SUB	ECX,EAX

		JNZ	L1$

		POP	EBX

		RET

FLUSH_EAX_TO_FINAL	ENDP


EXE_OUT_FLUSH_EXE	PROC
		;
		;IF NOT ALREADY DONE, FLUSH REMAINING DATA TO EXE AND DO
		;HEADER STUFF
		;
		GETT	AL,OUT_FLUSHED

		OR	AL,AL
		JZ	L1$

		RET

L1$:
		SETT	OUT_FLUSHED
		;
		;OK, NEED TO SEND VECTORS AND SECTION OFFSETS TO ROOT FILE
		;
		;
		;SELECT A DUMMY-TYPE SECTION
		;
if	any_overlays
		BITT	DOING_OVERLAYS
		JZ	2$
		CALL	FLUSH_OUTFILE
		LDS	SI,FIRST_SECTION	;ROOT SECTION
		MOV	CURN_SECTION.OFFS,SI
		MOV	CURN_SECTION.SEGM,DS
		CALL	EXE_OUT_NEW_SECTION
		MOV	AX,VECTOR_SECTION_FILE_ADDRESS.LW
		MOV	CURN_SECTION_FILE_ADDRESS.LW,AX
		MOV	CURN_OUTFILE_BASE_ADDRESS.LW,AX
		MOV	AX,VECTOR_SECTION_FILE_ADDRESS.HW
		MOV	CURN_SECTION_FILE_ADDRESS.HW,AX
		MOV	CURN_OUTFILE_BASE_ADDRESS.HW,AX
		XOR	AX,AX
		MOV	EXEHDR_ADDR.LW,AX
		MOV	EXEHDR_ADDR.HW,AX
		MOV	FINAL_HIGH_WATER.LW,AX

;		CALL	OUTPUT_VECTORS
		CALL	OUTPUT_SECTIONS

		;
		;NOW END DUMMY SECTION
		;
		CALL	FLUSH_ALMOST_FINAL	;WRITE LAST PARTIAL BLOCK
		LDS	SI,CURN_OUTFILE
		SYM_CONV_DS
		MOV	CX,[SI]._OF_FINAL_HIGH_WATER.HW
		MOV	DX,[SI]._OF_FINAL_HIGH_WATER.LW
		MOV	BX,_EXE_DEVICE
		CALL	DOSPOSITION_A
		CALL	FF_1			;SEEK AND TRUNCATE
		CALL	FLUSH_OUTFILE_2 	;CLEAR HANDLE
		OR	[SI]._OF_FLAGS,MASK OF_CLOSED+MASK OF_TRUNCATED
2$:
endif

		RET

EXE_OUT_FLUSH_EXE	ENDP

if	any_overlays

OUTPUT_SECTIONS PROC	NEAR
		;
		;OUTPUT SECTION PARAGRAPH OFFSETS PLEASE
		;
		FIXES
		LEA	DI,TEMP_RECORD
		MOV	AX,CURN_TIME_WD
		STOSW
		MOV	AX,CURN_DATE_WD
		STOSB
;		MOV	AX,SECTION_NUMBER
;		STOSW
		LDS	SI,FIRST_SECTION
1$:
		SYM_CONV_DS
		PUSHM	[SI]._SECT_NEXT_SECTION_ORDER.OFFS,[SI]._SECT_NEXT_SECTION_ORDER.SEGM
		TEST	[SI]._SECT_FLAGS,MASK SECT_CODEVIEW
		JNZ	2$
		MOV	AX,[SI]._SECT_FILE_ADDRESS.LW
		MOV	DX,[SI]._SECT_FILE_ADDRESS.HW
		CALL	SHR_DXAX_4
		STOSW
		XCHG	AX,DX
		STOSB
		CMP	DI,OFF TEMP_RECORD+TEMP_SIZE-4
		JB	2$
		CALL	REAL_RELOC_F1_NOPACK
2$:
		POPM	DS,SI
		MOV	AX,DS
		OR	AX,AX
		JNZ	1$
		MOV	AX,EXEHEADER._EXE_HDR_SIZE
		STOSW
		CALL	REAL_RELOC_F1_NOPACK
		RET

OUTPUT_SECTIONS ENDP

endif


		END

