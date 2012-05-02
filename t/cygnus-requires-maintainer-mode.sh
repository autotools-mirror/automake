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

# Check that, in cygnus mode, maintainer mode is required.

. ./defs || Exit 1

: > Makefile.am

$ACLOCAL
AUTOMAKE_fails -Wno-obsolete --cygnus
grep '^configure\.ac:.*AM_MAINTAINER_MODE.*required.*cygnus' stderr

cat >> configure.ac <<'END'
AC_CONFIG_FILES([sub/Makefile])
END

cat > Makefile.am <<'END'
SUBDIRS = sub
END

mkdir sub
cat > sub/Makefile.am <<'END'
AUTOMAKE_OPTIONS = -Wno-obsolete cygnus
END

rm -rf autom4te.cache
$ACLOCAL
AUTOMAKE_fails
grep '^configure\.ac:.*AM_MAINTAINER_MODE.*required.*cygnus' stderr

cat >> configure.ac <<'END'
AM_MAINTAINER_MODE
END

rm -rf autom4te.cache
$ACLOCAL
$AUTOMAKE --cygnus -Wno-obsolete

:
