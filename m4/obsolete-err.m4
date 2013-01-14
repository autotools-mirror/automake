#  -*- Autoconf -*-
# Deprecated, obsolescent or and obsolete macros.
#
# Copyright (C) 1996-2013 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

AC_DEFUN([AM_PROG_MKDIR_P],
[AC_REQUIRE([AC_PROG_MKDIR_P])dnl
AC_SUBST([mkdir_p], ['$(MKDIR_P)'])dnl
AC_DIAGNOSE([obsolete],
[macro '$0' is deprecated.
You should use the Autoconf-provided 'AC][_PROG_MKDIR_P' macro instead,
and use '$(MKDIR_P)' instead of '$(mkdir_p)' in your Makefile.am files.])])

dnl TODO: Remove in Automake 1.15.
AC_DEFUN([AM_CONFIG_HEADER],
[AC_FATAL(['$0': this macro is obsolete.
    You should use the 'AC][_CONFIG_HEADERS' macro instead.])])

dnl TODO: Remove in Automake 1.15.
AC_DEFUN([AM_PROG_CC_STDC],
[AC_FATAL(['$0': this macro is obsolete.
    You should simply use the 'AC][_PROG_CC' macro instead.
    Also, your code should no longer depend upon 'am_cv_prog_cc_stdc',
    but upon 'ac_cv_prog_cc_stdc'.])])

dnl TODO: Remove in Automake 1.14.
AC_DEFUN([AM_C_PROTOTYPES],
         [AC_FATAL([automatic de-ANSI-fication support has been removed])])
AU_DEFUN([fp_C_PROTOTYPES], [AM_C_PROTOTYPES])
