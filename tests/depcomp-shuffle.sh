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

# Dependency tracking in the face of added/removed/renamed files.
# This is meant to be sourced by other the tests, after they've
# set the variables '$xdir' and '$vpath' appropriately.

required=cc
. ./defs || Exit 1

test x${xdir+"set"} = x"set" || fatal_ "\$xdir is unset"
test x${vpath+"set"} = x"set" || fatal_ "\$vpath is unset"

if test $vpath = no; then
  srcdir=.
elif test $vpath = yes; then
  srcdir=..
else
  fatal_ "invalid value for \$vpath: '$vpath'"
fi

if test -z "$xdir"; then
  thedir=$srcdir
else
  thedir=$srcdir/$xdir
  xdir=$xdir/
fi


finalize_edit ()
{
  diff "$1" t && Exit 1
  mv -f t "$2"
}

func_subst ()
{
  subst=$1; shift
  for file
  do
    sed "$subst" "$file" > t
    finalize_edit "$subst" "$file"
  done
}

prepend ()
{
  cat "$1" "$2" > t
  finalize_edit "$@"
}

if cross_compiling; then
  grep_prog_out () { :; }
else
  grep_prog_out () { ./prg && ./prg | grep "$1" || Exit 1; }
fi

echo AC_PROG_CC                         >> configure.in
echo AM_PROG_AR                         >> configure.in
echo AC_PROG_RANLIB                     >> configure.in
test -z "$xdir" || echo AM_PROG_CC_C_O  >> configure.in
echo AC_OUTPUT                          >> configure.in

if test -n "$xdir"; then
  echo AUTOMAKE_OPTIONS = subdir-objects > Makefile.am
fi
cat >> Makefile.am <<END
noinst_PROGRAMS = prg
noinst_LIBRARIES = liber.a
prg_SOURCES = ${xdir}main.c
liber_a_SOURCES = ${xdir}niam.c
get-exeext:
	@echo \$(EXEEXT)
END

cat configure.in # For debugging.
cat Makefile.am  # Likewise.

test -z "$xdir" || mkdir "$xdir"

echo '#define THE_STRING "foofoofoo"' > ${xdir}foo.h

cat > ${xdir}main.c << 'END'
#include "foo.h"
#include <stdio.h>
int main (void)
{
   printf ("%s\n", THE_STRING);
   return 0;
}
END

sed 's/main/niam/' ${xdir}main.c > ${xdir}niam.c

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

test $vpath = no || { mkdir build && cd build; } || Exit 99

$srcdir/configure --enable-dependency-tracking
$MAKE
grep_prog_out foofoofoo # Sanity check.

EXEEXT=`$MAKE -s --no-print-directory get-exeext` \
  || fatal_ "cannot get \$EXEEXT"

# Modify an header file.
$sleep
echo '#define THE_STRING "oofoofoof"' > $thedir/foo.h
$MAKE
is_newest prg$EXEEXT $thedir/foo.h
is_newest liber.a $thedir/foo.h
grep_prog_out oofoofoof

# Rename an header file.
$sleep
mv $thedir/foo.h $thedir/foo2.h
func_subst 's|foo\.h|foo2.h|' $thedir/main.c $thedir/niam.c
$MAKE
is_newest prg$EXEEXT $thedir/main.c
is_newest liber.a $thedir/niam.c
grep_prog_out oofoofoof

# Add an header file, modify another one.
$sleep
mv $thedir/foo2.h $thedir/bar.h
echo '#include "bar.h"' > $thedir/foo2.h
$MAKE
grep_prog_out oofoofoof
is_newest prg$EXEEXT $thedir/foo2.h
is_newest liber.a $thedir/foo2.h

# Remove an header file, modify another one.
$sleep
echo '#define THE_STRING "bazbazbaz"' > $thedir/foo2.h
rm -f $thedir/bar.h
$MAKE
is_newest prg$EXEEXT $thedir/foo2.h
is_newest liber.a $thedir/foo2.h
grep_prog_out bazbazbaz

# Add two header files, rename another file.
$sleep
echo '#define S_ONE "zar"' > $thedir/1.h
echo '#define S_TWO "doz"' > $thedir/2.h
cat > $thedir/baz.h <<'END'
#include "1.h"
#include "2.h"
#define THE_STRING S_ONE S_TWO
END
func_subst 's|foo2\.h|baz.h|' $thedir/main.c $thedir/niam.c
rm -f $thedir/foo2.h
$MAKE
is_newest prg$EXEEXT $thedir/*.[ch]
is_newest liber.a $thedir/*.[ch]
grep_prog_out zardoz

# Check the distribution.
$sleep
echo prg_SOURCES += ${xdir}baz.h ${xdir}1.h ${xdir}2.h >> $srcdir/Makefile.am
$MAKE distcheck

:
