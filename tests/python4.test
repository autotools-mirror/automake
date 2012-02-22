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

# Python is not required for this test.
. ./defs || Exit 1

cat >>configure.ac <<EOF
AM_PATH_PYTHON
AC_OUTPUT
EOF

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

# Simulate no Python.
./configure PYTHON=: 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep 'no suitable Python interpreter found' stderr

# Again, but from the environment this time.
env PYTHON=: ./configure 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep 'no suitable Python interpreter found' stderr

:
