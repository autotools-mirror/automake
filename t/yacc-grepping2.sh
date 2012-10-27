#! /bin/sh
# Copyright (C) 2001-2012 Free Software Foundation, Inc.
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

# Test of yacc functionality, derived from GNU binutils
# by Tim Van Holder.

. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_YACC
END

$ACLOCAL

cat > Makefile.am << 'END'
bin_PROGRAMS = maude
maude_SOURCES = sub/maude.y
END
$AUTOMAKE -a
# No rule needed, the default .y.c: inference rule is enough
# (but there may be an additional dependency on a dirstamp file).
grep '^sub/maude\.c:.*maude\.y' Makefile.in && exit 1

## Try again with per-exe flags.

cat > Makefile.am << 'END'
bin_PROGRAMS = maude
maude_SOURCES = sub/maude.y
## A particularly tricky case.
maude_YFLAGS = -d
END
$AUTOMAKE -a
grep '^sub/maude-maude\.c:.*sub/maude\.y' Makefile.in
# Rule should use maude_YFLAGS.
grep 'AM_YFLAGS.*maude' Makefile.in && exit 1
# Silly regression.
grep 'maudec' Makefile.in && exit 1
# Make sure the .o file is required.
grep '^am_maude_OBJECTS.*maude' Makefile.in

:
