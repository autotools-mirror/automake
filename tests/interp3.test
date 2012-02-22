#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# Variable interpolation should work even when GNU make functions are
# involved.  This is unfortunately not the case currently, due to
# historical and hard-to-lift limitations (this is also documented in
# the manual, using an example that is a stripped-down version of this
# test case).

required=cc
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = foo
xs = one two
foo_SOURCES = main.c $(foreach base, $(xs), $(base).c $(base).h)
END

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure

echo 'int one (void) { return 1; }' > one.c
echo 'extern int one (void);' > one.h
echo 'int two (void) { return 2; }' > two.c
echo 'extern int two (void);' > two.h

cat > main.c <<'END'
#include "one.h"
#include "two.h"
int maint (void)
{
  return one () + two ();
}
END

$MAKE
$MAKE distcheck

:
