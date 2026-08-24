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

# LT2.6's OBJC and OBJCXX support.

required=libtool
. test-init.sh

# kludge:
cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_AR
AC_PROG_OBJC
AC_PROG_OBJCXX
LT_INIT
LT_SUPPORTED_TAG([OBJC])
LT_SUPPORTED_TAG([OBJCXX])
END

cat > Makefile.am << 'END'
lib_LTLIBRARIES = libfoo.la libbar.la
libfoo_la_SOURCES = foo.m
libbar_la_SOURCES = bar.mm
END

: > foo.m
: > bar.mm

# 'LT_INIT' wants this; we never run libtool, so an empty file will do.
: > ltmain.sh

$ACLOCAL
$AUTOMAKE -a

cat Makefile.in

grep '^LTOBJCCOMPILE = .*--tag=OBJC ' Makefile.in
grep '^OBJCLINK = .*--tag=OBJC ' Makefile.in
grep '^LTOBJCXXCOMPILE = .*--tag=OBJCXX' Makefile.in
grep '^OBJCXXLINK = .*--tag=OBJCXX' Makefile.in

:
