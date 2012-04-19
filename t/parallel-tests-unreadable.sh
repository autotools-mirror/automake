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

# Check that the testsuite driver copes well with unreadable '.log'
# and '.trs' files.

am_parallel_tests=yes
. ./defs || Exit 1

: > t
chmod a-r t && test ! -r t || skip_ "you can still read unreadable files"
rm -f t

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = foo.test bar.test
END

cat > foo.test << 'END'
#! /bin/sh
exit 0
END

cat > bar.test << 'END'
#! /bin/sh
exit 77
END

chmod a+x foo.test bar.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

doit ()
{
  rm -f $*
  $MAKE check
  rm -f test-suite.log
  chmod a-r $*
  $MAKE test-suite.log 2>stderr && { cat stderr >&2; Exit 1; }
  cat stderr >&2
}

permission_denied ()
{
  # FIXME: there are systems where errors on permissions generate a
  # FIXME: different message?  We might experience spurious failures
  # FIXME: there ...
  grep "$1:.*[pP]ermission denied" stderr
}

for lst in bar.log 'foo.log bar.log'; do
  doit $lst
  permission_denied bar.log
  grep 'test-suite\.log:.* I/O error reading test logs' stderr
done

doit foo.trs
permission_denied foo.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

doit foo.trs bar.trs
permission_denied foo.trs
permission_denied bar.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

doit foo.trs bar.log
permission_denied foo.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

:
