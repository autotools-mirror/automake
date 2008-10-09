# Autoconf support for the Vala compiler

# Copyright (C) 2007 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# serial 2

# Check whether the Vala compiler exists in `PATH'. If it is found the
# variable VALAC is set. Optionally a minimum release number of the compiler
# can be requested.
#
# Author: Mathias Hasselmann <mathias.hasselmann@gmx.de>
#
# AC_PROG_VALAC([MINIMUM-VERSION])
# --------------------------------------------------------------------------
AC_DEFUN([AC_PROG_VALAC],[
  AC_PATH_PROG([VALAC], [valac], [])
  AC_SUBST(VALAC)

  if test -z "${VALAC}"; then
    AC_MSG_WARN([No Vala compiler found. You will not be able to recompile .vala source files.])
  elif test -n "$1"; then
    AC_REQUIRE([AC_PROG_AWK])
    AC_MSG_CHECKING([valac is at least version $1])

    if "${VALAC}" --version | "${AWK}" -v r='$1' 'function vn(s) { if (3 == split(s,v,".")) return (v[1]*1000+v[2])*1000+v[3]; else exit 2; } /^Vala / { exit vn(r) > vn($[2]) }'; then
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
      AC_MSG_ERROR([Vala $1 not found.])
    fi
  fi
])
