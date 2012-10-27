#! /bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Test to make sure that sources for links created by AC_CONFIG_LINKS
# are distributed.

. test-init.sh

echo SUBDIRS = sdir > Makefile.am

: > src
: > src2
mkdir sdir
: > sdir/Makefile.am
: > sdir/src3
mkdir sdir-no-make
: > sdir-no-make/src4

cat >>configure.ac << 'EOF'
AC_CONFIG_FILES([sdir/Makefile])
AC_CONFIG_LINKS([dest:src])
AC_CONFIG_LINKS([sdir/dest2:src2 sdir-no-make/dest3:sdir/src3])
AC_CONFIG_LINKS([sdir/dest4:sdir-no-make/src4])
AC_OUTPUT
EOF

$ACLOCAL
$AUTOMAKE
$AUTOCONF
./configure
$MAKE distdir

find $distdir # For debugging.

rm -rf $distdir/am-ng

test -f $distdir/src
test -f $distdir/src2
test -f $distdir/sdir/src3
test -f $distdir/sdir-no-make/src4

count_distributed_dirs ()
{
  find $distdir${1+"/$1"} -type d | wc -l
}

test 2 -gt $(count_distributed_dirs 'sdir')
test 2 -gt $(count_distributed_dirs 'sdir-no-make')
test 4 -gt $(count_distributed_dirs)

:
