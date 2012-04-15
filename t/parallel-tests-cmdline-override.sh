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

# Check that we can use indirections when overriding TESTS from
# the command line.

am_parallel_tests=yes
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TEST_EXTENSIONS = .test .t
TEST_LOG_COMPILER = cat
T_LOG_COMPILER = cat
TESTS = bad.test
var1 = b.test $(var2)
var2 = c.test
var3 = d.d
var4 = e
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
rm -f config.log # Do not create false positives below.

cat > exp-log <<'END'
a.log
b.log
c.log
d.log
e.log
test-suite.log
END

cat > exp-out <<'END'
PASS: a.t
PASS: b.test
PASS: c.test
PASS: d.t
PASS: e.test
END

do_check ()
{
  $MAKE "$@" check >stdout || { cat stdout; Exit 1; }
  cat stdout
  grep '^PASS:' stdout | LC_ALL=C sort > got-out
  cat got-out
  ls . | grep '\.log$' | LC_ALL=C sort > got-log
  cat got-log
  st=0
  diff exp-out got-out || st=1
  diff exp-log got-log || st=1
  return $st
}

tests1='a.t $(var1) $(var3:.d=.t) $(var4:=.test)'
tests2='a $(var1:.test=) $(var3:.d=) $(var4)'

touch a.t b.test c.test d.t e.test

do_check TESTS="$tests1"
do_check TESTS="$tests2"

:
