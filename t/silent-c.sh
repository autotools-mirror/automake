#!/bin/sh
# Copyright (C) 2009-2013 Free Software Foundation, Inc.
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

# Check silent-rules mode for C, without libtool, both with and without
# automatic dependency tracking.

required=cc
. test-init.sh

mkdir sub

cat >>configure.ac <<'EOF'
AC_PROG_CC
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
# Need generic and non-generic rules.
bin_PROGRAMS = foo bar sub/baz sub/bla
bar_CFLAGS = $(AM_CFLAGS)
sub_bla_CFLAGS = $(AM_CFLAGS)
EOF

echo 'int main (void) { return 0; }' > foo.c
cp foo.c bar.c
cp foo.c sub/baz.c
cp foo.c sub/bla.c

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

for config_args in \
  '--enable-dependency-tracking' \
  '--disable-dependency-tracking' \
; do

  ./configure --enable-silent-rules $config_args
  run_make -O
  $EGREP ' (-c|-o)|(mv|mkdir) '   stdout && exit 1
  grep ' CC  *foo\.o'             stdout
  grep ' CC  *bar-bar\.o'         stdout
  grep ' CC  *sub/baz\.o'         stdout
  grep ' CC  *sub/sub_bla-bla\.o' stdout
  grep ' CCLD  *foo'              stdout
  grep ' CCLD  *bar'              stdout
  grep ' CCLD  *sub/baz'          stdout
  grep ' CCLD  *sub/bla'          stdout

  $MAKE clean
  run_make -O V=1
  grep ' -c' stdout
  grep ' -o foo' stdout
  grep ' -o sub/baz' stdout
  $EGREP '(CC|LD) ' stdout && exit 1

  $MAKE distclean

done

:
