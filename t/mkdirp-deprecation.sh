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

# Check that the AM_PROG_MKDIR_P macro is deprecated; it will be
# be removed in the next major Automake release.  But also check
# that it still works as expected in the current release series.

. ./defs || exit 1

cat >> configure.ac << 'END'
AM_PROG_MKDIR_P
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub
all-local:
	$(mkdir_p) . dir1/a
	@mkdir_p@ . dir2/b
check-local: all
	test -d dir1/a
	test -d dir2/b
	test -d dir3/c
	test -d dir3/d
END

mkdir sub
cat > sub/Makefile.am << 'END'
# '$(mkdir_p)' should continue to work even in subdir makefiles.
all-local:
	$(mkdir_p) .. ../dir3/c
	@mkdir_p@ .. ../dir3/d
END

grep_err ()
{
  loc='^configure.ac:4:'
  grep "$loc.*AM_PROG_MKDIR_P.*deprecated" stderr
  grep "$loc.* use .*AC_PROG_MKDIR_P" stderr
  grep "$loc.* use '\$(MKDIR_P)' instead of '\$(mkdir_p)'.*Makefile" stderr
}

$ACLOCAL

$AUTOCONF -Werror -Wobsolete 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
grep_err

$AUTOCONF -Werror -Wno-obsolete

AUTOMAKE_fails
grep_err
AUTOMAKE_fails --verbose -Wnone -Wobsolete
grep_err

$AUTOMAKE -Wno-obsolete

./configure
$MAKE check-local
$MAKE distcheck

:
