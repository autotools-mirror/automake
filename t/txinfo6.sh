#! /bin/sh
# Copyright (C) 1998-2012 Free Software Foundation, Inc.
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

# Make sure '.txi' and '.texinfo' are accepted Texinfo extensions.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac
echo info_TEXINFOS = foo.txi doc/bar.texinfo > Makefile.am

mkdir doc
echo '@setfilename foo.info' > foo.txi
echo '@setfilename bar.info' > doc/bar.texinfo
: > texinfo.tex

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

for fmt in info pdf dvi html; do
  $MAKE -n "$fmt" > stdout || { cat stdout; Exit 1; }
  cat stdout
  for basename in foo doc/bar; do
    grep "[/ $tab]$basename\\.$fmt[; $tab]" stdout
  done
done

:
