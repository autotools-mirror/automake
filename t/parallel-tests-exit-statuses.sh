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

# Check parallel-tests features: normal and special exit statuses
# in the test scripts.

. test-init.sh

cat >> configure.ac << 'END'
AC_OUTPUT
END

# $failure_statuses should be defined to the list of all integers between
# 1 and 255 (inclusive), excluded 77 and 99.
failure_statuses=$(seq_ 1 255 | $EGREP -v '^(77|99)$' | tr "$nl" ' ')
# For debugging.
echo "failure_statuses: $failure_statuses"
# Sanity check.
test $(for st in $failure_statuses; do echo $st; done | wc -l) -eq 253 \
  || fatal_ "initializing list of exit statuses for simple failures"

cat > Makefile.am <<END
LOG_COMPILER = $AM_TEST_RUNNER_SHELL ./do-exit
fail_tests = $failure_statuses
TESTS = 0 77 99 $failure_statuses
\$(TESTS):
END

cat > do-exit <<'END'
#!/bin/sh
echo "$0: $1"
case $1 in
  [0-9]|[0-9][0-9]|[0-9][0-9][0-9]) st=$1;;
  */[0-9]|*/[0-9][0-9]|*/[0-9][0-9][0-9]) st=${1##*/};;
  *) st=99;;
esac
exit $st
END
chmod a+x do-exit

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

{
  echo PASS: 0
  echo SKIP: 77
  echo ERROR: 99
  for st in $failure_statuses; do
    echo "FAIL: $st"
  done
} | LC_ALL=C sort > exp-fail

sed 's/^FAIL:/XFAIL:/' exp-fail | LC_ALL=C sort > exp-xfail-1
sed '/^ERROR:/d' exp-xfail-1 > exp-xfail-2

sort exp-fail
sort exp-xfail-1
sort exp-xfail-2

./configure

st=1
$MAKE check >stdout && st=0
cat stdout
cat test-suite.log
test $st -gt 0 || exit 1
LC_ALL=C grep '^[A-Z][A-Z]*:' stdout | LC_ALL=C sort > got-fail
diff exp-fail got-fail

st=1
XFAIL_TESTS="$failure_statuses 99" $MAKE -e check >stdout && st=0
cat stdout
cat test-suite.log
test $st -gt 0 || exit 1
LC_ALL=C grep '^[A-Z][A-Z]*:' stdout | LC_ALL=C sort > got-xfail-1
diff exp-xfail-1 got-xfail-1

st=0
XFAIL_TESTS="$failure_statuses" TESTS="0 77 $failure_statuses" \
  $MAKE -e check >stdout || st=$?
cat stdout
cat test-suite.log
test $st -eq 0 || exit 1
LC_ALL=C grep '^[A-Z][A-Z]*:' stdout | LC_ALL=C sort > got-xfail-2
diff exp-xfail-2 got-xfail-2

:
