#! /bin/sh
# Copyright (C) 2004-2013 Free Software Foundation, Inc.
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

# Test to make sure that if an auxfile (here depcomp) is required
# by a subdir Makefile.am, it is distributed by that Makefile.am.

. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([subdir/Makefile])
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = subdir
END

rm -f depcomp
mkdir subdir

: > subdir/Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE
test ! -e depcomp

cat > subdir/Makefile.am << 'END'
bin_PROGRAMS = foo
END

: > subdir/foo.c

$AUTOMAKE -a subdir/Makefile
test -f depcomp

# FIXME: the logic of this check and other similar ones in other
# FIXME: 'distcom*.sh' files should be factored out in a common
# FIXME: subroutine in 'am-test-lib.sh'...
sed -n -e "
  /^DIST_COMMON =.*\\\\$/ {
    :loop
    p
    n
    t clear
    :clear
    s/\\\\$/\\\\/
    t loop
    s/$/ /
    s/[$tab ][$tab ]*/ /g
    p
    n
  }" subdir/Makefile.in > dc.txt
cat dc.txt
$FGREP ' $(top_srcdir)/depcomp ' dc.txt

./configure
$MAKE distdir
test -f $distdir/depcomp

:
