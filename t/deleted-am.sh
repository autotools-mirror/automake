#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# The stub rules emitted to work around the "deleted header problem"
# for '.am' files shouldn't prevent the remake rules from correctly
# erroring out when a still-required file is missing.
# See also discussion about automake bug#9768.

. ./defs || exit 1

echo AC_OUTPUT >> configure.ac

echo 'include $(top_srcdir)/foobar.am' > Makefile.am
echo 'include zardoz.am' > foobar.am
: > zardoz.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE

rm -f zardoz.am
$MAKE 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
# This error will come from automake, not make, so we can be stricter
# in our grepping of it.
grep 'cannot open.*zardoz\.am' stderr
grep 'foobar\.am' stderr && exit 1 # No spurious error, please.

# Try with one less indirection.
: > foobar.am
$AUTOMAKE Makefile
./config.status Makefile
$MAKE # Sanity check.
rm -f foobar.am
$MAKE 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
# This error will come from automake, not make, so we can be stricter
# in our grepping of it.
grep 'cannot open.*foobar\.am' stderr

:
