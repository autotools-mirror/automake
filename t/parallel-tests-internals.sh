#! /bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Some internals of the parallel testsuite harness implementation.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS =
.PHONY: test
test:
	test x'$(call am__tpfx,)'      = x
	test x'$(call am__tpfx,.test)' = x'TEST_'
	test x'$(call am__tpfx,.sh5)'  = x'SH5_'
	test x'$(call am__tpfx,.x_y)'  = x'X_Y_'
	test x'$(call am__tpfx,  )'    = x
	test x'$(call am__tpfx, .t  )' = x'T_'
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE test

:
