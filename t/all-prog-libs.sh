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

# Test internal automake variables:
#  - $(am.all-progs).
#  - $(am__all_libs).
#  - $(am__all_ltlibs).

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_SUBST([CC], [who-cares])
m4_define([AM_PROG_AR], [AC_SUBST([AR], [who-cares])])
AM_PROG_AR
AC_SUBST([RANLIB], [who-cares])
AC_SUBST([LIBTOOL], [who-cares])
AC_SUBST([EXEEXT], [''])
AC_OUTPUT
END

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = no-dependencies

check_PROGRAMS = p1
check_LIBRARIES = lib01.a
check_LTLIBRARIES = lib1.la
check_SCRIPTS = x1

EXTRA_PROGRAMS = p2
EXTRA_LIBRARIES = lib02.a
EXTRA_LTLIBRARIES = lib2.la
EXTRA_SCRIPTS = x2

bin_PROGRAMS = p3
lib_LIBRARIES = lib03.a
lib_LTLIBRARIES = lib3.la
bin_SCRIPTS = x3

noinst_PROGRAMS = p4
noinst_LIBRARIES = lib04.a
noinst_LTLIBRARIES = lib4.la
noinst_SCRIPTS = x4

mydir = $(prefix)
my_PROGRAMS = p5
my_LIBRARIES = lib05.a
my_LTLIBRARIES = lib5.la
my_SCRIPTS = x5

.PHONY: debug test
debug:
	@echo  PROGS-BEG:  $(am.all-progs)   :PROGS-END
	@echo   LIBS-BEG:  $(am__all_libs)    :LIBS-END
	@echo LTLIBS-BEG:  $(am__all_ltlibs)  :LTLIBS-END
test: debug
	test '$(am.all-progs)'  = 'p1 p2 p3 p4 p5'
	test '$(am__all_libs)'   = 'lib01.a lib02.a lib03.a lib04.a lib05.a'
	test '$(am__all_ltlibs)' = 'lib1.la lib2.la lib3.la lib4.la lib5.la'
END

: > ltmain.sh

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure
$MAKE test
$MAKE test EXEEXT=.exe
$MAKE test EXEEXT=.bin

:
