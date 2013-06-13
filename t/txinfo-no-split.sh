#! /bin/sh
# Copyright (C) 2013 Free Software Foundation, Inc.
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

# Info split files should not be produced (automake bug#13351).

required=makeinfo
. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
MAKEINFO = makeinfo --split-size 10
info_TEXINFOS = foo.texi

test-split: # A sanity check.
	$(MAKEINFO) -o split.info foo.texi

check-local:
	test -f $(srcdir)/foo.info
	test ! -f $(srcdir)/foo.info-1
	test "`find $(srcdir) . | grep '\.info'`" = "$(srcdir)/foo.info"
END

# Systems lacking a working TeX installation cannot run "make dvi".
if test -z "$TEX"; then
  warn_ "TeX installation missing, \"make dvi\" will be skipped"
  echo AUTOMAKE_OPTIONS = -Wno-override >> Makefile.am
  echo 'dvi:; @echo Tex is missing, do nothing' >> Makefile.am
fi

cat > foo.texi << 'END'
\input texinfo
@setfilename foo.info
@settitle foo
@dircategory Dummy utilities
@direntry
* Foo: (foo).  Does nothing at all.
@end direntry

@node Top
@top Foo

@menu
* Intro::    Introduction
* Planets::  List of Planets
@end menu

@node Intro
@chapter Introduction
Will list planets.

@node Planets
@chapter List of planets
Hello Mercury.
Hello Venus
Hello Earth
Hello Mars.
Hello Jupiter.
Hello Saturn.
Hello Uran.
Hello Neptune.
Hello Pluto.
@bye
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE test-split
ls -l # For debugging.
test -f split.info
test -f split.info-1
test -f split.info-2
rm -f split*

$MAKE

ls -l # For debugging.
test -f foo.info
test ! -f foo.info-1
test "$(find . | $FGREP '.info' | sed 's|^\./||')" = foo.info

$MAKE distcheck

:
