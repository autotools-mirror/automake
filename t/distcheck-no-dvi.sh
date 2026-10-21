#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# By default, distcheck must not run 'make dvi', so that TeX is not
# required (automake bug#79053).  AM_DISTCHECK_DVI_TARGET can still
# ask for it.  See also 'distcheck-override-dvi.sh'.

# TeX should not be needed or invoked by default.
TEX=false
export TEX

required='makeinfo'
. test-init.sh

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
info_TEXINFOS = main.texi
END

# Protect with leading " # " to avoid spurious maintainer-check failures.
sed 's/^ *# *//' > main.texi << 'END'
 # \input texinfo
 # @setfilename main.info
 # @settitle main
 #
 # @node Top
 # Hello.
 # @bye
END

$ACLOCAL
$AUTOMAKE -a
$AUTOCONF

./configure
$MAKE
run_make -M distcheck
grep -- '-o main\.dvi' output && exit 1

# Asking for dvi explicitly runs texi2dvi again.
run_make -M distcheck AM_DISTCHECK_DVI_TARGET=dvi TEXI2DVI=true
grep '^true .*-o main\.dvi' output

:
