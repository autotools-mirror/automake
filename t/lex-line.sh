#! /bin/sh
# Copyright (C) 2011-2013 Free Software Foundation, Inc.
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

# Check that automake lex support ensures that lex-generated C
# files use correct "#line" directives.
# 'subdir-object' option enabled.
# See also sister test 'yacc-line.sh'.

required='cc lex'
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_LEX
AC_OUTPUT
END

mkdir dir sub sub/dir

cat > Makefile.am << 'END'
bin_PROGRAMS = foo bar
LDADD = $(LEXLIB)
bar_LFLAGS = -v
foo_SOURCES = zardoz.l
bar_SOURCES = dir/quux.l
END

cat > zardoz.l << 'END'
%{
#define YY_NO_UNISTD_H 1
%}
%%
"END"  return EOF;
.
%%
int main ()
{
  while (yylex () != EOF)
    ;
  return 0;
}

/* Avoid possible link errors. */
int yywrap (void)
{
  return 1;
}
END

cp zardoz.l dir/quux.l

c_outputs='zardoz.c dir/bar-quux.c'

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
  $EGREP 'line|\.l' $c_outputs

  grep '#.*line.*build.*\.l' $c_outputs && exit 1
  # Adjusted "#line" should not contain reference to the absolute
  # srcdir.
  $EGREP '#.*line *"?/.*\.l' $c_outputs && exit 1
  # Adjusted "#line" should not contain reference to the default
  # output file names, e.g., 'lex.yy.c'.
  grep '#.*line.*lex\.yy' $c_outputs && exit 1
  # Look out for a silly regression.
  grep "#.*\.l.*\.l" $c_outputs && exit 1
  if $vpath; then
    grep '#.*line.*"\.\./zardoz\.l"' zardoz.c
    grep '#.*line.*"\.\./dir/quux\.l"' dir/bar-quux.c
  else
    grep '#.*line.*"zardoz\.l"' zardoz.c
    grep '#.*line.*"dir/quux\.l"' dir/bar-quux.c
  fi

  cd $srcdir

done

:
