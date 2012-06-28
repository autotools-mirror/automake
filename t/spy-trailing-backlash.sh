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

# Check that GNU make line-continuation with backslash-newline has the
# semantic we expect.

am_create_testdir=empty
. ./defs || exit 1

cat > Makefile << 'END'
default:

hash = \#
ok: ; true :--$(hash)--:

var1 = \
rule1:

rule2: \
; echo ok > sentinel

# The backslash doesn't cause we to continue to read after
# the fist blank line.
rule3: \

var2 = ok

# Ditto.
var3 = a \

b:

# The backslash will cause the next line to be a comment as well \
$(error comment not continued)

var4 = foo \
# not seen

.PHONY: test
test:
	test $(var1) = rule1:
	test $(var2) = ok
	test $(var3) = a
	test $(var4) = foo
	test -z '$(var5)'

var5 = \
END

$MAKE
$MAKE ok
$MAKE ok | grep ':--#--:'
$MAKE rule1 && exit 1
$MAKE rule2
test -f sentinel
$MAKE rule3
$MAKE test

:
