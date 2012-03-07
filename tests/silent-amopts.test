#!/bin/sh
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

# Check that automake complaints if the 'silent-rules' option is
# used in AUTOMAKE_OPTIONS.

. ./defs || Exit 1

echo AUTOMAKE_OPTIONS = silent-rules > Makefile.am

$ACLOCAL
AUTOMAKE_fails
grep "^Makefile\.am:1:.*'silent-rules'.*AM_INIT_AUTOMAKE" stderr

:
