## ------------------------------- ##
## Check for function prototypes.  ##
## From Franc,ois Pinard           ##
## ------------------------------- ##

AC_DEFUN(AM_C_PROTOTYPES,
[AC_REQUIRE([AM_PROG_CC_STDC])
AC_MSG_CHECKING([for function prototypes])
if test "$ac_cv_prog_cc_stdc" != no; then
  AC_MSG_RESULT(yes)
  AC_DEFINE(PROTOTYPES)
  U= ANSI2KNR=
else
  AC_MSG_RESULT(no)
  U=_ ANSI2KNR=./ansi2knr
fi
AC_SUBST(U)dnl
AC_SUBST(ANSI2KNR)dnl
])
