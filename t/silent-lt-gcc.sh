#!/bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Check silent-rules mode, with libtool, non-fastdep case
# (so that, with GCC, we also cover the other code paths in depend2).

# Please keep this file in sync with 'silent-lt-generic.sh'.

required="libtoolize gcc"
. test-init.sh

mkdir sub

cat >>configure.ac <<'EOF'
AC_PROG_CC
AM_PROG_AR
AM_PROG_CC_C_O
AC_PROG_LIBTOOL
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
# Need generic and non-generic rules.
lib_LTLIBRARIES = libfoo.la libbar.la sub/libbaz.la sub/libbla.la
libbar_la_CFLAGS = $(AM_CFLAGS)
# Need generic and non-generic rules.
sub_libbla_la_CFLAGS = $(AM_CFLAGS)
EOF

echo 'int main (void) { return 0; }' > libfoo.c
cp libfoo.c libbar.c
cp libfoo.c sub/libbaz.c
cp libfoo.c sub/libbla.c

libtoolize
$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

./configure am_cv_CC_dependencies_compiler_type=gcc --enable-silent-rules
$MAKE >stdout || { cat stdout; exit 1; }
cat stdout
$EGREP ' (-c|-o)|(mv|mkdir) '             stdout && exit 1
grep ' CC  *libfoo\.lo'                   stdout
grep ' CC  *libbar_la-libbar\.lo'         stdout
grep ' CC  *sub/libbaz\.lo'               stdout
grep ' CC  *sub/sub_libbla_la-libbla\.lo' stdout
grep ' CCLD  *libfoo\.la'                 stdout
grep ' CCLD  *libbar\.la'                 stdout
grep ' CCLD  *sub/libbaz\.la'             stdout
grep ' CCLD  *sub/libbla\.la'             stdout

$MAKE clean
$MAKE V=1 >stdout || { cat stdout; exit 1; }
cat stdout
grep ' -c' stdout
grep ' -o libfoo' stdout
grep ' -o sub/libbaz' stdout
# The libtool command line can contain e.g. a '--tag=CC' option.
sed 's/--tag=[^ ]*/--tag=x/g' stdout | $EGREP '(CC|LD) ' && exit 1

:
