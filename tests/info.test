#! /bin/sh
# Copyright (C) 1996-2012 Free Software Foundation, Inc.
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

# Test to make sure info files are distributed correctly.
# FIXME: This test is probably obsoleted, or wrong.  The generated
#        Makefile.in seems not to define any 'INFOS' variable!

. ./defs || Exit 1

cat > Makefile.am << 'END'
info_TEXINFOS = foo.texi
END

echo '@setfilename foo.info' > foo.texi
: > texinfo.tex

$ACLOCAL
$AUTOMAKE

for i in `grep '^INFOS =' Makefile.in | sed -e 's/^INFOS = //'`; do
   echo $i
   case "$i" in
    foo*)
       ;;
    *)
       Exit 1
       ;;
   esac
done

:
