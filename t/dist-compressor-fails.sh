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

. test-init.sh

cat > configure.ac << END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([foreign dist-xz])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure

# stub
mkdir bin
cat > bin/xz << 'END'
#! /bin/sh
echo "fake xz: cannot compress that" >&2
exit 1
END
chmod a+x bin/xz

saved_PATH=$PATH
PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH
run_make -M -e FAIL dist-xz
PATH=$saved_PATH; export PATH

grep 'cannot compress that' output
# No truncated archive, and no leftover shared tarball.
test ! -e $distdir.tar.xz
test ! -e $distdir.tar

:
