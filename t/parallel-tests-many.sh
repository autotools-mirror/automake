#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Check that the parallel testsuite harness does not hit errors due
# to an exceeded command line length when there are many tests.
# For automake bug#7868.

. test-init.sh

expensive_

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
TEST_EXTENSIONS = .test .sh
LOG_COMPILER = true
TEST_LOG_COMPILER = $(LOG_COMPILER)
SH_LOG_COMPILER = $(LOG_COMPILER)
EXTRA_DIST = $(TESTS)
END

tst='a-test-script-with-a-long-name'
dir1='a-directory-with-a-long-name'
dir2='another-long-named-directory'

list_logs ()
{
  find . -name '*.log' | $EGREP -v '^\./(config|test-suite)\.log$'
}

# Number of test scripts will be 3 * $count.
count=10000

i=1
while test $i -le $count; do
  files="
    $tst-$i.test
    $dir1-$i/foo.sh
    $dir2-$i/$tst-$i
  "
  mkdir $dir1-$i $dir2-$i
  for f in $files; do
    : > $f
    echo $f
  done
  i=$(($i + 1))
  # Disable shell traces after the first iteration, to avoid
  # polluting the test logs.
  set +x
done > t
set -x # Re-enable shell traces.
echo 'TESTS = \'   >> Makefile.am
sed '$!s/$/ \\/' t >> Makefile.am
rm -f t

whole_count=$(($count * 3))

test $(wc -l <Makefile.am) -eq $((6 + $whole_count)) \
  || fatal_ "populating 'TESTS'"

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure

run_make -O check

grep "^# TOTAL: $whole_count$" stdout
grep "^# PASS:  $whole_count$" stdout

# Only check head, tail, and a random sample.

test -f $tst-1.log
test -f $dir1-1/foo.log
test -f $dir2-1/$tst-1.log

test -f $tst-$count.log
test -f $dir1-$count/foo.log
test -f $dir2-$count/$tst-$count.log

test -f $tst-163.log
grep "^PASS: $tst-163\.test$" stdout
test -f $dir1-7645/foo.log
grep "^PASS: $dir1-7645/foo.sh$" stdout
test -f $dir2-4077/$tst-4077.log
grep "^PASS: $dir2-4077/$tst-4077$" stdout

grep "^PASS: " stdout > grp
list_logs > lst

sed 20q lst # For debugging.
sed 20q grp # Likewise.

test $(wc -l <grp) -eq $whole_count
test $(wc -l <lst) -eq $whole_count

check_three_reruns ()
{
  grep "^PASS: $tst-1\.test$" stdout
  grep "^PASS: $dir1-1/foo\.sh$" stdout
  grep "^PASS: $dir2-1/$tst-1$" stdout
  test $(LC_ALL=C grep -c "^[A-Z][A-Z]*:" stdout) -eq 3
}

$sleep
touch $tst-1.test $dir1-1/foo.sh $dir2-1/$tst-1
run_make -O check AM_LAZY_CHECK=yes
check_three_reruns
grep "^# TOTAL: $whole_count$" stdout
grep "^# PASS:  $whole_count$" stdout

# We need to simulate the failure of few tests.
run_make -O -e FAIL check \
         TESTS="$tst-1.test $dir1-1/foo.sh $dir2-1/$tst-1" \
         LOG_COMPILER=false \
  && test $(grep -c '^FAIL:' stdout) -eq 3 \
  || fatal_ "couldn't simulate failure of 3 tests"

run_make -O recheck
check_three_reruns
grep "^# TOTAL: 3$" stdout
grep "^# PASS:  3$" stdout

# We need to simulate the failure of a lot of tests.
run_make -O -e FAIL check LOG_COMPILER=false
grep '^PASS:' stdout && exit 1
# A random sample.
grep "^FAIL: $tst-363\.test$" stdout
grep "^FAIL: $dir1-9123/foo.sh$" stdout
grep "^FAIL: $dir2-3609/$tst-3609$" stdout

grep "^FAIL: " stdout > grp
sed 20q grp # For debugging.
test $(wc -l <grp) -eq $whole_count

run_make -O recheck
grep '^FAIL:' stdout && exit 1
# A random sample.
grep "^PASS: $tst-363\.test$" stdout
grep "^PASS: $dir1-9123/foo.sh$" stdout
grep "^PASS: $dir2-3609/$tst-3609$" stdout

grep "^PASS: " stdout > grp
sed 20q grp # For debugging.
test $(wc -l <grp) -eq $whole_count
grep "^# TOTAL: $whole_count$" stdout
grep "^# PASS:  $whole_count$" stdout

# "make clean" might ignore some failures (either on purpose or spuriously),
# so we prefer to also grep its output to ensure that no "Argument list too
# long" error was encountered.
run_make -M clean
grep -i 'list.* too long' output && exit 1
list_logs | grep . && exit 1

:
