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

# Test TESTS = $(check_PROGRAMS)

# For gen-testsuite-part: ==> try-with-serial-tests <==
required='cc native'
. ./defs || exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
check_PROGRAMS = one two
TESTS = $(check_PROGRAMS)
check-local:
	test -f one$(EXEEXT)
	test -f two$(EXEEXT)
	touch ok
prepare-for-fake-exeext:
	rm -f ok
	mv -f one$(EXEEXT) one.bin
	mv -f two$(EXEEXT) two.bin
post-check-for-fake-exeext:
	test -f ok
	test ! -f one$(EXEEXT)
	test ! -f two$(EXEEXT)
.PHONY: prepare-for-fake-exeext post-check-for-fake-exeext
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

cat > one.c << 'END'
int main (void)
{
  return 0;
}
END
cp one.c two.c

./configure

$MAKE check
test -f ok

$MAKE prepare-for-fake-exeext
$MAKE check EXEEXT=.bin
$MAKE post-check-for-fake-exeext

# No TESTS rewriting has taken place.
grep '^TESTS = \$(check_PROGRAMS)$' Makefile.in

:
