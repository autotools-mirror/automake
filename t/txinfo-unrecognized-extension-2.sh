#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Test that automake complains properly when texinfo input files
# specify output info files with an invalid extension.

. test-init.sh

cat > Makefile.am << 'END'
info_TEXINFOS = foo.texi bar.texi baz.texi
END

echo '@setfilename foo.inf'     > foo.texi
echo '@setfilename bar'         > bar.texi
echo '@setfilename baz.texi'    > baz.texi
: > texinfo.tex

$ACLOCAL
AUTOMAKE_fails

grep "foo\.texi:.* 'foo.inf'.*unrecognized extension" stderr
grep "bar\.texi:.* 'bar'.*unrecognized extension" stderr
grep "baz\.texi:.* 'baz.texi'.*unrecognized extension" stderr

:
