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

# Verify that our expectations on the behaviour of (some) GNU make
# automatic variables are correct.
# This test is quite incomplete, and should be filled out whenever
# we want to start assuming and using a further behaviour of
# automatic variables of GNU make.

am_create_testdir=empty
. test-init.sh

cat > Makefile <<'END'
foo:
	test $@ = foo
	test $(@D) = .
	test $(@F) = foo
./bar:
	test $@ = ./bar || test $@ = bar
	test $(@D) = .
	test $(@F) = bar
../baz:
	test $@ = ../baz
	test $(@D) = ..
	test $(@F) = baz
1/2/3:
	test $@ = 1/2/3
	test $(@D) = 1/2
	test $(@F) = 3
/abs/path:
	test $@ = /abs/path
	test $(@D) = /abs
	test $(@F) = path
END

$MAKE foo
$MAKE ./foo
$MAKE bar
$MAKE ./bar
$MAKE ../baz
$MAKE 1/2/3
$MAKE ./1/2/3
$MAKE /abs/path

:
