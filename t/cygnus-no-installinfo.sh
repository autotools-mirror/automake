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

# Check that cygnus mode enables the 'no-installinfo' option.

required=makeinfo
. ./defs || Exit 1

cat >> configure.ac <<'END'
AM_MAINTAINER_MODE
AC_OUTPUT
END

cat > Makefile.am <<'END'
info_TEXINFOS = foo.texi
END

cat > foo.texi <<'END'
@setfilename foo.info
END

$ACLOCAL
# -Wno-override works around a buglet in definition of $(MAKEINFO)
# in cygnus mode; see also xfailing test 'txinfo5.test'.
# -Wno-obsolete accounts for the fact that the cygnus mode is now
# deprecated.
$AUTOMAKE --cygnus -Wno-override -Wno-obsolete
$AUTOCONF

cwd=`pwd` || Exit 1
./configure --prefix="$cwd"/_inst
$MAKE
$MAKE install
test ! -d _inst
test ! -r foo.info
test ! -d _inst/share/info
$MAKE install-info
ls -l _inst
test -f foo.info
test -f _inst/share/info/foo.info

:
