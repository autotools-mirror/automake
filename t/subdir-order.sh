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

# The $(SUDBIRS) entries are processed in the order they are specified.

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([
  sub0/Makefile
  sub1/Makefile
  sub2/Makefile
  sub3/Makefile
  sub3/a/Makefile
  sub3/b/Makefile
])
AC_OUTPUT
END

mkdir sub0 sub1 sub2 sub3 sub3/a sub3/b

cat > Makefile.am << 'END'
SUBDIRS = sub2 sub1 sub3 sub0
all-local:
	test -f sub0/run
	test -f sub1/run
	test -f sub2/run
	test -f sub3/run
	test -f sub3/a/run
	test -f sub3/b/run
	test ! -f run
	: > run

CLEANFILES = \
  run \
  sub0/run \
  sub1/run \
  sub2/run \
  sub3/run \
  sub3/a/run \
  sub3/b/run
END

cat > sub0/Makefile.am << 'END'
all-local:
	test ! -f $(top_builddir)/run
	test -f $(top_builddir)/sub1/run
	test -f $(top_builddir)/sub3/run
	test -f $(top_builddir)/sub3/a/run
	test -f $(top_builddir)/sub3/b/run
	test ! -f run
	: > run
END

cat > sub1/Makefile.am << 'END'
all-local:
	test ! -f $(top_builddir)/run
	test ! -f $(top_builddir)/sub0/run
	test -f $(top_builddir)/sub2/run
	test ! -f $(top_builddir)/sub3/run
	test ! -f $(top_builddir)/sub3/a/run
	test ! -f $(top_builddir)/sub3/b/run
	test ! -f run
	: > run
END


cat > sub2/Makefile.am << 'END'
all-local:
	test ! -f $(top_builddir)/run
	test ! -f $(top_builddir)/sub0/run
	test ! -f $(top_builddir)/sub1/run
	test ! -f $(top_builddir)/sub3/run
	test ! -f $(top_builddir)/sub3/a/run
	test ! -f $(top_builddir)/sub3/b/run
	test ! -f run
	: > run
END

cat > sub3/Makefile.am << 'END'
SUBDIRS = b . a
all-local:
	test ! -f $(top_builddir)/run
	test ! -f $(top_builddir)/sub0/run
	test -f $(top_builddir)/sub1/run
	test ! -f $(top_builddir)/sub3/a/run
	test -f $(top_builddir)/sub3/b/run
	test ! -f run
	: > run
END

cat > sub3/a/Makefile.am << 'END'
all-local:
	test ! -f $(top_builddir)/run
	test ! -f $(top_builddir)/sub0/run
	test -f $(top_builddir)/sub1/run
	test -f $(top_builddir)/sub3/b/run
	test -f $(top_builddir)/sub3/run
	test ! -f run
	: > run
END

cat > sub3/b/Makefile.am << 'END'
all-local:
	test ! -f $(top_builddir)/run
	test ! -f $(top_builddir)/sub0/run
	test -f $(top_builddir)/sub1/run
	test ! -f $(top_builddir)/sub3/b/run
	test ! -f $(top_builddir)/sub3/run
	test ! -f run
	: > run
END


$ACLOCAL
$AUTOCONF
$AUTOMAKE -c --add-missing

./configure

for j in '' -j12; do
  $MAKE $j
  test -f run
  test -f sub0/run
  test -f sub1/run
  test -f sub3/run
  test -f sub3/a/run
  test -f sub3/b/run
  $MAKE clean
  find . | grep 'run$' && exit 1
  : # For shells with busted 'set -e'
done

:
