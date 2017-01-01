#! /bin/sh
# Copyright (C) 2016-2017 Free Software Foundation, Inc.
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

# Ensure that the 'make distcheck'-run distcleancheck does not fail
# due to a leftover .deps/base.Tpo file when part of a successful build
# involves a failed attempt to create a .deps/base.Po file.

. test-init.sh

cat >> configure.ac <<END
AC_PROG_CC
AC_OUTPUT
END

cat > foo.c <<\END
#ifndef FAIL
int main() { return 0; }
#else
int x[no_such];
#endif
END

cat > Makefile.am <<\END
TESTS = foo bar.test
check_PROGRAMS = foo
EXTRA_DIST= bar.test foo.c
END

cat > bar.test <<END
#!/bin/sh
rm -f foo.o
$MAKE AM_CFLAGS=-DFAIL foo.o && exit 1
exit 0
END
chmod a+x bar.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure

# We can build the distribution.
run_make -M distcheck

:
