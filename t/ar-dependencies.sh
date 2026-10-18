#! /bin/sh
# Copyright (C) 2023-2026 Free Software Foundation, Inc.
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

# Object dependencies must not depend on library ordering (bug#60508).

. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_SUBST([OTHER_LIBS])
AM_PROG_AR
AC_PROG_RANLIB
AM_CONDITIONAL([COND], [test x = y])
END

cat > Makefile.am << 'END'
noinst_LIBRARIES =

libmMID_a_SOURCES = source.c
if COND
libmMID_a_SOURCES += extra.c
endif
noinst_LIBRARIES += libmMID.a

libaFIRST_a_SOURCES =
libaFIRST_a_LIBADD = $(common_objects)
common_objects = $(libmMID_a_OBJECTS)
noinst_LIBRARIES += libaFIRST.a

libzLAST_a_SOURCES =
libzLAST_a_LIBADD = $(libmMID_a_OBJECTS)
noinst_LIBRARIES += libzLAST.a

noinst_PROGRAMS = aFIRST mMID zLAST
mMID_SOURCES = main.c
aFIRST_SOURCES =
aFIRST_LDADD = $(mMID_OBJECTS) -lm @OTHER_LIBS@
zLAST_SOURCES =
zLAST_LDADD = $(mMID_OBJECTS)

noinst_LIBRARIES += liboverride.a
liboverride_a_SOURCES =
liboverride_a_LIBADD = $(libmMID_a_OBJECTS)
liboverride_a_DEPENDENCIES = explicit
END

: > ar-lib

$ACLOCAL
$AUTOMAKE

# Make sure DEPENDENCIES is setup correctly.
grep '_a_DEPENDENCIES =' Makefile.in
grep '^libzLAST_a_DEPENDENCIES = $(libmMID_a_OBJECTS)' Makefile.in
grep '^libaFIRST_a_DEPENDENCIES = $(common_objects)$' Makefile.in
grep '^aFIRST_DEPENDENCIES = $(mMID_OBJECTS)$' Makefile.in
grep '^zLAST_DEPENDENCIES = $(mMID_OBJECTS)$' Makefile.in
grep '^liboverride_a_DEPENDENCIES = explicit$' Makefile.in

:
