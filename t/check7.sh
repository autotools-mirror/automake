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

# Check EXEEXT extension for XFAIL_TESTS.

# For gen-testsuite-part: ==> try-with-serial-tests <==
required=cc
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = $(XFAIL_TESTS)
XFAIL_TESTS = a b c d
check_PROGRAMS = a c d
check_SCRIPTS = b
EXTRA_PROGRAMS = new old
EXTRA_DIST = $(check_SCRIPTS)

prepare-for-fake-exeext:
	rm -f out.new out.old
	touch a.fake c.fake d.fake
	mv -f new$(EXEEXT) new.fake
	mv -f old$(EXEEXT) old.fake
post-check-for-fake-exeext:
	test -f new.fake
	test -f old.fake
	test ! -f new
	test ! -f new$(EXEEXT)
	test ! -f old
	test ! -f old$(EXEEXT)
.PHONY: prepare-for-fake-exeext post-check-for-fake-exeext
END

cat > b <<'END'
#! /bin/sh
exit 1
END
chmod a+x b

cat > a.c <<'END'
#include <stdlib.h>
int main (void)
{
  return EXIT_FAILURE;
}
END

cp a.c c.c
cp a.c d.c

cat > new.c <<'END'
#include <stdio.h>
int main (void)
{
  FILE *fp = fopen ("out.new", "w");
  fprintf (fp, "%s!\n", "Hello, Brave New World");
  return (fclose (fp) != 0);
}
END

cat > old.c <<'END'
#include <stdio.h>
int main (void)
{
  FILE *fp = fopen ("out.old", "w");
  fprintf (fp, "%s!\n", "Hello, Europe");
  return (fclose (fp) == 0);
}
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE check

$MAKE check TESTS='old new' XFAIL_TESTS=old
grep 'Hello, Brave New World!' out.new
grep 'Hello, Europe!' out.old

$MAKE prepare-for-fake-exeext
$MAKE check TESTS='old new' EXEEXT=.fake XFAIL_TESTS=old
$MAKE post-check-for-fake-exeext
grep 'Hello, Brave New World!' out.new
grep 'Hello, Europe!' out.old

$MAKE distcheck

:
