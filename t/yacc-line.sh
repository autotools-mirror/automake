#! /bin/sh
# Copyright (C) 2001-2013 Free Software Foundation, Inc.
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

# Check that automake yacc support ensures that yacc-generated
# C files use correct "#line" directives.
# See also sister test 'lex-line.sh'.

required='cc yacc'
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_PROG_YACC
AC_OUTPUT
END

mkdir dir

cat > Makefile.am << 'END'
noinst_PROGRAMS = foo bar baz
baz_YFLAGS = -d
foo_SOURCES = zardoz.y
bar_SOURCES = dir/quux.y
baz_SOURCES = zardoz.y
END

cat > zardoz.y << 'END'
%{
int yylex () { return 0; }
void yyerror (char *s) { return; }
%}
%%
x : 'x' {};
%%
int main(void)
{
  return yyparse ();
}
END

cp zardoz.y dir/quux.y

c_outputs='zardoz.c dir/quux.c baz-zardoz.c'

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

for vpath in : false; do

  if $vpath; then
    srcdir=..
    mkdir build
    cd build
  else
    srcdir=.
  fi

  $srcdir/configure
  $MAKE

  # For debugging,
  ls -l . dir
  $EGREP 'line|\.y' $c_outputs

  # Adjusted "#line" should not contain reference to the builddir.
  grep '#.*line.*build.*\.y' $c_outputs && exit 1
  # Adjusted "#line" should not contain reference to the absolute
  # srcdir.
  $EGREP '#.*line *"?/.*\.y' $c_outputs && exit 1
  # Adjusted "#line" should not contain reference to the default
  # output file names, e.g., 'y.tab.c' and 'y.tab.h'.
  grep '#.*line.*y\.tab\.' $c_outputs && exit 1
  # Look out for a silly regression.
  grep "#.*\.y.*\.y" $c_outputs && exit 1
  if $vpath; then
    grep '#.*line.*"\.\./zardoz\.y"' zardoz.c
    grep '#.*line.*"\.\./zardoz\.y"' baz-zardoz.c
    grep '#.*line.*"\.\./dir/quux\.y"' dir/quux.c
  else
    grep '#.*line.*"zardoz\.y"' zardoz.c
    grep '#.*line.*"zardoz\.y"' baz-zardoz.c
    grep '#.*line.*"dir/quux\.y"' dir/quux.c
  fi

  cd $srcdir

done

:
