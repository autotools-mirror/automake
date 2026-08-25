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
AM_INIT_AUTOMAKE([gnu])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

: > Makefile.am
: > AUTHORS
: > ChangeLog
: > NEWS
: > README
: > INSTALL
: > COPYINGv2
: > COPYINGv3
: > COPYING.LESSERv3

$ACLOCAL
$AUTOMAKE --add-missing

# No license file may have been added ...
test ! -e COPYING
# ... and nothing may have been said about one being missing.
$AUTOMAKE --add-missing 2>stderr
cat stderr
grep -i 'COPYING' stderr && exit 1

# All of them are distributed, as plain COPYING would be.
$FGREP 'COPYINGv2' Makefile.in
$FGREP 'COPYINGv3' Makefile.in
$FGREP 'COPYING.LESSERv3' Makefile.in

# A package with no license at all must still get one, as before.
mkdir sub
cd sub
cat > configure.ac << END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([gnu])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am
for f in AUTHORS ChangeLog NEWS README INSTALL; do : > $f; done
$ACLOCAL
$AUTOMAKE --add-missing
test -e COPYING

:
