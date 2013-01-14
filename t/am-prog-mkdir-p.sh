#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Check that the AM_PROG_MKDIR_P macro is deprecated, but still works.
# We should should also still define $(mkdir_p), for backward
# compatibility.

. test-init.sh

cat >> configure.ac <<'END'
AC_CONFIG_FILES([sub/Makefile])
AM_PROG_MKDIR_P
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub
all-local:
	$(MKDIR_P) . dir1/a
	$(mkdir_p) . dir2/b
	@MKDIR_P@ . dir3/c
	@mkdir_p@ . dir4/d
check-local: all
	test -d dir1/a
	test -d dir2/b
	test -d dir3/c
	test -d dir4/d
	test -d dir5/e
	test -d dir5/f
	test -d dir5/g
END

mkdir sub
cat > sub/Makefile.am << 'END'
# Even '$(mkdir_p)' should continue to work also in subdir makefiles.
all-local:
	$(MKDIR_P) .. ../dir5/d
	$(mkdir_p) .. ../dir5/e
	@MKDIR_P@ .. ../dir5/f
	@mkdir_p@ .. ../dir5/g
END

$ACLOCAL
$AUTOCONF -Wnone -Wobsolete -Werror 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep "^configure\\.ac:5:.*'AM_PROG_MKDIR_P'.*deprecated" stderr
grep "[Aa]utoconf-provided 'AC_PROG_MKDIR_P'.* instead" stderr
grep "'\$(MKDIR_P)' instead of '\$(mkdir_p)'" stderr

$AUTOCONF -Wno-obsolete
$AUTOMAKE

./configure
$MAKE check-local
$MAKE distcheck

:
