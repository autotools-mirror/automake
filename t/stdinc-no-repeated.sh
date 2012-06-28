#!/bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Check that automake rules do not use repeated "-I $(srcdir)" in the
# compiler invocation.

required=cc
. ./defs || exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

echo 'bin_PROGRAMS = foo' > Makefile.am
echo 'int main (void) { return 0; }' > foo.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

# Test with $builddir != $srcdir
mkdir build
cd build
../configure
$MAKE V=1 > stdout || { cat stdout; exit 1; }
cat stdout
grep '.*-I *\. .*-I *\.\. ' stdout
grep '.*-I *\. .*-I *\. ' stdout && exit 1
cd ..

# Test with $builddir = $srcdir
./configure
$MAKE V=1 > stdout || { cat stdout; exit 1; }
cat stdout
grep '.*-I *\.  ' stdout
grep '.*-I *\..*-I *\.' stdout && exit 1

:
