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

# Verify that iterating variable used in a $(foreach ...) builtin is
# only temporary, and restored to its previous variable if it was already
# set.

am_create_testdir=empty
. ./defs || exit 1

cat > Makefile <<'END'
$(foreach x,1 2,$(warning foo-$(x))$(eval y:=$$(x)))
$(foreach u,oops ko,$(warning bar-$(u))$(eval v=$(u)))
test:
	test .'$(x)' = .
	test .'$(origin x)' = .'undefined'
	test .'$(y)' = .2
	test .'$(v)' = .ko
	test .'$(u)' = .ok
	test .'$(origin u)' = .'command line'
END

x= y= u= v=; unset x y u v
$MAKE test u=ok

:
