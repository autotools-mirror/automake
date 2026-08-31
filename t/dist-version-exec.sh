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

# Check that VERSION can be defined as a shell command substitution.
# dviljk, ICU, and Gregorio in TeX Live define it this way.

. test-init.sh

echo '#define VERSION "execversion (version 1.0)"' > execversion.c
mkdir sub
: > sub/nested
cat > Makefile.am <<'END'
VERSION = `grep 'define VERSION' $(srcdir)/execversion.c | sed -e 's/^.*version //' -e 's/).*//'`
EXTRA_DIST = execversion.c sub/nested
END

# The two -e arguments to sed provoke a duplicate-target warning when
# VERSION is expanded in make syntax instead of only in shell recipes.
cat > configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure
$MAKE distcheck

test -s "$distdir".tar.gz
test ! -e am__distdir.tar

:
