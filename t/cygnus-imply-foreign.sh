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

# Check that 'cygnus' mode imply 'foreign' mode.

. ./defs || Exit 1

cat >> configure.ac <<'END'
# This is *required* in cygnus mode
AM_MAINTAINER_MODE
END

$ACLOCAL

: > Makefile.am

# We want complete control automake flags, while honouring the
# user overrides for $AUTOMAKE.
AUTOMAKE=$am_original_AUTOMAKE

# Sanity check: gnu mode must complain about missing files and
# portability problems.
AUTOMAKE_fails
grep 'required file.*README' stderr

# But cygnus mode should imply foreign mode, so no complaints.
# And cygnus mode should by able to override gnu and gnits modes.
$AUTOMAKE --cygnus -Werror
$AUTOMAKE --gnu --cygnus -Werror
$AUTOMAKE --gnits --cygnus -Werror

# Try again, this time enabling cygnus mode from Makefile.am.
cp Makefile.am Makefile.sav
echo 'AUTOMAKE_OPTIONS = gnu cygnus' >> Makefile.am
$AUTOMAKE -Werror
mv -f Makefile.sav Makefile.am

# Try again, this time enabling cygnus mode from configure.ac.
cp configure.ac configure.sav
sed 's/^AM_INIT_AUTOMAKE/&([gnits cygnus])/' configure.sav >configure.ac
cmp configure.ac configure.sav && fatal_ 'failed to edit configure.ac'

$ACLOCAL --force
$AUTOMAKE -Werror
mv -f configure.sav configure.ac

:
