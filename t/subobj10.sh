#! /bin/sh
# Copyright (C) 2006-2012 Free Software Foundation, Inc.
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

# PR 492: Test asm subdir objects.

required=gcc
. test-init.sh

cat >> configure.ac << 'END'
AM_PROG_AS
AM_PROG_AR
AC_PROG_RANLIB
AC_OUTPUT
END

cat > Makefile.am << 'END'
noinst_LIBRARIES = libfoo.a libbar.a

libfoo_a_SOURCES = src/a.s b.s
libbar_a_SOURCES = src/c.s d.s
libbar_a_CCASFLAGS =

.PHONY: test-objs
check-local: test-objs
test-objs:
	find . -name '*.$(OBJEXT)' > o.lst && cat o.lst
	test -f src/a.$(OBJEXT)
	test -f b.$(OBJEXT)
	test -f src/libbar_a-c.$(OBJEXT)
	test -f libbar_a-d.$(OBJEXT)
	test $$(wc -l <o.lst) -eq 4
	rm -f o.lst
END

mkdir src
: >src/a.s
: >b.s
: >src/c.s
: >d.s

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE
$MAKE test-objs
$MAKE distcheck

:
