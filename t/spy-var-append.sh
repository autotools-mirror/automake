#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# GNU make allows us to append to undefined variables.
# Also, if we override a variable definition from the command line,
# any '+=' appending to it gets overridden as well.

am_create_testdir=empty
. test-init.sh

cat > Makefile << 'END'
var0 += foo

var1 += bar
var1 += baz

var2 = a
var2 += b

var3 := x
var3 += y

.PHONY: test1 test2
test1:
	test x'$(var0)' = x'foo'
	test x'$(var1)' = x'bar baz'
	test x'$(var2)' = x'a b'
	test x'$(var3)' = x'x y'
test2:
	test x'$(var0)' = x'mu'
	test x'$(var1)' = x
	test x'$(var2)' = x'two'
	test x'$(var3)' = x'three'
END

checkit ()
{
  $MAKE "$@" 2>stderr && test ! -s stderr || { cat stderr >&2; exit 1; }
}

checkit test1
checkit test2 var0=mu var1= var2=two var3=three

:
