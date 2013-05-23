#! /bin/sh
# Copyright (C) 2001-2013 Free Software Foundation, Inc.
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

# Test to make sure 'compile' doesn't call 'mv SRC SRC'.

required=gcc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
$CC --version; $CC -v; # For debugging.
AC_OUTPUT
END

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = wish
wish_SOURCES = a.c
END

mkdir sub

cat > a.c << 'END'
#include <stdio.h>

int main ()
{
  printf ("hi\n");
}
END

cat > Mycomp << END
#!/bin/sh

case " \$* " in
 *\ -c*\ -o* | *\ -o*\ -c*)
    exit 1
    ;;
esac

# Use '$CC', not 'gcc', to honour the compiler chosen
# by the testsuite setup.
exec $CC "\$@"
END

chmod +x Mycomp

# Make sure the compiler doesn't understand '-c -o'
CC=$(pwd)/Mycomp
export CC

$ACLOCAL
$AUTOCONF
$AUTOMAKE --copy --add-missing

mkdir build
cd build

../configure
run_make -E
grep 'mv.*the same file' stderr && exit 1

:
