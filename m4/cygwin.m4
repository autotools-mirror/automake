# Check to see if we're running under Cygwin32, without using
# AC_CANONICAL_*.  If so, set output variable EXEEXT to ".exe".
# Otherwise set it to "".

dnl AM_CYGWIN32()
AC_DEFUN(AM_CYGWIN32,
[AC_MSG_CHECKING(for Cygwin32 environment)
AC_EGREP_CPP(lose, [
#ifdef __CYGWIN32__
lose
#endif], [EXEEXT=.exe
AC_MSG_RESULT(yes)], [EXEEXT=
AC_MSG_RESULT(no)])
AC_SUBST(EXEEXT)])
