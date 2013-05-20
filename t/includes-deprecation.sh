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

# Support for $(INCLUDES) is deprecated.

. test-init.sh

echo AC_PROG_CC >> configure.ac

$ACLOCAL

cat > Makefile.am << 'END'
bin_PROGRAMS = foo
INCLUDES = -DFOO
END

AUTOMAKE_fails -Wnone -Wobsolete
grep "^Makefile\\.am:2:.* 'INCLUDES'.* deprecated.* 'AM_CPPFLAGS'" stderr
AUTOMAKE_run -Wall -Wno-obsolete
test ! -s stderr

echo 'AC_SUBST([INCLUDES])' >> configure.ac
sed '/^INCLUDES/d' Makefile.am > t && mv -f t Makefile.am

AUTOMAKE_run -Wno-error
grep "^configure\\.ac:5:.* 'INCLUDES'.* deprecated.* 'AM_CPPFLAGS'" stderr

:
