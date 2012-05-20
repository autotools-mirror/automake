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

# In a VPATH build, a target starting with $(srcdir) is triggered to
# build a source with the same name but without the $(srcdir).

required=cc
. ./defs || Exit 1

ocwd=`pwd` || fatal_ "couldn't get current working directory"

cat >> configure.ac <<'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am <<'END'
noinst_PROGRAMS = p1 p2 p3 tp1 tp2 tp3

write-it = echo 'int main (void) { return 0; }' >$@

# We keep all the targets on separate lines to make sure the dumb
# Automake parser actually sees them all.
$(srcdir)/p1.c:
	$(write-it)
${srcdir}/p2.c:
	$(write-it)
@srcdir@/p3.c:
	$(write-it)
$(top_srcdir)/tp1.c:
	$(write-it)
${top_srcdir}/tp2.c:
	$(write-it)
@top_srcdir@/tp3.c:
	$(write-it)
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

mkdir build
cd build
../configure
$MAKE all

cd "$ocwd"
rm -f *.c
mkdir -p sub1/sub2/sub3
cd sub1/sub2/sub3
"$ocwd"/configure --disable-dependency-tracking
$MAKE all

cd "$ocwd"
rm -f *.c
./configure
$MAKE all
$MAKE distcheck

:
