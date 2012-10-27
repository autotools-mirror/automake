#! /bin/sh
# Copyright (C) 2002-2012 Free Software Foundation, Inc.
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

# Make sure that we can enable or disable warnings on a per-file basis.

. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_CONFIG_FILES([sub/Makefile])
AM_CONDITIONAL([COND_FALSE], [false])
AC_OUTPUT
END

mkdir sub

# These two Makefile contain the same errors, but have different
# warnings disabled.

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects -Wno-unsupported
if COND_FALSE
AUTOMAKE_OPTIONS += no-dependencies
endif
bin_PROGRAMS = foo
foo_SOURCES = sub/foo.c
SUBDIRS = sub
END

cat > sub/Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects -Wno-portability
if COND_FALSE
AUTOMAKE_OPTIONS += no-dependencies
endif
bin_PROGRAMS = foo
foo_SOURCES = sub/foo.c
END

$ACLOCAL
AUTOMAKE_fails
# The expected diagnostic is
#   automake: warnings are treated as errors
#   Makefile.am:6: warning: compiling 'sub/foo.c' in subdir requires 'AM_PROG_CC_C_O' in 'configure.ac'
#   sub/Makefile.am:1: warning: 'AUTOMAKE_OPTIONS' cannot have conditional contents
grep '^Makefile\.am:.*sub/foo\.c.*AM_PROG_CC_C_O' stderr
grep '^sub/Makefile.am:.*AUTOMAKE_OPTIONS' stderr
grep '^sub/Makefile\.am:.*AM_PROG_CC_C_O' stderr && exit 1
grep '^Makefile\.am:.*AUTOMAKE_OPTIONS' stderr && exit 1
# Only two lines of warnings.
test $(grep -v 'warnings are treated as errors' stderr | wc -l) -eq 2

rm -rf autom4te*.cache

# If we add a global -Wnone, all warnings should disappear.
cat >configure.ac <<END
AC_INIT([warnopts], [1.0])
AM_INIT_AUTOMAKE([-Wnone])
AC_CONFIG_FILES([Makefile sub/Makefile])
AC_PROG_CC
AC_OUTPUT
END
$ACLOCAL
$AUTOMAKE

:
