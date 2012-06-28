#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# Yacc + C++ support for a program built only from yacc sources.
# Lex + C++ support for a program built only from lex sources.

required='c++ yacc'
. ./defs || exit 1

cat >> configure.ac << 'END'
AC_PROG_CXX
AC_PROG_LEX
AC_PROG_YACC
AC_OUTPUT
END

cat > Makefile.am << 'END'
bin_PROGRAMS = foo bar
foo_SOURCES = foo.yy
bar_SOURCES = bar.lxx

.PHONY: check-dist
check-dist: distdir
	echo ' ' $(am__dist_common) ' ' | grep '[ /]foo\.cc'
	echo ' ' $(am__dist_common) ' ' | grep '[ /]bar\.cxx'
	ls -l $(distdir)
	test -f $(distdir)/foo.cc
	test -f $(distdir)/bar.cxx
END

cat > foo.yy << 'END'
%{
// Valid C++, but deliberately invalid C.
#include <cstdio>
#include <cstdlib>
// "std::" qualification required by Sun C++ 5.9.
int yylex (void) { return std::getchar (); }
void yyerror (const char *s) { return; }
%}
%%
a : 'a' { exit(0); };
%%
int main (void)
{
  yyparse ();
  return 1;
}
END

cat > bar.lxx << 'END'
%{
#define YY_NO_UNISTD_H 1
int isatty (int fd) { return 0; }
%}
%%
"x" return EOF;
.
%%
// Valid C++, but deliberately invalid C.
#include <cstdlib>
int main (void)
{
  /* We don't use a 'while' loop here (like a real lexer would do)
     to avoid possible hangs. */
  if (yylex () == EOF)
    std::exit (0);
  else
    std::exit (1);
}

/* Avoid possible link errors. */
int yywrap (void) { return 1; }
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE

# The Yacc-derived and Lex-derived C++ sources must be created, and not
# removed once compiled (i.e., not treated like "intermediate files" in
# the GNU make sense).
test -f foo.cc
test -f bar.cxx

if cross_compiling; then :; else
  echo a | ./foo
  echo b | ./foo && exit 1
  echo x | ./bar
  echo y | ./bar && exit 1
  : # Don't trip on 'set -e'.
fi

# The Yacc-derived and Lex-derived C++ sources must be shipped.
$MAKE check-dist

# Sanity check on distribution.
$MAKE distcheck

:
