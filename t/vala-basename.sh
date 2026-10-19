#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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

# Relocating generated Vala output must not move unrelated handwritten C sources.

required='valac cc pkg-config'
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CC
AM_PROG_VALAC
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0])
AC_OUTPUT
END
mkdir src
cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = foo
foo_SOURCES = src/foo.vala foo.c
AM_CFLAGS = $(GOBJECT_CFLAGS)
LDADD = $(GOBJECT_LIBS)
END
echo 'void main () {}' > src/foo.vala
echo 'void helper (void) {}' > foo.c
cp foo.c expected
$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure
$MAKE
cmp foo.c expected

:
