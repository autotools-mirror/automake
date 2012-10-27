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

# If we have a Makefile containing a file inclusion like this:
#
#   include .//foo.mk
#
# Solaris 10 make fails with a message like:
#
#   make: ... can't find '/foo.mk': No such file or directory
#   make: fatal error ... read of include file '/foo.mk' failed
#
# (even if the file 'foo.mk' exists).  Our dependency tracking support
# code used to generate include directives like that sometimes, thus
# causing spurious failures.
#
# GNU make shouldn't suffer from that Solaris make bug, but we check
# the problematic setup anyway -- better safe than sorry.

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = foo
## The './/' below is meant.
foo_SOURCES = .//src/foo.c
END

mkdir src

cat > src/foo.c << 'END'
int main(void)
{
  return 0;
}
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure --enable-dependency-tracking

$MAKE
depdir=src/.deps
ls -l "$depdir"
test -f "$depdir"/foo.Po

echo 'quux:; echo "z@rd@z" >$@' >> "$depdir"/foo.Po

$MAKE quux
$FGREP "z@rd@z" quux

$MAKE

DISTCHECK_CONFIGURE_FLAGS='--enable-dependency-tracking' $MAKE distcheck
DISTCHECK_CONFIGURE_FLAGS='--disable-dependency-tracking' $MAKE distcheck

:
