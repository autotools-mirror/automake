#! /bin/sh
# Copyright (C) 1999-2013 Free Software Foundation, Inc.
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

# Grepping checks on the use of subdir objects with C++.
# See relate test 't/subobj-cxx-grep.sh' for semantic checks.

. test-init.sh

echo AC_PROG_CXX >> configure.ac

cat > Makefile.am << 'END'
bin_PROGRAMS = wish
wish_SOURCES = generic/a.cc generic/b.cxx
END

$ACLOCAL
$AUTOMAKE

$FGREP 'generic/a.$(OBJEXT)' Makefile.in
$FGREP 'generic/b.$(OBJEXT)' Makefile.in
grep '[^/][ab]\.\$(OBJEXT)' Makefile.in && exit 1
grep '.* -c -o ' Makefile.in

:
