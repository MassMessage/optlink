		TITLE	IRESTYPE - Copyright (C) 1994 SLR Systems

		INCLUDE	MACROS
		INCLUDE	RESSTRUC

if	fg_segm

		PUBLIC	INSTALL_RESOURCE_TYPE,INSTALL_RES_TYPE_NAME,INSTALL_RTNL


		.DATA

		EXTERNDEF	RESOURCE_TYPE_STUFF:DWORD,RESTYPE_BYNAME_GINDEX:DWORD,RESTYPE_BYORD_GINDEX:DWORD,N_RTNLS:DWORD
		EXTERNDEF	RESTYPE_N_BYORD:DWORD,RESTYPE_N_BYNAME:DWORD,RESTYPE_HASH:DWORD,RES_TYPENAME_HASH:DWORD
		EXTERNDEF	RESOURCE_FLAGS:DWORD,RESOURCE_TYPE_ID:DWORD,RESTYPE_HASH_TABLE_PTR:DWORD,RESOURCE_FILE_ADDR:DWORD
		EXTERNDEF	RES_TYPENAME_HASH_TABLE_PTR:DWORD,RESOURCE_SIZE:DWORD,FIRST_RTNL_GINDEX:DWORD,LAST_RTNL_GINDEX:DWORD
		EXTERNDEF	N_RESTYPENAMES:DWORD

		EXTERNDEF	RESTYPE_GARRAY:STD_PTR_S,RES_TYPENAME_GARRAY:STD_PTR_S,RTNL_GARRAY:STD_PTR_S


		.CODE	PASS2_TEXT

		EXTERNDEF	RESTYPE_POOL_GET:PROC,RES_TYPENAME_POOL_GET:PROC,RTNL_POOL_GET:PROC


INSTALL_RESOURCE_TYPE	PROC
		;
		;EAX IS ITEM TO STORE...  RETURN EAX == GINDEX
		;
		;IF DX==0, AX IS RESOURCE TYPE_ID
		;IF DX!=0, AX IS RESNAME_GINDEX
		;
		PUSH	EDI
		MOV	EDI,EAX

		XOR	EDX,EDX
		PUSH	EBX

		MOV	EBX,RESTYPE_HASH_TABLE_PTR

		HASHDIV	RESTYPE_HASH
		;
		;NOW EDI IS RESOURCE_TYPE_ID
		;
		MOV	EAX,DPTR [EBX+EDX*4]
		LEA	EBX,[EBX+EDX*4 - RESTYPE_STRUCT._RT_NEXT_HASH_GINDEX]
NAME_NEXT:
		TEST	EAX,EAX
		JZ	DO_INSTALL

		MOV	EDX,EAX
		CONVERT	EAX,EAX,RESTYPE_GARRAY
		ASSUME	EAX:PTR RESTYPE_STRUCT
		MOV	EBX,EAX
		;
		;IS IT A MATCH?
		;
		MOV	ECX,[EAX]._RT_ID_GINDEX
		MOV	EAX,[EAX]._RT_NEXT_HASH_GINDEX

		CMP	ECX,EDI
		JNZ	NAME_NEXT

		MOV	ECX,EBX
		MOV	EAX,EDX

		POPM	EBX,EDI

		RET

DO_INSTALL:
		;
		;DS:SI GETS POINTER
		;
		;CX:DI
		;
		PUSH	EDI
		MOV	EDX,EBX

		MOV	EAX,SIZE RESTYPE_STRUCT
		CALL	RESTYPE_POOL_GET		;ES:DI AX

		MOV	EBX,EAX
		ASSUME	EBX:PTR RESTYPE_STRUCT
		MOV	EDI,EAX

		INSTALL_POINTER_GINDEX	RESTYPE_GARRAY

		MOV	[EDX].RESTYPE_STRUCT._RT_NEXT_HASH_GINDEX,EAX
		MOV	EDX,EAX

		MOV	ECX,SIZE RESTYPE_STRUCT/4
		XOR	EAX,EAX

		REP	STOSD

		POP	EAX

		CMP	EAX,64K
		JAE	L5$
		;
		;BY_ORD
		;
		MOV	ECX,RESTYPE_N_BYORD
		MOV	[EBX]._RT_ID_GINDEX,EAX

		INC	ECX
		MOV	EAX,RESTYPE_BYORD_GINDEX

		MOV	RESTYPE_BYORD_GINDEX,EDX
		MOV	RESTYPE_N_BYORD,ECX

		MOV	[EBX]._RT_NEXT_RT_GINDEX,EAX
		JMP	L6$

L5$:
		;
		;BY_NAME
		;
		MOV	ECX,RESTYPE_N_BYNAME
		MOV	[EBX]._RT_ID_GINDEX,EAX

		INC	ECX
		MOV	EAX,RESTYPE_BYNAME_GINDEX

		MOV	RESTYPE_BYNAME_GINDEX,EDX
		MOV	RESTYPE_N_BYNAME,ECX

		MOV	[EBX]._RT_NEXT_RT_GINDEX,EAX
L6$:
		POPM	EBX,EDI

		MOV	EAX,EDX

		RET

INSTALL_RESOURCE_TYPE	ENDP


INSTALL_RES_TYPE_NAME	PROC
		;
		;ECX IS RESTYPE_GINDEX
		;EAX IS TYPE_ID_NAME_GINDEX
		;
		;IF DX==0, AX IS RESOURCE RTN_ID
		;IF DX!=0, AX IS RESNAME_GINDEX
		;
		PUSH	EDI
		MOV	EDX,ECX

		ROL	EDX,16
		MOV	EDI,EAX

		XOR	EAX,EDX
		XOR	EDX,EDX
		;
		;NOW DI IS RESOURCE_RTN_ID
		;    CX IS RESNAME_GINDEX
		;
		PUSH	EBX
		MOV	EBX,RES_TYPENAME_HASH_TABLE_PTR

		HASHDIV	RES_TYPENAME_HASH

		PUSH	ESI

		MOV	EAX,DPTR [EBX+EDX*4]
		LEA	EBX,[EBX+EDX*4 - RES_TYPE_NAME_STRUCT._RTN_NEXT_HASH_GINDEX]
NAME_NEXT:
		TEST	EAX,EAX
		JZ	DO_INSTALL

		MOV	EDX,EAX
		CONVERT	EAX,EAX,RES_TYPENAME_GARRAY
		ASSUME	EAX:PTR RES_TYPE_NAME_STRUCT
		MOV	EBX,EAX
		ASSUME	EBX:PTR RES_TYPE_NAME_STRUCT
		;
		;IS IT A MATCH?
		;
		MOV	ESI,[EAX]._RTN_TYPE_GINDEX
		MOV	EAX,[EAX]._RTN_NEXT_HASH_GINDEX

		CMP	ESI,ECX
		JNZ	NAME_NEXT

		CMP	[EBX]._RTN_ID_GINDEX,EDI
		JNZ	NAME_NEXT

		POPM	ESI,EBX,EDI
		MOV	EAX,EDX

		RET

DO_INSTALL:
		;
		;DS:SI GETS POINTER
		;
		;CX:DI:BX
		;
		PUSH	EDI
		MOV	EDX,EBX

		MOV	EAX,SIZE RES_TYPE_NAME_STRUCT
		CALL	RES_TYPENAME_POOL_GET		;ES:DI AX

		MOV	EBX,EAX
		MOV	EDI,EAX

		INSTALL_POINTER_GINDEX	RES_TYPENAME_GARRAY

		MOV	[EDX].RES_TYPE_NAME_STRUCT._RTN_NEXT_HASH_GINDEX,EAX
		MOV	ESI,ECX

		MOV	EDX,EAX
		MOV	ECX,SIZE RES_TYPE_NAME_STRUCT/4

		XOR	EAX,EAX
		MOV	[EBX]._RTN_TYPE_GINDEX,ESI

		REP	STOSD

		MOV	EDI,N_RESTYPENAMES
		POP	ECX

		GETT	AL,OUTPUT_PE
		INC	EDI

		MOV	[EBX]._RTN_ID_GINDEX,ECX
		CONVERT	ESI,ESI,RESTYPE_GARRAY
		ASSUME	ESI:PTR RESTYPE_STRUCT
		MOV	N_RESTYPENAMES,EDI

		OR	AL,AL
		JNZ	L4$
		;
		;16-BIT MUST BE LINKED IN ORDER...
		;
		MOV	ECX,[ESI]._RT_N_RTN_BYORD
		MOV	EAX,[ESI]._RT_RTN_BYNAME_GINDEX	;THIS IS LAST ENTRY

		INC	ECX
		MOV	[ESI]._RT_RTN_BYNAME_GINDEX,EDX

		TEST	EAX,EAX
		JZ	L3$

		CONVERT	EAX,EAX,RES_TYPENAME_GARRAY
		ASSUME	EAX:PTR RES_TYPE_NAME_STRUCT

		MOV	[EAX]._RTN_NEXT_RTN_GINDEX,EDX
L2$:
		MOV	[ESI]._RT_N_RTN_BYORD,ECX

		POPM	ESI,EBX,EDI
		MOV	EAX,EDX

		RET

L3$:
		MOV	[ESI]._RT_RTN_BYORD_GINDEX,EDX	;THIS IS FIRST ENTRY
		JMP	L2$

L4$:
		CMP	ECX,64K
		JAE	L5$
		;
		;BY_ORD
		;
		MOV	ECX,[ESI]._RT_N_RTN_BYORD
		MOV	EAX,[ESI]._RT_RTN_BYORD_GINDEX

		INC	ECX
		MOV	[ESI]._RT_RTN_BYORD_GINDEX,EDX

		MOV	[ESI]._RT_N_RTN_BYORD,ECX
		JMP	L6$

L5$:
		;
		;BY_NAME
		;
		MOV	ECX,[ESI]._RT_N_RTN_BYNAME
		MOV	EAX,[ESI]._RT_RTN_BYNAME_GINDEX

		INC	ECX
		MOV	[ESI]._RT_RTN_BYNAME_GINDEX,EDX

		MOV	[ESI]._RT_N_RTN_BYNAME,ECX
L6$:
		MOV	[EBX]._RTN_NEXT_RTN_GINDEX,EAX
		POPM	ESI,EBX,EDI
		MOV	EAX,EDX

		RET

INSTALL_RES_TYPE_NAME	ENDP


INSTALL_RTNL	PROC
		;
		;EAX IS RTN GINDEX, ECX IS LANGUAGE
		;
		PUSH	EDI
		MOV	EDI,EAX

		CONVERT	EAX,EAX,RES_TYPENAME_GARRAY
		ASSUME	EAX:PTR RES_TYPE_NAME_STRUCT

		PUSHM	ESI,EBX

		LEA	EBX,[EAX]._RTN_RTNL_GINDEX - RTNL_STRUCT._RTNL_NEXT_LANG_GINDEX
		MOV	EAX,[EAX]._RTN_RTNL_GINDEX
L1$:
		TEST	EAX,EAX
		JZ	DO_INSTALL

		MOV	EDX,EAX
		CONVERT	EAX,EAX,RTNL_GARRAY
		ASSUME	EAX:PTR RTNL_STRUCT
		MOV	EBX,EAX

		MOV	ESI,[EAX]._RTNL_LANG_ID
		MOV	EAX,[EAX]._RTNL_NEXT_LANG_GINDEX

		CMP	ECX,ESI
		JNZ	L1$

		CMP	ESP,-1
		POPM	EBX,ESI,EDI

		MOV	EAX,EDX

		RET

DO_INSTALL:
		;
		;EBX GET POINTER
		;
		MOV	EAX,SIZE RTNL_STRUCT
		CALL	RTNL_POOL_GET

		MOV	ESI,EBX
		MOV	EBX,EAX
		ASSUME	EBX:PTR RTNL_STRUCT

		INSTALL_POINTER_GINDEX	RTNL_GARRAY

		ASSUME	ESI:PTR RTNL_STRUCT

		MOV	EDX,LAST_RTNL_GINDEX
		MOV	LAST_RTNL_GINDEX,EAX

		TEST	EDX,EDX
		JZ	FIRST_RTNL

		ASSUME	EDX:PTR RTNL_STRUCT

		MOV	[EDX]._RTNL_NEXT_GINDEX,EAX
FIRST_RTNL_RET:
		MOV	[ESI]._RTNL_NEXT_LANG_GINDEX,EAX

		MOV	EDX,EAX
		XOR	EAX,EAX

		MOV	ESI,RESOURCE_FILE_ADDR
		MOV	[EBX]._RTNL_NEXT_LANG_GINDEX,EAX

		MOV	[EBX]._RTNL_FILE_ADDRESS,ESI
		MOV	EAX,RESOURCE_SIZE

		MOV	ESI,RESOURCE_FLAGS
		MOV	[EBX]._RTNL_FILE_SIZE,EAX

		MOV	[EBX]._RTNL_FLAGS,ESI
		CONVERT	EDI,EDI,RES_TYPENAME_GARRAY
		ASSUME	EDI:PTR RES_TYPE_NAME_STRUCT
		MOV	EAX,RESOURCE_TYPE_ID

		MOV	[EBX]._RTNL_LANG_ID,ECX
		MOV	[EBX]._RTNL_TYPE_ID,EAX

		MOV	[EBX]._RTNL_NEXT_GINDEX,0

		MOV	ECX,[EDI]._RTN_N_RTNL
		MOV	EAX,EDX

		INC	ECX
		MOV	EDX,N_RTNLS

		MOV	[EDI]._RTN_N_RTNL,ECX
		ADD	EDX,1				;CLEARS CARRY TOO...

		POPM	EBX,ESI,EDI
		MOV	N_RTNLS,EDX

		RET

FIRST_RTNL:
		MOV	FIRST_RTNL_GINDEX,EAX
		JMP	FIRST_RTNL_RET

INSTALL_RTNL	ENDP

endif

		END

