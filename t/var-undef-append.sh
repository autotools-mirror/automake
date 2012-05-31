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

# Automake should allow us top append to undefined variables, for
# consistency with GNU make.  For the same reason, if we override
# a variable definition from the command line, any '+=' appending
# to it should get overridden as well.
# See also "spy" test 'spy-var-append.sh'.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AM_CONDITIONAL([COND_NO], [false])
AM_CONDITIONAL([COND_YES], [:])
AM_CONDITIONAL([COND_YES2], [:])
AC_OUTPUT
END

cat > Makefile.am << 'END'
var0 += foo0

if COND_NO
var00 += foo00
endif

if COND_YES
if COND_YES2
var000 += foo000
endif
endif

if COND_NO
var1 = oops
endif
var1 += bar
if COND_YES
var1 += baz
endif
if COND_NO
var1 += oops
endif

if COND_YES
var2 = a
endif
var2 += b

if COND_YES
var3 := c
endif
var3 += d

var4 = cuckoo
var4 += nightingale

.PHONY: test1 test2
test1:
	test x'$(var0)' = x'foo0'
	test x'$(var00)' = x''
	test x'$(var000)' = x'foo000'
	test x'$(var1)' = x'bar baz'
	test x'$(var2)' = x'a b'
	test x'$(var3)' = x'c d'
        test x'$(var4)' = x'cuckoo nightingale'
test2:
	test x'$(var0)' = x
	test x'$(var1)' = x'one'
	test x'$(var2)' = x'two'
	test x'$(var3)' = x'three'
	test x'$(var4)' = x''
END

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure

checkit ()
{
  $MAKE "$@" 2>stderr && test ! -s stderr || { cat stderr >&2; Exit 1; }
}

checkit test1
checkit test2 var0= var1=one var2=two var3=three var4=

:
