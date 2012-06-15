#! /bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Check that double colon rules work.
# This test not only checks that Automake do not mangle double-colon rules
# seen in input Makefile.am, but also that GNU make support of double-colon
# rules is as reliable and well-working as we expect and need.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
all-local:
	@echo Please select an explicit target; exit 1

# No space after 'a'.
a:: b
	echo rule1 >> $@
# Deliberate space after 'a'.
a :: c
	echo rule2 >> $@

# Overlapping rules should work as well
a2 :: b2
	echo rule21 >> $@
a2 :: c2
	echo rule22 >> $@
a2:: b2 c2
	echo rule23 >> $@
b2 c2:
	touch $@
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

grep '::' Makefile.in # For debugging.
test $(grep -c '^a *:: *b *$' Makefile.in) -eq 1
test $(grep -c '^a *:: *c *$' Makefile.in) -eq 1
test $(grep -c '^a2 *:: *b2 *$' Makefile.in) -eq 1
test $(grep -c '^a2 *:: *c2 *$' Makefile.in) -eq 1
test $(grep -c '^a2 *:: *b2  *c2 *$' Makefile.in) -eq 1

./configure

# Non-overlapping double-colon rules.

touch b c
$sleep
: > a
$MAKE a
test ! -s a
$sleep
touch b
$MAKE a
test "$(cat a)" = rule1
: > a
$sleep
touch c
$MAKE a
test "$(cat a)" = rule2

: > a
$sleep
touch b c
$MAKE a
test "$(sort a)" = "rule1${nl}rule2"

rm -f a b c

# Overlapping double-colon rules.

$MAKE a2
test -f a2
test -f b2
test -f c2

: > a2
$MAKE a2
test ! -s a2
$sleep
touch b2
$MAKE a2
test "$(sort a2)" = "rule21${nl}rule23"
: > a2
$sleep
touch c2
$MAKE a2
test "$(sort a2)" = "rule22${nl}rule23"

: > a2
$sleep
touch b2 c2
$MAKE a2
test "$(sort a2)" = "rule21${nl}rule22${nl}rule23"

:
