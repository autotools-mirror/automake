#!/bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Check rebuild rules for AC_CONFIG_HEADERS.
# (This should also work without GNU Make.)

required=cc
. ./defs || Exit 1

cat >>configure.ac <<'EOF'
AC_PROG_CC
AC_SUBST([BOT], [bot])
AC_CONFIG_HEADERS([defs.h config.h:sub1/config.top:sub2/config.${BOT}],,
                  [BOT=$BOT])
AC_CONFIG_FILES([sub3/Makefile])
AC_OUTPUT
EOF

mkdir sub1 sub2 sub3

: > sub1/config.top
echo '#define NAME "grepme1"' >sub2/config.bot

cat > Makefile.am <<'END'
SUBDIRS = sub3
.PHONY: test-prog-updated
test-prog-updated:
	stat older sub3/run$(EXEEXT) || : For debugging.
	test `ls -t older sub3/run$(EXEEXT) | sed 1q` = sub3/run$(EXEEXT)
END

cat > sub3/Makefile.am <<'END'
noinst_PROGRAMS = run
END

cat >sub3/run.c <<'EOF'
#include <defs.h>
#include <config.h>
#include <stdio.h>

int main (void)
{
  puts (NAME); /* from config.h */
  puts (PACKAGE); /* from defs.h */
}
EOF


$ACLOCAL
$AUTOCONF
$AUTOHEADER
$AUTOMAKE

# Do not reject slow dependency extractors: we need dependency tracking.
./configure --enable-dependency-tracking
$MAKE
# Sanity check.
cross_compiling || { sub3/run | grep grepme1; }

: > older
$sleep
echo '#define NAME "grepme2"' > sub2/config.bot
$MAKE
cross_compiling || { sub3/run | grep grepme2; }
$MAKE test-prog-updated

$MAKE distcheck

:
