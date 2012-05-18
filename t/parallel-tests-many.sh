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

# Check that the parallel-tests harness does not hit errors due to
# an exceeded command line length when there are many tests.
# For automake bug#7868.  This test is currently expected to fail.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am <<'END'
# Sanity check that the $(TESTS) is going to exceed the system
# command line length.
# Extra quoting and indirections below are required to ensure the
# various make implementations (e.g, GNU make or Sun Distributed Make)
# will truly spawn a shell to execute this command, instead of relying
# on optimizations that might mask the "Argument list too long" error
# we expect.
this-will-fail:
	@":" && ":" $(TEST_LOGS)
TEST_LOG_COMPILER = true
include list-of-tests.am
# So that we won't have to create a ton of dummy test cases.
$(TESTS):
END

# The real instance will be dynamically created later.
echo TESTS = foo.test > list-of-tests.am

$ACLOCAL && $AUTOCONF && $AUTOMAKE -a \
  || framework_failure_ "unexpected autotools failure"
./configure \
  || framework_failure_ "unexpected configure failure"

# We want to hit the system command-line length limit without hitting
# the filename length limit or the PATHMAX limit; so we use longish
# (but not too long) names for the testcase, and place them in a nested
# (but not too deeply) directory.
# We also prefer to use the minimal(ish) number of test cases that can
# make us hit the command-line length limit, since the more the test
# cases are, the more time "automake" and "make check" will take to run
# (especially on Cygwin and MinGW/MSYS).

tname="wow-this-is-a-very-long-name-for-a-simple-dummy-test-case"
dname="and-this-too-is-a-very-long-name-for-a-dummy-directory"

deepdir=.
depth=0
for i in 1 2 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18 19 29 21 22 23 24; do
  new_deepdir=$deepdir/$dname.d$i
  mkdir $new_deepdir || break
  tmpfile=$new_deepdir/$tname-some-more-chars-for-good-measure
  if touch $tmpfile; then
    rm -f $tmpfile || Exit 99
  else
    rmdir $new_deepdir || Exit 99
  fi
  deepdir=$new_deepdir
  unset tmpfile new_deepdir
  depth=$i
done

cat <<END
*********************************************************************
Our tests will be in the following directory (depth = $depth)
*********************************************************************
$deepdir
*********************************************************************
END

setup_data ()
{
  # Use perl, not awk, to avoid errors like "awk: string too long"
  # (seen e.g. with Solaris 10 /usr/bin/awk).
  count=$count deepdir=$deepdir tname=$tname $PERL -e '
    use warnings FATAL => "all";
    use strict;
    print "TESTS = \\\n";
    my $i = 0;
    while (++$i)
      {
        print "  $ENV{deepdir}/$ENV{tname}-$i.test";
        if ($i >= $ENV{count})
          {
            print "\n";
            last;
          }
        else
          {
            print " \\\n";
          }
      }
  ' > list-of-tests.am || Exit 99
  sed 20q list-of-tests.am || Exit 99 # For debugging.
  $AUTOMAKE Makefile \
    || framework_failure_ "unexpected automake failure"
  ./config.status Makefile \
    || framework_failure_ "unexpected config.status failure"
}

for count in 1 2 4 8 12 16 20 24 28 32 48 64 96 128 E_HUGE; do
  test $count = E_HUGE && break
  count=`expr $count '*' 100` || Exit 99
  setup_data
  if $MAKE this-will-fail; then
    continue
  else
    # We have managed to find a number of test cases large enough to
    # hit the system command-line limits; we can stop.  But first, for
    # good measure, increase the number of tests of some 20%, to be
    # "even more sure" of really tickling command line length limits.
    count=`expr '(' $count '*' 12 ')' / 10` || Exit 99
    setup_data
    break
  fi
done

if test $count = E_HUGE; then
  framework_failure_ "system has a too-high limit on command line length"
else
  cat <<END
*********************************************************************
               Number of tests we will use: $count
*********************************************************************
END
fi

env TESTS=$deepdir/$tname-1.test $MAKE -e check \
  && test -f $deepdir/$tname-1.log \
  || framework_failure_ "\"make check\" with one single tests"

rm -f $deepdir/* || Exit 99

$MAKE check > stdout || { cat stdout; Exit 1; }
cat stdout

grep "^# TOTAL: $count$" stdout
grep "^# PASS:  $count$" stdout

grep "^PASS: .*$tname-[0-9][0-9]*\.test" stdout > grp
ls -1 $deepdir | grep '\.log$' > lst

sed 20q lst # For debugging.
sed 20q grp # Likewise.

test `cat <grp | wc -l` -eq $count
test `cat <lst | wc -l` -eq $count

# We need to simulate a failure of two tests.
st=0
env TESTS="$deepdir/$tname-1.test $deepdir/$tname-2.test" \
    TEST_LOG_COMPILER=false $MAKE -e check > stdout && st=1
cat stdout
test `grep -c '^FAIL:' stdout` -eq 2 || st=1
test $st -eq 0 || fatal_ "couldn't simulate failure of two tests"
unset st

$MAKE recheck > stdout || { cat stdout; Exit 1; }
cat stdout
grep "^PASS: .*$tname-1\.test" stdout
grep "^PASS: .*$tname-2\.test" stdout
test `LC_ALL=C grep -c "^[A-Z][A-Z]*:" stdout` -eq 2
grep "^# TOTAL: 2$" stdout
grep "^# PASS:  2$" stdout

# "make clean" might ignore some failures, so we prefer to also grep its
# output to ensure that no "Argument list too long" error was encountered.
$MAKE clean >output 2>&1 || { cat output; Exit 1; }
cat output
grep -i 'list.* too long' output && Exit 1
ls $deepdir | grep '\.log$' && Exit 1

:
