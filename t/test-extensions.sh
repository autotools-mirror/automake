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

# Make sure that Automake diagnose invalid entries in TEST_EXTENSIONS,
# and do not diagnose valid (albeit more unusual) ones.
# See automake bug#9400.

. ./defs || Exit 1

cat >> configure.ac <<'END'
AC_OUTPUT
END

$ACLOCAL
$AUTOCONF

valid_extensions='sh T t1 _foo BAR x_Y_z _'

echo TESTS = > Makefile.am
echo " $valid_extensions" \
  | sed -e 's/ / ./g' -e 's/^/TEST_EXTENSIONS =/' >> Makefile.am
cat Makefile.am # For debugging.

$AUTOMAKE -a

grep -i 'log' Makefile.in # For debugging.

for lc in $valid_extensions; do
  uc=`echo $lc | tr '[a-z]' '[A-Z]'`
  grep "^${uc}_LOG_DRIVER =" Makefile.in
  grep "^%\.log %\.trs *:.*%\.${lc}" Makefile.in
done

# The produced Makefile is not broken.
./configure
$MAKE all check
$MAKE distclean

cat > Makefile.am << 'END'
TESTS = foo.test bar.sh
TEST_EXTENSIONS  = .test mu .x-y a-b .t.1 .sh .6c .0 .11
TEST_EXTENSIONS += .= .t33 .a@b _&_
END

$AUTOMAKE
./configure

$MAKE 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
for suf in mu .x-y a-b .t.1 .6c .0 .11  '.=' '_&_'; do
  $FGREP "invalid test extension: '$suf'" stderr
done

# Verify that we accept valid suffixes, even if intermixed with
# invalid ones.
$EGREP 'invalid.*\.(sh|test|t33)' stderr && Exit 1

:
