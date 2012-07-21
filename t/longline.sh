#! /bin/sh
# Copyright (C) 2004-2012 Free Software Foundation, Inc.
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

# Long lines of = and += should be wrapped.
# Report from Simon Josefsson.

. ./defs || exit 1

i=0
while test $i -lt 30; do
  echo some_very_very_long_variable_content_$i
  i=$(($i + 1))
done > t

{ echo "DUMMY =" && sed 's/^/DUMMY +=/' t; } > Makefile.am
{ echo "ZARDOZ =" && cat t; } | tr '\012\015' '  ' >> Makefile.am

$ACLOCAL
$AUTOMAKE
grep long_variable Makefile.in # For debugging.
test 80 -ge $(grep DUMMY Makefile.in | wc -c)
test 80 -ge $(grep ZARDOZ Makefile.in | wc -c)

:
