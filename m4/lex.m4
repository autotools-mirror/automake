## Replacement for AC_PROG_LEX and AC_DECL_YYTEXT
## by Alexandre Oliva <oliva@dcc.unicamp.br>

dnl AM_PROG_LEX
dnl Look for flex, lex or missing, then run AC_PROG_LEX and AC_DECL_YYTEXT
AC_DEFUN(AM_PROG_LEX,
[AC_CHECK_PROGS(LEX, flex lex, "$1/missing flex")
AC_PROG_LEX
AC_DECL_YYTEXT])
