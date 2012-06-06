#! /bin/sh
# Copyright (C) 1996-2012 Free Software Foundation, Inc.
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

# Test to make sure misspellings in _LDADD variable cause failure.

required=cc
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = zardoz
zardoz_SOURCES = x.c
qardoz_LDADD = -lm
END

echo 'int main (void) { return 0; }' > x.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

$MAKE 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2

LC_ALL=C sed 's/^Makefile:[0-9][0-9]*: //' stderr > got

cat > exp << 'END'
variable 'qardoz_LDADD' is defined but no program
  or library has 'qardoz' as canonical name
*** Some Automake-NG error occurred.  Stop.
END

diff exp got

:
