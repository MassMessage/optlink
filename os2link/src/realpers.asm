
		INCLUDE	MACROS

		.CODE	STARTUP_TEXT

		PUBLIC	PERSONALITY

PERSONALITY	PROC

		SETT	LIB_NOT_FOUND_FATAL
		RET

PERSONALITY	ENDP

		END

