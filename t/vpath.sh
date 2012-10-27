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

# Test to make sure VPATH can be overridden.
# Report from Anthony Green.

. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
VPATH = zardoz
%.bar: %.foo
	cp $< $@
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

mkdir build
cd build
mkdir zardoz
../configure

echo OK > zardoz/file.foo
echo KO > ../file.foo
$MAKE file.bar
test "$(cat file.bar)" = OK
rm -f file.bar zardoz/file.foo
$MAKE file.bar && exit 1
test ! -f file.bar

:
