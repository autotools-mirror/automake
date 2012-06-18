#! /bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Some grepping checks on Texinfo support.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

$ACLOCAL

: > texinfo.tex

echo info_TEXINFOS = main.texi other.texi sub/x.texi > Makefile.am
mkdir sub
echo @setfilename main.info > main.texi
echo @setfilename other.info > other.texi
echo @setfilename sub/x.info > sub/x.texi
$AUTOMAKE
$EGREP '\.(info|pdf|ps|dvi|html|texi)' Makefile.in # For debugging.
test $(grep -c '^%\.info: %\.texi$' Makefile.in) -eq 1
test $(grep -c '^%\.html: %\.texi$' Makefile.in) -eq 1
test $(grep -c '^%\.dvi: %\.texi$'  Makefile.in) -eq 1
test $(grep -c '^%\.pdf: %\.texi$'  Makefile.in) -eq 1
test $(grep -c '^%\.ps: %\.dvi$'    Makefile.in) -eq 1

for t in info dist-info dvi-am install-html uninstall-pdf-am; do
  $FGREP $t Makefile.in # For debugging.
  test $(grep -c "^$t *:" Makefile.in) -eq 1
done

:
