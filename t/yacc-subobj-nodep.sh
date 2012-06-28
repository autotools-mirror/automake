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

# Ensure subdirs for subdir parsers are generated when subdir objects
# are used, even when dependency tracking is disabled.

required='cc yacc'
. ./defs || exit 1

cat >configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([no-dependencies])
AC_CONFIG_FILES([Makefile])
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_YACC
AC_OUTPUT
END

cat >Makefile.am <<END
bin_PROGRAMS = p1 p2
p1_SOURCES = sub1/s1.y
p2_SOURCES = sub2/s2.y
p2_CPPFLAGS = -DWHATEVER
END

mkdir sub1 sub2

cat >sub1/s1.y <<END
%{
int yylex () { return 0; }
void yyerror (char *s) { return; }
int main (void) { yyparse (); return 1; }
%}
%%
foobar : 'f' 'o' 'o' 'b' 'a' 'r' {};
END

cp sub1/s1.y sub2/s2.y

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
mkdir build
cd build

# Sanity check.
../configure --help # For debugging.
../configure --help | $EGREP '(dis|en)able-depend' \
  && fatal_ "couldn't disable dependency tracking support globally"

../configure
$MAKE sub1/s1.c
$MAKE sub2/s2.c
rm -rf sub1 sub2
$MAKE

:
