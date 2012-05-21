#! /bin/sh
# Copyright (C) 2004-2012 Free Software Foundation, Inc.
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

# Test to make sure that if an auxfile (here depcomp) is required
# by a subdir Makefile.am, it is distributed by that Makefile.am.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([subdir/Makefile])
AC_PROG_CC
AC_PROG_FGREP
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = subdir
END

rm -f depcomp
mkdir subdir

cat > subdir/Makefile.am << 'END'
.PHONY: test-distcommon
test-distcommon:
	echo ' ' $(am__dist_common) ' ' | $(FGREP) ' $(top_srcdir)/depcomp '
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
test ! -f depcomp

cat >> subdir/Makefile.am << 'END'
bin_PROGRAMS = foo
END

: > subdir/foo.c

$AUTOMAKE -a subdir/Makefile
test -f depcomp
./configure
(cd subdir && $MAKE test-distcommon)
$MAKE distdir
test -f $distdir/depcomp

:
