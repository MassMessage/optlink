
module parse;

import io_struc;

// MVFILNAM - Copyright (c) SLR Systems 1994

void* MOVE_FILE_LIST_GINDEX_PATH_PRIM_EXT(EAX, ECX)
{

	// ECX IS GINDEX, EAX IS DESTINATION

	EDI = EAX;
	FILE_LIST_STRUCT* EDX;
	CONVERT	EDX,ECX,FILE_LIST_GARRAY
	EAX = [EDX].FILE_LIST_PATH_GINDEX;
	if (EAX)
	{
	    CONVERT	EAX,EAX,FILE_LIST_GARRAY
	    ASSUME	EAX:PTR FILE_LIST_STRUCT

	    ECX = EAX.FILE_LIST_NFN.NFN_PATHLEN;
	    ESI = &EAX.FILE_LIST_NFN.NFN_TEXT;
	    memcpy(EDI, ESI, ECX);
	    EDI += ECX;
	}

	// OUTPUT FILENAME IN ASCII PLEASE
	// FROM [SI] TO [DI]

	ECX = [EDX].FILE_LIST_NFN.NFN_TOTAL_LENGTH;
	ESI = &[EDX].FILE_LIST_NFN.NFN_TEXT;
	memcpy(EDI, ESI, ECX);
	return EDI + ECX;
}


ubyte* MOVE_PATH_PRIM_EXT(ubyte* EAX, NFN_STRUCT* ECX)
{
	// OUTPUT FILENAME IN ASCII PLEASE

	// FROM [ECX] TO [EAX]
	memcpy(EAX, &ECX.NFN_TEXT, ECX.NFN_TOTAL_LENGTH);
	return EAX + ECX.NFN_TOTAL_LENGTH;
}

// MVFNASC - Copyright (c) SLR Systems 1994

void MOVE_FN_TO_ASCIZ(NFN_STRUCT* EAX)
{
    // MOVE FILNAM [EAX] TO ASCIZ STRING

    auto ECX = EAX.NFN_TOTAL_LENGTH;
    ASCIZ_LEN = ECX;	// length in bytes, not 0
    memcpy(&ASCIZ, EAX.NFN_TEXT, ECX);
    *cast(int*)(&ASCIZ + ECX) = 0;
}


// MVFN - Copyright (c) SLR Systems 1994

MOVE_NFN(NFN_STRUCT* EAX, NFN_STRUCT* ECX)
{
    // EAX IS TARGET NFN_STRUCT, ECX IS SOURCE
    memcpy(EAX, ECX,
	NFN_STRUCT.sizeof - NFN_TEXT_SIZE + ECX.NFN_TOTAL_LENGTH + 4);
}

// MVLISTNF - Copyright (c) SLR Systems 1994

MOVE_FILE_LIST_GINDEX_NFN(NFN_STRUCT* EAX, ECX)
{
	// MOVE COMPLETE NFN FROM FILE LIST TO NFN STRUCTURE

	// ECX IS FILE_LIST_GINDEX


	EDX = EAX;
		CONVERT	EAX,ECX,FILE_LIST_GARRAY

	ECX = [EAX].FILE_LIST_STRUCT.FILE_LIST_NFN.NFN_TOTAL_LENGTH +
		NFN_STRUCT.NFN_TEXT+4;

	EAX = [EAX].FILE_LIST_STRUCT.FILE_LIST_PATH_GINDEX;
	memcpy(EDX, &FILE_LIST_STRUCT.FILE_LIST_NFN[EAX], ECX);

	if (EAX)
	{
	    CONVERT	EAX,EAX,FILE_LIST_GARRAY
	    ECX = &FILE_LIST_STRUCT.FILE_LIST_NFN[EAX];

	    EAX = EDX;
	    MOVE_ECXPATH_EAX();
	}
}


// MVPATH

MOVE_ECXPATH_EAX(NFN_STRUCT* EAX, NFN_STRUCT* ECX)
{
	// MOVE PATH FROM ECX TO EAX, PRESERVE EAX

	auto dst = EAX;
	auto src = ECX;

	// Make room
	memmove(&dst.NFN_TEXT[src.NFN_PATHLEN],
		&dst.NFN_TEXT[dst.NFN_PATHLEN],
		dst.NFN_TOTAL_LENGTH - dst.NFN_PATHLEN);

	// Copy path
	memcpy(dst.NFN_TEXT, src.NFN_TEXT, src.NFN_PATHLEN);

	dst.NFN_TOTAL_LENGTH += src.NFN_PATHLEN - dst.NFN_PATHLEN;
	dst.NFN_PATHLEN = src.NFN_PATHLEN;

	*cast(int*)&dst.NFN_TEXT[dst.NFN_TOTAL_LENGTH] = 0;
	return dst;
}

// MVSRCFIL - Copyright (c) SLR Systems 1994

MOVE_SRCPRIM_TO_EAX_CLEAN(NFN_STRUCT* EAX)
{
	EAX.NFN_PRIMLEN = 0;
	EAX.NFN_PATHLEN = 0;
	EAX.NFN_EXTLEN = 0;
	EAX.NFN_TOTAL_LENGTH = 0;
	MOVE_SRCPRIM_TO_EAX(EAX);
}

MOVE_SRCPRIM_TO_EAX(NFN_STRUCT* EAX)
{
	// MOVE PRIMARY PART OF SRCNAM TO FILNAM

	MOVE_ECXPRIM_TO_EAX(EAX, &SRCNAM);
}

MOVE_ECXPRIM_TO_EAX(NFN_STRUCT* EAX, NFN_STRUCT* ECX)
{
	auto dst = EAX;
	auto src = ECX;

	// Make room
	memmove(&dst.NFN_TEXT[dst.NFN_PATHLEN + src.NFN_PRIMLEN],
		&dst.NFN_TEXT[dst.NFN_PATHLEN + dst.NFN_PRIMLEN],
		dst.NFN_EXT);

	// Copy path
	memcpy(&dst.NFN_TEXT[dst.NFN_PATHLEN],
	       &src.NFN_TEXT[src.NFN_PATHLEN],
	       src.NFN_PRIMLEN);

	dst.NFN_TOTAL_LENGTH += src.NFN_PRIMLEN - dst.NFN_PRIMLEN;
	dst.NFN_PRIMLEN = src.NFN_PRIMLEN;

	*cast(int*)&dst.NFN_TEXT[dst.NFN_TOTAL_LENGTH] = 0;
	return dst;
}

// GTNXTU - Copyright (c) SLR Systems 1994


// Get next character from EBX in upper case
ubyte GTNXTU(inout ubyte* EBX)
{
    auto AL = *EBX++;
    if (AL >= 'a' && AL <= 'z')
	AL -= 0x20;
    return AL;
}

// DO_FN - Copyright (c) SLR Systems 1994

DO_FILENAME(NFN_STRUCT* ECX, CMDLINE_STRUCT* EAX)
{
	// EAX IS FILESTUFF_PTR

	PARSE_FILENAME(ECX);

	// DEAL WITH DEFAULTS
	return DO_DEFAULTS(ECX, EAX);
}

DO_DEFAULTS(NFN_STRUCT* ECX, CMDLINE_STRUCT* EAX)
{
	// EAX IS FILESTUFF_PTR
	// ECX IS NFN_STRUCT

	NFN_STRUCT* ESI = ECX;
	CMDLINE_STRUCT* EDI = EAX;

	AL = ESI.NFN_FLAGS;

	if (EAX & MASK NFN_PRIM_SPECIFIED)
		JZ	L1$
L19$:
	if (EAX & MASK NFN_EXT_SPECIFIED)
		JNZ	L3$

	// MOVE DEFAULT EXTENT (UNLESS PRIMARY IS NUL)

	EAX = ESI;
	if (!CHECK_NUL1(EAX))
	{
	    // MOVE DEFAULT EXTENT...
	    EAX = 0;
	    AL = EDI.CMD_EXTENT[0];
	    ECX = EAX;
	    EAX -= ESI.NFN_EXTLEN;
	    ESI.NFN_EXTLEN = ECX;
	    ESI.NFN_TOTAL_LENGTH += EAX;
	    EAX = ESI.NFN_PATHLEN + ESI.NFN_PRIMLEN;
	    memcpy(ESI.NFN_TEXT + EAX, EDI.CMD_EXT + 1, ECX);
	    *cast(int*)(ESI.NFN_TEXT + EAX + ECX) = 0;
	}
L3$:
	EAX = ESI;
	return EAX;

L1$:
	// NO PRIMARY FILENAME, MOVE EITHER NUL OR SRC...

		PUSH	EAX
	[EDI].CMD_SELECTED();
	// WANT IT, MOVE SOURCE NAME
		JNZ	L13$

	// OK, IF PATH OR EXTENTION SPECIFIED, MOVE SOURCE TOO


	if (BPTR [ESI].NFN_FLAGS & MASK NFN_PATH_SPECIFIED+MASK NFN_EXT_SPECIFIED)
		JZ	L15$
L13$:
	EAX = ESI;
	MOVE_SRCPRIM_TO_EAX();
L15$:
		POP	EAX
	goto L19$;

}

// CHKNUL - Copyright (c) SLR Systems 1994

CHECK_NUL(NFN_STRUCT* EAX)
{
	// SEE IF [EAX] IS NUL DEVICE..., SET FLAG IF SO...

	if (EAX.NFN_PRIMLEN == 0 || !CHECK_NUL1(EAX))
	    EAX.NFN_FLAGS |= MASK NFN_NUL;
}

// Return true if [EAX] primary name is 'NUL'
bool CHECK_NUL1(NFN_STRUCT* EAX)
{
	// SEE  IF [EAX] PRIMARY NAME IS 'NUL'

	// RETURNS EAX INTACT
	EDX = [EAX].NFN_PRIMLEN;
	ECX = [EAX].NFN_PATHLEN;

	if (EDX != 3)
		return false;

	ECX = &EAX.NFN_TEXT[ECX+1];
	AL = ECX[-1];
	AL = toupper(AL);
	if (AL != 'N')
		return false;
	AL = *ECX++;
	AL = toupper(AL);
	if (AL != 'U')
		return false;
	AL = *ECX++;
	AL = toupper(AL);
	if (AL != 'L')
		return false;
	return true;
}

// LIBRTN - Copyright (c) SLR Systems 1994

struct LRF_VARS
{
    ubyte[NFN_STRUCT.sizeof] LRF_NFN_STRUCT_EBP;
}


FIX	MACRO	XX
	XX	EQU	([EBP-SIZEOF LRF_VARS].(XX&_EBP))
ENDM

FIX	LRF_NFN_STRUCT


ubyte* LIB_ROUTINE_FINAL(EAX)
{
	// EAX IS INPTR1 TO USE

	LRF_VARS LRF_NFN_STRUCT;

	EDX = EAX;

	while (1)
	{
	    do
	    {
		AL = *EDX++;
	    } while (AL == ';' || AL == ',' || AL == ' ');

	    if (AL == CR)
		break;
	    --EDX;
	    if (AL == 0x1A)
		break;
	    ECX = &LRF_NFN_STRUCT;
	    EAX = &LIBSTUFF;
	    // EAX IS FILESTUFF
	    // EDX IS INPTR
	    // ECX IS NFN_STRUCT, RETURNS EAX IS INPTR
	    GET_FILENAME();

		    PUSH	EAX
	    EAX = &LRF_NFN_STRUCT;
	    HANDLE_LIBS();
		    POP	EDX
	}
	return EDX;
}


LIB_ROUTINE_FINAL_COMENT()
{

	// EAX IS INPTR1 TO USE


	LRF_VARS LRF_NFN_STRUCT;
	EDX = EAX;
	goto L2$;

L1$:
	ECX = &LRF_NFN_STRUCT;
	EAX = &LIBSTUFF;

	// EAX IS FILESTUFF, EDX IS INPTR, ECX IS NFN_STRUCT, RETURNS EAX IS INPTR
	GET_FILENAME();

		PUSH	EAX
	EAX = &LRF_NFN_STRUCT;
		ASSUME	EAX:PTR NFN_STRUCT

	ECX = EAX.NFN_PATHLEN + EAX.NFN_PRIMLEN;
	EDX = EAX.NFN_EXTLEN;
	if (EDX == 4)
	{
	    DL = [EAX+ECX+1].NFN_TEXT;
	    ECX = &[EAX+ECX+2].NFN_TEXT;

	    if (toupper(DL) == 'L' &&
		toupper(*ECX++) == 'O' &&
		toupper(*ECX++) == 'D')
	    {
		// HANDLE LIKE A STUB FILE
		if (LOD_SUPPLIED)
		{
		    WARN_RET(DUP_LOD_ERR);
		}
		else
		{
		    AL = DOSX_EXE_TYPE;
		    XCHG	AL,EXETYPE_FLAG
		    if (AL && AL != DOSX_EXE_TYPE)
			ERR_RET(DOSX_NONDOSX_ERR);
		    if (EXEPACK_SELECTED)
			ERR_ABORT(DOSX_EXEPACK_ERR);
		    EAX = &LRF_NFN_STRUCT;
		    LOD_SUPPLIED = -1;
		    HANDLE_LOD();
		}
			POP	EDX
		goto L9$;
	    }
	}
	// IGNORE LIBSEARCH REQUESTS?
	if (DEFAULTLIBRARYSEARCH_FLAG)
	{
	    EAX = &LRF_NFN_STRUCT;
	    HANDLE_LIBS();
	}
		POP	EDX
	goto L2$;

L2$:
	do
	{
	    AL = *EDX++;
	} while (AL == ';' || AL == ',' || AL == ' ');

	if (AL != CR)
	{
	    --EDX;
	    if (AL != 0x1A)
		goto L1$;
	}
L9$:
	return EDX;
}


		ALIGN	4

LIBSTUFF	LABEL	DWORD
		DCA	RET_FALSE;	// DEFAULT TO NUL
		DD	LIB_EXT;	// DEFAULT LIB EXTENSION
    version(fg_mscmd)
    {
		DCA	RET_TRUE;	// YES, THIS IS WANTED
		DD	LIB_MSG;	// IF PROMPTING...
LIB_MSG		DB	21,'Libraries and Paths: '
    }

LIB_EXT		DB	4,'.lib'

RET_FALSE()
{

	if (AL $$ AL)
	return;
}

RET_TRUE()
{
	AL |= 1;
	return;
}

// GET_FN - Copyright (c) SLR Systems 1994

GET_FILENAME(EAX, NFN_STRUCT* ECX, EDX)
{
	// EAX IS FILESTUFF_PTR
	// ECX IS NFN_STRUCT TO USE
	// EDX IS INPTR1 OR SOMETHING


	// RETURNS:
	// 	EAX IS UPDATED INPTR1


		PUSHM	EDI,ESI
	ESI = EDX;
		PUSH	EBX
	EBX = EAX;
L0$:
	AL = *ESI++;
	if (AL == ' ')
		goto L0$;
	if (AL == 9)
		goto L0$;
	--ESI;
	EDI = &[ECX].NFN_TEXT;
	EAX = 0;
L1$:
	AL = *ESI++;
	if (AL == '"')
		goto L6$;
	*EDI++ = AL;
	AL = FNTBL[EAX];
	if (AL & MASK FNTBL_ILLEGAL)
		JZ	L1$
L15$:
	// 		MOV	DPTR [EDI-2],0

	EDI -= ECX;
	--ESI;
	EDI -= NFN_STRUCT.NFN_TEXT+1;
	[ECX].NFN_TOTAL_LENGTH = EDI;
		JZ	L9$
	EAX = EBX;
	// EAX IS FILESTUFF_PTR, ECX IS NFN_STRUCT
	DO_FILENAME();
L5$:
		POP	EBX
	EAX = ESI;
		POPM	ESI,EDI
	return;

L6$:
	AL = *ESI++;
	if (AL == '"')
		goto L1$;
	*EDI++ = AL;
	if (AL == ' ')
		goto L6$;
	AL = FNTBL[EAX];
	if (AL & MASK FNTBL_ILLEGAL)
		JZ	L6$
	goto L15$;

L9$:
	ERR_INBUF_ABORT(FILE_EXP_ERR);
	goto L5$;
}


// HNDLLIBS - Copyright (c) SLR Systems 1994

HANDLE_LIBS(NFN_STRUCT* EAX)
{
    if (EAX.NFN_FLAGS & MASK NFN_PRIM_SPECIFIED+MASK NFN_EXT_SPECIFIED)
    {
	DO_SEARCH_LIBRARY(EAX);
	return;
    }
    // Remove base file name and extension from NFN_TEXT
    EAX.NFN_TOTAL_LENGTH -= EAX.NFN_PRIMLEN + EAX.NFN_EXTLEN;
    EAX.NFN_PRIMLEN = 0;
    EAX.NFN_EXTLEN = 0;
    *cast(int*)&EAX.NFN_TEXT[EAX.NFN_TOTAL_LENGTH] = 0;
    STORE_LIBPATH(EAX);
}


DO_SRCNAM(NFN_STRUCT* EAX)
{
	MOVE_NFN(&SRCNAM, EAX);
}


DO_LIBRARY(NFN_STRUCT* EAX)
{
	DO_SEARCH_LIBRARY(EAX);
}

DO_SEARCH_LIBRARY(NFN_STRUCT* EAX)
{
	EAX.NFN_TYPE = NFN_LIB_TTYPE;
	DO_OBJS_1(EAX, &LIB_LIST);
}


DO_OBJS(NFN_STRUCT* EAX)
{
	// IF NOT NUL, ADD NEW TO LIST...
	DO_OBJS_1(EAX, &OBJ_LIST);
}

DO_OBJS_1(NFN_STRUCT* EAX, ECX)
{
	// ECX IS FILE_LIST TO PUT IT IN

	DH = [EAX].NFN_FLAGS;
	DL = 0;
	DH &= MASK NFN_AMBIGUOUS;
	if (!DH)
	{
	    // CURRENTLY UNAMBIGUOUS
	    RESS	THIS_AMBIGUOUS,DL
	    NOT_AMBIGUOUS();
	    return;
	}

	// OK, NAME IN SI IS AMBIGUOUS...

		PUSHM	EDI,ESI
	--EDX;		// LISTTYPE
	EDI = ECX;	// NOPE, GOT WHOLE FILENAME
	ESI = EAX;

	// OOPS...
	THIS_AMBIGUOUS,DL = -1;
	// EAX IS NFN_STRUCT
	DO_FINDFIRST();
	// ALL DONE, NOT FOUND...
		JC	L11$
L1$:
	EAX = ESI;
	ECX = EDI;
	NOT_AMBIGUOUS();
	EAX = ESI;
	DO_FINDNEXT();
		JNC	L1$
	CLOSE_FINDNEXT();
L11$:
		POPM	ESI,EDI
	return;
}


COPY_FIRST_OBJ(EDI)
{
	if (EDI == &OBJ_LIST)
	{   DO_SRCNAM();
	    EAX = ESI;
	}
	COPY_FIRST_OBJ_RET();
}

NOT_AMBIGUOUS(NFN_STRUCT* EAX, ECX)
{
	// ECX IS FILE_LIST
	EDX = SRCNAM.NFN_PRIMLEN;
	EDI = ECX;
	ESI = EAX;
	if (!EDX && EDI == &OBJ_LIST)
	{   DO_SRCNAM();
	    EAX = ESI;
	}
	COPY_FIRST_OBJ_RET();
}

COPY_FIRST_OBJ_RET()
{
	// RETURNS ECX AS SYMBOL ADDRESS
	FILENAME_INSTALL();
	// EAX IS GINDEX

		ASSUME	ECX:PTR FILE_LIST_STRUCT

	EDX = EAX;

	// ADD TO LIST IF NOT ALREADY THERE...

	// DS:BX IS SYMBOL, DX IS LOGICAL ADDR

		PUSH	EBX
	AL = ECX.FILE_LIST_FLAGS;
	if (DOING_NODEF)
	{
	    ECX.FILE_LIST_FLAGS |= MASK MOD_IGNORE;
	    return;
	}
	// MODEFAULT, IGNORE
	if (EAX & MASK MOD_IGNORE)
		return;
	if (EAX & MASK MOD_ADD)
	// ALREADY IN ADD LIST...
	{
	    ASSUME	EDI:PTR FILE_LISTS

	    // ALREADY THERE, WAS IT UNAMBIGUOUS?
	    if (EAX & MASK MOD_UNAMBIG)
		    return;	// YES, IGNORE.

	    // WAS AMBIGUOUS, WHAT ABOUT NOW?
	    if (THIS_AMBIGUOUS)
		    return;	// STILL AMBIGUOUS

	    // NOW UNAMBIGUOUS, MOVE IT TO END OF LINKED LIST...
	    ECX.FILE_LIST_FLAGS = AL |MASK MOD_UNAMBIG;

	    // FIRST, IF .FILE_LAST_ITEM MATCHES, SKIP SEARCH, JUST FLAG IT..
	    if ([EDI].FILE_LAST_GINDEX == EDX)
		    return;

	    // SEARCH LIST FOR IT (DX:BX)
		    PUSH	EDI
	    EAX = [EDI].FILE_FIRST_GINDEX;
	    do
	    {
		CONVERT	EDI,EAX,FILE_LIST_GARRAY
		ASSUME	EDI:PTR FILE_LIST_STRUCT
		EAX = [EDI].FILE_LIST_NEXT_GINDEX;
	    } while (EAX != EDX);

	    // MAKE [DI:CX] POINT TO [DS:SI]
	    EAX = 0;
	    EBX = [ECX].FILE_LIST_NEXT_GINDEX;
	    [ECX].FILE_LIST_NEXT_GINDEX = 0;
	    [EDI].FILE_LIST_NEXT_GINDEX = EBX;
		    POP	EDI

	    // NOW, MAKE .LAST PT TO THIS...
	}
	else
	{
	    AL |= MASK MOD_ADD;
	    if (THIS_AMBIGUOUS == 0)
	    {
		version(any_overlays)
		{
		    if (EAX & MASK MOD_UNAMBIG && ECX.FILE_LIST_SECTION_GINDEX)
		    {
			ERR_INBUF_ABORT(DUP_SECTION_ERR);
		    }
		}
		AL |= MASK MOD_UNAMBIG;
	    }
	    [ECX].FILE_LIST_FLAGS = AL;
	}

    // PUT_IN_ADD_LIST

    // ESI IS NFN_STRUCT
    // EDI IS LISTTYPE
    // EDX IS CURN FILE_LIST_GINDEX
    // ECX IS CURN FILE_LIST_ADDRESS

    ASSUME	EDI:PTR FILE_LISTS
    version(any_overlays)
    {
	ECX.FILE_LIST_SECTION = CURN_SECTION;
	ECX.FILE_LIST_PLTYPE = CURN_PLTYPE;
    }
    EAX = EDI.FILE_LAST_GINDEX;
    ECX.FILE_LIST_PLINK_FLAGS |= DEBUG_TYPES_SELECTED;
    EDI.FILE_LAST_GINDEX = EDX;

    CONVERT	EAX,EAX,FILE_LIST_GARRAY
    ASSUME	EAX:PTR FILE_LIST_STRUCT
    // CAUSE THIS IS NOT THREAD
    EAX.FILE_LIST_NEXT_GINDEX = EDX;    // ORDER, THIS IS LOGICAL ORDER

    version(fgh_inthreads)
    {
	if (HOST_THREADED & OBJS_DONE)
	{
	    EAX = EDX;
	    OBJ_LIST.FILE_LAST_GINDEX = EAX;
	    LINK_TO_THREAD();
	}
    }
}



STORE_LIBPATH(NFN_STRUCT* EAX)
{
	DL = 2;
	ECX = OFF LIBPATH_LIST;
	LNI_PATHS(EAX, EDX, ECX);
}

LNI_PATHS(NFN_STRUCT* EAX, EDX, ECX)
{
	// DONT ADD NUL PATH
	DH = 0;
	if (EAX.NFN_PATHLEN == 0)
	{
	    LNI_FILES(EAX, EDX, ECX);
	}
}

LNI_FILES(EAX, EDX, ECX)
{
	EAX.NFN_TYPE = DH;
	*FILE_HASH_MOD = DL;
	DO_OBJS_1();
	EAX = 0;
	FILE_HASH_MOD = 0;
}

HANDLE_OBJPATHS(NFN_STRUCT* EAX)
{
	DL = 3;
	LNI_PATHS(EAX, EDX, &OBJPATH_LIST);
}


version(fg_segm OR fg_pe)
{

HANDLE_STUBPATHS(NFN_STRUCT* EAX)
{
	// PARSING PATH= VARIABLE

	DL = 4;
	LNI_PATHS(EAX, EDX, &STUBPATH_LIST);
}

HANDLE_STUB(NFN_STRUCT* EAX)
{
	EDX = 5+256*NFN_STUB_TTYPE;
	LNI_FILES(EAX, EDX, &STUB_LIST);
}

HANDLE_OLD(NFN_STRUCT* EAX)
{
	EDX = 6+256*NFN_OLD_TTYPE;
	LNI_FILES(EAX, EDX, &OLD_LIST);
}

HANDLE_RCS(NFN_STRUCT* EAX)
{
	ECX = *cast(int*)&EAX.NFN_TEXT[EAX.NFN_PATHLEN + EAX.NFN_PRIMLEN];
	if (ECX != 'SER.' && ECX != 'ser.')
	    WARN_ASCIZ_RET(IMPROBABLE_RES_ERR, EAX.NFN_TEXT);

	EDX = 7+NFN_RES_TTYPE*256;
	LNI_FILES(EAX, EDX, &RC_LIST);
}


HANDLE_LOD(NFN_STRUCT* EAX)
{
	EDX = 8+NFN_LOD_TTYPE*256;
	LNI_FILES(EAX, EDX, &LOD_LIST);
}

}

// PARSE_FN - Copyright (c) SLR Systems 1994

NFN_STRUCT* PARSE_FILENAME(NFN_STRUCT* EAX)
{
	// EAX IS NFN_STRUCT
	// (LENGTH IS ALREADY SET, AND TEXT IS THERE)


	// RETURNS:
	// 	EAX IS NFN_STRUCT


	NFN_STRUCT* ESI = EAX;

	EAX = 0;
	NFN_STRUCT* EDI = ESI;

	ESI.NFN_PATHLEN = 0;
	ESI.NFN_PRIMLEN = 0;
	ESI.NFN_EXTLEN = 0;
	ESI.NFN_FLAGS = 0;
	ESI.NFN_TYPE = 0;
	ESI.reserved1 = 0;

	ECX = [ESI].NFN_TOTAL_LENGTH;
	ESI = &ESI.NFN_TEXT;
	EDX = ESI;		// SAVE START OF FILENAME IN DX
	DPTR [ESI+ECX] = EAX;	// ZERO AT END
	ESI += ECX-1;		// ESI IS AT THE LAST CHAR OF TOKEN

	// SCAN FORWARDS LOOKING FOR AMBIGUOUS CHARACTERS

	if (!ECX)
		goto L9$

	// OK, NOW SCAN BACKWARDS FOR EXTENT OR PATH STUFF
	// SKIP TRAILING SPACES
L30$:
	AL = *ESI--;
	if (AL != ' ')
		goto L31$;
	--ECX;
	[EDI].NFN_TOTAL_LENGTH = ECX;
	if (ECX)
		goto L30$
	goto L9$;

L3$:
	--ESI;
L31$:
	AL = FNTBL[EAX];
	--ECX;
	if (AL & MASK FNTBL_AMBIGUOUS)
	{
	    [EDI].NFN_FLAGS |= MASK NFN_AMBIGUOUS;
	    AL = [ESI];
	    if (ECX)
		    goto L3$
	    goto DO_PRIMARY2;
	}
	if (!(AL & (MASK FNTBL_PATH_SEPARATOR | MASK FNTBL_DOT)))
	{
	    AL = *ESI;
	    if (ECX)
		    goto L3$
	    goto DO_PRIMARY2;
	}
	if (AL & MASK FNTBL_DOT)
	{
	    // GOT A '.', SO STORE EXTENSION LENGTH
	    EAX = [EDI].NFN_TOTAL_LENGTH;
	    [EDI].NFN_FLAGS |= MASK NFN_EXT_SPECIFIED;
	    EAX -= ECX;
	    if (EAX == 1 && !FORCE_PATH)
	    {
		// JUST A DOT, REMOVE IT...
		--EDI.NFN_TOTAL_LENGTH;
	    }
	    else
	    {
		EDI.NFN_EXTLEN = EAX;
	    }

	    // NOW LOOK ONLY FOR END-OF-PRIMARY...
	    EAX = 0;
	    if (!ECX)
		    goto L9$;
	    while (1)
	    {
		AL = *ESI--;
		AL = FNTBL[EAX];
		--ECX;
		if (ECX == 0)
		{
		    if (AL & (MASK FNTBL_PATH_SEPARATOR | MASK FNTBL_AMBIGUOUS))
		    {
			if (!(AL & MASK FNTBL_PATH_SEPARATOR))
			    EDI.NFN_FLAGS |= MASK NFN_AMBIGUOUS;
			break;
		    }
		    goto DO_PRIMARY2;
		}
		if (AL & MASK FNTBL_PATH_SEPARATOR)
		    break;
		if (AL & MASK FNTBL_AMBIGUOUS)
		    [EDI].NFN_FLAGS |= MASK NFN_AMBIGUOUS;
	    }
	}
	++ECX;
DO_PRIMARY:
	++ESI;
DO_PRIMARY2:
	EAX = EDI.NFN_TOTAL_LENGTH - EDI.NFN_EXTLEN - ECX;
	EDI.NFN_PRIMLEN = EAX;
	if (EAX)
	    [EDI].NFN_FLAGS |= MASK NFN_PRIM_SPECIFIED;

	// NOW, CX IS # OF BYTES IN A PATH-SPEC
	if (ECX)
	{
	    EDI.NFN_PATHLEN = ECX;
	    EDI.NFN_FLAGS |= MASK NFN_PATH_SPECIFIED;
	}
L9$:
	// ALL DONE, CONGRATS!
	if (FORCE_PATH)
	{
	    // IF PRIMLEN OR EXTLEN !=0, MAKE THEM ZERO AND ADD A \ AT END

	    EBX = EDI.NFN_PRIMLEN;
	    EDI.NFN_FLAGS &= ~(NFN_RECORD.NFN_PRIM_SPECIFIED | NFN_RECORD.NFN_EXT_SPECIFIED);
	    EBX += EDI.NFN_EXTLEN;
	    if (EBX)
	    {
		++EBX;
		EAX = 0;
		EBX += EDI.NFN_PATHLEN;
		EDI.NFN_PRIMLEN = 0;
		EDI.NFN_PATHLEN = EBX;
		EDI.NFN_EXTLEN = 0;
		EDI.NFN_TEXT[EBX-1] = '\';
		++EDI.NFN_TOTAL_LENGTH;
		EDI.NFN_FLAGS |= NFN_RECORD.NFN_PATH_SPECIFIED;
	    }
	}
	EAX = EDI;
	return EAX;
}


// MUST BE IN DATA SEGMENT, AS WE MODIFY IT...

ubyte[256] FNTBL =
{
	// ILLEGAL HPFS FILENAME CHARS ARE:

	//  0-1FH, " * + , / : ; < = > ? [ \ ] |

	// WE ALLOW PATH SEPARATORS \ / :
	// WE ALLOW AMBIGUOUS CHARS ? *


	// 00 NUL
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 01 SOH
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 02
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 03
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 04
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 05
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 06
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 07 BEL
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 08 BS
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 09 TAB
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0A LF
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0B
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0C
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0D CR
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0E
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 0F
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 10
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 11
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 12
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 13
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 14
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 15
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 16
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 17
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 18
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 19
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1A
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1B ESC
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1C
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1D
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1E
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 1F
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,

	// 20 SPACE
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 21 !
	0,
	// 22 "
	FNTBL_RECORD.FNTBL_ILLEGAL
	// 23 #
	0,
	// 24 $
	0,
	// 25 %
	0,
	// 26 &
	0,
	// 27 '
	0,
	// 28 (
	FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 29 )	;ILLEGAL IN FILE NAMES IF '(' OVERLAY FOUND
	FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 2A *
	FNTBL_RECORD.FNTBL_AMBIGUOUS | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 2B +
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 2C ,
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 2D -
	0,
	// 2E .
	FNTBL_RECORD.FNTBL_DOT,
	// 2F /	;ILLEGAL FOR MSCMDLIN SUPPORT...
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,

	// 30 0
	FNTBL_RECORD.IS_NUMERIC,
	// 31 1
	FNTBL_RECORD.IS_NUMERIC,
	// 32 2
	FNTBL_RECORD.IS_NUMERIC,
	// 33 3
	FNTBL_RECORD.IS_NUMERIC,
	// 34 4
	FNTBL_RECORD.IS_NUMERIC,
	// 35 5
	FNTBL_RECORD.IS_NUMERIC,
	// 36 6
	FNTBL_RECORD.IS_NUMERIC,
	// 37 7
	FNTBL_RECORD.IS_NUMERIC,
	// 38 8
	FNTBL_RECORD.IS_NUMERIC,
	// 39 9
	FNTBL_RECORD.IS_NUMERIC,
	// 3A :
	FNTBL_RECORD.FNTBL_PATH_SEPARATOR | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 3B ;
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 3C <
	FNTBL_RECORD.FNTBL_ILLEGAL,
	// 3D =
	FNTBL_RECORD.FNTBL_ILLEGAL | FNTBL_RECORD.SYMTBL_ILLEGAL,
	// 3E >
	FNTBL_RECORD.FNTBL_ILLEGAL,
	// 3F ?
	FNTBL_RECORD.FNTBL_AMBIGUOUS,

	// 40 @
	0,
	// 41 A
	FNTBL_RECORD.IS_ALPHA,
	// 42 B
	FNTBL_RECORD.IS_ALPHA,
	// 43 C
	FNTBL_RECORD.IS_ALPHA,
	// 44 D
	FNTBL_RECORD.IS_ALPHA,
	// 45 E
	FNTBL_RECORD.IS_ALPHA,
	// 46 F
	FNTBL_RECORD.IS_ALPHA,
	// 47 G
	FNTBL_RECORD.IS_ALPHA,
	// 48 H
	FNTBL_RECORD.IS_ALPHA,
	// 49 I
	FNTBL_RECORD.IS_ALPHA,
	// 4A J
	FNTBL_RECORD.IS_ALPHA,
	// 4B K
	FNTBL_RECORD.IS_ALPHA,
	// 4C L
	FNTBL_RECORD.IS_ALPHA,
	// 4D M
	FNTBL_RECORD.IS_ALPHA,
	// 4E N
	FNTBL_RECORD.IS_ALPHA,
	// 4F O
	FNTBL_RECORD.IS_ALPHA,

	// 50 P
	FNTBL_RECORD.IS_ALPHA,
	// 51 Q
	FNTBL_RECORD.IS_ALPHA,
	// 52 R
	FNTBL_RECORD.IS_ALPHA,
	// 53 S
	FNTBL_RECORD.IS_ALPHA,
	// 54 T
	FNTBL_RECORD.IS_ALPHA,
	// 55 U
	FNTBL_RECORD.IS_ALPHA,
	// 56 V
	FNTBL_RECORD.IS_ALPHA,
	// 57 W
	FNTBL_RECORD.IS_ALPHA,
	// 58 X
	FNTBL_RECORD.IS_ALPHA,
	// 59 Y
	FNTBL_RECORD.IS_ALPHA,
	// 5A Z
	FNTBL_RECORD.IS_ALPHA,
	// 5B [
	FNTBL_RECORD.FNTBL_ILLEGAL,
	// 5C \
	FNTBL_RECORD.FNTBL_PATH_SEPARATOR,
	// 5D ]
	FNTBL_RECORD.FNTBL_ILLEGAL,
	// 5E ^
	0,
	// 5F _
	0,

	// 60 `
	0,
	// 61 a
	FNTBL_RECORD.IS_ALPHA,
	// 62 b
	FNTBL_RECORD.IS_ALPHA,
	// 63 c
	FNTBL_RECORD.IS_ALPHA,
	// 64 d
	FNTBL_RECORD.IS_ALPHA,
	// 65 e
	FNTBL_RECORD.IS_ALPHA,
	// 66 f
	FNTBL_RECORD.IS_ALPHA,
	// 67 g
	FNTBL_RECORD.IS_ALPHA,
	// 68 h
	FNTBL_RECORD.IS_ALPHA,
	// 69 i
	FNTBL_RECORD.IS_ALPHA,
	// 6A j
	FNTBL_RECORD.IS_ALPHA,
	// 6B k
	FNTBL_RECORD.IS_ALPHA,
	// 6C l
	FNTBL_RECORD.IS_ALPHA,
	// 6D m
	FNTBL_RECORD.IS_ALPHA,
	// 6E n
	FNTBL_RECORD.IS_ALPHA,
	// 6F o
	FNTBL_RECORD.IS_ALPHA,

	// 70 p
	FNTBL_RECORD.IS_ALPHA,
	// 71 q
	FNTBL_RECORD.IS_ALPHA,
	// 72 r
	FNTBL_RECORD.IS_ALPHA,
	// 73 s
	FNTBL_RECORD.IS_ALPHA,
	// 74 t
	FNTBL_RECORD.IS_ALPHA,
	// 75 u
	FNTBL_RECORD.IS_ALPHA,
	// 76 v
	FNTBL_RECORD.IS_ALPHA,
	// 77 w
	FNTBL_RECORD.IS_ALPHA,
	// 78 x
	FNTBL_RECORD.IS_ALPHA,
	// 79 y
	FNTBL_RECORD.IS_ALPHA,
	// 7A z
	FNTBL_RECORD.IS_ALPHA,
	// 7B {
	0,
	// 7C |
	FNTBL_RECORD.FNTBL_ILLEGAL,
	// 7D }
	0,
	// 7E ~
	0,
	// 7F
	0,
];


