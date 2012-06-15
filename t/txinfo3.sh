#! /bin/sh
# Copyright (C) 1997-2012 Free Software Foundation, Inc.
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

# Test to make sure .info-less @setfilename works.

required='makeinfo tex texi2dvi'
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
info_TEXINFOS = textutils.texi doc/automake-ng.texi
.PHONY: echo-info-deps
echo-info-deps:
	echo ' ' $(INFO_DEPS) ' '
END

cat > textutils.texi <<EOF
\input texinfo
@setfilename textutils
@settitle main
@node Top
Hello walls.
@bye
EOF

mkdir doc
cat > doc/automake-ng.texi <<EOF
\input texinfo
@setfilename automake-ng
@settitle automake-ng
@node Top
Blurb.
@bye
EOF

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure
$MAKE distcheck

$MAKE
test -f textutils
test -f doc/automake-ng
test ! -f textutils.info
test ! -f doc/automake-ng.info

$MAKE distdir
test -f $distdir/textutils
test -f $distdir/doc/automake-ng

$MAKE echo-info-deps | grep '[ /]textutils '
$MAKE echo-info-deps | grep '[ /]doc/automake-ng '

:
