#define NSYM_UNDEFINED		0	// NOT ANYTHING, IN NO LIST, UNREFERENCED
#define NSYM_ASEG		2	// SEGMENT 'AT' KIND, IN PUBLIC LIST
#define NSYM_RELOC		4	// NORMAL RELOCATABLE, IN PUBLIC LIST
#define NSYM_COMM_NEAR		6	// NORMAL, IN COMMUNAL LIST
#define NSYM_COMM_FAR		8	// NORMAL, IN COMMUNAL LIST, FAR
#define NSYM_COMM_HUGE		10	// HUGE COMMUNAL, IN COMMUNAL LIST
#define NSYM_CONST		12	// X EQU 5, IN PUBLIC LIST
#define NSYM_LIBRARY		14	// NOT DEFINED OR REFERENCED, IN A LIB, NO LIST
#define NSYM_IMPORT		16	// SYMBOL IS IMPORTED
#define NSYM_PROMISED		18	// PROMISED BY A DEFINE, DOSSEG, LIB
#define NSYM_EXTERNAL		20	// UNDEFINED, REFERENCED, IN EXTRN LIST
#define NSYM_WEAK_EXTRN		22	// THIS IS IN THE REFERENCED 'WEAK EXTRNS' LIST...
#define NSYM_POS_WEAK		24	// THIS REFERENCED HERE AS WEAK EXTRN, NOT IN LIST YET
#define NSYM_LIBRARY_LIST	26	// UNDEFINED, REFERENCED, IN A LIB LIST
#define NSYM__IMP__UNREF	28	// __imp_ SYMBOL, NOT REFERENCED
#define NSYM_ALIASED		30	// HAS AN ALIAS ASSIGNED, REFERENCED
#define NSYM_COMDAT		32	// COMDAT SYMBOL
#define NSYM_WEAK_DEFINED	34	// REFERENCED WEAK EXTRN, MY DEFAULT HAS BEEN DEFINED, OR AT LEAST 'REFERENCED'
#define NSYM_WEAK_UNREF		36	// UNREFERENCED WEAK, IN NO LIST
#define NSYM_ALIASED_UNREF	38	// UNREFERENCED ALIAS, IN NO LIST
#define NSYM_POS_LAZY		40	// MAKING THIS A LAZY
#define NSYM_LAZY		42	// REFERENCED LAZY, IN LIST
#define NSYM_LAZY_UNREF		44	// UNREFERENCED LAZY, IN NO LIST
#define NSYM_ALIAS_DEFINED	46	// REFERENCED ALIAS, MY DEFAULT HAS BEEN REFERENCED
#define NSYM_LAZY_DEFINED	48	// REFERENCED LAZY, MY DEFAULT HAS BEEN REFERENCED
#define NSYM_NCOMM_UNREF	50	// UNREFERENCED NEAR COMMUNAL, IN NO LIST
#define NSYM_FCOMM_UNREF	52	// UNREFERENCED FAR COMMUNAL, IN NO LIST
#define NSYM_HCOMM_UNREF	54	// UNREFERENCED HUGE COMMUNAL, IN NO LIST
#define NSYM__IMP__		56
#define NSYM_UNDECORATED	58	// USED BY DEFINE_EXPORTS

#define NSYM_SIZE	60	// LENGTH OF THIS LIST

#define NSYM_ANDER	63

typedef struct SYMBOL_STRUCT
{
    unsigned char _S_NSYM_TYPE;		// UNDEFINED, ASEG, RELOC, PROMISED, ETC **
    unsigned char _S_REF_FLAGS;		// REFERENCED FLAG..., FIARQQ FLAG	**
    unsigned short _S_CV_TYPE3;

    void *_S_NEXT_HASH_GINDEX;		// NEXT SYMBOL IN HASH
					// LATER IT IS PARAGRAPH OR OS2_SELECTOR #
    #define _S_OS2_NUMBER	_S_NEXT_HASH_GINDEX	// or paragraph

    struct SYMBOL_STRUCT *_S_NEXT_SYM_GINDEX;		// FORWARD LINK	-	USED ALWAYS
    void *_S_PREV_SYM_GINDEX;		// BACKWARDS LINK -	LATER IT IS OS2_FLAGS
    #define _S_OS2_FLAGS	_S_PREV_SYM_GINDEX

    int _S_MOD_GINDEX;			// REFERENCING MODULE, MODULE IN LIBRARY, DEFINING MODULE GINDEX
    #define _S_N_CPP_MATCHES	_S_MOD_GINDEX
    int _S_SEG_GINDEX;			// DEFINING LIBRARY, INITIALLY SEGMOD, LATER SEGMENT?
    #define _S_N_NCPP_MATCHES	_S_SEG_GINDEX

    int _S_OFFSET;			// OFFSET FROM SEGMOD, LATER OFFSET FROM FRAME - OR TOTAL OFFSET
    #define _S_CD_SEGMOD_GINDEX		_S_OFFSET	// SEGMOD I WILL USE
    #define _S_ALIAS_SUBSTITUTE_GINDEX	_S_OFFSET	// SYMBOL TO USE FOR THIS ONE
    #define _S_LAST_CPP_MATCH		_S_OFFSET	// SYMBOL_STRUCT*

    int _S_LAST_XREF;
    #define _S_LAST_NCPP_MATCH		_S_LAST_XREF	// SYMBOL_STRUCT*

#if any_overlays
    #define _S_SECTION_GINDEX	_S_NEXT_HASH_GINDEX	// LOWEST COMMON SECTION REFERENCED FROM
					// LATER IT BECOMES VECTOR #
    unsigned char _S_PLTYPE;		// PLTYPES RECORD
    unsigned char _S_PLINK_FLAGS;
    #define _S_VECTOR		_S_GROUP_GINDEX	// VECTOR INDEX #
#endif

    int _S_NAME_TEXT;
    #define _S_FLOAT_TYPE	(_S_NAME_TEXT+8)

} SYMBOL_STRUCT;

	// LIBRARY
#define _S_LIB_GINDEX	_S_SEG_GINDEX		// DEFINING LIBRARY
#define _S_LIB_MODULE	_S_MOD_GINDEX		// MODULE # IN LIBRARY

	// ALIAS

	// WEAK EXTRN

#define _S_WEAK_DEFAULT_GINDEX	_S_OFFSET		// DEFAULT EXTERNAL TO USE IF DEFINED

	// LAZY EXTRN

#define _S_LAZY_DEFAULT_GINDEX	_S_OFFSET		// SYMBOL TO USE IF WE CANNOT FIND ME

#define _S__IMP__DEFAULT_GINDEX	_S_OFFSET

/*

PLINK_SYMBOL_REC	RECORD	\
		VECTOR_ALWAYS:1,\
		VECTOR_NEVER:1,\
		VECTOR_TRACK:1,\
		VECTOR_YES:1,\			;SYMBOL IS VECTORED
		MERGE_PUBLIC:1,\
		MERGE_PRIVATE:1,\
		DEBUG_GLOBAL:1
*/

#define	S_DATA_REF 0x80
#define	S_USE_GROUP 0x40
#define	S_WEAK_AGAIN 0x20
#define	S_SPACES 0x10
#define	S_REFERENCED 8
#define	S_FLOAT_SYM 4
#define	S_HARD_REF 2
#define	S_SOFT_REF 1

#define S_NO_CODEVIEW		S_SOFT_REF

#define UNDECO_EXACT		S_SOFT_REF
#define UNDECO_REFERENCED_1	S_HARD_REF

#define _S_REF_MOD_GINDEX	_S_MOD_GINDEX		// FIRST MODULE REFERENCING THIS (FOR ERROR_UNDEFINED)
/*
;_S_LAST_XREF	EQU	_S_OFFSET			;LINKED LIST OF REFERENCING MODULES
_S_DEFINING_MOD	EQU	_S_MOD_GINDEX			;MODULE # IF DEFINED NORMALLY (USED DURING XREF OUTPUT)

_S_IMP_NOFFSET	EQU	(_S_OFFSET)			;OFFSET TO NAME TEXT
_S_IMP_MODULE	EQU	_S_SEG_GINDEX			;IMPORT MODULE NUMBER (INDEX INTO NEXEHEADER) (AND IMPMOD_GARRAY)
;_S_IMP_FLAGS	EQU	(_S_OFFSET.LW)			;0=BYNAME, 1=ORDINAL
_S_IMP_IMPNAME_GINDEX	EQU	_S_PREV_SYM_GINDEX	;IF IMPORTED BY NAME OR HINT
_S_IMP_ORDINAL	EQU	_S_PREV_SYM_GINDEX		;IF IMPORTED BY ORDINAL
;_S_IMP_IMPMOD_GINDEX	EQU	(_S_OFFSET.HW)		;MODULE (IN IMPNAME TABLE)
_S_IMP_NEXT_GINDEX	EQU	_S_NEXT_SYM_GINDEX	;LIST FOR SCANNING IMPORTS
_S_IMP_JREF_INDEX	EQU	(_S_OFFSET)		;INDEX INTO IMPCODE SEGMENT

S_IMP_ORDINAL	EQU	<S_USE_GROUP>


_COMM_NSYM_TYPE		EQU	<_S_NSYM_TYPE>
_COMM_REF_FLAGS		EQU	<_S_REF_FLAGS>

_COMM_NEXT_HASH_GINDEX	EQU	<_S_NEXT_HASH_GINDEX>

_COMM_NEXT_SYM_GINDEX	EQU	<_S_NEXT_SYM_GINDEX>
_COMM_PREV_SYM_GINDEX	EQU	<_S_PREV_SYM_GINDEX>

_COMM_MOD_GINDEX	EQU	<_S_MOD_GINDEX>
_COMM_SIZE_A		EQU	<_S_SEG_GINDEX>

_COMM_SIZE_B		EQU	<_S_OFFSET>

if	fg_td

TDBG_SYMBOL_STRUCT	STRUC

_TDBG_S_FLAGS		DB	?	;DEBUG TYPE COMPRESSED.
_TDBG_S_BP_FLAGS	DB	?	;TDBG STUFF
_TDBG_S_SRC_MOD		DW	?	;SOURCE FILE DEFINING THIS GUY
_TDBG_S_LINNUM		DW	?	;LINE NUMBER...
_TDBG_S_TID		DW	?	;TURBO TYPE INDEX

TDBG_SYMBOL_STRUCT	ENDS

endif

*/