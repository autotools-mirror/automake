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

# Check that automake error out (with an helpful error message) against
# old-style usages of AM_INIT_AUTOMAKE (i.e., calls with two or three
# arguments).

. ./defs || Exit 1

warn_rx='AM_INIT_AUTOMAKE.* old-style two-.* three-arguments form.*unsupported'

$ACLOCAL
mv aclocal.m4 aclocal.sav

cat > configure.ac <<'END'
AC_INIT([Makefile.am])
AM_INIT_AUTOMAKE([twoargs], [1.0])
AC_CONFIG_FILES([Makefile])
END

do_check()
{
  rm -rf autom4te*.cache
  for cmd in "$ACLOCAL" "$AUTOCONF" "$AUTOMAKE"; do
    cp aclocal.sav aclocal.m4
    $cmd -Wnone -Wno-error 2>stderr && { cat stderr; Exit 1; }
    cat stderr >&2
    grep "^configure\.ac:2:.*$warn_rx" stderr
  done
}

: > Makefile.am
do_check

sed "/^AM_INIT_AUTOMAKE/s|)$|, [NODEFINE])|" configure.ac > t
diff configure.ac t && fatal_ "failed to edit configure.ac"
mv -f t configure.ac
do_check

:
