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

# Check that Automake support entries with user-defined extensions of
# files in _SOURCES, and we can override the choice of a link in case
# the Automake default (C linker) would be inappropriate.

required=c++
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CXX
AC_OUTPUT
END

cat > Makefile.am <<'END'
%.$(OBJEXT): %.xt
## Creative quoting to plase maintainer checks.
	sed -e 's/@/o/g' -e 's/!/;/g' -e 's/<-/<''</g' $< >$*-t.cc \
	  && $(CXX) -c $*-t.cc \
	  && rm -f $*-t.cc \
	  && mv -f $*-t.$(OBJEXT) $@
bin_PROGRAMS = foo
foo_SOURCES = 1.xt 2.xt
foo_LINK = $(CXX) -o $@
END

cat > 1.xt <<'END'
#include <cstdlib>
void say_hell@ (v@id)!
int main (v@id)
{
   say_hell@ ()!
   std::exit(0)!
}
END

cat > 2.xt <<'END'
#include <i@stream>
void say_hell@ (v@id)
{
  using namespace std!
  c@ut <- "Hell@, W@rld\n" <- endl!
}
END

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure

$MAKE all
if cross_compiling; then :; else
  ./foo
  ./foo | grep 'Hello, World'
fi

$MAKE distcheck

:
