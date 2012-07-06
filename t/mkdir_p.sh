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

# AM_INIT_AUTOMAKE should still define $(mkdir_p), for backward
# compatibility.

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub
all-local:
	$(mkdir_p) . dir1/dir2
check-local: all
	test -d dir1/dir2
	test -d dir1/dir3
END

mkdir sub
cat > sub/Makefile.am << 'END'
# '$(mkdir_p)' should continue to work even in subdir makefiles.
all-local:
	$(mkdir_p) .. ../dir1/dir3
END

$ACLOCAL
$AUTOCONF -Werror -Wall
$AUTOMAKE

./configure
$MAKE check-local
$MAKE distcheck

:
