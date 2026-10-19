#! /bin/sh
# Copyright (C) 2013-2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Prerequisite-only redeclarations must not change the selection of
# Automake's generated link rules (bug#13940).

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_CONDITIONAL([FOO], [test "$foo" = yes])
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = prog
prog_SOURCES = main.c
if FOO
prog$(EXEEXT): conditional
endif
prog$(EXEEXT): always
always conditional:
	:
END

cat > main.c << 'END'
int main (void) { return 0; }
END

$ACLOCAL
$AUTOMAKE -a -Werror
$AUTOCONF
./configure foo=no
$MAKE
./prog
$MAKE clean
$MAKE prog
./prog

# A conditional custom recipe must still override the generated one only
# in that condition; adding unconditional prerequisites must not broaden it.
cat > Makefile.am << 'END'
bin_PROGRAMS = prog
prog_SOURCES = main.c
if FOO
prog$(EXEEXT):
	@echo custom > custom-seen
endif
prog$(EXEEXT): always
always:
	:
END
$AUTOMAKE -Werror
./configure foo=no
$MAKE clean
$MAKE prog
./prog
test ! -e custom-seen
./configure foo=yes
$MAKE clean
$MAKE prog
test -f custom-seen

:
