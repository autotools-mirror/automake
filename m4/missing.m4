## --------------------------------------------------------- ##
## Fake the existence of programs that GNU maintainers use.  ##
## --------------------------------------------------------- ##
dnl AM_MISSING_PROG(NAME, PROGRAM, DIRECTORY)
AC_DEFUN(AM_MISSING_PROG, [$1=${$1-"$3/missing --run $2"}
AC_SUBST($1)])
