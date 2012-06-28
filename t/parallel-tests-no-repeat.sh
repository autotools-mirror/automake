#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# The parallel-tests harness do not cause the same test to be
# uselessly run multiple times.

. ./defs || exit 1

echo AC_OUTPUT >> configure.ac
echo TESTS = foo.test > Makefile.am

cat > foo.test <<'END'
#! /bin/sh
ls -l && mkdir bar
END
chmod a+x foo.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE -j1 check || { cat test-suite.log; exit 1; }
rmdir bar
$MAKE -j2 check || { cat test-suite.log; exit 1; }
rmdir bar
$MAKE -j4 check || { cat test-suite.log; exit 1; }

:
