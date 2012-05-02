#! /bin/sh
# Copyright (C) 2004-2012 Free Software Foundation, Inc.
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

# Make sure distclean works in cygnus mode.
# Report from Daniel Jacobowitz.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AM_MAINTAINER_MODE
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub

data_DATA = bar

bar:
	touch $@

DISTCLEANFILES = bar
END

mkdir sub

cat > sub/Makefile.am << 'END'
data_DATA = foo

foo:
	touch $@

CLEANFILES = $(data_DATA)
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --cygnus -Wno-obsolete

./configure
$MAKE
ls -l
test -f bar
test -f sub/foo
$MAKE distclean
ls -l
test ! -r bar
test ! -r sub/foo
test ! -r Makefile
test ! -r config.status
test -f Makefile.in
test -f configure

:
