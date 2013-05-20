#! /bin/sh
# Copyright (C) 1996-2013 Free Software Foundation, Inc.
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

# Test for bug reported by Harlan Stenn: the tags target doesn't work
# when there are only headers in a directory.

required=mkid
. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
noinst_HEADERS = iguana.h
test-id: ID
	test -f $(srcdir)/iguana.h
	test -f ID
check-local: test-id
END

cat > iguana.h << 'END'
#define FOO "bar"
int zap (int x, char y);
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE test-id
$MAKE distcheck

:
