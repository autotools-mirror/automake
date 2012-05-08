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

# Sanity check for the automake testsuite.
# Test the sanity checks performed by the 'defs' script.  Also check
# that we can use 'defs' elsewhere, when we duplicate some of the
# infrastructure from the automake/tests subdirectory.

am_create_testdir=empty
. ./defs || Exit 1

# Avoid to confuse traces from child processed with our own traces.
show_stderr ()
{
  sed 's/^/ | /' stderr >&2
}

AM_TESTS_REEXEC=no; export AM_TESTS_REEXEC

source_defs=". '$am_top_builddir/defs'"

if $AM_TEST_RUNNER_SHELL -c "$source_defs" dummy.sh 2>stderr; then
  show_stderr
  Exit 1
else
  show_stderr
  grep 'defs-static: not found in current directory' stderr
fi

sed 's|^am_top_srcdir=.*|am_top_srcdir=foo|' \
  "$am_top_builddir"/defs-static > defs-static
if $AM_TEST_RUNNER_SHELL -c "$source_defs" t/dummy.sh 2>stderr; then
  show_stderr
  Exit 1
else
  show_stderr
  grep 'foo/defs-static\.in not found.*check \$am_top_srcdir' stderr
fi

sed 's|^am_top_builddir=.*|am_top_builddir=foo|' \
  "$am_top_builddir"/defs-static > defs-static
if $AM_TEST_RUNNER_SHELL -c "$source_defs" t/dummy.sh 2>stderr; then
  show_stderr
  Exit 1
else
  show_stderr
  grep 'foo/defs-static not found.*check \$am_top_builddir' stderr
fi

# We still need a little hack to make ./defs work outside automake's
# tree 'tests' subdirectory.  Not a big deal.
sed "s|^am_top_builddir=.*|am_top_builddir='`pwd`'|" \
  "$am_top_builddir"/defs-static > defs-static
# Redefining *srcdir and *builddir variables in the environment shouldn't
# cause problems
env \
  builddir=bad-dir srcdir=bad-dir \
  top_builddir=bad-dir top_srcdir=bad-dir \
  abs_builddir=bad-dir abs_srcdir=bad-dir \
  abs_top_builddir=bad-dir abs_top_srcdir=bad-dir \
  $AM_TEST_RUNNER_SHELL -c "$source_defs && echo '!OK!' > ../foo" t/dummy.sh
$FGREP '!OK!' t/foo

:
