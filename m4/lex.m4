## Replacement for AC_PROG_LEX.                       -*-  Autoconf -*-
## by Alexandre Oliva <oliva@dcc.unicamp.br>

# Copyright 1998, 1999, 2000, 2001 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# serial 2

AC_PREREQ(2.50)

# AM_PROG_LEX
# -----------
# Look for flex, lex or missing, then run AC_PROG_LEX.
AC_DEFUN([AM_PROG_LEX],
[AC_REQUIRE([AM_MISSING_HAS_RUN])dnl
AC_CHECK_PROGS(LEX, flex lex, [${am_missing_run}flex])
AC_PROG_LEX])
