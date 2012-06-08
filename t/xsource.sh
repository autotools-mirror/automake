#! /bin/sh
# Copyright (C) 1997-2012 Free Software Foundation, Inc.
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

# Test to make sure multiple source files with the same object
# file causes error.

. ./defs || Exit 1

cat > Makefile.am << 'END'
bin_PROGRAMS = zardoz
lib_LTLIBRARIES = libfoo.la
zardoz_SOURCES = z.c
libfoo_la_SOURCES = z.c
END

: > ltmain.sh
: > config.guess
: > config.sub

cat >> configure.ac << 'END'
AC_PROG_CC
AC_SUBST([LIBTOOL], [unused])
END

$ACLOCAL
AUTOMAKE_fails
$FGREP "object 'z.\$(OBJEXT)' created both with libtool and without" stderr

:
