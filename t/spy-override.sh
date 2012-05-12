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

# Verify that use of 'override' directive to re-set a variable does
# not cause any warning or extra output.

am_create_testdir=empty
. ./defs || Exit 1

cat > Makefile <<'END'
foo = 1
override foo = 2

bar = 3
override bar := 4

override baz = 6
override zap := 8

override zardoz += doz

nihil:
	@:
sanity-check:
	test '$(foo)' = 2
	test '$(bar)' = 4
	test '$(baz)' = 6
	test '$(zap)' = 8
	test '$(zardoz)' = 'zar doz'
.PHONY: nihil sanity-check
END

$MAKE sanity-check baz=5 zap=7 zardoz=zar
$MAKE --no-print-directory nihil >output 2>&1 \
  && test ! -s output \
  || { cat output; Exit 1; }

:
