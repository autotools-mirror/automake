#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Use of "custom" headers (with custom suffix).

required='cc native'
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
noinst_PROGRAMS = zardoz
nodist_zardoz_SOURCES = foo.c bar.h
EXTRA_DIST = bar.my-h foo.my-c
BUILT_SOURCES = bar.h
%.c: %.my-c
	sed 's/INTEGER/int/' $< >$@
%.h: %.my-h
	sed 's/SUBSTITUTE/#define/' $< >$@
CLEANFILES = $(nodist_zardoz_SOURCES) $(BUILT_SOURCES)
END

cat > foo.my-c << 'END'
#include "bar.h"
INTEGER main (void)
{
  printf ("Hello, %s!\n", PLANET);
  return 0;
}
END

cat > bar.my-h << 'END'
#include <stdio.h>
SUBSTITUTE PLANET "Mars"
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure --enable-dependency-tracking

$MAKE
./zardoz
test "$(./zardoz)" = 'Hello, Mars!'

$sleep
$PERL -npi -e 's/\bMars\b/Jupiter/' bar.my-h

$MAKE
./zardoz
test "$(./zardoz)" = 'Hello, Jupiter!'

$MAKE distdir
test -f $distdir/foo.my-c
test -f $distdir/bar.my-h
test ! -f $distdir/foo.c
test ! -f $distdir/bar.h

$MAKE clean
test ! -f foo.c
test ! -f bar.h

$MAKE distcheck

:
