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

# The pdf, ps and dvi targets shouldn't let clutter in the build directory.
# Related to automake bug#11146.

required='makeinfo tex texi2dvi-o dvips'
. ./defs || Exit 1

mkdir sub

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
all-local: ps pdf dvi html
info_TEXINFOS = foo.texi sub/bar.texi
END

cat > foo.texi << 'END'
\input texinfo
@setfilename foo.info
@settitle foo
@node Top
Hello walls.
@include version.texi
@bye
END

cat > sub/bar.texi << 'END'
\input texinfo
@setfilename bar.info
@settitle bar
@node Top
Hello walls.
@include version2.texi
@bye
END

cat > baz.texi << 'END'
\input texinfo
@setfilename baz.info
@settitle baz
@node Top
Hello walls.
@bye
END

cat > baz.texi << 'END'
\input texinfo
@setfilename baz.info
@settitle baz
@defindex au
@defindex sa
@defindex sb
@synindex sa sb
@node Top
Hello walls.
@cindex foo
foo
@pindex bar
bar
@auindex baz
baz
@saindex sa
sa
@sbindex sb
sb
@bye
END

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

./configure

# Try one by one, to ensure later targets don't involuntarily
# clean up potential cruft left by earlier ones.
for fmt in info pdf ps dvi html all; do
  $MAKE $fmt
  ls -l . sub # For debugging.
  ls -d foo* baz* sub/bar* > lst
  $EGREP -v '^(foo|sub/bar|baz)\.(texi|dvi|ps|pdf|html|info)$' lst && Exit 1
  $MAKE clean
done

$MAKE distcheck

:
