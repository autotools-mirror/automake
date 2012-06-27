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

# Check support for:
#   - MOSTLYCLEANFILES
#   - CLEANFILES
#   - DISTCLEANFILES
#   - MAINTAINERCLEANFILES
# Especially checks that it is possible to extend them also from a
# "wrapper" makefile never processed nor seen by Automake.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

setup () { touch mostly plain dist maint mostly2 plain2 dist2 maint2; }

cat > Makefile.am << 'END'
MOSTLYCLEANFILES = mostly
CLEANFILES = plain
DISTCLEANFILES = dist
MAINTAINERCLEANFILES = maint
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

cat > GNUmakefile << 'END'
include Makefile
MOSTLYCLEANFILES += mostly2
CLEANFILES += plain2
DISTCLEANFILES += dist2
MAINTAINERCLEANFILES += maint2
END

./configure
cp config.status config.sav # Save for later.

setup
$MAKE mostlyclean
test ! -f mostly
test ! -f mostly2
test -f plain
test -f plain2
test -f dist
test -f dist2
test -f maint
test -f maint2

setup
$MAKE clean
test ! -f mostly
test ! -f mostly2
test ! -f plain
test ! -f plain2
test -f dist
test -f dist2
test -f maint
test -f maint2

setup
$MAKE distclean
test ! -f mostly
test ! -f mostly2
test ! -f plain
test ! -f plain2
test ! -f dist
test ! -f dist2
test -f maint
test -f maint2

setup
# The "make distclean" before has removed Makefile and config.status.
mv config.sav config.status
./config.status Makefile
$MAKE maintainer-clean
test ! -f mostly
test ! -f mostly2
test ! -f plain
test ! -f plain2
test ! -f dist
test ! -f dist2
test ! -f maint
test ! -f maint2

:
