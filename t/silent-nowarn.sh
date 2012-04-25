#!/bin/sh
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

# Check that the 'silent-rules' mode suppresses the warnings for recursive
# make variable expansions.  This should happen regardless of whether and
# where these warnings are requested.

. ./defs || Exit 1

cat > configure.ac <<END
AC_INIT([$me], [1.0])
# Yes, we repeat the warnings two times, both before and after
# 'silent-rules'.  This is deliberate.
AM_INIT_AUTOMAKE([gnu -Wall -Wportability-recursive
                      silent-rules
                      -Wall -Wportability-recursive])
AC_CONFIG_FILES([Makefile])
END

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = gnu -Wall -Wportability-recursive
foo = $($(v)) $(x$(v)) $($(v)x) $(y$(v)z)
END

# Files required bu gnu strictness.
touch AUTHORS ChangeLog COPYING INSTALL NEWS README THANKS

$ACLOCAL
$AUTOMAKE --gnu -Wall -Wportability-recursive

:
