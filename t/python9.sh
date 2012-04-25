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

# Test ACTION-IF-TRUE in AM_PATH_PYTHON.
# Similar to python8.test, but requiring a version.

required=python
. ./defs || Exit 1

cat >>configure.ac <<'EOF'
# $PYTHON is supposed to be properly set in ACTION-IF-TRUE.
AM_PATH_PYTHON([0.0], [$PYTHON -c 'print("%u:%u" % (1-1, 2**0))' > py.out])
AC_OUTPUT
EOF

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure
test x"`cat py.out`" = x0:1

:
