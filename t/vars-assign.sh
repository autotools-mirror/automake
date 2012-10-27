#! /bin/sh
# Copyright (C) 2008-2012 Free Software Foundation, Inc.
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

# Automake do not complain about nor messes up GNU make specific
# variable assignments (":=" and "?=").

. test-init.sh

echo AC_OUTPUT >> configure.ac

unset PREFOO FOO BAR BAZ XFOO XBAZ || :

cat > Makefile.am <<'END'
PREFOO = bar
FOO := foo$(PREFOO)$(XFOO)
XFOO = fail
BAR ?= barbar

.PHONY: test1 test2
test1:
	test $(FOO) = foobar
	test $(BAR) = barbar
test2:
	test $(FOO) = foobar
	test $(BAR) = rabrab
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure
$MAKE test1
PREFOO=notseen FOO=notseen BAR=rabrab $MAKE test2

:
