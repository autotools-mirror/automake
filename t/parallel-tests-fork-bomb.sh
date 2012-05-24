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

# Check parallel-tests features:
#  - If $(TEST_SUITE_LOG) is in $(TEST_LOGS), we get a diagnosed
#    error, not a make hang or a system freeze.

. ./defs || Exit 1

# We don't want localized error messages from make, since we'll have
# to grep them.  See automake bug#11452.
LANG=C LANGUAGE=C LC_ALL=C
export LANG LANGUAGE LC_ALL

# The tricky part of this test is to avoid that make hangs or even
# freezes the system in case infinite recursion (which is the bug we
# are testing against) is encountered.  The following hacky makefile
# should minimize the probability of that happening.
cat > Makefile.am << 'END'
TEST_LOG_COMPILER = true
TESTS =

errmsg = ::OOPS:: Recursion too deep

is_too_deep := $(shell test $(MAKELEVEL) -lt 10 && echo no)

## Extra indentation here required to avoid confusing Automake.
## FIXME: now that we assume make is GNU make, this shouldn't happen!
 ifeq ($(is_too_deep),no)
   # All is ok.
 else
   $(error $(errmsg), $(MAKELEVEL) levels)
 endif
END

echo AC_OUTPUT >> configure.ac

# Another helpful idiom to avoid hanging on capable systems.  The subshell
# is needed since 'ulimit' might be a special shell builtin.
if (ulimit -t 8); then ulimit -t 8; fi

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

do_check ()
{
  st=0
  log=$1; shift
  $MAKE "$@" check >output 2>&1 || st=$?
  cat output
  $FGREP '::OOPS::' output && Exit 1 # Possible infinite recursion.
  grep "[Cc]ircular.*dependency" output | $FGREP "$log"
  grep "$log:.*depends on itself" output
  test $st -gt 0
}

: > test-suite.test
do_check test-suite.log TESTS=test-suite.test
rm -f *.log *.test

: > 0.test
: > 1.test
: > 2.test
: > 3.test
: > foobar.test
do_check foobar.log TESTS='0 1 foobar 2 3' TEST_SUITE_LOG=foobar.log
rm -f *.log *.test

:
