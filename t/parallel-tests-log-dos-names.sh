#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# The parallel test harness must not create files with two dots in their
# names, such as 'test-suite.log.tmp': DOS without long file names, e.g.
# FreeDOS with DJGPP, cannot create them.

. test-init.sh

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = foo.test
END

cat > foo.test << 'END'
#! /bin/sh
exit 0
END
chmod a+x foo.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

grep 'TEST_SUITE_LOG)\.' Makefile.in && exit 1

./configure
$MAKE check
test -f test-suite.log
test ! -e test-suite.tmp

# A user-chosen name for the global log works the same way.
run_make check TEST_SUITE_LOG=mysuite.log
test -f mysuite.log
test ! -e mysuite.tmp
grep '^# PASS: *1$' mysuite.log

:
