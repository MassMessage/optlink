		TITLE	PROLOG	 -

		INCLUDE	MACROS

		PUBLIC	PERFORM_VERIFY

		.DATA

	SOFT	EXTB	SYMBOL_TPTR

	SOFT	EXTW	SYMBOL_LENGTH

	SOFT	EXTCA	OPTI_MOVE

		.CODE	MIDDLE_TEXT

	SOFT	EXTP	FAR_INSTALL,SEARCH_RAINBOW_AXBXXX,ERR_ABORT,AX_MESOUT,LNAME_INSTALL

	SOFT	EXTA	CANNOT_LINK_ERR

		ASSUME	DS:NOTHING

PERFORM_VERIFY	PROC
		;
		;LOOK FOR SEGMENTS AND SYMBOLS
		;
		CALL	VERIFY_SEGMENT
		LEA	SI,@_RTSMain_ModulaEntry
		CALL	VERIFY_SYMBOL
		LEA	SI,@_SYSTEM_HALT
		CALL	VERIFY_SYMBOL
		RET

PERFORM_VERIFY	ENDP

VERIFY_SEGMENT	PROC	NEAR
		;
		;
		;
		LEA	SI,CLASS1
		CALL	VERIFY_CLASS
		MOV	DS,AX
		SYM_CONV_DS
;		PUSH	[BX]._C_CLASS_NUMBER
		PUSH	CS
		POP	DS
		LEA	SI,SEG1
		CALL	UNXOR
		FIXES
		GET_NAME_HASH
		CALL	LNAME_INSTALL
		POP	CX
;		ADD	CX,RECTYP_SEGMENT
		CALL	SEARCH_RAINBOW_AXBXXX
		JC	VERIFY_FAIL
		RET

VERIFY_SEGMENT	ENDP

VERIFY_CLASS	PROC	NEAR
		;
		;
		;
		PUSH	CS
		POP	DS
		CALL	UNXOR
		FIXES
		GET_NAME_HASH
		CALL	LNAME_INSTALL
;		MOV	CX,RECTYP_CLASS
		CALL	SEARCH_RAINBOW_AXBXXX
		JC	VERIFY_FAIL
		RET

VERIFY_CLASS	ENDP

VERIFY_FAIL:
		MOV	AX,SEG CALL_SLR
		MOV	SI,OFF CALL_SLR
		CALL	AX_MESOUT
		MOV	CL,CANNOT_LINK_ERR
		CALL	ERR_ABORT

VERIFY_SYMBOL	PROC	NEAR
		;
		;
		;
		PUSH	CS
		POP	DS
		CALL	UNXOR
		FIXES
		GET_NAME_HASH
		CALL	FAR_INSTALL
		JNC	VERIFY_FAIL
		RET

VERIFY_SYMBOL	ENDP

UNXOR		PROC	NEAR
		;
		;
		;
		PUSH	SI
		MOV	AH,0AAH
		XOR	BPTR [SI],AH
		LODSB
		MOV	CL,AL
		XOR	CH,CH
1$:
		XOR	BPTR [SI],AH
		INC	SI
		LOOP	1$
		POP	SI
		RET

UNXOR		ENDP

GENSTRING	MACRO	XX
		LOCAL	LEN

@_&XX		DB	LEN XOR 0AAH
		IRPC	XXX,<XX>
		DB	'&XXX' XOR 0AAH
		ENDM

LEN		EQU	$-1-@_&XX

		ENDM

		GENSTRING	RTSMain_ModulaEntry
		GENSTRING	SYSTEM_HALT
CLASS1		LABEL	BYTE
		GENSTRING	<CODE>
SEG1		LABEL	BYTE
		GENSTRING	RTSExec_TEXT

CALL_SLR	DB	LENGTH CALL_SLR-1,'Cannot link with this version of OPTLINK.',0dh,0ah,\
'Contact SLR Systems, Inc at (412)282-0864 for other OPTLINK versions.',0dh,0ah, \
'Or write:',0dh,0ah, \
'  1622 N. Main St.',0dh,0ah, \
'  Butler, PA  16001',0dh,0ah

		END

