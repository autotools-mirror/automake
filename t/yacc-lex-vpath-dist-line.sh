#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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

# Yacc and lex outputs generated in a VPATH build must not carry
# "#line" directives pointing through the srcdir into the distribution
# (automake bug#39666).  The build tree copies must keep them.
# See also 'yacc-line.sh' and 'lex-line.sh'.

required='cc yacc lex'
. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AC_PROG_CC
AC_PROG_YACC
AC_PROG_LEX
AC_OUTPUT
END

mkdir dir sub sub/dir

cat > Makefile.am << 'END'
AM_LFLAGS = --never-interactive
SUBDIRS = sub
noinst_PROGRAMS = foo bar baz
AM_YFLAGS = -d
bar_YFLAGS =
foo_SOURCES = parse.y
bar_SOURCES = dir/quux.y
baz_SOURCES = scan.l
LDADD = $(LEXLIB)
## Avoid spurious failures with Solaris make.
parse.@OBJEXT@: parse.c
bar-quux.@OBJEXT@: bar-quux.c
END

cat > sub/Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
AM_LFLAGS = --never-interactive
noinst_PROGRAMS = foo
foo_SOURCES = dir/parse.y dir/scan.l
LDADD = $(LEXLIB)
## Avoid spurious failures with Solaris make.
dir/parse.@OBJEXT@: dir/parse.c
dir/scan.@OBJEXT@: dir/scan.c
END

cat > parse.y << 'END'
%{
int yylex (void) { return 0; }
void yyerror (const char *s) {}
%}
%%
x : 'x' {};
%%
int main (void)
{
  return yyparse ();
}
END

cp parse.y dir/quux.y
sed 's/main/sub_main/;s/^int yylex (void).*/int yylex (void);/' parse.y \
  > sub/dir/parse.y
echo 'int main (void) { return sub_main (); }' >> sub/dir/parse.y

cat > scan.l << 'END'
%%
"END"  return EOF;
.
%%
int main (void)
{
  return 0;
}
int yywrap (void)
{
  return 1;
}
END

cat > sub/dir/scan.l << 'END'
%%
"END"  return 0;
.
%%
int yywrap (void)
{
  return 1;
}
END

outputs='parse.c parse.h bar-quux.c scan.c sub/dir/parse.c sub/dir/scan.c'

$ACLOCAL
$AUTOCONF
# FIXME: stop disabling the warnings in the 'unsupported' category
# FIXME: once the 'subdir-objects' option has been mandatory.
$AUTOMAKE -a -Wno-unsupported

grep '^am__ylwrap_dist_files' Makefile.in sub/Makefile.in

check_dist ()
{
  srcdir=$1

  $srcdir/configure
  $MAKE
  $MAKE distdir
  ls -l $distdir $distdir/dir $distdir/sub/dir

  # For debugging.
  for f in $outputs; do
    grep '^#.*line' $distdir/$f || :
  done

  # The build tree copies still point to the srcdir.
  grep '^#.*line.*"\.\./\.\./sub/dir/parse\.y"' sub/dir/parse.c \
    || grep "^#.*line.*\"$srcdir/sub/dir/parse\\.y\"" sub/dir/parse.c

  # The distributed copies do not.
  for f in $outputs; do
    $EGREP '^#.*line.*"(\.\./|/)' $distdir/$f && exit 1
  done
  grep '^#.*line.*"parse\.y"' $distdir/parse.c
  grep '^#.*line.*"dir/quux\.y"' $distdir/bar-quux.c
  grep '^#.*line.*"scan\.l"' $distdir/scan.c
  grep '^#.*line.*"dir/parse\.y"' $distdir/sub/dir/parse.c
  grep '^#.*line.*"dir/scan\.l"' $distdir/sub/dir/scan.c

  # The header must not be older than its parser.
  test -z "$(find $distdir/parse.c -newer $distdir/parse.h)"

  $MAKE distcheck
}

# Relative srcdir.
mkdir build
cd build
check_dist ..
cd ..
rm -rf build

# Absolute srcdir.
mkdir build
cd build
check_dist "$(cd .. && pwd)"
cd ..

:
