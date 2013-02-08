#! /bin/sh
# Copyright (C) 2013 Free Software Foundation, Inc.
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

# Test %reldir% and %canon_reldir%.

. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_CONFIG_FILES([zot/Makefile])
AC_OUTPUT
END

mkdir foo
mkdir foo/bar
mkdir foo/foobar
mkdir zot

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS =
include $(top_srcdir)/foo/local.mk
include $(srcdir)/foo/foobar/local.mk
include local.mk
END

cat > zot/Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS =
include $(top_srcdir)/zot/local.mk
include $(top_srcdir)/top.mk
include ../reltop.mk
END

cat > local.mk << 'END'
%canon_reldir%_whoami:
	@echo "I am %reldir%/local.mk"

bin_PROGRAMS += %reldir%/mumble
%canon_reldir%_mumble_SOURCES = %reldir%/one.c
END

cat > top.mk << 'END'
%canon_reldir%_top_whoami:
	@echo "I am %reldir%/top.mk"

bin_PROGRAMS += %D%/scream
%C%_scream_SOURCES = %D%/two.c
END

cat > reltop.mk << 'END'
%C%_reltop_whoami:
	@echo "I am %D%/reltop.mk"

bin_PROGRAMS += %reldir%/sigh
%canon_reldir%_sigh_SOURCES = %reldir%/three.c
END

cat > one.c << 'END'
int main(void) { return 0; }
END

cp local.mk foo
cp local.mk foo/bar
cp local.mk foo/foobar
cp local.mk zot
echo "include %reldir%/bar/local.mk" >> foo/local.mk

cp one.c foo
cp one.c foo/bar
cp one.c foo/foobar
cp one.c zot
cp one.c two.c
cp one.c three.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure

$MAKE whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am local.mk" output
$MAKE foo_whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am foo/local.mk" output
$MAKE foo_bar_whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am foo/bar/local.mk" output
$MAKE foo_foobar_whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am foo/foobar/local.mk" output

$MAKE
./mumble
foo/mumble
foo/bar/mumble
foo/foobar/mumble

cd zot

$MAKE ___top_whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am ../top.mk" output
$MAKE ___reltop_whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am ../reltop.mk" output
$MAKE whoami >output 2>&1 || { cat output; exit 1; }
cat output
grep "I am local.mk" output

$MAKE
./mumble
../scream
../sigh
