#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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
# This test calls AC_CONFIG_AUX_DIR with a '.' argument, thus explicitly
# making the top-level directory the config auxdir.
# Keep this in sync with sister tests 'auxdir6.sh' and 'auxdir8.sh'.

. test-init.sh

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AC_CONFIG_AUX_DIR([.])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile subdir/Makefile])
END

mkdir subdir

: > Makefile.am
: > subdir/Makefile.am

$ACLOCAL
$AUTOMAKE

grep '^am\.conf\.aux-dir = \$(top_srcdir)$' Makefile.in
grep '^am\.conf\.aux-dir = \$(top_srcdir)$' subdir/Makefile.in

:
