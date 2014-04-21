#! /bin/sh
# Copyright (C) 2013-2014 Free Software Foundation, Inc.
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

# Expose part of automake bug#13928: if the subdir-objects option is
# in use and a source file is listed in a _SOURCES variable with a
# leading $(srcdir) component, Automake will generate a Makefile that
# tries to create the corresponding object file in $(srcdir) as well.

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_OUTPUT
END

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = subdir-objects
noinst_PROGRAMS = test
test_SOURCES = $(srcdir)/test.c
test-objs:
	test ! -f $(srcdir)/test.$(OBJEXT)
	test -f test.$(OBJEXT)
END

$ACLOCAL && $AUTOCONF && $AUTOMAKE -a || fatal_ "autotools failed"

$EGREP 'test\.|DEPDIR|dirstamp|srcdir' Makefile.in || : # For debugging.
$EGREP '\$.srcdir./test\.[o$]' Makefile.in && exit 1
$FGREP '$(srcdir)/$(am__dirstamp)' Makefile.in && exit 1
$FGREP '$(srcdir)/$(DEPDIR)' && exit 1

cat > test.c << 'END'
int main (void)
{
  return 0;
}
END

mkdir build && cd build || fatal "preparation of build directory failed"
../configure || fatal_ "./configure failed"

$MAKE
$MAKE test-objs

:
