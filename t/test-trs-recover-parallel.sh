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

# Check parallel harness features:
#  - recovery from deleted '.log' and '.trs' files, with parallel make

. ./defs || Exit 1

all= log= trs=
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  all="$all $i" log="$log $i" trs="$trs $i"
done

echo AC_OUTPUT >> configure.ac
echo TESTS = > Makefile.am

for i in $all; do
  echo TESTS += $i.test >> Makefile.am
  (echo "#!/bin/sh" && echo "mkdir $i.d") > $i.test
  chmod a+x $i.test
done

ls -l # For debugging.

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

: Create the required log files.
$MAKE check

for n in 1 2 5 7 12; do
  for suf in log trs; do
    rmdir *.d
    rm -f *.$suf
    $MAKE -j$n check
    for f in $all; do
      test -f $f.log
      test -f $f.trs
    done
  done
done

:
