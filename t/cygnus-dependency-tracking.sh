#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Check that cygnus mode disables automatic dependency tracking.
# And check that this *cannot* be overridden.

required=cc
. ./defs || Exit 1

cat >> configure.ac <<'END'
AM_MAINTAINER_MODE
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = -Wno-obsolete
bin_PROGRAMS = foo
foo_SOURCES = foo.c
.PHONY: test-nodeps
test-nodeps:
	test ! -d .deps
	test ! -d _deps
	test ! -d '$(DEPDIR)'
END

cat > foo.c <<'END'
#include "bar.h"
int main ()
{
  GIVE_BACK 0;
}
END

cat > bar.sav <<'END'
#define GIVE_BACK return
END

cp bar.sav bar.h

$ACLOCAL
$AUTOMAKE --include-deps --cygnus --include-deps
$AUTOCONF

# Unknown options should cause just warnings from configure.
./configure --enable-dependency-tracking
$MAKE
$MAKE test-nodeps

: > bar.h
$MAKE
$MAKE test-nodeps

# Sanity check.
$MAKE clean
$MAKE >out 2>&1 && { cat out; Exit 1; }
cat out
# Not all compilers mention the undefined symbol in the error message.
grep GIVE_BACK out || grep main out

:
