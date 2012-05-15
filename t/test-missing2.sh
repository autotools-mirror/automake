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

# parallel-tests:
#  - non-existent scripts listed in TESTS get diagnosed, even when
#    all the $(TEST_LOGS) have a dummy dependency.
# See also related test 'test-missing.test'.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = foobar1.test foobar2.test
$(TEST_LOGS):
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE foobar1.log foobar2.log || Exit 99
test ! -f foobar1.log || Exit 99
test ! -f foobar1.trs || Exit 99
test ! -f foobar2.log || Exit 99
test ! -f foobar2.trs || Exit 99

$MAKE check >output 2>&1 && { cat output; Exit 1; }
cat output
grep 'test-suite\.log.*foobar1\.log' output
grep 'test-suite\.log.*foobar1\.trs' output
grep 'test-suite\.log.*foobar2\.log' output
grep 'test-suite\.log.*foobar2\.trs' output
test ! -f test-suite.log

:
