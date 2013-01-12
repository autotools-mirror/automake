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

# Test of subdir objects with C.

. test-init.sh

echo AC_PROG_CC >> configure.ac

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = wish
wish_SOURCES = generic/a.c generic/b.c
END

$ACLOCAL
rm -f compile
$AUTOMAKE --add-missing 2>stderr || { cat stderr >&2; exit 1; }
cat stderr >&2
# Make sure compile is installed, and that Automake says so.
grep '^configure\.ac:4:.*install.*compile' stderr
test -f compile

grep '^generic/a\.\$(OBJEXT):' Makefile.in
grep '[^/]a\.\$(OBJEXT)' Makefile.in && exit 1

# Opportunistically test for a different bug.
grep '^generic/b\.\$(OBJEXT):.*dirstamp' Makefile.in

:
