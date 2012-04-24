#! /bin/sh
# Copyright (C) 2008-2012 Free Software Foundation, Inc.
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

# Test AM_PROG_VALAC.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_VALAC([0.0.1])
AC_OUTPUT
END

: > Makefile.am

cat > valac << 'END'
#! /bin/sh
if test "x$1" = x--version; then
  echo 1.2.3
fi
exit 0
END
chmod +x valac

cwd=`pwd`

# Use $cwd instead of `pwd` in the && list below to avoid a bug in
# the way Solaris/Heirloom Sh handles 'set -e'.

$ACLOCAL
$AUTOMAKE -a
$AUTOCONF

# The "|| Exit 1" is required here even if 'set -e' is active,
# because ./configure migt exit with status 77, and in that case
# we want to FAIL, not to SKIP.
./configure "VALAC=$cwd/valac" || Exit 1

sed 's/AM_PROG_VALAC.*/AM_PROG_VALAC([9999.9])/' < configure.ac >t
mv -f t configure.ac
$AUTOCONF --force
st=0; ./configure "VALAC=$cwd/valac" || st=$?
test $st -eq 77 || Exit 1

sed 's/AM_PROG_VALAC.*/AM_PROG_VALAC([1.2.3])/' < configure.ac >t
mv -f t configure.ac
$AUTOCONF --force
# See comments above for why "|| Exit 1" is needed.
./configure "VALAC=$cwd/valac" || Exit 1

:
