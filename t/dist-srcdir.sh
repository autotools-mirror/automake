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

# We use EXTRA_DIST to distribute stuff *explicitly* from the srcdir.

am_create_testdir=empty
. ./defs || exit 1

ocwd=`pwd` || fatal_ "cannot get current working directory"

mkdir src
cd src

cat >> configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
SUBDIRS = sub

EXTRA_DIST = \
  $(srcdir)/one \
  @srcdir@/two \
  $(top_srcdir)/three \
  @top_srcdir@/four

.PHONY: test
check-local: test
test: distdir
	find $(distdir) # For debugging.
	test -f $(distdir)/one
	test -f $(distdir)/two
	test -f $(distdir)/three
	test -f $(distdir)/four
	test -f $(distdir)/sub/five
	test -f $(distdir)/sub/six
	test ! -f $(distdir)/five
	test ! -f $(distdir)/six
	test -f $(distdir)/seven
	test -f $(distdir)/eight
	test ! -f $(distdir)/sub/seven
	test ! -f $(distdir)/sub/eight
END

mkdir sub
cat > sub/Makefile.am <<'END'
EXTRA_DIST  = $(srcdir)/five @srcdir@/six
EXTRA_DIST += $(top_srcdir)/seven @top_srcdir@/eight
END

touch one two three four sub/five sub/six seven eight

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

mkdir build
cd build
../configure
$MAKE test
$MAKE distcheck
cd "$ocwd"

mkdir a a/b a/b/c
cd a/b/c
../../../src/configure
$MAKE test
cd "$ocwd"

mkdir build2
cd build2
"$ocwd"/src/configure
$MAKE test
cd "$ocwd"

:
