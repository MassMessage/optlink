		TITLE	CMDSUBS - Copyright (c) SLR Systems 1994

		INCLUDE MACROS
		INCLUDE	SECTS
		INCLUDE	IO_STRUC
		INCLUDE	SECTIONS

		.DATA

		EXTERNDEF	CODEVIEW_BYTE:BYTE,OUTBUF:BYTE,TEMP_RECORD:BYTE,INBUF:BYTE,FNTBL:BYTE,CURN_PLTYPE:BYTE
		EXTERNDEF	CACHE_DEFAULT_BYTE:BYTE,COMPRESS_DEFAULT_BYTE:BYTE,CASE_TYPE:BYTE,COMMENT_CHAR:BYTE
		EXTERNDEF	FIRST_SECTION_PLTYPE:BYTE,SYMBOL_TEXT:BYTE

		EXTERNDEF	SYMBOL_LENGTH:DWORD,CURN_COUNT:DWORD,FILESTUFF_PTR:DWORD,SECTION_NUMBER:DWORD,INDIRECT_LEVEL:DWORD
		EXTERNDEF	AREA_COUNT:DWORD,NEXT_READ_THREAD:DWORD,INPTR1:DWORD,THREAD_STACKS:DWORD,PLINK_LEVEL:DWORD
		EXTERNDEF	TOKSTR:DWORD,MAX_LEVEL:DWORD,IND_DEVICE:DWORD,CURN_SECTION_GINDEX:DWORD,CURN_AREA_GINDEX:DWORD
		EXTERNDEF	SYMBOL_HASH:DWORD,CURN_OUTFILE_GINDEX:DWORD,CURN_INPTR:DWORD,INDIR_TABLE:DWORD,SECTION_COUNT:DWORD
		EXTERNDEF	ENVIRONMENT_BLOCK:DWORD,FIRST_AREA_GINDEX:DWORD,FIRST_SECTION_GINDEX:DWORD,LAST_SECTION_GINDEX:DWORD
		EXTERNDEF	ME_PTR:DWORD,ME_PATH_LEN:DWORD

		EXTERNDEF	FILNAM:NFN_STRUCT,SRCNAM:NFN_STRUCT,SYMBOL_TPTR:TPTR_STRUCT,FILE_LIST_SEM:QWORD,INDNAM:NFN_STRUCT
		EXTERNDEF	MYI_STUFF:MYI_STRUCT

		EXTERNDEF	SECTION_GARRAY:STD_PTR_S,AREA_GARRAY:STD_PTR_S

		EXTERNDEF	OPTI_MOVE:DWORD,OPTI_HASH:DWORD,CASE_STRING_COMPARE:DWORD

                EXTERNDEF	GINPUT_LINE_NUMBER:DWORD

XSEG		SEGMENT	AT 0

X		MYI_STRUCT	<>

}


		.CODE	FILEPARSE_TEXT

		EXTERNDEF	OPTI_MOVE_PRESERVE_SIGNIFICANT:PROC,DO_FINDFIRST:PROC,RETT:PROC,OS2_FIXER:PROC,RET_TRUE:PROC
		EXTERNDEF	RET_FALSE:PROC,ISSUE_PROMPT:PROC,ERR_ABORT:PROC,OPTI_MOVE_PRESERVE_IGNORE:PROC
		EXTERNDEF	OPTI_MOVE_UPPER_IGNORE:PROC,PROCESS_DEF:PROC,OBJ_PLUS_ABSORBER:PROC,OPTI_MOVE_LOWER_IGNORE:PROC
		EXTERNDEF	DO_FINDNEXT:PROC,FILENAME_INSTALL:PROC,MOVE_NFN:PROC,PLUS_ABSORBER:PROC,EXE_PROC:PROC,ABORT:PROC
		EXTERNDEF	INIT_THREAD:PROC,DO_CAPTURE_SSAX:PROC,LOUTALL_CON:PROC,ERR_INBUF_ABORT:PROC,OPEN_INPUT:PROC
		EXTERNDEF	SIGNON:PROC,ERR_DSSI_FN_ABORT:PROC,END_OF_INDIRECT:PROC,DO_RELEASE_SSAX:PROC,PROPER_PROMPT:PROC
		EXTERNDEF	DO_FILENAME:PROC,DO_DOSSEMCLEAR_DSAX:PROC,LOUTALL_CON:PROC,ERR_INBUF_RET:PROC
		EXTERNDEF	CASE_STRING_COMPARE_EASY:PROC,CASE_STRING_COMPARE_HARD:PROC,OPTI_HASH_IGNORE:PROC
		EXTERNDEF	OPTI_HASH_SIGNIFICANT:PROC,GET_NEW_IO_LOG_BLK:PROC,ERR_NFN_ABORT:PROC,FORCE_SIGNON:PROC

		EXTERNDEF	TOKEN_TOO_LONG_ERR:ABS,FILE_EXP_ERR:ABS,FILE_NOT_FOUND_ERR:ABS,ENDAREA_ERR:ABS,DUP_SECTION_ERR:ABS
		EXTERNDEF	AREA_DEEP_ERR:ABS,ID_EXP_ERR:ABS,INDIRECT_DEEP_ERR:ABS,FILENAME_ERR:ABS

public GET_LINE()
{
	// GET NEXT LINE OF INPUT FROM INPUT STREAM... INTO INBUF

		PUSH	ESI
		GETT	CL,GET_LINE_PARTIAL
		PUSH	EDI
		PUSH	EBX
	EDI = &INBUF+4;
	if (CL)
		goto L6$
	INPTR1 = EDI;
	if (INBUF_EOF)
		goto L99$

	if (!INDIRECT_MODE || !ECHO_INDIRECT)
		goto L1$
	ISSUE_PROMPT();

	// STARTING A BRAND NEW LINE
	goto L1$;

L99$:
	// END OF FILE

	EAX = 0;
		STC
	*EDI = 0x1A;
		POPM	EBX,EDI,ESI
	DPTR INBUF = 1;
	return;

L6$:

	// PARTIAL LINE BEFORE, MOVE BUFFER DOWN, AND READ SOME MORE PLEASE...


	ECX = DPTR INBUF;
	ESI = INPTR1;
	INPTR1 = EDI;
	ECX -= ESI;
	AL = 0;
	ECX += EDI;
		RESS	GET_LINE_PARTIAL,AL
		OPTI_MOVSB
	goto L1$;


L9$:
	GET_LINE_PARTIAL = -1;
	goto L42$;

L41$:
	AL = GET_NEXT_CHAR();
	if (AL == LF)
		goto L4$;
	--CURN_INPTR;
	++CURN_COUNT;
	goto L4$;

L2$:

	// ^ ESCAPE CHARACTER

	*EDI++ = AL;
	AL = GET_NEXT_CHAR();
L0$:
	*EDI = AL;
	// MAX LINE LENGTH-2
	if (EDI $$ OFF INBUF+INBUF_LEN-4-1)
	EDI++;
	// WILL BE A PARTIAL LINE...
		JAE	L9$
L1$:
	AL = GET_NEXT_CHAR();
	if (AL == '^')
		goto L2$;
	if (AL == CR)
		goto L41$;
	if (AL == LF)
		goto L4$;
	if (AL == '@')
		goto L3$;
	if (COMMENT_CHAR != AL)
		goto L0$;

	// COMMENT CHARACTER...


L70$:
	AL = GET_NEXT_CHAR();
	if (AL == CR)
	// VALID END OF COMMENT
		goto L41$;
	if (AL != LF)
		goto L70$;
L4$:

	// END OF LINE


	WPTR [EDI] = 0ACR;
	EDI += 2;
	++GINPUT_LINE_NUMBER;
L42$:
	// 		MOV	CURN_INPTR,ESI

	EAX = EDI;
		GETT	CL,INDIRECT_MODE
	EAX -= OFF INBUF+4;
	DPTR INBUF = EAX;
	if (CL)
		JZ	L429$
	if (ECHO_INDIRECT)
		JZ	L429$
		PUSH	EAX
	SIGNON();
		POP	ECX
	EAX = OFF INBUF+4;
	LOUTALL_CON();
L429$:
		POPM	EBX,EDI,ESI
	EAX = 0;
	return;

L3$:
	// BEGINNING OF LINE, GO AHEAD
	if (EDI $$ OFF INBUF+4)
	CL = BPTR [EDI-1];
		JZ	L32$
	// OR PRECEDED BY A SPACE
	if (CL == ' ')
		goto L32$;
	// OR TAB
	if (CL == 9)
		goto L32$;
	if (CL == '+')
		goto L32$;
	// OR COMMA
	if (CL != ' $$ ')
		goto L00$;

	// OPEN UP INDIRECT COMMAND FILE


L32$:
	if (SUPPORT_@_INDIRECT)
		JZ	L00$

	INDIRECT();
	goto L1$;

L00$:
	goto L0$;

}


ubyte GET_NEXT_CHAR()
{
	// GET CHAR, REFILL BUFFER AND/OR UNNEST IF NEEDED

    while (1)
    {
	while (1)
	{
	    if (CURN_COUNT)
	    {
		CURN_COUNT--;
		AL = *CURN_INPTR++;
		if (AL == 0x1A)
		    break;
		return AL;
	    }
	    TRY_ANOTHER_BUFFER();
	}

	// Try unnesting
	if (IND_DEVICE)
	    DO_UNNEST();
	else
	{   INBUF_EOF = -1;
	    return LF;
	}

	// FOR MS CMDLINE, IGNORE CR IMMEDIATELY FOLLOWING EOF

	AL = GET_NEXT_CHAR();

	// SKIP CR LF
	if (AL != CR)
	{
	    if (AL != LF)
		return AL;
    L75:
	    if (INBUF_EOF == 0)
		continue;
	    INBUF_EOF = -1;
	    return LF;
	}
	AL = GET_NEXT_CHAR();
	if (AL == LF)
	    goto L75;

	--CURN_INPTR;
	++CURN_COUNT;
	return LF;
    }
}


void UNGET_CHAR()
{
    --CURN_INPTR;
    ++CURN_COUNT;
}


void TRY_ANOTHER_BUFFER()
{
    MYI_STRUCT* EAX = IND_DEVICE;
    if (EAX)
    {
	[EAX].MYI_FILLBUF();

	ECX = [EAX].MYI_COUNT;
	EDX = [EAX].MYI_PTRA;

	if (ECX)
	{
	    CURN_INPTR = EDX;
	    CURN_COUNT = ++ECX;
	    return;
	}
    }
    else if (!DOING_CFG && !CMDLINE_FINAL)
    {
	// GO AHEAD AND PROMPT FOR INPUT
	SIGNON();
	PROPER_PROMPT();
	return;
    }
    CURN_COUNT = 2;
    CURN_INPTR = &TEMP_RECORD;
    *CURN_INPTR = 0x1A;
}


void DO_UNNEST()
{
	// RETURN TO PREVIOUS INDIRECTION LEVEL

	// CLOSE AND RELEASE
	END_OF_INDIRECT();

	ESI = INDIRECT_LEVEL;
	if (--INDIRECT_LEVEL == 0)
	{
		RESS	INDIRECT_MODE
	}
	ESI = INDIR_TABLE[ESI*4];
	// MOVE CURN_INPTR, CURN_COUNT, IND_DEVICE
	memcpy(&CURN_INPTR, ESI, 3 * 4);
	ESI += 3 * 4;

	if (IND_DEVICE)
	{	// MOVE THRU MYI_FILLBUF
		memcpy(IND_DEVICE, ESI, MYI_STRUCT.MYI_FILLBUF+4);
	}
}


private void INDIRECT()
{
	// SET UP TO READ FROM INDIRECT COMMAND FILE

	// PLACE TEXT GOES
		PUSHM	EDI
	EAX = 0;
	// PROBABLY IN TEMP_RECORD
	EDI = &INDNAM.NFN_TEXT;

	while (1)
	{
	    AL = GET_NEXT_CHAR();
	    *EDI = AL;
	    if (AL == '"')
		goto L6$;	// SPECIAL HANDLING
	    ++EDI;
	    if (EDI > &INDNAM.NFN_TEXT+NFN_TEXT_SIZE)
	    {
		TOKEN_TOO();
		continue;
	    }
	    if (FNTBL[EAX] & MASK FNTBL_ILLEGAL)
		    break;
	    else
		    continue;

    L6$:
	    AL = GET_NEXT_CHAR();
	    if (AL == '"')
	    // END SPECIAL HANDLING
		    continue;
	    *EDI = AL;
	    if (EDI > &INDNAM.NFN_TEXT+NFN_TEXT_SIZE-1)
	    {
		TOKEN_TOO();
		continue;
	    }
	    ++EDI;
	    if (AL == ' ' || FNTBL[AL] & MASK(FNTBL_ILLEGAL))
		goto L6$;
	    break;
	}

	// STORES POINTER TOO
	UNGET_CHAR();
	EDI -= &INDNAM.NFN_TEXT+1;
	EAX = &INDIR_STUFF;
	INDNAM.NFN_TOTAL_LENGTH = EDI;
	ECX = &INDNAM;
	DO_FILENAME();
	NEST_INDIRECT();

		POPM	EDI
}


public NEST_INDIRECT()
{
		PUSHM	EDI,ESI

	INDIRECT_MODE = -1;

	// STORE INFO FOR NESTING...
	EDI = INDIRECT_LEVEL;
	ESI = &CURN_INPTR;

	++EDI;
	ECX = 0;

	INDIRECT_LEVEL = EDI;
	ECX = INDIR_TABLE[EDI*4];
	if (EDI > INDIRECT_NEST_LIMIT)
		goto L5$;

	if (!ECX)
	// GO ALLOCATE SPACE
		goto L2$;
L3$:
	EDI = ECX;
	ECX = 3;

	// MOVE CURN_INPTR, CURN_COUNT, IND_DEVICE
	memcpy(EDI, ESI, ECX);
	ESI += ECX;
	EDI += ECX;
	ECX = 0;

	ESI = IND_DEVICE;
	CL = (MYI_STRUCT.MYI_FILLBUF+4)/4;

	if (ESI)
	{
	    // STORE HANDLE, PTRS, COUNTS
	    memcpy(EDI, ESI, ECX);
	    ESI += ECX;
	    EDI += ECX;
	    ECX = 0;
	}
	EDI = OFF CURN_INPTR;
	CL = 2;

	EAX = 0;

	// ZERO CURN_INPTR, CURN_COUNT
		REP	STOSD

	EDI = IND_DEVICE;
	CL = (MYI_STRUCT.MYI_FILLBUF+4)/4;

	if (EDI)
	{
	    IND_DEVICE = EAX;
		REP	STOSD
	}
		POPM	ESI,EDI
	// MARK BUFFER EMPTY
	CURN_COUNT = 1;
	OPEN_INDIRECT();
	return;

L2$:
	EAX = MYI_STRUCT.MYI_FILLBUF+4+16;
		TEXT_POOL_ALLOC
	ECX = EAX;
	INDIR_TABLE[EDI*4] = EAX;
	goto L3$;

L5$:
	ERR_ABORT(INDIRECT_DEEP_ERR);
}


OPEN_INDIRECT()
{
	// OPEN AN INDIRECT COMMAND FILE

	// WALTER LOOKS THIS UP IN THE ENVIRONMENT FIRST...
	EAX = &INDNAM;
	IND_DEVICE = OPEN_ENVIRONMENT();
		JC	L2$
	return;

L2$:
	EAX = &INDNAM;
	// OPEN INDIRECT FILE
	IND_DEVICE = OPEN_INPUT();
	// FILE NOT FOUND
		JC	L5$

	// FROM INDIRECT FILE
	return;

L5$:
	ERR_NFN_ABORT(FILE_NOT_FOUND_ERR, &INDNAM);
}


/******************************
 * Returns carry set on error.
 */
private int OPEN_ENVIRONMENT()
{

	// EAX IS NFN_STRUCT


		PUSH	ESI
	NFN_STRUCT* ESI = EAX;

		PUSHM	EDI,EBX

	EDI = ENVIRONMENT_BLOCK;
	EBX = [ESI].NFN_TOTAL_LENGTH;

	if (EDI)
		JZ	L99$

	[EBX+ESI].NFN_TEXT = '=';

	NFN_STRUCT* EDX = ESI;
	goto L7$;

L1$:
	--EDI;
	ECX = [EDX].NFN_TOTAL_LENGTH;

	ESI = &[EDX].NFN_TEXT;
	// STRING LENGTH (INCLUDING =)
	++ECX;

	EBX = EDI;

	// COMPARE CX BYTES
		REPE	CMPSB

	// 16K MAX, ABORT
	CH = 64;
	// MATCH, JUMP
		JZ	L4$

	// NEED TO FIND END OF STRING
	--EDI;
	AL = 0;

	// THANK-YOU
		REPNE	SCASB

		JNZ	L9$
L7$:
	// TRAILING ZERO?
		SCASB

		JNZ	L1$
L9$:

	// NOTHING FOUND, RETURN


L99$:
	EAX = [EDX].NFN_TOTAL_LENGTH;
		POPM	EBX,EDI,ESI

	[EAX+EDX].NFN_TEXT = 0;

		STC	// error
	return;

L8$:
		POP	EDI
	goto L9$;

L4$:

	// ES:DI POINTS TO STRING...


		PUSH	EDI
L41$:

	// SEE IF ANY NON-BLANK CHARACTERS


	AL = *EDI++;

	// END OF ENVIRONMENT
	if (AL == 0)
		goto L8$;

	if (AL == ' ' || AL == '\t')
		goto L41$;
L49$:
		POP	ESI
	GET_NEW_IO_LOG_BLK();

	EBX = OFF MYI_STUFF;
		ASSUME	EBX:PTR MYI_STRUCT
	EDI = EAX;

	CURN_INPTR = EDI;

	[EBX].MYI_BLOCK = EAX;
	[EBX].MYI_PTRA = EDI;
L5$:
	do
	{
	    AL = *ESI++;
	    *EDI++ = AL;
	} while (AL);

	--EDI;
	*EDI++ = CR;
	*EDI++ = LF;

	EDI -= [EBX].MYI_BLOCK;
	EAX = 0;

	[EBX].MYI_FILE_LENGTH = EDI;
	[EBX].MYI_BYTE_OFFSET = 0;

	++EDI;
	[EBX].MYI_PHYS_ADDR = 0;

	CURN_COUNT = EDI;
	[EBX].MYI_COUNT = 0;

	[EBX].MYI_FILLBUF = &ENVIRON_READ_RETT;

	EAX = EBX;
		POPM	EBX,EDI,ESI

	return EAX;
}


ENVIRON_READ_RETT()
{
}


public SEE_NEXT()
{



	ESI = INPTR1;

	AL = [ESI];

	return;

}


public GET_NEXT()
{



	ESI = INPTR1;
	AL = [ESI];
	++ESI;
	INPTR1 = ESI;
	return;

}


public GETNST()
{



	ECX = INPTR1;
	EAX ^= EAX;
	EDX = OFF PARSE_TABLE;
L0$:
	AL = [ECX];
	++ECX;
	if (ECX $$ OFF INBUF+INBUF_LEN+1)
	AL = [EDX+EAX];
	// GET ANOTHER LINE
		JZ	L2$
	if (AL == CH_SPC)
		goto L0$;
	if (AL == CH_SEMI)
	// EOF...
		goto L1$;
	if (AL $$ CH_NL)
    version(fg_mscmd)
    {
		JZ	L5$
    }
    else
    {
	// GET ANOTHER LINE
		JZ	L2$
    }
L6$:
	if (ECX $$ OFF INBUF+INBUF_LEN/2)
	AL = [ECX-1];
		JAE	L3$
L4$:
	INPTR1 = ECX;
	return;

    version(fg_mscmd)
    {
L5$:
    version(fg_plink)
    {
	if (CMDLINE_FREEFORMAT)
		JNZ	L2$
    }
    version(fg_def)
    {
	if (DEF_IN_PROGRESS)
		JNZ	L2$
    }
	if (BPTR [ECX-1] == CR)
		goto L6$;
	// ACTUALLY READ NEXT LINE WITH LF
	goto L2$;
    }

L3$:
	if (GET_LINE_PARTIAL)
		JZ	L4$
	--ECX;
	INPTR1 = ECX;
L2$:
	GET_LINE();
		JNC	GETNST
L21$:
	ECX = INPTR1;
	++ECX;
L1$:
	INPTR1 = ECX;
	//  OR 0x1A
	AL = [ECX-1];
    version(fg_def)
    {
	if (AL != ';')
		goto L9$;
	if (DEF_IN_PROGRESS)
		JNZ	L2$
    }
L9$:
	return;

}


public HANDLE_EOF()
{



	if (INDIRECT_LEVEL == 0)
		goto L9$;
	DO_UNNEST();
	goto HANDLE_EOF;

L9$:
	return;

}


public YYLEX_FILENAME()
{

	// EAX IS STUFF FOR DEFAULT


		PUSH	FILESTUFF_PTR
	FILESTUFF_PTR = EAX;

	// PUT INTO FILNAM
	YY_FILENAME();

	EAX = FILESTUFF_PTR;
	ECX = OFF FILNAM;
	DO_FILENAME();
		POP	FILESTUFF_PTR

	return;

}


public YY_FILENAME()
{
	// DEALS WITH BLANKS
	GETNST();

		PUSH	ESI
	ESI = INPTR1;

	// TO COMPATIBLY HANDLE ^, WE MUST COPY TO ANOTHER BUFFER...


		PUSH	EDI
	--ESI;

	EDI = OFF FILNAM.NFN_TEXT;
	EAX ^= EAX;

	EDX = OFF FNTBL;
	ECX ^= ECX;
L1$:
	AL = [ESI];
	++ESI;
L11$:
	if (AL == '^')
		goto L2$;

	if (AL == '"')
		goto L5$;

	if (AL == "'")
		goto L5$;
L13$:
	[EDI] = AL;
	++EDI;

	if (AL == '%')
		goto L7$;

	if (AL == ' ')
		goto L4$;
L79$:
	AL = [EDX+EAX];
	if (EDI AE OFF FILNAM.NFN_TEXT+NFN_TEXT_SIZE)
		goto L8$;
	if (AL & MASK FNTBL_ILLEGAL)
		JZ	L1$
L15$:
	--ESI;
	EDI -= OFF FILNAM.NFN_TEXT+1;
	FILNAM.NFN_TOTAL_LENGTH = EDI;
		JZ	L9$
L16$:
		POP	EDI
	INPTR1 = ESI;
		POP	ESI
	return;

L2$:
		MOVSB
	goto L1$;

L4$:
	// SPACE BAD IF NOT IN QUOTES
	if (CL == 0)
		goto L15$

	AL = 'A';
	// OTHERWISE, OK
	goto L79$;

L5$:
	// SAME QUOTE I'M ALREADY PROCESSING?
	if (CL == AL)
		goto L59$;

	// WAS I PROCESSING A QUOTE?
	if (CL)
		goto L13$

	// NOW I'M PROCESSING A QUOTE
	CL = AL;
	goto L1$;

L59$:
	// CLEAR STRING PROCESSING
	CL = 0;
	goto L1$;

L7$:
	// GOT A %, WHATS NEXT?
	AL = *ESI++;
	*EDI++ = AL;

	if (AL != '@')
		goto L77$;

	// GOT A %@
	AL = *ESI++;
	*EDI++ = AL;

	if (AL != 'p' && AL != 'P')
		goto L77$;
	// GOT A %@P
	AL = *ESI++;
	*EDI++ = AL;

	if (AL != '%')
		goto L77$;

	// SAVE QUOTES FLAG
	if (ME_PATH_LEN)
	{
	    EDI -= 4;
	    memcpy(EDI, ME_PTR, ME_PATH_LEN);
	    EDI += ME_PATH_LEN;
	    if (EDI[-1] == '\')
		--EDI;
	}
	goto L79$;

L77$:
	--EDI;
	goto L11$;

L8$:
	TOKEN_TOO();

L9$:
    version(fg_plink)
    {
	if (CMDLINE_FREEFORMAT)
		JZ	L91$
	ERR_INBUF_ABORT(FILE_EXP_ERR);
L91$:
    }
	// CHECK LAST ILLEGAL CHARACTER, MAKE SURE IT ISN'T
	//    >, <, =, ), [, ], |,
	// I.E., ONLY ALLOW CR, +, ", SPACE, /, ;
	// 	WE ALREADY SKIPPED SPACES, TABS,+, ", /

	AL = [ESI];
	switch (AL)
	{
	    case CR:
	    case ',':
	    case ';':
	    case 0x1A:
		goto L16$;
	}
	ERR_INBUF_ABORT(FILENAME_ERR);
}


public GET_KEYWORD()
{
	// MOVE TEXT INTO SYMBOL_TEXT, RETURN LENGTH IN AX
	// EOF ILLEGAL


	GETNST();
		PUSHM	EDI,ESI
	ESI = INPTR1 - 1;
	// PLACE TO COPY COMMAND
	EDI = &SYMBOL_TEXT;
	EAX = 0;
	TOKSTR = ESI;

	// SKIP LEADING SPACE AND COMM


    version(fg_td)
    {
	EDX = &PARSE_TABLE;
	if (TLINK_SYNTAX)
	    EDX = &PARSE_TABLE_TL;
	MY_PARSE_TABLE = EDX;
    }
    else
    {
	EDX = &PARSE_TABLE;
    }
L0$:
	AL = *ESI++;
	AL = EDX[EAX];
	// SEP, AT, OR SEMI
	if (AL < CH_SEMI)
	    goto L31$;
	if (AL == CH_SEMI)
	    goto L3$;
	goto L12$;

	// OK, FOUND A NON SPACE-TAB, BUILD TOKEN


L1$:
    version(fg_td)
    {
	EDX = MY_PARSE_TABLE;
    }
    else
    {
	EDX = &PARSE_TABLE;
    }
L11$:
	AL = *ESI++;
	if (EDI >= &SYMBOL_TEXT+SYMBOL_TEXT_SIZE-1)
		goto TOKEN_TOO;
	AL = EDX[EAX];
L12$:
	*EDI++ = AL;
	if (AL >= ' ')
		goto L11$;

	// SPECIAL CHARACTER
	--EDI;
L2$:
	switch (EAX)
	{
	   case 0: // SPACE OR TAB - SEPARATER
		goto K_SPCTAB;
	   case 1: // END OF TOKEN - PRESERVE IF TOKEN
		goto K_SEPARATOR;
	   case 2: // I DON'T KNOW...
		goto K_AT;
	   case 3: // SEMICOLON - SEPARATOR - PRESERVE
		goto K_SEMI;
	   case 4: // END-OF-LINE - SEPARATOR
		goto K_EOL;
	   case 5: // ESCAPE CHAR
		goto K_ESCAPE;
	}


public TOKEN_TOO	LABEL	PROC

	ERR_INBUF_ABORT(TOKEN_TOO_LONG_ERR);

L3$:
	--ESI;
L31$:
	*EDI++ = AL;
	goto K_SPCTAB1;

K_EOL:
K_SEPARATOR:
K_SEMI:
K_AT:
K_SPCTAB:

	// SEPARATOR
	--ESI;
K_SPCTAB1:
	DPTR [EDI] = 0;
	EDI -= &SYMBOL_TEXT;
	INPTR1 = ESI;
		POP	ESI
	SYMBOL_LENGTH = EDI;
	EAX = EDI;
		POP	EDI
	return;

K_ESCAPE:

	// ESCAPE, MAKE SURE NEXT ISN'T EOL

	version(fg_td)
	{
	    EDX = MY_PARSE_TABLE;
	}
	else
	{
	    EDX = &PARSE_TABLE;
	}
	AL = EDX[*ESI++];
	if (AL < ' ')
	    AL = ESI[-1];
K_ESCAPE_1:
	*EDI++ = AL;
	goto L11$;
}


void GET_SYMBOL()
{
	// MOVE TEXT INTO SYMBOL_TEXT, RETURN LENGTH IN AX

	GETNST();
		PUSHM	EDI,ESI
	ESI = INPTR1 - 1;
	// PLACE TO COPY COMMAND
	EDI = OFF SYMBOL_TEXT;
	EDX = OFF FNTBL;
	EAX = 0;
	TOKSTR = ESI;
	CL = 0;
L1$:
	AL = *ESI++;
	if (AL == '^')
		goto L2$;
	if (AL == '"')
		goto L6$;
	if (AL == "'")
		goto L6$;
	*EDI++ = AL;
	AL = EDX[EAX];
	if (EDI >= OFF SYMBOL_TEXT+SYMBOL_TEXT_SIZE)
		goto L8$;
	if (AL & MASK SYMTBL_ILLEGAL)
		JZ	L1$
L15$:
	DPTR [EDI-1] = 0;

	--ESI;
	EDI -= &SYMBOL_TEXT+1;

	INPTR1 = ESI;
	EAX = EDI;

	SYMBOL_LENGTH = EDI;
		JZ	L4$

		POPM	ESI,EDI

	return;

L2$:
	*EDI++ = *ESI++;
	goto L1$;

L4$:
	// ZERO LENGTH ONLY ALLOWED IF QUOTES USED...
	if (CL)
	{
	    POPM	ESI,EDI
	    return EAX;
	}
L5$:
	AL = ID_EXP_ERR;
	ERR_INBUF_RET();
		POPM	ESI,EDI
	EAX = 0;
	return EAX;

L6$:
	CL = AL;
L61$:
	AL = *ESI++;
	if (AL == CL)
		goto L1$;
	*EDI++ = AL;
	if (AL >= ' ')
		goto L61$;
	goto L15$;

L8$:
	TOKEN_TOO();
}


public YYLEX_SYMBOL()
{



	GET_SYMBOL();
		PUSHM	EDI,ESI
	EAX = SYMBOL_LENGTH;
	ESI = OFF SYMBOL_TEXT;
	if (EAX)
	{
	    EDI = ESI;
	    // TRANSLATE AND HASH
	    OPTI_MOVE();
		    POPM	ESI,EDI
	    SYMBOL_HASH = EDX;
	    return;
	}
L9$:
	ERR_INBUF_ABORT(ID_EXP_ERR);
}


public GROUPSTACK_PROC()
{
    STACK_GROUP_FLAG = -1;
}


public NOGROUPSTACK_PROC()
{
	RESS	STACK_GROUP_FLAG
}


public ERRORDELETE_PROC()
{
	DELETE_EXE_ON_ERROR = -1;
}


public NOERRORDELETE_PROC()
{
	RESS	DELETE_EXE_ON_ERROR
}


public IGNORECASE_PROC	LABEL	PROC

	AL = 1;
	goto DEFINE_CASE_MODE;

public NOIGNORECASE_PROC	LABEL	PROC
public MIXCASE_PROC		LABEL	PROC

	AL = 0;
	goto DEFINE_CASE_MODE;

public UPPERCASE_PROC	LABEL	PROC

	AL = 2;
	goto DEFINE_CASE_MODE;

public LOWERCASE_PROC	LABEL	PROC

	AL = 3;
DEFINE_CASE_MODE::
	CASE_TYPE = AL;




public SET_CASE_MODE()
{

	// OK, LOOK AT OPTIONS, SET UP OPTI_MOVE AND CONVERT_TABLE

		PUSH	ESI
	// 0 = PRESERVE, SIGNIFICANT
	// 1 = PRESERVE, IGNORE
	// 2 = CONVERT UPPER
	// 3 = CONVERT LOWER
	AL = CASE_TYPE;

	IGNORE_PRESERVE = -1;
	EDX = OFF CASE_STRING_COMPARE_HARD;
	ECX = OFF OPTI_HASH_IGNORE;
	ESI = OFF OPTI_MOVE_PRESERVE_IGNORE;
	--AL;
		JZ	L0$
		RESS	IGNORE_PRESERVE
	EDX = OFF CASE_STRING_COMPARE_EASY;
	ESI = OFF OPTI_MOVE_UPPER_IGNORE;
	--AL;
		JZ	L0$
	ESI = OFF OPTI_MOVE_LOWER_IGNORE;
	--AL;
		JZ	L0$

	// 0 = PRESERVE, SIGNIFICANT


	ESI = OFF OPTI_MOVE_PRESERVE_SIGNIFICANT;
	ECX = OFF OPTI_HASH_SIGNIFICANT;
L0$:
	OPTI_MOVE = ESI;
		POP	ESI
	OPTI_HASH = ECX;
	CASE_STRING_COMPARE = EDX;
}


public CHECKSUM_PROC()
{
	// SLR
	DO_CHECKSUMING = -1;
}

public NOCHECKSUM_PROC()
{
	RESS	DO_CHECKSUMING
}

public NONULLSDOSSEG_PROC()
{
	RESS	NULLSDOSSEG_FLAG
	DOSSEG_PROC();
}

public DOSSEG_PROC()
{
	// ENABLE DOSSEG ORDERING SCHEME IN DGROUP
	DOSSEG_FLAG = -1;
}


public NFN_STRUCT* STORE_FILNAM(NFN_STRUCT* EAX)
{
	// EAX IS FILENAME TO STORE
	PUSH	EAX
	EAX = [EAX].NFN_TOTAL_LENGTH;
	EAX += NFN_STRUCT.NFN_TEXT+1;
	TEXT_POOL_ALLOC
	POP	ECX
	PUSH	EAX
	MOVE_NFN();
	POP	EAX
	return EAX;
}


public SET_ECHO_IND()
{
	ECHO_INDIRECT = -1;
	ECHO_ANY = -1;
}

public NOLOGO_PROC	LABEL	PROC
public RES_LOGO_OUTPUT	LABEL	PROC

		RESS	LOGO_OUTPUT

public RES_ECHO_IND	LABEL	PROC
public SILENT_PROC	LABEL	PROC

		RESS	INFORMATION_FLAG
		RESS	ECHO_INDIRECT
	if (!INDIRECT_MODE)
	{
		RESS	ECHO_ANY
	}
	return;
}

public VERBOSE_PROC()
{
	INFORMATION_FLAG = -1;
}


public INIT_AREA()
{
	// INITIALIZE ROOT AREA

	// ALLOCATE ROOM FOR AREA_STRUCT

		PUSH	EDI
	EAX = SIZE AREA_STRUCT;
		SECTION_POOL_ALLOC
	EDI = EAX;
		INSTALL_POINTER_GINDEX	AREA_GARRAY
	FIRST_AREA_GINDEX = EAX;
	CURN_AREA_GINDEX = EAX;
	memset(EDI, 0, AREA_STRUCT.sizeof);
	// SIMPLY FOR COUNTING AREAS
	AREA_COUNT = 0;
		POP	EDI
	return;

}

    version(any_overlays)
    {

		PUBLIC	ENDAREA_PROC,OVLCODEFIRST_PROC,OVLCODELAST_PROC,NORENAME_PROC

ENDAREA_PROC()
{

	// CLOSE MOST RECENT AREA


		LDS	SI,CURN_AREA
		ASSUME	DS:NOTHING
		SYM_CONV_DS
	AX ^= AX;
	if ([SI]._AREA_LEVEL == AX)
		goto 9$;
	[SI]._AREA_MAX_ADDRESS.LW = AX;
	[SI]._AREA_MAX_ADDRESS.HW = AX;

		LDS	SI,[SI]._AREA_PARENT_SECTION
	CURN_SECTION.OFFS = SI;
	CURN_SECTION.SEGM = DS;
		SYM_CONV_DS
	AX = 0;
	CURN_PLTYPE = AL;
	if ([SI]._SECT_LEVEL != AX)
		goto 2$;
	CURN_PLTYPE = MASK LEVEL_0_SECTION;
2$:
	AX = SECTION_NUMBER;
	AX -= [SI]._SECT_NUMBER;
	--AX;
	[SI]._SECT_CHILDREN = AX;
	SI = &[SI]._SECT_PARENT_AREA;
	DI = &CURN_AREA;
		MOVSW
		MOVSW
		LDS	SI,-4[SI]
		SYM_CONV_DS
	DI = &CURN_OUTFILE;
	SI = &[SI]._AREA_LAST_OUTFILE;
		MOVSW
		MOVSW
		FIXDS
	--PLINK_LEVEL;
	return;

9$:
	CL = ENDAREA_ERR;
	ERR_INBUF_ABORT(AL);
}

OVLCODEFIRST_PROC()
{



	$$SLR_CODE_FIRST = -1;
	return;

}

OVLCODELAST_PROC()
{



		RESS	$$SLR_CODE_FIRST
	return;

}

NORENAME_PROC()
{
		RESS	ROOT_ENVIRONMENT_LEGAL
	return;
}

    }


public VERIFY_SECTION()
{
	if (CURN_SECTION_GINDEX == 0)
		goto L1$;
	return;
L1$:
}


public DO_NEW_SECTION()
{
	// IF LEVEL=0, AND THIS AREA ALREADY HAS A SECTION, DO NEW

	// AREA FIRST


		PUSHM	EDI,ESI,EBX

	if (PLINK_LEVEL != 0)
		goto L11$;
	// LEVEL 0
	EAX = CURN_AREA_GINDEX;
		CONVERT	EAX,EAX,AREA_GARRAY
		ASSUME	EAX:PTR AREA_STRUCT
	if ([EAX]._AREA_LAST_SECT_GINDEX == 0)
		goto L1$;
	ESI = EAX;
		ASSUME	ESI:PTR AREA_STRUCT

	EAX = SIZE AREA_STRUCT;
		SECTION_POOL_ALLOC
	EBX = EAX;
		ASSUME	EBX:PTR AREA_STRUCT
	EDI = EAX;
		INSTALL_POINTER_GINDEX	AREA_GARRAY
	CURN_AREA_GINDEX = EAX;
	[ESI]._AREA_NEXT_AREA_GINDEX = EAX;
	EAX = 0;
	ECX = (SIZE AREA_STRUCT+3)/4;
		REP	STOSD
	CURN_SECTION_GINDEX = EAX;
	EAX = CURN_OUTFILE_GINDEX;
	++AREA_COUNT;

	// SET LAST OUTFILE?


	[EBX]._AREA_LAST_OUTFILE_GINDEX = EAX;
L1$:
L11$:
	EAX = SIZE SECTION_STRUCT;
		SECTION_POOL_ALLOC
	EBX = EAX;
		ASSUME	EBX:PTR SECTION_STRUCT
	EDI = EAX;
		INSTALL_POINTER_GINDEX	SECTION_GARRAY
	EDX = EAX;

	ESI = LAST_SECTION_GINDEX;

	ECX = (SIZE SECTION_STRUCT+3)/4;
	EAX = 0;
		REP	STOSD

	if (ESI & ESI)
		JZ	L7$

		CONVERT	ESI,ESI,SECTION_GINDEX
		ASSUME	ESI:PTR SECTION_STRUCT

	[ESI]._SECT_NEXT_SECTION_GINDEX = EDX;

L79$:
	EAX = SECTION_COUNT;
	LAST_SECTION_GINDEX = EDX;

	++EAX;
	ECX = CURN_OUTFILE_GINDEX;

	[EBX]._SECT_NUMBER = EAX;
	SECTION_COUNT = EAX;

	EAX = CURN_AREA_GINDEX;
	[EBX]._SECT_OUTFILE_GINDEX = ECX;

	[EBX]._SECT_PARENT_AREA_GINDEX = EAX;

	// SET OUTFILE


    version(any_overlays)
    {
	if (CACHE_DEFAULT_BYTE == 0)
		goto L4$;
	[EBX]._SECT_FLAGS |= MASK SECT_CACHEABLE;
L4$:
	if (COMPRESS_DEFAULT_BYTE == 0)
		goto L41$;
	[EBX]._SECT_FLAGS |= MASK SECT_SLRPACK;
L41$:
    }
	EAX = CURN_AREA_GINDEX;
		CONVERT	EAX,EAX,AREA_GARRAY
		ASSUME	EAX:PTR AREA_STRUCT

	ECX = [EAX]._AREA_LAST_SECT_GINDEX;
	[EAX]._AREA_LAST_SECT_GINDEX = EDX;
	if (ECX & ECX)
	// GO DO FIRST SECTION
		JZ	L3$
		CONVERT	ECX,ECX,SECTION_GARRAY
	[ECX].SECTION_STRUCT._SECT_NEXT_SECT_GINDEX = EDX;
L5$:
	CURN_PLTYPE = 0;
	CURN_SECTION_GINDEX = EDX;
	if (PLINK_LEVEL != 0)
		goto L6$;
	CURN_PLTYPE = MASK LEVEL_0_SECTION;
L6$:
		POPM	EBX,ESI,EDI
	return;

L7$:
	FIRST_SECTION_GINDEX = EDX;
	goto L79$;

L3$:
	[EAX]._AREA_FIRST_SECT_GINDEX = EDX;
	goto L5$;

}


public HELP_PROC_1()
{

	// EAX IS COMMAND TABLE


		ASSUME	ESI:NOTHING

		PUSH	EAX
	FORCE_SIGNON();

		POP	ESI
	EDI = OFF OUTBUF;
L1$:
	// ONE OF THESE FOR EVERY STARTING LETTER
	EAX = [ESI];
	ESI += 4;
	EAX |= EAX;
		JZ	L25$
		PUSH	ESI
	ESI = EAX;
L2$:
	DO_ONE();
		JNZ	L2$
		POP	ESI
	goto L1$;

L25$:
	if (EDI == OFF OUTBUF)
		goto L3$;
	HELP_PRINT();
L3$:
	goto ABORT;
}


DO_ONE()
{
	EDX = 0;
	ECX = 0;
	DL = *ESI++;
	EDX |= EDX;
		JZ	L9$

	CL = [ESI];
	ESI += 5;
	EDX -= ECX;
	memcpy(EDI, ESI, ECX);
	ESI += ECX;
	EDI += ECX;
	ECX = EDX;
	if (EDX == 0)
	    goto L2$;
	AL = '[';
	*EDI++ = AL;
L1$:
	AL = *ESI++;
	if (AL B$ 'A')
		goto L15$;
	if (AL A$ 'Z')
		goto L15$;
	AL += 20H;
L15$:
	*EDI++ = AL;
		LOOP	L1$
	AL = ']';
	*EDI++ = AL;
L2$:
	ECX = &OUTBUF+26 - EDI;
	if (ECX >= 0)
	    goto L3$;
	ECX = &OUTBUF+52 - EDI;
	if (ECX >= 0)
	    goto L3$;

HELP_PRINT	LABEL	PROC

	AX = 0ACR;
	*EDI++ = AX;
	EAX = OFF OUTBUF;
	ECX = EDI;
	ECX -= EAX;
	LOUTALL_CON();
	EDI = OFF OUTBUF;
L5$:
	AL |= -1;
L9$:
	return;

L3$:
	AL = ' ';
		REP	STOSB
	goto L5$;

}


public SET_REORDER_ALLOWED()
{

	REORDER_ALLOWED = -1;
	return;

}


public RES_REORDER_ALLOWED()
{

		RESS	REORDER_ALLOWED
	return;

}


public RES_PACKFUNCTIONS()
{

		RESS	PACKFUNCTIONS_FLAG
	return;

}


public SET_PACKFUNCTIONS()
{

	PACKFUNCTIONS_FLAG = -1;
	return;

}


bool CHECK_MAP_FLAG()
{
    return (MAPFILE_SELECTED ||
	    LINENUMBERS_FLAG ||
	    XREF_OUT ||
	    DETAILEDMAP_FLAG ||
	    SYMBOLS_OUT);
}


		.CONST


	// DEFAULT EXTENSIONS


OBJ_EXT		DB	4,'.obj'
MAP_EXT		DB	4,'.map'
IND_EXT		DB	4,'.lnk'
EXE_EXT		DB	4,'.exe'
DEF_EXT		DB	4,'.def'
NUL_EXT		DB	0
    version(any_overlays)
    {
OVL_EXT		DB	4,'.ovl'
    }
    version(fg_segm)
    {
RES_EXT		DB	4,'.res'
LIB_EXT		DB	4,'.lib'
DIN_EXT		DB	4,'.din'
    }

		ALIGN	4
public NULSTUFF	LABEL	DWORD
public INDIR_STUFF	LABEL	DWORD
	// CMD_SELECTED - NUL OR SRCNAM
		DCA	RET_FALSE
	// 		DD	IND_EXT		;CMD_EXTENT - DEFAULT EXTENT

		DD	NUL_EXT
    version(fg_mscmd)
    {
	// CMD_DESIRED - USED AT ALL?
		DCA	RET_TRUE
	// CMD_PMSG - PROMPT MESSAGE
		DD	IND_MSG
    }

public LOCAL_INFO	LABEL	DWORD
public OBJSTUFF	LABEL	DWORD

	// NO DEFAULT PRIMARY NAME
		DCA	RET_FALSE
	// DEFAULT EXTENSION
		DD	OBJ_EXT
    version(fg_mscmd)
    {
	// YES WE WANT THIS
		DCA	RET_TRUE
		DD	OBJ_MSG
    }

public EXESTUFF	LABEL	DWORD
	// YES, DEFAULT=SOURCE
		DCA	RET_TRUE
	// DEFAULT EXTENTION
		DD	EXE_EXT
    version(fg_mscmd)
    {
	// USE THIS AT ALL?  YES!
		DCA	RET_TRUE
	// IF PROMPTING
		DD	OUT_MSG
    }

public MAPSTUFF	LABEL	WORD
	// USE LIBRARY NAME IF SELECT
		DCA	CHECK_MAP_FLAG
		DD	MAP_EXT
    version(fg_mscmd)
    {
	// YES, WE WANT THIS
		DCA	RET_TRUE
		DD	MAP_MSG
    }

    version(fg_mscmd)
    {

		PUBLIC	DEFSTUFF

DEFSTUFF	LABEL	WORD
	// DEFAULT TO NUL
		DCA	RET_FALSE
	// DEFAULT LIB EXTENSION
		DD	DEF_EXT
	// YES, THIS IS WANTED
		DCA	RET_TRUE
	// IF PROMPTING...
		DD	DEF_MSG

    }

		DD	0

public PATHSTUFF	LABEL	WORD
	// DEFAULT TO NUL
		DCA	RET_FALSE
	// DEFAULT PATH EXTENSION
		DD	NUL_EXT
    version(fg_mscmd)
    {
	// YES, THIS IS WANTED
		DCA	RET_TRUE
	// IF PROMPTING...
		DD	IND_MSG
    }

    version(any_overlays)
    {

		PUBLIC	OVLSTUFF

OVLSTUFF	DCA	RET_FALSE
		DD	OVL_EXT
    version(fg_mscmd)
    {
	// YES, THIS IS WANTED
		DCA	RET_TRUE
	// IF PROMPTING...
		DD	IND_MSG
    }

    }

    version(fg_segm)
    {

		PUBLIC	STUBSTUFF,RCSTUFF,IMPLIB_STUFF,IMPDEF_STUFF,RESSTUFF

STUBSTUFF	LABEL	WORD
	// DEFAULT TO NUL
		DCA	RET_FALSE
	// DEFAULT LIB EXTENSION
		DD	EXE_EXT
	// YES, THIS IS WANTED
		DCA	RET_TRUE
	// IF PROMPTING...
		DD	IND_MSG

RCSTUFF		LABEL	WORD
	// OUTPUT FILENAME BY DEFAULT
		DCA	RET_TRUE
	// .RES
		DD	RES_EXT
	// YES, I WANT IT
		DCA	RET_TRUE
		DD	IND_MSG

RESSTUFF	LABEL	WORD
	// NUL BY DEFAULT
		DCA	RET_FALSE
	// .RES
		DD	RES_EXT
	// YES, I WANT IT
		DCA	RET_TRUE
		DD	RES_MSG

IMPLIB_STUFF	LABEL	WORD
	// USE OUTPUT FILENAME BY DEFAULT
		DCA	RET_TRUE
		DD	LIB_EXT
		DCA	RET_TRUE
	// NO PROMPTING...
		DD	IND_MSG

IMPDEF_STUFF	LABEL	WORD
	// USE OUTPUT FILENAME BY DEFAULT
		DCA	RET_TRUE
		DD	DIN_EXT
		DCA	RET_TRUE
	// NO PROMPTING...
		DD	IND_MSG

    }

    version(fg_mscmd)
    {

	// PROMPTS

OBJ_MSG		DB	11,'OBJ Files: '
MAP_MSG		DB	10,'Map File: '
OUT_MSG		DB	13,'Output File: '
IND_MSG		DB	1,'I'
DEF_MSG		DB	17,'Definition File: '
RES_MSG		DB	16,'Resource Files: '

    }

    version(any_overlays)
    {

		PUBLIC	CACHE_BYTE,COMPRESS_BYTE,RELOAD_BYTE,TRACK_BYTE,DEBUG_BYTE,CODEVIEW_BYTE,MODEL_FAR_BYTE
		PUBLIC	MULTI_LEVEL_BYTE,MULTI_AREA_BYTE,MULTI_FILES_BYTE,OVR_EXTRN_TABLE,OVR_EXTRN_COUNT,BYTES

		.DATA

const OVR_EXTRN_COUNT = 6;

	// $$SLR_INI
OVR_EXTRN_TABLE	DW	OVR_EXTRN
	// CACHE, RELOAD, CODEVIEW
		DB	3
		DB	CACHE_OFF
		DB	RELOAD_OFF
		DB	CODEVIEW_OFF

	// $$SLR_SF
SELECT_EXTRN_TABLE	DW	SELECT_EXTRN
		DB	1
		DB	MT_FILES_OFF

	// $$SLR_HND
HANDLER_EXTRN_TABLE	DW	HANDLER_EXTRN
		DB	3
		DB	RELOAD_OFF
		DB	MODEL_FAR_OFF
		DB	TRACK_OFF

	// $$SLR_LSECT
LSECT_EXTRN_TABLE	DW	LSECT_EXTRN
		DB	4
		DB	CACHE_OFF
		DB	COMPRESS_OFF
		DB	MT_AREA_OFF
		DB	MT_LEVEL_OFF

	// $$SLR_CCH
CACHE_EXTRN_TABLE	DW	CACHE_EXTRN
		DB	3
		DB	CACHE_OFF
		DB	MT_LEVEL_OFF
		DB	MT_AREA_OFF

CV_EXTRN_TABLE	DW	CV_EXTRN
		DB	1
		DB	CODEVIEW_OFF


public OVR_EXTRN	DB	9,'$$SLR_INI'
SELECT_EXTRN	DB	8,'$$SLR_SF'
HANDLER_EXTRN	DB	9,'$$SLR_HND'
LSECT_EXTRN	DB	11,'$$SLR_LSECT'
CACHE_EXTRN	DB	9,'$$SLR_CCH'
CV_EXTRN	DB	8,'$$SLR_CV'

BYTES		LABEL	BYTE
CACHE_BYTE	DB	'N'
COMPRESS_BYTE	DB	'N'
RELOAD_BYTE	DB	'N'
TRACK_BYTE	DB	'N'
	// FAR OVERLAYS BY DEFAULT
MODEL_FAR_BYTE	DB	'Y'
DEBUG_BYTE	DB	'N'
CODEVIEW_BYTE	DB	'N'
MULTI_LEVEL_BYTE DB	'N'
MULTI_AREA_BYTE	DB	'N'
MULTI_FILES_BYTE DB	'N'

CACHE_OFF	EQU	CACHE_BYTE-BYTES
COMPRESS_OFF	EQU	COMPRESS_BYTE-BYTES
RELOAD_OFF	EQU	RELOAD_BYTE-BYTES
TRACK_OFF	EQU	TRACK_BYTE-BYTES
MODEL_FAR_OFF	EQU	MODEL_FAR_BYTE-BYTES
DEBUG_OFF	EQU	DEBUG_BYTE-BYTES
CODEVIEW_OFF	EQU	CODEVIEW_BYTE-BYTES
MT_LEVEL_OFF	EQU	MULTI_LEVEL_BYTE-BYTES
MT_AREA_OFF	EQU	MULTI_AREA_BYTE-BYTES
MT_FILES_OFF	EQU	MULTI_FILES_BYTE-BYTES

OVR_EXTRN_ENDER LABEL	BYTE

    }

	// CAUSE SOMETIMES THIS CHANGES...
		.DATA

public ubyte[256] PARSE_TABLE =
{
	// 0 IS SPACE-TAB (OR OTHER IGNORED CONTROL CHARS)
	// 2 IS SEPARATOR ( # , @ % ( ) - " * + / = : )
	// 4 IS SEMICOLON
	// 6 IS NEW-LINE CHARS (CR, LF, FF)


	// 00-03 SKIP IT
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// 04-07 SKIP IT
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// 08-0B
	CH_SPC,CH_SPC,CH_NL,CH_SPC,

	// 0C-0F
	CH_NL,CH_NL,CH_SPC,CH_SPC,

	// 10-1F
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC, CH_SPC,
	CH_SEMI,
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC,

	//  !"#
	CH_SPC,'!',CH_SEP,CH_SEP,

	// $%&'
	'$','%','&','\'',

	// ()*+
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// ,-./
	CH_SEP,CH_SEP,'.',CH_SEP,

	// 01234567
	'0','1','2','3','4','5','6','7',

	// 89:;
	'8','9',CH_SEP,CH_SEMI,

	// <=>?
	'<',CH_SEP,'>','?',

	CH_AT,'A','B','C','D','E','F','G',
	'H','I','J','K','L','M','N','O',
	'P','Q','R','S','T','U','V','W',
	'X','Y','Z','[','\',']',CH_ESC,'_',
	'`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
	'P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~',0x7F,

	0x80,0x81,0x82,0x83, 0x84,0x85,0x86,0x87,
	0x88,0x89,0x8A,0x8B, 0x8C,0x8D,0x8E,0x8F,

	0x90,0x91,0x92,0x93, 0x94,0x95,0x96,0x97,
	0x98,0x99,0x9A,0x9B, 0x9C,0x9D,0x9E,0x9F,

	0xA0,0xA1,0xA2,0xA3, 0xA4,0xA5,0xA6,0xA7,
	0xA8,0xA9,0xAA,0xAB, 0xAC,0xAD,0xAE,0xAF,

	0xB0,0xB1,0xB2,0xB3, 0xB4,0xB5,0xB6,0xB7,
	0xB8,0xB9,0xBA,0xBB, 0xBC,0xBD,0xBE,0xBF,

	0xC0,0xC1,0xC2,0xC3, 0xC4,0xC5,0xC6,0xC7,
	0xC8,0xC9,0xCA,0xCB, 0xCC,0xCD,0xCE,0xCF,

	0xD0,0xD1,0xD2,0xD3, 0xD4,0xD5,0xD6,0xD7,
	0xD8,0xD9,0xDA,0xDB, 0xDC,0xDD,0xDE,0xDF,

	0xE0,0xE1,0xE2,0xE3, 0xE4,0xE5,0xE6,0xE7,
	0xE8,0xE9,0xEA,0xEB, 0xEC,0xED,0xEE,0xEF,

	0xF0,0xF1,0xF2,0xF3, 0xF4,0xF5,0xF6,0xF7,
	0xF8,0xF9,0xFA,0xFB, 0xFC,0xFD,0xFE,0xFF,
]

    version(fg_td)
    {
ubyte[256] PARSE_TABLE_TL =
[
	// 0 IS SPACE-TAB (OR OTHER IGNORED CONTROL CHARS)
	// 2 IS SEPARATOR ( # , @ % ( ) - " * + / = : )
	// 4 IS SEMICOLON
	// 6 IS NEW-LINE CHARS (CR, LF, FF)

	// 00-03 SKIP IT
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// 04-07 SKIP IT
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// 08-0B
	CH_SPC,CH_SPC,CH_NL,CH_SPC,

	// 0C-0F
	CH_NL,CH_NL,CH_SPC,CH_SPC,

	// 10-1F
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC, CH_SPC,
	CH_SEMI,
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,
	CH_SPC,

	//  !"#
	CH_SPC,'!',CH_SEP,CH_SEP,

	// $%&'
	'$','%','&','\'',

	// ()*+
	CH_SPC, CH_SPC, CH_SPC, CH_SPC,

	// ,-./
	CH_SEP,CH_SEP,'.',CH_SEP,

	// 01234567
	'0','1','2','3','4','5','6','7',

	// 89:;
	'8','9',CH_SEP,CH_SEMI,

	// <=>?
	'<',CH_SEP,'>','?',

	CH_AT,'A','B','C','D','E','F','G',
	'H','I','J','K','L','M','N','O',
	'P','Q','R','S','T','U','V','W',
	'X','Y','Z','[','\',']',CH_ESC,'_',
	'`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
	'p','q','r','s','t','u','v','w','x','y','z','{','|','}','~',0x7F,

	0x80,0x81,0x82,0x83, 0x84,0x85,0x86,0x87,
	0x88,0x89,0x8A,0x8B, 0x8C,0x8D,0x8E,0x8F,

	0x90,0x91,0x92,0x93, 0x94,0x95,0x96,0x97,
	0x98,0x99,0x9A,0x9B, 0x9C,0x9D,0x9E,0x9F,

	0xA0,0xA1,0xA2,0xA3, 0xA4,0xA5,0xA6,0xA7,
	0xA8,0xA9,0xAA,0xAB, 0xAC,0xAD,0xAE,0xAF,

	0xB0,0xB1,0xB2,0xB3, 0xB4,0xB5,0xB6,0xB7,
	0xB8,0xB9,0xBA,0xBB, 0xBC,0xBD,0xBE,0xBF,

	0xC0,0xC1,0xC2,0xC3, 0xC4,0xC5,0xC6,0xC7,
	0xC8,0xC9,0xCA,0xCB, 0xCC,0xCD,0xCE,0xCF,

	0xD0,0xD1,0xD2,0xD3, 0xD4,0xD5,0xD6,0xD7,
	0xD8,0xD9,0xDA,0xDB, 0xDC,0xDD,0xDE,0xDF,

	0xE0,0xE1,0xE2,0xE3, 0xE4,0xE5,0xE6,0xE7,
	0xE8,0xE9,0xEA,0xEB, 0xEC,0xED,0xEE,0xEF,

	0xF0,0xF1,0xF2,0xF3, 0xF4,0xF5,0xF6,0xF7,
	0xF8,0xF9,0xFA,0xFB, 0xFC,0xFD,0xFE,0xFF,
]
    }

version(fg_td)
{
    void *MY_PARSE_TABLE;
}

