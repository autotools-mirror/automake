#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Check that automake does not complain on repeated options, nor
# generate broken or incorrect makefiles.

required=bzip2
. ./defs || Exit 1

cat >configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([foreign foreign dist-bzip2 no-dist-gzip dist-bzip2])
AC_PROG_CC
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = no-dist-gzip no-dist-gzip dist-bzip2
AUTOMAKE_OPTIONS += dist-bzip2 foreign
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --foreign --foreign -Wall 2>stderr && test ! -s stderr \
  || { cat stderr >&2; Exit 1; }

./configure

$MAKE
$MAKE distcheck
test -f $me-1.0.tar.bz2
test ! -r $me-1.0.tar.gz

:
