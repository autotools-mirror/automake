#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# If we distribute a file whose name that starts with $(srcdir),
# then the distribution rules should not try to instead distribute
# a file with the same name from the builddir.
# Currently, this doesn't work (the reasons and details for this
# limitation should be explained in depth in comments in file
# 'lib/am/distdir.am').

. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
EXTRA_DIST = $(srcdir)/filename-that-is-easy-to-grep
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

mkdir build
cd build
../configure

echo bad > filename-that-is-easy-to-grep
$MAKE distdir 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep 'filename-that-is-easy-to-grep' stderr

echo good > ../filename-that-is-easy-to-grep
$MAKE distdir
test "$(cat $distdir/filename-that-is-easy-to-grep)" = good

:
