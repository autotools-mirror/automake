#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# Test Objective C++ compilation flags.
# See also sister test 'objc-flags.sh'.

. ./defs || Exit 1

cat >> configure.ac << 'END'
dnl Support for Object C++ was introduced only in Autoconf 2.65.
AC_PREREQ([2.65])
AC_PROG_OBJCXX
AC_OUTPUT
END

cat > Makefile.am << 'END'
AM_DEFAULT_SOURCE_EXT = .mm
bin_PROGRAMS = foo2 foo4
AM_OBJCXXFLAGS = -DVALUE=2 -DERROR=1
foo4_OBJCXXFLAGS = -DVALUE=4 -DERROR=1
END

for i in 2 4; do
  unindent > foo$i.mm << END
    /* Let's make this file valid Objective C but invalid C. */
    #import <stdlib.h>
    @interface Who_Cares { } @end
    #ifdef ERROR
    #  error "macro ERROR is defined for foo.mm"
    #else
    #  if VALUE == $i
         int main (void) { exit (0); }
    #  else
    #    error "VALUE is != $i in foo.mm"
    #  endif
    #endif
END
done

if $ACLOCAL; then
  : We have a modern enough autoconf, go ahead.
elif test $? -eq 63; then
  skip_ "Object C++ support requires Autoconf 2.65 or later"
else
  Exit 1 # Some other aclocal failure.
fi

$AUTOCONF
$AUTOMAKE -a

$FGREP OBJCXXFLAGS Makefile.in # For debugging.
grep '\$(OBJCXXFLAGS).*\$(AM_OBJCXXFLAGS)'       Makefile.in && Exit 1
grep '\$(OBJCXXFLAGS).*\$(foo.*_OBJCXXFLAGS)'    Makefile.in && Exit 1
grep '\$(foo.*_OBJCXXFLAGS).*\$(AM_OBJCXXFLAGS)' Makefile.in && Exit 1

./configure OBJCXXFLAGS=-UERROR
$MAKE 

:
