
		INCLUDE	..\COMMON\MACROS


		.CODE	PASS1_TEXT


		PUBLIC	SLRLOAD_ENTRY,SLRLOAD_BOX_ENTRY

SLRLOAD_ENTRY	PROC
		;
		;
		;
		MOV	EAX,OFF SLRLOAD_OBJ
		MOV	ECX,SLRLOAD_OBJ_LEN

		RET

SLRLOAD_ENTRY	ENDP


SLRLOAD_BOX_ENTRY	PROC
		;
		;
		;
		MOV	EAX,OFF SLRLOAD_BOX_OBJ
		MOV	ECX,SLRLOAD_BOX_OBJ_LEN

		RET

SLRLOAD_BOX_ENTRY	ENDP


		.CONST

SLRLOAD_OBJ	LABEL	BYTE

		INCLUDE	SLRLOAD.DAT

SLRLOAD_OBJ_LEN	EQU	$-SLRLOAD_OBJ


SLRLOAD_BOX_OBJ	LABEL	BYTE

		INCLUDE	SLRLOADB.DAT

SLRLOAD_BOX_OBJ_LEN	EQU	$-SLRLOAD_BOX_OBJ


		END

