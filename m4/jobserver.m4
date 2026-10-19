# Enable compiler access to GNU make's jobserver.       -*- Autoconf -*-
# Copyright (C) 2026 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# _AM_JOBSERVER
# -------------
AC_DEFUN([_AM_JOBSERVER],
[AC_ARG_ENABLE([jobserver],
  [AS_HELP_STRING([--enable-jobserver],
    [let compilers and linkers use the GNU make jobserver])],
  [], [enable_jobserver=no])
AM_JOBSERVER=
AS_CASE([$enable_jobserver],
  [yes], [
    AS_IF([${MAKE-make} --version 2>/dev/null | grep 'GNU Make' >/dev/null],
      [], [AC_MSG_ERROR([--enable-jobserver requires GNU make])])
    dnl MAKEFLAGS begins with the single-letter flags, without a dash.
    dnl Prefix a dash so firstword does not pick up a later option or
    dnl variable assignment when there are no single-letter flags.
    dnl Do not mark commands recursive under -n, -q, or -t.
    AM_JOBSERVER='$(if $(findstring n,$(firstword -$(MAKEFLAGS)))$(findstring q,$(firstword -$(MAKEFLAGS)))$(findstring t,$(firstword -$(MAKEFLAGS))),,+)'
  ],
  [no], [],
  [AC_MSG_ERROR([bad value '$enable_jobserver' for --enable-jobserver])])
AC_SUBST([AM_JOBSERVER])
])
