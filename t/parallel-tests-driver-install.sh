#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# Check that auxiliary script 'test-driver' gets automatically installed
# in the correct directory by 'parallel-tests' option.

. ./defs || Exit 1

: Try first with parallel-tests defined in AM_INIT_AUTOMAKE.

mkdir am-init-automake
cd am-init-automake

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AC_CONFIG_AUX_DIR([my_aux_dir])
AM_INIT_AUTOMAKE([parallel-tests])
AC_CONFIG_FILES([Makefile sub/Makefile])
AC_OUTPUT
END

mkdir sub my_aux_dir

cat > Makefile.am <<END
SUBDIRS = sub
TESTS = foo.test
END

cat > sub/Makefile.am <<END
TESTS = bar.test
END

$ACLOCAL
$AUTOMAKE -a 2>stderr || { cat stderr >&2; Exit 1; }
cat stderr >&2

ls -l . sub my_aux_dir # For debugging.
test -f my_aux_dir/test-driver
test ! -r test-driver
test ! -r sub/test-driver

grep '^configure\.ac:3:.*installing.*my_aux_dir/test-driver' stderr

cd ..

: Now try with parallel-tests defined in AUTOMAKE_OPTIONS.

mkdir automake-options
cd automake-options

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([dir/GNUmakefile])
AC_OUTPUT
END

mkdir build-aux dir

cat > dir/GNUmakefile.am <<END
TESTS = foo.test
AUTOMAKE_OPTIONS = parallel-tests
TESTS += bar.test
END

$ACLOCAL
$AUTOMAKE --add-missing --copy dir/GNUmakefile 2>stderr \
  || { cat stderr >&2; Exit 1; }
cat stderr >&2

ls -l . dir build-aux # For debugging.
test -f build-aux/test-driver
test ! -r test-driver
test ! -r dir/test-driver

grep '^dir/GNUmakefile\.am:2:.*installing.*build-aux/test-driver' stderr

:
