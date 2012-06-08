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

# Test of subdir objects with libtool.

required='cc libtoolize'
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_AR
AC_PROG_LIBTOOL
AC_OUTPUT
END

cat > Makefile.am << 'END'
noinst_LTLIBRARIES = libs/libfoo.la
libs_libfoo_la_SOURCES = generic/1.c generic/2.c sub/subsub/3.c

.PHONY: remake-single-object
remake-single-object:
	rm -rf generic
	$(MAKE) generic/1.lo
	test -f generic/1.lo
	test ! -f generic/2.lo
	rm -rf generic
	$(MAKE) generic/2.lo
	test ! -f generic/1.lo
	test -f generic/2.lo
	rm -rf sub generic
	$(MAKE) sub/subsub/3.lo
	test -f sub/subsub/3.lo
	test ! -d generic
END

mkdir generic sub sub/subsub
echo 'int one (void) { return 1; }' > generic/1.c
echo 'int two (void) { return 2; }' > generic/2.c
echo 'int three (void) { return 3; }' > sub/subsub/3.c

libtoolize
$ACLOCAL

$AUTOMAKE --add-missing 2>stderr || { cat stderr >&2; Exit 1; }
cat stderr >&2

# Make sure compile is installed, and that Automake says so.
grep 'install.*compile' stderr
test -f compile

grep '[^/][123]\.lo' Makefile.in && Exit 1

$AUTOCONF

mkdir build
cd build
../configure
$MAKE

test -d libs
test -d generic
test -d sub/subsub

# The libraries and executables are not uselessly remade.
: > xstamp
$sleep
echo dummy > libs/change-dir-timestamp
echo dummy > generic/change-dir-timestamp
echo dummy > sub/change-dir-timestamp
echo dummy > sub/subsub/change-dir-timestamp
$MAKE
is_newest xstamp libs/libfoo.la

$MAKE remake-single-object

# VPATH builds must work also with dependency tracking disabled.
# Also sanity check the distribution.
$MAKE distcheck DISTCHECK_CONFIGURE_FLAGS=--disable-dependency-tracking

:
