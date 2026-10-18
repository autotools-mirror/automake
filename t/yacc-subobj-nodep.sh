#! /bin/sh
# Copyright (C) 2011-2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Ensure subdir parsers and headers can be generated in a VPATH build
# with dependency tracking disabled.  Cover both suffix and explicit rules.
# https://bugs.gnu.org/27188; https://bugs.debian.org/807050

required='cc c++ yacc'
. test-init.sh

cat >>configure.ac <<\END
AC_PROG_CC
AC_PROG_CXX
AC_PROG_YACC
AC_OUTPUT
END

cat >Makefile.am <<\END
AUTOMAKE_OPTIONS = subdir-objects
AM_YFLAGS = -d
bin_PROGRAMS = p1 p2
p1_SOURCES = sub1/parse.y
p2_SOURCES =
nodist_p2_SOURCES = sub2/parse.yy
END

mkdir sub1 sub2
cat >sub1/parse.y <<\END
%{
int yylex (void) { return 0; }
void yyerror (const char *s) {}
%}
%%
start: ;
%%
int main (void) { return yyparse (); }
END
cp sub1/parse.y sub2/parse.yy

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
mkdir build
cd build
../configure --disable-dependency-tracking
$MAKE sub1/parse.c
$MAKE sub2/parse.cc
test -f sub1/parse.h
test -f sub2/parse.hh
rm -rf sub1 sub2
$MAKE
./p1
./p2

:
