#! /bin/sh
# Copyright (C) 2002-2012 Free Software Foundation, Inc.
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

# Interaction between user-defined extensions for files in _SOURCES
# and the use of AM_DEFAULT_SOURCE_EXT.

required=c++
. ./defs || Exit 1

cat >> configure.ac <<'END'
AC_PROG_CXX
AC_OUTPUT
END

cat > Makefile.am <<'END'
AM_DEFAULT_SOURCE_EXT = .cc
bin_PROGRAMS = foo bar baz qux
%.cc: %.zoo
	sed 's/INTEGER/int/g' $< >$@
EXTRA_DIST = $(addsuffix .zoo,$(bin_PROGRAMS))
generated_cc_sources = $(addsuffix .cc,$(bin_PROGRAMS))
CLEANFILES = $(generated_cc_sources)
# We don't want the generated C++ files to be distributed, and this
# is the best workaround we've found so far.  Not very clean, but it
# works.
dist-hook:
	rm -f $(addprefix $(distdir)/,$(generated_cc_sources))
END

# This is deliberately valid C++, but invalid C.
cat > foo.zoo <<'END'
using namespace std;
INTEGER main (void)
{
  return 0;
}
END
cp foo.zoo bar.zoo
cp foo.zoo baz.zoo
cp foo.zoo qux.zoo

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure

$MAKE all
$MAKE distdir
ls -l $distdir
test ! -f $distdir/foo.cc
test ! -f $distdir/bar.cc
test ! -f $distdir/baz.cc
test ! -f $distdir/qux.cc
$MAKE distcheck

:
