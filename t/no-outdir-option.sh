#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Check that the '-o' aka '--output-dir' option is not recognized anymore.

. ./defs || Exit 1

: > Makefile.am

AUTOMAKE_fails -Wno-error --output-dir=foo
grep 'unrecognized option.*--output-dir' stderr

AUTOMAKE_fails -Wno-error -o foo
grep 'unrecognized option.*-o' stderr

:
