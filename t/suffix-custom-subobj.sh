#! /bin/sh
# Copyright (C) 2002-2012 Free Software Foundation, Inc.
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

# Tests that pattern rules with subdir objects are understood.
# Originally reported by John Ratliff against suffix rules.

required=cc
. ./defs || exit 1

cat >>configure.ac <<EOF
AC_PROG_CC
AC_OUTPUT
EOF

cat >Makefile.am << 'END'
# We fake here:
%.o: %.baz
	cp $< $@

bin_PROGRAMS = foo
foo_SOURCES = foo.c sub/bar.baz

.PHONY: test-fake test-real
test-fake:
	echo $(foo_OBJECTS) | grep '^foo\.quux sub/bar\.quux$$'
test-real:
	echo $(foo_OBJECTS) | grep '^foo\.$(OBJEXT) sub/bar\.$(OBJEXT)$$'
END

mkdir sub
: > sub/bar.baz
: > foo.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE test-fake OBJEXT=quux
$MAKE test-real

:
