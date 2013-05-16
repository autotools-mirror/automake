#! /bin/sh
# Copyright (C) 1999-2013 Free Software Foundation, Inc.
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

# Test to make sure header vars defined only once when including.
# Report from Marcus G. Daniels.

. test-init.sh

cat >> configure.ac <<END
AC_OUTPUT
END

cat > Makefile.am << 'END'
include Will_Be_Included_In_Makefile
END

: > Will_Be_Included_In_Makefile

$ACLOCAL
$AUTOMAKE
test $(grep -c '^srcdir' Makefile.in) -eq 1

# Also make sure include file is distributed.
sed -n -e '/^DIST_COMMON =.*\\$/ {
   :loop
   p
   n
   t clear
   :clear
   s/\\$/\\/
   t loop
   p
   n
   }' -e '/^DIST_COMMON =/ p' Makefile.in | grep Will_Be_Included_In_Makefile

:
