#! /bin/sh
# Copyright (C) 2002-2013 Free Software Foundation, Inc.
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

# Check that Automake can take advantage of GNU make ability to
# automatically chain suffix-based pattern rules.
# See automake bug#7824 and bug#7670.

required=cc
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am <<'END'
bin_PROGRAMS = foo
nodist_foo_SOURCES = foo.c
EXTRA_DIST = foo.c0
%.c0: %.c1
	(echo 'int main (void)' && echo '{' && cat $<) > $@
%.c: %.c0
	(cat $< && echo '}') > $@
CLEANFILES = foo.c0 foo.c
END

echo 'return 0;' > foo.c1

$ACLOCAL
$AUTOMAKE
$AUTOCONF
./configure
$MAKE all
$MAKE distcheck

# Try with explicit dependencies as well.
$MAKE clean
cat >> Makefile <<'END'
foo.c: foo.c0
foo.c0: foo.c1
END
$MAKE all

:
