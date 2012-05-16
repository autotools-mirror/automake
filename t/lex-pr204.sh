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

# Related to PR 204.
# C sources derived from nodist_ lex sources should not be distributed.
# See also related test 'lex-nodist.test'.
# The tests 'yacc-nodist.test' and 'yacc-pr204.test' does similar checks
# for yacc-generated .c and .h files.

required='cc lex'
. ./defs || Exit 1

cat >> configure.ac <<'EOF'
AM_MAINTAINER_MODE
AC_PROG_CC
dnl We use AC_PROG_LEX deliberately.
dnl Sister 'lex-nodist.test' should use 'AM_PROG_LEX' instead.
AC_PROG_LEX
AC_OUTPUT
EOF

# The LEXER2 intermediate variable is there to make sure Automake
# matches 'nodist_' against the right variable name...
cat > Makefile.am << 'EOF'
EXTRA_PROGRAMS = foo
LEXER2 = lexer2.l
nodist_foo_SOURCES = lexer.l $(LEXER2)

distdirtest: distdir
	test ! -f $(distdir)/lexer.c
	test ! -f $(distdir)/lexer.l
	test ! -f $(distdir)/lexer.h
	test ! -f $(distdir)/lexer2.c
	test ! -f $(distdir)/lexer2.l
	test ! -f $(distdir)/lexer2.h
EOF

cat > lexer.l << 'END'
%{
#define YY_NO_UNISTD_H 1
%}
%%
"GOOD"   return EOF;
.
%%
int main (void)
{
  return yylex ();
}
END

cp lexer.l lexer2.l

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE distdirtest

# Make sure lexer.c and lexer2.c are still targets.
$MAKE lexer.c lexer2.c
test -f lexer.c
test -f lexer2.c

# Ensure the rebuild rule works despite AM_MAINTAINER_MODE, because
# it's a nodist_ lexer.
$sleep
touch lexer.l lexer2.l
$sleep
$MAKE lexer.c lexer2.c
stat lexer.c lexer.l lexer2.c lexer2.l || : # For debugging.
test `ls -t lexer.c lexer.l | sed 1q` = lexer.c
test `ls -t lexer2.c lexer2.l | sed 1q` = lexer2.c

:
