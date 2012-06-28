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

# Make sure we warn about possible variable typos when we should.

. ./defs || exit 1

: > ltmain.sh

cat >> configure.ac <<'END'
m4_define([AC_PROG_RANLIB], [AC_SUBST([RANLIB],  [who-cares])])
m4_define([AM_PROG_AR],     [AC_SUBST([AR],      [who-cares])])
m4_define([LT_INIT],        [AC_SUBST([LIBTOOL], [who-cares])])
LT_INIT
AM_PROG_AR
AC_PROG_RANLIB
AC_OUTPUT
END

cat > Makefile.am <<'END'
foo_SOURCES =
dist_foo_SOURCES =
nodist_foo_SOURCES =
EXTRA_foo_SOURCES =
EXTRA_dist_foo_SOURCES =
EXTRA_nodist_foo_SOURCES =

foo_DEPENDENCIES =
EXTRA_foo_DEPENDENCIES =

foo_LDADD =
foo_LDFLAGS =
EXTRA_foo_LDADD =
EXTRA_foo_LDFLAGS =

libfoo_a_SOURCES =
dist_libfoo_a_SOURCES =
nodist_libfoo_a_SOURCES =
EXTRA_libfoo_a_SOURCES =
EXTRA_dist_libfoo_a_SOURCES =
EXTRA_nodist_libfoo_a_SOURCES =

libfoo_a_DEPENDENCIES =
EXTRA_libfoo_a_DEPENDENCIES =

libfoo_a_LIBADD =
EXTRA_libfoo_a_LIBADD =
libfoo_a_LDFLAGS =
EXTRA_libfoo_a_LDFLAGS =

libbar_la_SOURCES =
dist_libbar_la_SOURCES =
nodist_libbar_la_SOURCES =
EXTRA_libbar_la_SOURCES =
EXTRA_dist_libbar_la_SOURCES =
EXTRA_nodist_libbar_la_SOURCES =

libbar_la_DEPENDENCIES =
EXTRA_libbar_la_DEPENDENCIES =

libbar_la_LIBADD =
EXTRA_libbar_la_LIBADD =
libbar_la_LDFLAGS =
EXTRA_libbar_la_LDFLAGS =

.PHONY: nihil
nihil:
	@:
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE nihil 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2

$FGREP 'as canonical' stderr \
  | $EGREP -v " '(foo|libfoo_a|libbar_la)' " && exit 1
test 36 -eq $(grep -c 'variable.*is defined but' stderr)

# If matching programs or libraries are defined, all errors should
# disappear.
cat >> Makefile.am <<'END'
bin_PROGRAMS = foo
lib_LIBRARIES = libfoo.a
lib_LTLIBRARIES = libbar.la
END

# FIXME!  We have to remake the Makefile by hand!  This is unacceptable.
$AUTOMAKE Makefile
./config.status Makefile
$MAKE nihil

:
