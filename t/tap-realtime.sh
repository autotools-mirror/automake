#! /bin/sh
# Copyright (C) 2011-2013 Free Software Foundation, Inc.
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

# TAP support:
#  - testsuite progress on console should happen mostly "in real time";
#    i.e., it's not acceptable for the driver to wait the end of the
#    script to start displaying results from it.
# FIXME: this test uses expect(1) to ensure line buffering from make and
# children, and is pretty hacky and complex; is there a better way to
# accomplish the checks done here?

. test-init.sh

cat >expect-check <<'END'
eval spawn $env(SHELL) -c ":"
expect eof
END
expect -f expect-check || {
    echo "$me: failed to find a working expect program" >&2
    exit 77
}
rm -f expect-check

# Unfortunately, some make implementations (among them, FreeBSD make,
# NetBSD make, and Solaris Distributed make), when run in parallel mode,
# serialize the output from their targets' recipes unconditionally.  In
# such a situation, there's no way the partial results of a TAP test can
# be displayed until the test has terminated.  And this is not something
# our TAP driver script can work around; in fact, the driver *is* sending
# out its output progressively and "in sync" with test execution -- it is
# make that is stowing such output away instead of presenting it to the
# user as soon as it gets it.
if ! using_gmake; then
  case $MAKE in
    *\ -j*) skip_ "doesn't work with non-GNU concurrent make";;
  esac
  # Prevent Sun Distributed Make from trying to run in parallel.
  DMAKE_MODE=serial; export DMAKE_MODE
fi

cat > Makefile.am << 'END'
TESTS = all.test
AM_COLOR_TESTS= no
END

. tap-setup.sh

cat > all.test <<'END'
#! /bin/sh
echo 1..3

# Creative quoting to placate maintainer-check.
sleep="sleep "3

# The awk+shell implementation of the TAP driver must "read ahead" of one
# line in order to catch the exit status of the test script it runs.  So
# be sure to echo one "dummy" line after each result line in order not to
# cause false positives.

echo ok 1 - foo
echo DUMMY
$sleep
test -f ok-1 || { echo 'Bail out!'; exit 1; }

echo ok 2 - bar
echo DUMMY
$sleep
test -f ok-2 || { echo 'Bail out!'; exit 1; }

echo ok 3 - baz
echo DUMMY
$sleep
test -f ok-3 || { echo 'Bail out!'; exit 1; }

: > all-is-well
END

chmod a+x all.test

cat > expect-make <<'END'
eval spawn $env(MAKE) check
expect {
  "PASS: all.test 1 - foo" {
    open "ok-1" "w"
    exp_continue
  }
  "PASS: all.test 2 - bar" {
    open "ok-2" "w"
    exp_continue
  }
  "PASS: all.test 3 - baz" {
    open "ok-3" "w"
    exp_continue
  }
  "Testsuite summary" {
    exit 0
  }
  timeout {
    puts "expect timed out"
    exit 1
  }
  default {
    puts "expect error"
    exit 1
  }
}
END

# Expect should simulate a tty as stdout, which should ensure a
# line-buffered output.
MAKE=$MAKE expect -f expect-make
test -f all-is-well

:
