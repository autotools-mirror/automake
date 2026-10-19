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

# Optional archives must survive selective and repeated Makefile regeneration.

required='bzip2'
. test-init.sh

cat >> configure.ac <<'END'
AM_OPTIONAL_AUTOMAKE([dist-bzip2])
AM_OPTIONAL_AUTOMAKE([dist-bzip2])
AC_CONFIG_FILES([sub/Makefile Other:Makefile.in])
AC_OUTPUT
END
mkdir sub
echo "SUBDIRS = sub" > Makefile.am
: > sub/Makefile.am
$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure
$MAKE dist
test -s "$distdir.tar.bz2"
rm -f "$distdir.tar.bz2"
./config.status Makefile
$MAKE dist
test -s "$distdir.tar.bz2"

# Repeated full regenerations must neither duplicate nor lose recipes.
./config.status
./config.status
test $(grep -c '^am--optional-dist-bzip2:' Makefile) -eq 1
grep '^am--optional-dist-bzip2:' sub/Makefile && exit 1
rm -f "$distdir.tar.bz2"
$MAKE -f Other dist
test -s "$distdir.tar.bz2"

:
