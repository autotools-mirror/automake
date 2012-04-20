#! /bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Check parallel-tests features:
# - listing $(srcdir)/ or $(top_srcdir)/ in TESTS doesn't work ATM,
#   and is thus diagnosed.

# TODO: this test should also ensure that the 'make' implementation
#       properly adheres to rules in all cases.  See the Autoconf
#       manual for the ugliness in this area, when VPATH comes into
#       play.  :-/

am_parallel_tests=yes
. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
TESTS = $(srcdir)/bar.test $(top_srcdir)/baz.test
END

$ACLOCAL
$AUTOCONF
AUTOMAKE_fails -a
grep '$(srcdir).*TESTS.*bar\.test' stderr
grep '$(top_srcdir).*TESTS.*baz\.test' stderr

:
