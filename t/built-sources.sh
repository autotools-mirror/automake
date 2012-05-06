#! /bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Basic test on BUILT_SOURCES.

required=cc
. ./defs || Exit 1

cat >> configure.ac <<'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
BUILT_SOURCES = foo.c
noinst_PROGRAMS = bar baz
foo.c:
	rm -f $@ $@-t
	echo '#include <stdio.h>'               >  $@-t
	echo 'int main (void)'                  >> $@-t
	echo '{               '                 >> $@-t
	echo '  printf ("%s\n", FOOMSG);'       >> $@-t
	echo '  return 0;'                      >> $@-t
	echo '}'                                >> $@-t
	mv -f $@-t $@
CLEANFILES = foo.c
END

cat > bar.c <<'END'
#define FOOMSG "Howdy, World"
#include "foo.c"
END

cat > baz.c <<'END'
#define FOOMSG "Hello, Earth"
#include "foo.c"
END

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure
$MAKE
if cross_compiling; then :; else
  ./bar
  ./bar | grep 'Howdy, World'
  ./baz
  ./baz | grep 'Hello, Earth'
fi
$MAKE distcheck

:
