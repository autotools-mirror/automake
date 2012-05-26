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

# Test to make sure Automake supports multiple derivations for the
# same suffix.
# From PR/37.

required='cc libtoolize'
. ./defs || Exit 1

cat >>configure.ac <<'END'
AM_PROG_AR
AM_PROG_LIBTOOL
AC_OUTPUT
END

cat >Makefile.am << 'END'
# $(LINK) is not defined automatically by Automake, since the *_SOURCES
# variables don't contain any known extension (.c, .cc, .f ...),
# So we need this hack.
LINK = :

bin_PROGRAMS = foo
lib_LTLIBRARIES = libfoo.la

foo_SOURCES = foo.x_
libfoo_la_SOURCES = bar.x_

%.y_: %.x_
	cp $< $@
%.o: %.x_
	cp $< $@
%.obj: %.x_
	cp $< $@
%.z_: %.y_
	cp $< $@
%.lo: %.z_
	cp $< $@

.PHONY: test0 test1 test2
test0:
	echo $(foo_OBJECTS) | grep '^foo\.foo$$'
	echo $(libfoo_la_OBJECTS) | grep '^bar\.lo$$'
test1:
	echo $(foo_OBJECTS) | grep '^foo\.$(OBJEXT)$$'
	echo $(libfoo_la_OBJECTS) | grep '^bar\.lo$$'
test2: $(foo_OBJECTS) $(libfoo_la_OBJECTS)
	test -f foo.$(OBJEXT)
	test -f bar.lo
check-local: test1 test2
END

echo 'int main (void) { return 0; }' > foo.x_
echo 'int bar (void) { return 0; }' > bar.x_

libtoolize
$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE test0 OBJEXT=foo

for target in test1 test2 all distcheck; do
  $MAKE $target
done

:
