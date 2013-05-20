#! /bin/sh
# Copyright (C) 1999-2013 Free Software Foundation, Inc.
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

# Test to make sure that suffix rules chain.

required=c++
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CXX
AC_OUTPUT
END

cat > Makefile.am << 'END'
%.cc: %.zoo
	sed 's/INTEGER/int/g' $< >$@
bin_PROGRAMS = zardoz
nodist_zardoz_SOURCES = foo.cc
EXTRA_DIST = foo.zoo
CLEANFILES = foo.cc
END

$ACLOCAL
$AUTOMAKE

# Automake has been clearly told that foo.zoo is eventually transformed
# into foo.o, and to use this latter file (to link foo).
$FGREP 'foo.$(OBJEXT)' Makefile.in
# Finally, our dummy package doesn't use C in any way, so it the
# Makefile shouldn't contain stuff related to the C compiler.
$FGREP '$(LINK)'   Makefile.in && exit 1
$FGREP 'AM_CFLAGS' Makefile.in && exit 1
$FGREP '$(CFLAGS)' Makefile.in && exit 1
$FGREP '$(CC)'     Makefile.in && exit 1

$AUTOCONF
./configure

# This is deliberately valid C++, but invalid C.
cat > foo.zoo <<'END'
using namespace std;
INTEGER main (void)
{
  return 0;
}
END

$MAKE all
$MAKE distcheck

# Intermediate files should not be distributed.
$MAKE distdir
test ! -e $me-1.0/foo.cc

:
