#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# Tests Yacc support with yacc-generated headers
# (i.e., '-d' in *YFLAGS).
# Keep in sync with sister test 'yacc-d-cxx.sh'.

required='cc yacc'
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_PROG_YACC
AC_CONFIG_FILES([foo/Makefile bar/Makefile baz/Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
SUBDIRS = foo bar baz
END

mkdir foo bar baz

cat > foo/Makefile.am <<'END'
bin_PROGRAMS = zardoz
zardoz_SOURCES = parse.y main.c
.PHONY: echo-distcom
echo-distcom:
	@echo ' ' $(DIST_COMMON) ' '
END
cp foo/Makefile.am bar/Makefile.am
cp foo/Makefile.am baz/Makefile.am

cat > foo/parse.y << 'END'
%{
#include "parse.h"
int yylex () { return 0; }
void yyerror (char *s) {}
%}
%%
x : 'x' {};
%%
END
# Using ylwrap, we actually generate y.tab.[ch].  Unfortunately, we
# forgot to rename #include "y.tab.h" into #include "parse.h" during
# the conversion from y.tab.c to parse.c.  This was OK when Bison was
# not issuing such an #include (up to 2.6).
#
# To make sure that we perform this conversion, in bar/parse.y, use
# y.tab.h instead of parse.c.
sed -e 's/parse\.h/y.tab.h/' <foo/parse.y >bar/parse.y

cat > foo/main.c << 'END'
#include "parse.h"
int main ()
{
  return yyparse ();
}
END
cp foo/main.c bar/main.c

# Even the generated header file is renamed when target-specific YFLAGS
# are used.  This might not be the best behavior, but it has been in
# place for quite a long time, so just go along with it for now.
sed 's/"parse\.h"/"zardoz-parse.h"/' foo/parse.y > baz/parse.y
sed 's/"parse\.h"/"zardoz-parse.h"/' foo/main.c > baz/main.c

$ACLOCAL
$AUTOCONF

$AUTOMAKE -a
$FGREP parse.h foo/Makefile.in bar/Makefile.in baz/Makefile.in && exit 1

cat >> foo/Makefile.am <<END
BUILT_SOURCES = parse.h
YFLAGS=\
-d
END
$AUTOMAKE -Wno-gnu foo/Makefile

sed 's/EOL$//' >> bar/Makefile.am <<END
AM_YFLAGS${tab}=  -d EOL
BUILT_SOURCES = parse.h
END
$AUTOMAKE bar/Makefile

cat >> baz/Makefile.am <<END
BUILT_SOURCES = zardoz-parse.h
zardoz_YFLAGS =-d${tab}
END
$AUTOMAKE baz/Makefile

./configure

$MAKE

test -f foo/parse.c
test -f foo/parse.h
test -f bar/parse.c
test -f bar/parse.h
test -f baz/zardoz-parse.c
test -f baz/zardoz-parse.h

# The generated C source and header files must be shipped.
for dir in foo bar; do
  cd $dir
  $MAKE echo-distcom
  $MAKE -s echo-distcom | grep '[ /]parse.c '
  $MAKE -s echo-distcom | grep '[ /]parse.h '
  cd ..
done
cd baz
$MAKE echo-distcom
$MAKE -s echo-distcom | grep '[ /]zardoz-parse.c '
$MAKE -s echo-distcom | grep '[ /]zardoz-parse.h '
cd ..

$MAKE distdir
ls -l $distdir
test -f $distdir/foo/parse.c
test -f $distdir/foo/parse.h
test -f $distdir/bar/parse.c
test -f $distdir/bar/parse.h
test -f $distdir/baz/zardoz-parse.c
test -f $distdir/baz/zardoz-parse.h

# Sanity check the distribution.
yl_distcheck

# While we are at it, make sure that 'parse.c' and 'parse.h' are erased
# by maintainer-clean, and not by distclean.
$MAKE distclean
test -f foo/parse.c
test -f foo/parse.h
test -f bar/parse.c
test -f bar/parse.h
test -f baz/zardoz-parse.c
test -f baz/zardoz-parse.h
./configure # Re-create 'Makefile'.
$MAKE maintainer-clean
test ! -e foo/parse.c
test ! -e foo/parse.h
test ! -e bar/parse.c
test ! -e bar/parse.h
test ! -e baz/zardoz-parse.c
test ! -e baz/zardoz-parse.h

:
