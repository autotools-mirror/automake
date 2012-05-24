#! /bin/sh
# Copyright (C) 2007-2012 Free Software Foundation, Inc.
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

# Test internal automake variable $(am__all_progs).

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_SUBST([CC], ['whocares'])
AC_SUBST([EXEEXT], [''])
AC_OUTPUT
END

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = no-dependencies

check_PROGRAMS = p1
check_SCRIPTS = x1

EXTRA_PROGRAMS = p2
EXTRA_SCRIPTS = x2

bin_PROGRAMS = p3
bin_SCRIPTS = x3

noinst_PROGRAMS = p4
noinst_SCRIPTS = x4

mydir = $(prefix)
my_PROGRAMS = p5
my_SCRIPTS = x5

.PHONY: debug test
debug:
	@echo BEG: $(am__all_progs) :END
test: debug
	test '$(sort $(am__all_progs))' = 'p1 p2 p3 p4 p5'
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE test
$MAKE test EXEEXT=.exe
$MAKE test EXEEXT=.bin

:
