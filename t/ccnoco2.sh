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

# Make sure Automake requires AM_PROG_CC_C_O when either per-targets
# flags or subdir objects are used.

. ./defs || exit 1

cat >>configure.ac <<EOF
AC_CONFIG_FILES([src/Makefile])
AC_PROG_CC
AC_OUTPUT
EOF

$ACLOCAL

cat >Makefile.am <<EOF
SUBDIRS = src
bin_PROGRAMS = wish
wish_SOURCES = a.c
wish_CPPFLAGS = -DWHATEVER
EOF

mkdir src
cat >src/Makefile.am <<EOF
bin_PROGRAMS = wish2
wish2_SOURCES = sub/a.c
EOF

AUTOMAKE_fails --copy --add-missing
grep "^Makefile\.am:3:.* 'a\.c' with per-target flags.* 'AM_PROG_CC_C_O'" stderr
grep "^src/Makefile\.am:2:.* 'sub/a\.c' in subdir.* 'AM_PROG_CC_C_O'" stderr

rm -rf autom4te*.cache
echo AM_PROG_CC_C_O >> configure.ac
$ACLOCAL
$AUTOMAKE -a

:
