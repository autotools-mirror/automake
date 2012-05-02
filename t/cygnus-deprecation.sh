#! /bin/sh
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

# Check that support for Cygnus-style trees is deprecated.
# That feature will be removed in the next major Automake release.
# See automake bug#11034.

. ./defs || Exit 1

warn_rx='support for Cygnus.*trees.*deprecated'

cat >> configure.ac <<'END'
AC_PROG_CC
AM_MAINTAINER_MODE
END

$ACLOCAL
$AUTOCONF

: > Makefile.am

# 'cygnus' option from command line
$AUTOMAKE --cygnus -Wno-obsolete
AUTOMAKE_fails --cygnus
grep "^automake.*: .*$warn_rx" stderr
AUTOMAKE_fails -Wnone -Wobsolete --cygnus
grep "^automake.*: .*$warn_rx" stderr
AUTOMAKE_fails --cygnus -Wnone -Wobsolete
grep "^automake.*: .*$warn_rx" stderr

rm -rf autom4te*.cache

# 'cygnus' option in Makefile.am
echo "AUTOMAKE_OPTIONS = cygnus" > Makefile.am
cat Makefile.am # For debugging.
$AUTOMAKE -Wno-obsolete
AUTOMAKE_fails
grep "^Makefile\.am:1:.*$warn_rx" stderr
AUTOMAKE_fails -Wnone -Wobsolete
grep "^Makefile\.am:1:.*$warn_rx" stderr

rm -rf autom4te*.cache

# 'cygnus' option in configure.ac
: > Makefile.am
sed "s|^\\(AM_INIT_AUTOMAKE\\).*|\1([cygnus])|" configure.ac > t
diff configure.ac t && fatal_ "failed to edit configure.ac"
mv -f t configure.ac
$AUTOMAKE -Wno-obsolete
AUTOMAKE_fails
grep "^configure\.ac:2:.*$warn_rx" stderr
AUTOMAKE_fails -Wnone -Wobsolete
grep "^configure\.ac:2:.*$warn_rx" stderr

:
