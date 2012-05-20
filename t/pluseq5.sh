#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
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

# Test for another '+=' problem.  Report from Brian Jones.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AM_CONDITIONAL([CHECK], [true])
END

cat > Makefile.am << 'END'
if CHECK
AM_CPPFLAGS = abc
endif
AM_CPPFLAGS += def
END

$ACLOCAL
AUTOMAKE_fails

# We expect the following diagnostic:
#
# Makefile.am:4: cannot apply '+=' because 'AM_CPPFLAGS' is not defined in
# Makefile.am:4: the following conditions:
# Makefile.am:4:   !CHECK
# Makefile.am:4: either define 'AM_CPPFLAGS' in these conditions, or use
# Makefile.am:4: '+=' in the same conditions as the definitions.

# Is !CHECK mentioned?
grep ':.*!CHECK$' stderr
# Is there only one missing condition?
test `grep ':  ' stderr | wc -l` = 1

:
