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

# Check that the behaviour of the $(wildcard) builtin in corner cases
# matches the assumptions done in our recipes.

. ./defs || exit 1

mkdir dir
echo dummy > file

cat > Makefile <<'END'
.PHONY: test
test:
	test x'$(wildcard dir)'    = x'dir'
	test x'$(wildcard file)'   = x'file'
	test x'$(wildcard dir/)'   = x'dir/'
	test x'$(wildcard file/.)' = x''
END

$MAKE test

:
