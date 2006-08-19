##                                                          -*- Autoconf -*-
# Copyright (C) 2003, 2004, 2005, 2006  Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# AM_PROG_MKDIR_P
# ---------------
# Check for `mkdir -p'.
AC_DEFUN([AM_PROG_MKDIR_P],
[AC_PREREQ([2.60])dnl
AC_REQUIRE([AC_PROG_MKDIR_P])dnl
dnl Automake 1.8 to 1.9.6 used to define mkdir_p.
dnl We now use MKDIR_P, while keeping a definition of mkdir_p for
dnl backward compatibility. Do not define mkdir_p as $(MKDIR_P) for
dnl the sake of Makefile.ins that do not define MKDIR_P.
AC_SUBST([mkdir_p], ["$MKDIR_P"])dnl
])
