#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Check that any attempt to use the obsolete macro AM_PROG_MKDIR_P
# elicits clear and explicit fatal errors.

. test-init.sh

geterr ()
{
    "$@" -Wnone 2>stderr && { cat stderr >&2; exit 1; }
    cat stderr >&2
    grep "^configure\.ac:4:.*'AM_PROG_MKDIR_P'.*obsolete" stderr
    grep "'AC_PROG_MKDIR_P'.* instead" stderr
    grep " use '\$(MKDIR_P)' instead of '\$(mkdir_p)'.*Makefile" stderr
}

$ACLOCAL
mv aclocal.m4 aclocal.sav

echo AM_PROG_MKDIR_P >> configure.ac

geterr $ACLOCAL
test ! -f aclocal.m4

cat aclocal.sav "$am_automake_acdir"/obsolete-err.m4 > aclocal.m4

geterr $AUTOCONF
geterr $AUTOMAKE

:
