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

# Test detection of missing Python.
# Same as python4.test, but requiring a version.

# Python is not required for this test.
. ./defs || Exit 1

cat >>configure.ac <<EOF
# Hopefully the Python team will never release such a version.
AM_PATH_PYTHON([9999.9])
AC_OUTPUT
EOF

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure >stdout 2>stderr && {
  cat stdout
  cat stderr >&2
  Exit 1
}
cat stdout
cat stderr >&2
$EGREP 'checking for a Python interpreter with version >= 9999\.9\.\.\. no(ne)? *$' stdout
grep 'no suitable Python interpreter found' stderr

:
