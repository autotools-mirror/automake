#!/bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# For PR/352: make sure we support bin_PROGRAMS, lib_LIBRARIES and
#             lib_LTLIBRARIES being defined conditionally.

. ./defs || Exit 1

cat >>configure.ac <<'EOF'
m4_define([AM_PROG_AR], [:])
AM_PROG_AR
AM_CONDITIONAL([C1], [test x"$two" != x"yes"])
AM_CONDITIONAL([C2], [test x"$two"  = x"yes"])
AC_OUTPUT
EOF

# Avoid spurious interferences from the environment.
unset undefined two || :

cat > Makefile.am <<'EOF'
AUTOMAKE_OPTIONS = no-dependencies
CC = false
AR = false
RANLIB = false
LIBTOOL = false
EXEEXT = .foo

if C1
bin_PROGRAMS = a
lib_LIBRARIES = liba.a
lib_LTLIBRARIES = libxa.la
endif
if C2
bin_PROGRAMS = b $(undefined)
lib_LIBRARIES = libb.a $(undefined)
lib_LTLIBRARIES = libxb.la $(undefined)
endif

.PHONY: test-a test-b
test-a:
	test a.foo = $(bin_PROGRAMS)
	test liba.a = $(lib_LIBRARIES)
	test libxa.la = $(lib_LTLIBRARIES)
test-b:
	test b.foo = $(bin_PROGRAMS)
	test libb.a = $(lib_LIBRARIES)
	test libxb.la = $(lib_LTLIBRARIES)
EOF

: > ltmain.sh

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

$FGREP SOURCES Makefile.in # For debugging.

$FGREP 'a_SOURCES = a.c' Makefile.in
$FGREP 'b_SOURCES = b.c' Makefile.in
$FGREP 'liba_a_SOURCES = liba.c' Makefile.in
$FGREP 'libb_a_SOURCES = libb.c' Makefile.in
$FGREP 'libxa_la_SOURCES = libxa.c' Makefile.in
$FGREP 'libxb_la_SOURCES = libxb.c' Makefile.in

./configure two=no
$MAKE test-a

./configure two=yes
$MAKE test-b

:
