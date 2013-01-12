##                                                          -*- Autoconf -*-
# Copyright (C) 1999-2013 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# AM_PROG_CC_C_O
# --------------
# Basically a no-op now, completely superseded by the AC_PROG_CC
# adjusted by Automake.  Kept for backward-compatibility.
AC_DEFUN([AM_PROG_CC_C_O],
[AC_REQUIRE([AC_PROG_CC])dnl
dnl Make sure AC_PROG_CC is never called again, or it will override our
dnl setting of CC.
m4_define([AC_PROG_CC],
          [m4_fatal([AC_PROG_CC cannot be called after AM_PROG_CC_C_O])])
# For better backward-compatibility.  Users are advised to stop
# relying on this cache variable and C preprocessor symbol ASAP.
eval ac_cv_prog_cc_${am__cc}_c_o=\$am_cv_prog_cc_${am__cc}_c_o
if eval test \"\$ac_cv_prog_cc_${am__cc}_c_o\" != yes; then
  AC_DEFINE([NO_MINUS_C_MINUS_O], [1],
            [Define to 1 if your C compiler doesn't accept -c and -o together.])
fi
])
