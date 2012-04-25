#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Test exe-specific flags with dependency tracking.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = foo
foo_SOURCES = foo.c
foo_CFLAGS = -DFOO
END

: > compile

$ACLOCAL
$AUTOMAKE

$FGREP ' -o foo-foo' Makefile.in
$FGREP 'foo.o.o' Makefile.in && Exit 1
$FGREP 'foo.$(OBJEXT).$(OBJEXT)' Makefile.in && Exit 1
$FGREP '$(foo_CFLAGS)' Makefile.in

:
