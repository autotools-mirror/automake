#!/bin/sh
# Copyright (C) 1996-2013 Free Software Foundation, Inc.
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

# Check that we don't emit harmless but useless code in the generated
# Makefile.in when the project does not use compiled languages.  Motivated
# by a regression caused by removal of automatic de-ANSI-fication support:
# <http://lists.gnu.org/archive/html/automake-patches/2011-08/msg00200.html>

. test-init.sh

echo AC_OUTPUT >> configure.ac

: > Makefile.am

rm -f depcomp compile

$ACLOCAL
$AUTOMAKE

$EGREP 'DEFAULT_INCLUDES|@am__isrc@|-compile|\$\(OBJEXT\)|tab\.[ch]' \
  Makefile.in && exit 1

:
