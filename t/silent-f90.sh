#!/bin/sh
# Copyright (C) 2010-2013 Free Software Foundation, Inc.
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

# Check silent-rules mode for Fortran 90.
# Keep this ins sync with the sister test 'silent-f77.sh'.

required=fortran
. test-init.sh

mkdir sub

cat >>configure.ac <<'EOF'
AC_PROG_FC
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
# Need generic and non-generic rules.
bin_PROGRAMS = foo1 foo2 sub/bar1 bar2
foo1_SOURCES = foo.f90
foo2_SOURCES = $(foo1_SOURCES)
foo2_FCFLAGS = $(AM_FCLAGS)
sub_bar1_SOURCES = sub/bar.f90
bar2_SOURCES = $(sub_bar1_SOURCES)
bar2_FCFLAGS = $(AM_FCLAGS)
EOF

cat > foo.f90 <<'EOF'
      program foo
      stop
      end
EOF
cp foo.f90 sub/bar.f90

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

./configure --enable-silent-rules
run_make -O
# Avoid spurious failures with SunStudio Fortran compilers.
sed '/^NOTICE:/d' stdout > t
mv -f t stdout
cat stdout

$EGREP ' (-c|-o)' stdout && exit 1
grep 'mv ' stdout && exit 1

grep ' FC  *foo\.'          stdout
grep ' FC  *foo2-foo\.'     stdout
grep ' FC  *sub/bar\.'      stdout
grep ' FC  *sub/bar2-bar\.' stdout
grep ' FCLD  *foo1'         stdout
grep ' FCLD  *foo2'         stdout
grep ' FCLD  *sub/bar1'     stdout
grep ' FCLD  *bar2'         stdout

$EGREP '(F77|F77LD) ' stdout && exit 1

# Ensure a clean rebuild.
$MAKE clean

run_make -O V=1

grep ' -c ' stdout
grep ' -o ' stdout

$EGREP '(F77|FC|LD) ' stdout && exit 1

:
