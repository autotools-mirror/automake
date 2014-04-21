#! /bin/sh
# Copyright (C) 1998-2014 Free Software Foundation, Inc.
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

# Test on some aclocal options.  Report from Alexandre Oliva.

am_create_testdir=empty
. test-init.sh

echo "AC_INIT([$me], [0]) AM_INIT_AUTOMAKE" > configure.ac

$ACLOCAL --output=fred
test -f fred

$ACLOCAL --output 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep 'option.*--output.*requires an argument' stderr
grep '[Tt]ry.*--help.*for more information' stderr

$ACLOCAL --unknown-option 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep 'unrecognized option.*--unknown-option' stderr
grep '[Tt]ry.*--help.*for more information' stderr

$ACLOCAL foobar 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep 'non-option argument.*foobar' stderr
grep '[Tt]ry.*--help.*for more information' stderr

$ACLOCAL --ver 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep 'unrecognized option.*--ver' stderr
grep '[Tt]ry.*--help.*for more information' stderr

$ACLOCAL --versi

:
