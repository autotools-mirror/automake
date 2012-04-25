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
# Same as python5.test, but with the user forcing the python to use.

required=python
. ./defs || Exit 1

cat >>configure.ac << 'END'
# Hopefully the Python team will never release such a version.
AM_PATH_PYTHON([9999.9])
AC_OUTPUT
END

mkdir bin
cat > bin/my-python << 'END'
#! /bin/sh
exec python ${1+"$@"}
END
chmod a+x bin/my-python
PATH=`pwd`/bin$PATH_SEPARATOR$PATH

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure PYTHON=my-python >stdout 2>stderr && {
  cat stdout
  cat stderr >&2
  Exit 1
}
cat stdout
cat stderr >&2
grep 'whether my-python version is >= 9999\.9\.\.\. no *$' stdout
grep '[Pp]ython interpreter is too old' stderr

:
