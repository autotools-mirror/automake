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

# Another test to make sure no-dependencies option does the right thing.

. ./defs || Exit 1

cat > Makefile.am << 'END'
bin_PROGRAMS = foo
foo_SOURCES = a.c b.cpp c.m cxx.mm d.S e.java f.upc
END

cat > configure.ac << 'END'
AC_INIT([nodep2], [1], [bug-automake@gnu.org])
AM_INIT_AUTOMAKE([no-dependencies])
AC_CONFIG_FILES([Makefile])
AC_PROG_CC
AC_PROG_CXX
AC_PROG_OBJC
# FIXME: this is to cater to older autoconf; remove this once we
# FIXME: automake requires Autoconf 2.65 or later.
m4_ifdef([AC_PROG_OBJCXX], [AC_PROG_OBJCXX], [
  AC_SUBST([OBJCXX], [whocares])
  AM_CONDITIONAL([am__fastdepOBJCXX], [whocares])
])
AM_PROG_AS
AM_PROG_GCJ
AM_PROG_UPC
AC_OUTPUT
END

$ACLOCAL
$AUTOMAKE

grep DEPMODE Makefile.in && Exit 1

:
