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

could_not_read ()
{
  # We have to settle for weak checks to avoid spurious failures due to
  # the differences in error massages on different systems; for example:
  #
  #   $ cat unreadable-file # GNU/Linux or NetBSD
  #   cat: unreadable-file: Permission denied
  #   $ cat unreadable-file # Solaris 10
  #   cat: cannot open unreadable
  #
  #   $ grep foo unreadable-file # GNU/Linux and NetBSD
  #   grep: unreadable: Permission denied
  #   $ grep foo unreadable-file # Solaris 10
  #   grep: can't open "unreadable"
  #
  # Plus, we must cater to error messages displayed by our own awk
  # script: "cannot read "unreadable"".
  #
  # FIXME: this might still needs adjustments on other systems ...
  #
  grep "$1:.*[pP]ermission denied" stderr \
    || $EGREP "can(no|')t (open|read) [\"'\`]?$1" stderr
}

for lst in bar.log 'foo.log bar.log'; do
  doit $lst
  could_not_read bar.log
  grep 'test-suite\.log:.* I/O error reading test results' stderr
done

doit foo.trs
could_not_read foo.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

doit foo.trs bar.trs
could_not_read foo.trs
could_not_read bar.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

doit foo.trs bar.log
could_not_read foo.trs
grep 'test-suite\.log:.* I/O error reading test results' stderr

:
