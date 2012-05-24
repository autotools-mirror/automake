#! /bin/sh
# Copyright (C) 1996-2012 Free Software Foundation, Inc.
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

# Test to make sure AC_CONFIG_AUX_DIR works correctly.
# This test tries without an explicit call to AC_CONFIG_AUX_DIR;
# the config auxdir should be implicitly defined to '.' since
# the install-sh, py-compile, etc., scripts are in the top-level
# directory.
# Keep this in sync with sister tests auxdir6.test and auxdir7.test.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([subdir/Makefile])
END

mkdir subdir

: > Makefile.am
: > subdir/Makefile.am

$ACLOCAL
$AUTOMAKE

grep '^am__config_aux_dir = \$(top_srcdir)$' Makefile.in
grep '^am__config_aux_dir = \$(top_srcdir)$' subdir/Makefile.in

:
