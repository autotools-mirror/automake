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

# A rebuilt Vala source must not leave C files or stamps in a VPATH
# build directory after distclean (bug#76527).

required="pkg-config valac cc GNUmake"
. test-init.sh

mkdir src

cat >> 'configure.ac' << 'END'
AC_PROG_CC
AM_PROG_VALAC([0.7.0])
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.4])
AC_OUTPUT
END

cat > 'src/zardoz.vala' <<'END'
using GLib;

public class Zardoz {
  public static void main () {
    stdout.printf ("Zardoz!\n");
  }
}
END

echo 'void helper () {}' > src/helper.vala.in

cat > 'Makefile.am' <<'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = src/zardoz
src_zardoz_CFLAGS = $(GOBJECT_CFLAGS)
src_zardoz_LDADD = $(GOBJECT_LIBS)
src_zardoz_SOURCES = src/zardoz.vala src/helper.vala
BUILT_SOURCES = src/helper.vala
DISTCLEANFILES = $(BUILT_SOURCES)
EXTRA_DIST = src/helper.vala.in
# Regenerate in the distcheck build even though this file is distributed.
src/helper.vala: $(srcdir)/src/helper.vala.in Makefile
	$(AM_V_at)$(MKDIR_P) src
	cp $(srcdir)/src/helper.vala.in $@
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE
test -f src/zardoz.c
test -f src_zardoz_vala.stamp
$MAKE distcheck
$MAKE maintainer-clean
test ! -e src/zardoz.c
test ! -e src_zardoz_vala.stamp

:
