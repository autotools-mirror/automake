#! /bin/sh
# Copyright (C) 2011-2013 Free Software Foundation, Inc.
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

# Check that AUTOMAKE_OPTIONS support variable expansion.

am_create_testdir=empty
. test-init.sh

# We want complete control over automake options.
AUTOMAKE=$am_original_AUTOMAKE

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([-Wall -Werror gnu])
AC_CONFIG_FILES([Makefile])
AC_PROG_CC
AC_PROG_RANLIB
# The absence of AM_PROG_AR will give a warning with
# '-Wextra-portability', which we want to elicit.
END

cat > Makefile.am <<'END'
# The following should expand to:
#   no-dist -Wnone -Wno-error foreign -Wextra-portability
AUTOMAKE_OPTIONS = $(foo) foreign
AUTOMAKE_OPTIONS += ${bar}
foo = $(foo1)
foo1 = ${foo2}
foo2 = no-dist -Wnone
foo2 += $(foo3)
foo3 = -Wno-error
bar = -Wextra-portability
noinst_LIBRARIES = libfoo.a
# This would give a warning with '-Woverride'.
install:
END

: > compile
: > missing
: > depcomp
: > install-sh

$ACLOCAL
AUTOMAKE_run
$FGREP 'AM_PROG_AR' stderr
$FGREP 'README' stderr && exit 1
$EGREP '(install|override)' stderr && exit 1
$EGREP 'distdir|\.tar[ .]' Makefile.in && exit 1

:
