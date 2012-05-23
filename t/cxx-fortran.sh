#! /bin/sh
# Copyright (C) 2006-2012 Free Software Foundation, Inc.
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

# Test mixing Fortran 77 and C++.

# For now, require the GNU compilers, to avoid possible spurious failure.
required='gfortran g++'
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CXX
AC_PROG_F77
AC_OUTPUT
END

cat > Makefile.am << 'END'
noinst_PROGRAMS = foo
foo_SOURCES = new.cc old.f
END

cat > new.cc << 'END'
#include <iostream>
using namespace std;
extern "C" { int cube_ (int *); }
int main (void)
{
   int n = 3;
   cout << "The Cube of " << n << " is " << cube_ (&n) << endl;
   return 0;
}
END

cat > old.f << 'END'
      INTEGER FUNCTION CUBE(N)
C     COMPUTES AND RETURN THE CUBE OF THE INTEGER N
      CUBE=N*N*N
      RETURN
      END
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
# The C++ linker should be preferred.
grep '\$(FCLINK)' Makefile.in && Exit 1
grep '.\$(CXXLINK)' Makefile.in

./configure
$MAKE

if cross_compiling; then :; else
  ./foo
  test "$(./foo)" = "The Cube of 3 is 27"
fi

$MAKE distcheck
