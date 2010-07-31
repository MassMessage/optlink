		TITLE	SLR-DECOMPRESSOR Copyright (c) SLR Systems 1990

		DOSSEG

		INCLUDE UNMACROS
		INCLUDE SLR32

DATA		SEGMENT WORD PUBLIC 'DATA'

	SOFT	EXTD	EXEPACK_STRUCTURE

DATA		ENDS

DGROUP		GROUP	DATA,STACK,BSS

CODE		SEGMENT DWORDP PUBLIC 'CODE'
		ASSUME	CS:CODE

	SOFT	EXTN	COMPRESS,GET_EXEPACK_BYTES,REXE_INIT

DECOMPRESS_TEST PROC
		;
		;GET SET UP FOR DOING A COMPRESS JOB...
		;

FNF:
		LEA	SI,FNF_MSG
		JMP	DO_MSG

START:
		;
		;DS = PSP
		;ES = PSP
		;SS = STACK SEGMENT
		;
		CLD
		MOV	AH,30H
		DO_INT21
		CMP	AL,2
		JNC	L1
		MOV	AX,4C01H
		DO_INT21
L1:
		LEA	BP,MYDATA+80H
		MOV	DX,DGROUP
		MOV	ES,DX		;SET UP FOR MOVING CMDLINE FROM PSP

		ASSUME	ES:DGROUP

		CLI
		LEA	SP,MYSTACK	;INIT STACK POINTER
		MOV	SS,DX
		STI

		ASSUME	SS:DGROUP
		;
		;ZERO OUT VARIABLES
		;
		LEA	DI,FLAGS
		LEA	CX,END_BP_STRUCT
		SUB	CX,DI
		SHR	CX,1
		XOR	AX,AX
		REP	STOSW
		;
		;COPY FILENAMES TO ASCIZ STORAGE AREAS
		;
		MOV	SI,80H		;TO DATA SEGMENT
		LEA	DI,ASCIZ0
		LODSB
		XOR	AH,AH
		XCHG	AX,CX
		CALL	PARSE_NAME
		LEA	DI,ASCIZ1
		CALL	PARSE_NAME

		PUSH	DS
		POP	ES
		MOV	DS,DX
		ASSUME	DS:DGROUP
		;
		;CALCULATE LAST PARAGRAPH
		;
		MOV	AX,SP
		MOV	CL,4
		SHR	AX,CL
		INC	AX
		ADD	AX,DX
		MOV	BX,ES
		SUB	BX,AX		;SIZE OF BLOCK
		NEG	BX
		MOV	AH,4AH
		DO_INT21

		LEA	SI,SIGNON
		CALL	PRINT
		;
		;OPEN INPUT FILE
		;
		LEA	DX,ASCIZ0
		MOV	AX,3D00H	;R/O
		DO_INT21
		JC	FNF
		MOV	ASCIZ0_HANDLE,AX
		XCHG	AX,BX
		XOR	CX,CX
		XOR	DX,DX
		MOV	AX,4202H
		DO_INT21
		MOV	INFILE_BYTES_LEFT.LW,AX
		MOV	INFILE_BYTES_LEFT.HW,DX
		MOV	NEW_REPT_ADDR.LW,AX
		MOV	NEW_REPT_ADDR.HW,DX
		XOR	CX,CX
		XOR	DX,DX
		MOV	AX,4200H
		DO_INT21
		;
		;OPEN OUTPUT FILE
		;
		FIXDS
		FIXES
		CMP	ASCIZ1,0
		JNZ	0$
		CALL	MOVE_0_TO_1
0$:
		LEA	DX,ASCIZ1
		MOV	AX,3D02H	;R/W
		DO_INT21
		JNC	F_OPENED
		XOR	CX,CX
		MOV	AX,3C00H		;CREATE
		DO_INT21
		JNC	F_OPENED
CANT_CREATE:
		LEA	SI,CCM
		JMP	DO_MSG

F_OPENED:
		MOV	ASCIZ1_HANDLE,AX
		;
		;
		;
		MOV	AX,WRITE_BUF_SEG
		MOV	ES,AX
		XOR	DI,DI

		MOV	AX,READ_BUF_SEG
		MOV	DS,AX
		XOR	SI,SI
		CALL	FIX_INPUT
		MOV	AX,BYTES_LEFT
		CMP	AX,16K
		JA	NORM
NORM_1:
		MOV	INITIAL_BYTES,AX
		SUB	BYTES_LEFT,AX
		DEC	AX
		DEC	AX
		MOV	BYTES_LIMIT,AX
		MOV	DX,1
		XOR	BX,BX
		JMP	LOOP_CHECK

NORM:
		MOV	AX,16K
		JMP	NORM_1

SB_1:
		MOVSB
		LOOP	SB_2
		JMP	LOOP_CHECK

LC_1:
		CALL	FIX_OUTPUT
		JMP	LC_2

LC_3:
		CALL	FIX_INPUT
		JMP	LC_4

STRAIGHT_BYTES:
		XCHG	AX,CX
		INC	CX
		TEST	SI,DX
		ADD	BX,CX
		JNZ	SB_1
SB_2:
		SHR	CX,1
		REP	MOVSW
		ADC	CX,CX
		REP	MOVSB
LOOP_CHECK:
		CMP	DI,8K
		JAE	LC_1
LC_2:
		SUB	BYTES_LEFT,BX
		MOV	AX,BYTES_LIMIT
		CMP	BYTES_LEFT,AX
		JB	LC_3
LC_4:
		;
		;SI POINTS TO 16K+2 OR ALL
		;
		LODSB
		MOV	BX,1
		OR	AL,AL
		JS	1$
		XOR	AH,AH
		CMP	AL,64
		JC	STRAIGHT_BYTES
		ADD	AX,4000H-64
		CMP	AL,32
		JC	REPT_BYTES_1
		ADD	AX,1000H-32
		CMP	AL,112
		JC	REPT_WORDS_1
		ADD	AX,2000H-16
		JMP	REPT_DWORDS_1

REPT_BYTES:
		SUB	AX,4000H
REPT_BYTES_1:
		XCHG	AX,CX
		INC	CX
		LODSB
		INC	BX
		MOV	AH,AL
		TEST	DI,DX
		JNZ	RB_1
RB_2:
		SHR	CX,1
		REP	STOSW
		JNC	LOOP_CHECK
		STOSB
		JMP	LOOP_CHECK

RB_1:
		STOSB
		LOOP	RB_2
		JMP	LOOP_CHECK

REPT_WORDS:
		SUB	AX,5000H
REPT_WORDS_1:
		XCHG	AX,CX
		LODSB
		MOV	AH,AL
		LODSB
		XCHG	AH,AL
		ADD	BX,2
		TEST	DI,DX
		JNZ	RW_2
		STOSW
		REP	STOSW
		JMP	LOOP_CHECK

RW_2:
		STOSB
		XCHG	AL,AH
		REP	STOSW
		STOSB
		JMP	LOOP_CHECK

1$:
		AND	AL,7FH
		MOV	AH,AL
		LODSB
		INC	BX
2$:
		CMP	AX,4000H
		JC	STRAIGHT_BYTES
		CMP	AX,5000H
		JC	REPT_BYTES
		CMP	AX,7000H
		JC	REPT_WORDS
		INC	AX
		JZ	DONE
		SUB	AX,7000H
REPT_DWORDS_1:
		XCHG	AX,CX
R_4_L:
		MOVSB			;BYTES BECAUSE OF WRAP AROUND...
		MOVSB
		MOVSB
		MOVSB
		SUB	SI,4
		LOOP	R_4_L
		ADD	SI,4
		ADD	BX,4
		JMP	LOOP_CHECK

DONE:
		;
		;FLUSH OUTPUT BUFFER
		;
		;
		;CLOSE FILES
		;
		CALL	FLUSH_OUTPUT
		;
		MOV	BX,ASCIZ1_HANDLE
		XOR	CX,CX			;TRUNCATE FILE
		MOV	AH,40H
		DO_INT21
		MOV	AH,3EH			;CLOSE IT
		DO_INT21
		;
		;
		;
		LEA	SI,SUCCESS_MSG
		CALL	PRINT
		MOV	AX,4C00H
		DO_INT21

DECOMPRESS_TEST ENDP

FIX_INPUT	PROC
		;
		;NEED MORE DATA IN INPUT BUFFER, CALL DECOMPRESSOR TO GET ANOTHER 16K PLEASE
		;
		PUSHM	DS,SI,ES,DI,DX,CX,BX,AX
		CALL	DECOMPRESS		;DECOMPRESS A CHUNK
		JC	9$
8$:
		ADD	BYTES_LEFT,AX
		POPM	AX,BX,CX,DX,DI,ES,SI,DS
		RET

9$:
		BITT	INPUT_END
		JNZ	99$
		SETT	INPUT_END
		MOV	AX,INITIAL_BYTES
		JMP	8$

99$:
		LEA	SI,CORRUPT_MSG
		JMP	DO_MSG

FIX_INPUT	ENDP

FIX_OUTPUT	PROC
		;
		;DI IS SIZE OF BUFFER, AT LEAST 8K IN SIZE
		;WRITE OUT AN EVEN # OF K TO REDUCE BUFFER TO BELOW 1K IN SIZE
		;
		PUSH	CX
		MOV	CX,DI
		AND	CX,NOT (1K-1)		;EVEN 1K INCREMENT
F_O_1:
		PUSHM	DS,SI,ES
		POP	DS
		PUSHM	DX,BX,AX
		MOV	SI,CX			;FIRST LEFT-OVER BYTE
		SUB	DI,CX			;# OF LEFT-OVER BYTES
		XOR	DX,DX
		MOV	BX,ASCIZ1_HANDLE
		MOV	AH,40H
		DO_INT21
		CMP	AX,CX
		JNZ	8$			;JMP IF DISK FULL
9$:
		POPM	AX,BX,DX
		MOV	CX,DI
		XOR	DI,DI
		OPTI_MOVSB
		POPM	SI,DS,CX
		RET

8$:
		LEA	SI,CWM
		JMP	DO_MSG

FIX_OUTPUT	ENDP

FLUSH_OUTPUT	PROC
		;
		;
		;
		PUSH	CX
		MOV	CX,DI
		JMP	F_O_1

FLUSH_OUTPUT	ENDP

MOVE_0_TO_1	PROC
		;
		;RE-USE FILENAME FROM INPUT
		;
		LEA	SI,ASCIZ0
		LEA	DI,ASCIZ1
1$:
		LODSB
		STOSB
		OR	AL,AL
		JNZ	1$
		RET

MOVE_0_TO_1	ENDP

DO_MSG:
		CALL	PRINT
ABORT:
		MOV	AX,4C01H
		DO_INT21

PRINT:
		MOV	AX,DGROUP
		MOV	DS,AX
		LODSB
		CBW
		XCHG	AX,CX
		MOV	DX,SI
		MOV	BX,1
		MOV	AH,40H
		DO_INT21
		RET

PARSE_NAME	PROC
		;
		;DS:SI IS SOURCE, ES:DI IS DESTINATION, CX IS BYTES LEFT
		;
		JCXZ	9$
		LODSB
		DEC	CX
		CMP	AL,9
		JZ	PARSE_NAME
		CMP	AL,20H
		JZ	PARSE_NAME
1$:
		STOSB
		JCXZ	5$
		LODSB
		DEC	CX
		CMP	AL,9
		JZ	5$
		CMP	AL,20H
		JNZ	1$
5$:
9$:
		XOR	AL,AL
		STOSB
		RET

PARSE_NAME	ENDP

DOT		PROC
		;
		;
		;
		PUSHM	DS,DX,CX,BX,AX
		FIXDS
		LEA	DX,DOT_DAT
		MOV	CX,1
		MOV	BX,1
		MOV	AH,40H
		DO_INT21
		POPM	AX,BX,CX,DX,DS
		RET

DOT		ENDP

	ASSUME	DS:NOTHING
CODE		ENDS

DATA		SEGMENT PUBLIC	'DATA'

DOT_DAT 	DB	'.'

OOM_MSG 	DB	LENGTH OOM_MSG-1,'Not enough memory'

FNF_MSG 	DB	LENGTH FNF_MSG-1,'File not found'

CCM		DB	LENGTH CCM-1,"Can't create file"
CWM		DB	LENGTH CWM-1,'Error writing file'

EOF_MSG 	DB	LENGTH EOF_MSG-1,'Unexepected EOF reading file'

NODATA_MSG	DB	LENGTH NODATA_MSG-1,'No Data to compress'

SIGNON		DB	LENGTH SIGNON-1,' Copyright (C) SLR Systems 1990 ',0DH,0AH

CORRUPT_MSG	DB	LENGTH CORRUPT_MSG-1,'Compressed Data Corrupt',0dh,0ah

SUCCESS_MSG	DB	LENGTH SUCCESS_MSG-1,'Finished',0DH,0AH

DATA		ENDS

BSS		SEGMENT DWORD PUBLIC	'BSS'

MYDATA		DB	SIZE BP_STRUCT1 + 80H DUP(?)

BSS		ENDS

STACK		SEGMENT STACK PARA 'STACK'

		DB	512 DUP(?)

MYSTACK 	LABEL	WORD

STACK		ENDS

PACK_SLR	SEGMENT PARA PUBLIC	'FAR_DATA'

POS_TABLE	DB	1,0,0,1,2,6,15,22,20,19,42	;0,1,0,2,3,7,18,47,50

POS_TABLE_LEN	EQU	$-POS_TABLE

PACK_SLR	ENDS

WRITE_BUF_SEG	SEGMENT PARA PUBLIC	'FAR_DATA'

WRITE_BUF	DB	24K DUP(?)

WRITE_BUF_SEG	ENDS

READ_BUF_SEG	SEGMENT PARA PUBLIC	'FAR_DATA'

READ_BUF	DB	63K DUP(?)
		DB	1K DUP(?)

READ_BUF_SEG	ENDS

		END	START
