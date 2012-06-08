#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
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

# Test of compiled java.

required='gcc gcj'
. ./defs || Exit 1

cat >> configure.ac << 'END'
# FIXME: AM_PROG_GCJ should cause OBJEXT and EXEEXT to be set, but
# FIXME: it currently does not.  See also xfailing test 'gcj6.sh'.
AC_PROG_CC
AM_PROG_GCJ
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = convert
convert_SOURCES = $(my-java-source)
convert_LDFLAGS = --main=convert
my-java-source = x/y/convert.java
$(my-java-source):
	rm -f $@-t $@
	test -d $(@D) || $(MKDIR_P) $(@D)
	echo 'public class convert {'                      >> $@-t
	echo '  public static void main (String[] args) {' >> $@-t
	echo '    System.out.println("Hello, World!");'    >> $@-t
	echo '  }'                                         >> $@-t
	echo '}'                                           >> $@-t
	chmod a-w $@-t && mv -f $@-t $@
.PHONY: test-obj
check-local: test-obj
test-obj:
	test -f x/y/convert.$(OBJEXT)
END

$ACLOCAL
$AUTOMAKE
$FGREP 'x/y/convert.$(OBJEXT)' Makefile.in

$AUTOCONF
./configure

$MAKE
$MAKE test-obj
if ! cross_compiling; then
  ./convert
  test "$(./convert)" = 'Hello, World!'
fi
$MAKE distcheck

:
