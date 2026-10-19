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

# The intermediate tarball shared by the dist-* targets must not be left
# behind when GNU make keeps it, either because of a user .SECONDARY or
# because it already existed; otherwise 'make distcheck' fails.

. test-init.sh

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am <<'END'
.SECONDARY:
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

$MAKE dist
test -f $distdir.tar.gz
test ! -e am__distdir.tar
test ! -d $distdir

# A stale file is overwritten, and distclean removes it.
rm -f $distdir.tar.gz
echo junk > am__distdir.tar
$MAKE dist-gzip
gzip -dc $distdir.tar.gz | tar tf - | grep "^$distdir/Makefile.am\$"
$MAKE distclean
test ! -e am__distdir.tar

./configure
$MAKE distcheck

:
