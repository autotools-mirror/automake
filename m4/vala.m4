# Autoconf support for the Vala compiler

# Copyright (C) 2008-2012 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# Check whether the Vala compiler exists in $PATH. If it is found, the
# variable VALAC is set. Optionally a minimum release number of the
# compiler can be requested.
#
# AM_PROG_VALAC([MINIMUM-VERSION], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# --------------------------------------------------------------------------
AC_DEFUN([AM_PROG_VALAC],
  [AC_PATH_PROG([VALAC], [valac], [valac])
   AS_IF([test "$VALAC" != valac && test -n "$1"],
      [AC_MSG_CHECKING([whether $VALAC is at least version $1])
       am__vala_version=`$VALAC --version | sed 's/Vala  *//'`
       AS_VERSION_COMPARE([$1], ["$am__vala_version"],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([no])
          VALAC=valac])])
    if test "$VALAC" = valac; then
      m4_default([$3],
        [AC_MSG_WARN([no proper vala compiler found])
         AC_MSG_WARN([you will not be able to compile vala source files])])
    else
      m4_default([$2], [:])
    fi])
