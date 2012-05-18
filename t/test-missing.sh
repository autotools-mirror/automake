#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# parallel-tests: non-existent scripts listed in TESTS get diagnosed.

am_parallel_tests=yes
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = ok.test zardoz.test
TEST_LOG_COMPILER = true
END

: > ok.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE check >stdout 2>stderr && { cat stdout; cat stderr >&2; Exit 1; }
cat stdout; cat stderr >&2
test -f ok.log
grep '^PASS: ok\.test' stdout
$FGREP 'zardoz.log' stderr
test ! -f test-suite.log

$MAKE TESTS='zardoz2.test' check 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr
$FGREP 'zardoz2.log' stderr
test ! -f test-suite.log

$MAKE TESTS='zardoz3' check 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
$FGREP 'zardoz3.log' stderr
test ! -f test-suite.log

# The errors should persist even after 'test-suite.log'
# has been created.

: > zardoz.test
$MAKE check
rm -f zardoz.test

$MAKE check 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
$FGREP 'zardoz.log' stderr
test ! -f test-suite.log

:
