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

#
# - Automake should handle trailing backslashes in comments the way GNU
#   make does, i.e., considering the next line as a continuation of the
#   comment.
#
# - Automake should allow backslash-escaped '#' characters at the end
#   of a line (in variable definitions as well as well as in recipes),
#   because GNU make allows that.
#
# - GNU make handles comments following trailing backslashes gracefully,
#   so Automake should do the same.
#
# - Automake should not complain if the Makefile ands with a backslash
#   and newline sequence, because GNU make handles that gracefully.
#

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

# Avoid possible interferences from the environment.
var1= var2=; unset var1 var2

cat > Makefile.am << 'END'
# a comment with backslash \
var1 = foo
var2 = bar

var3 = \#
var4 = $(var3)

var5 = ok \
# ko

.PHONY: test
test:
	test -z '$(var1)'
	test '$(var2)' = bar
	test '$(var3)' = '#'
	test '$(var4)' = \#
	: Use '[', not 'test', here, so that spurious comments
	: are ensured to cause syntax errors.
	[ $(var5) = ok ]

# Yes, this file ends with a backslash-newline.  So what?
\
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE test

:
