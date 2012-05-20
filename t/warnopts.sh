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

. ./defs || Exit 1

cat >>configure.ac <<END
AC_CONFIG_FILES([sub/Makefile])
AM_CONDITIONAL([COND_FALSE], [false])
AC_OUTPUT
END

mkdir sub

# These two Makefile contain the same errors, but have different
# warnings disabled.

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = -Wno-unsupported
if COND_FALSE
AUTOMAKE_OPTIONS += no-dependencies
endif
foo_SOURCES = unused
SUBDIRS = sub
END

cat > sub/Makefile.am << 'END'
AUTOMAKE_OPTIONS = -Wno-syntax
if COND_FALSE
AUTOMAKE_OPTIONS += no-dependencies
endif
foo_SOURCES = unused
END

$ACLOCAL
AUTOMAKE_fails
# The expected diagnostic is
#   automake: warnings are treated as errors
#   Makefile.am:5: warning: variable 'foo_SOURCES' is defined but no program or
#   Makefile.am:5: library has 'foo' as canonical name (possible typo)
#   sub/Makefile.am:1: warning: 'AUTOMAKE_OPTIONS' cannot have conditional contents
grep '^Makefile.am:.*foo_SOURCES' stderr
grep '^sub/Makefile.am:.*AUTOMAKE_OPTIONS' stderr
grep '^sub/Makefile.am:.*foo_SOURCES' stderr && Exit 1
grep '^Makefile.am:.*AUTOMAKE_OPTIONS' stderr && Exit 1
# Only three lines of warnings.
test `grep -v 'warnings are treated as errors' stderr | wc -l` = 3

rm -rf autom4te*.cache

# If we add a global -Wnone, all warnings should disappear.
cat >configure.ac <<END
AC_INIT([warnopts], [1.0])
AM_INIT_AUTOMAKE([-Wnone])
AC_CONFIG_FILES([Makefile sub/Makefile])
AC_OUTPUT
END
$ACLOCAL
$AUTOMAKE

:
