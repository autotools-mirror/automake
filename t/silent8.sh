#!/bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Check texinfo rules in silent-rules mode.

required='makeinfo-html tex texi2dvi-o dvips'
. ./defs || Exit 1

cat >>configure.ac <<'EOF'
AM_SILENT_RULES
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
info_TEXINFOS = foo.texi
EOF

cat > foo.texi <<'EOF'
\input texinfo
@c %**start of header
@setfilename foo.info
@settitle foo manual
@c %**end of header
@bye
EOF

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

./configure --disable-silent-rules

# Make sure that all labels work in silent-mode.
$MAKE V=0 dvi html info ps pdf >stdout || { cat stdout; Exit 1; }
cat stdout
grep 'DVIPS    foo.ps' stdout || Exit 1
grep 'MAKEINFO foo.html' stdout || Exit 1
# NetBSD make will print './foo.info' instead of 'foo.info'.
grep 'MAKEINFO.*foo.info' stdout || Exit 1
grep 'TEXI2DVI foo.dvi' stdout || Exit 1
grep 'TEXI2PDF foo.pdf' stdout || Exit 1

# Now make sure the labels don't appear in verbose mode.
$MAKE clean || Exit 1
$MAKE V=1 dvi html info ps pdf >stdout || { cat stdout; Exit 1; }
cat stdout
grep 'DVIPS    foo.ps' stdout && Exit 1
grep 'MAKEINFO foo.html' stdout && Exit 1
grep 'MAKEINFO.*foo.info' stdout && Exit 1
grep 'TEXI2DVI foo.dvi' stdout && Exit 1
grep 'TEXI2PDF foo.pdf' stdout && Exit 1

:
