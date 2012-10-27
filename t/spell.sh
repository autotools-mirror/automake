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

# Test to make sure misspellings in _SOURCES variables cause failure.

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = zardoz foo
zardoz_SOURCES = x.c
boo_SOURCES = y.c
END

echo 'int main (void) { return 0; }' > x.c
echo 'int main (void) { return 0; }' > y.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2

LC_ALL=C sed -e 's|^Makefile:[0-9][0-9]*: ||' \
             -e 's|.*\.mk:[0-9][0-9]*: ||' \
             -e '/^\*\*\*.*Automake-NG/d' stderr > got

cat > exp << 'END'
variable 'boo_SOURCES' is defined but no program
  or library has 'boo' as canonical name
END

diff exp got

:
