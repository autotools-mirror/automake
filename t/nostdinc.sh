#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
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

# Test to make sure nostdinc option works correctly.

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = nostdinc
bin_PROGRAMS = foo
END

cat > foo.c << 'END'
#include <stdlib.h>
int main (void)
{
  exit (0);
}
END

# This shouldn't be picked up.
cat > stdlib.h << 'END'
#error "stdlib.h from source dir included"
choke me
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

# Test with $builddir != $srcdir
mkdir build
cd build
../configure
$MAKE V=1 > output || { cat output; exit 1; }
cat output
grep '.*-I *\.' stdout && exit 1
$MAKE clean
# Shouldn't be picked up from builddir either.
cp ../stdlib.h .
$MAKE
cd ..

# Test with $builddir = $srcdir
./configure
$MAKE V=1 > output || { cat output; exit 1; }
cat output
grep '.*-I *\.' output && exit 1

:
