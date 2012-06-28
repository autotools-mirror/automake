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

# The parallel-tests driver should be able to cope with test scripts
# whose names end with several concatenated suffixes.

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

tests='foo.sh foo.t.sh foo.sh.t foo.x.x foo.x.t.sh foo.t.x.sh foo.sh.t.x'

for t in $tests; do
  (echo '#!/bin/sh' && echo 'echo == /$0 ==') > $t
  chmod a+x $t
done

cat > Makefile.am <<END
TEST_EXTENSIONS = .t .sh .x
TESTS = $tests
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

for j in '' -j4; do

  # Use append mode here to avoid dropping output.  See automake bug#11413.
  # Also, use 'echo' here to "nullify" the previous contents of 'stdout',
  # since Solaris 10 /bin/sh would try to optimize a ':' away after the
  # first iteration, even if it is redirected.
  echo " " >stdout
  $MAKE $j check >>stdout || { cat stdout; exit 1; }
  cat stdout
  count_test_results total=7 pass=7 fail=0 skip=0 xfail=0 xpass=0 error=0
  for t in $tests; do grep "^PASS: $t *$" stdout; done

  grep '== .*/foo\.sh =='       foo.log
  grep '== .*/foo\.t\.sh =='    foo.t.log
  grep '== .*/foo\.sh\.t =='    foo.sh.log
  grep '== .*/foo\.x\.x =='     foo.x.log
  grep '== .*/foo\.x\.t\.sh ==' foo.x.t.log
  grep '== .*/foo\.t\.x\.sh ==' foo.t.x.log
  grep '== .*/foo\.sh\.t\.x ==' foo.sh.t.log

  $MAKE $j clean
  test ! -f foo.log
  test ! -f foo.t.log
  test ! -f foo.sh.log
  test ! -f foo.x.log
  test ! -f foo.x.t.log
  test ! -f foo.t.x.log
  test ! -f foo.sh.t.log

done

:
