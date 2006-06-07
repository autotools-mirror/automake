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
[AC_PREREQ([2.59c])dnl
AC_REQUIRE([AC_PROG_MKDIR_P])dnl
AC_SUBST([mkdir_p], [$MKDIR_P])dnl
])
