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

# Dependency tracking:
#  - we can recover if any .Po file in $(DEPDIR) gets removed;
#  - in fact, we can recover if the whole $(DEPDIR) directory gets
#    removed.

required=cc
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CC
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
SUBDIRS = . sub
noinst_PROGRAMS = foo
foo_SOURCES = main.c foo.c foo.h
get-depdir:
	@echo '$(DEPDIR)'
END

cat > main.c <<'END'
#include "foo.h"
int main (void)
{
  return foo ();
}
END
cat > foo.c <<'END'
#include "foo.h"
int foo (void)
{
  return 0;
}
END
echo 'int foo (void);' > foo.h

mkdir sub sub/src
cat > sub/Makefile.am <<'END'
noinst_PROGRAMS = foo
foo_SOURCES = src/main.c src/foo.c src/foo.h
END
cp main.c foo.c foo.h sub/src

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

for vpath in : false; do

  if $vpath; then
    srcdir=..
    mkdir build
    cd build
  else
    srcdir=.
  fi

  $srcdir/configure --enable-dependency-tracking
  $MAKE
  depdir=$($MAKE -s --no-print-directory get-depdir) \
    && test -n "$depdir" \
    && test -d $depdir \
    && test -d sub/src/$depdir \
    || fatal_ "cannot find the depdir"

  for remove_stuff in \
    "rm -f $depdir/main.Po" \
    "rm -f sub/src/$depdir/foo.Po" \
    "rm -rf $depdir" \
    "rm -rf $depdir sub/src/$depdir" \
  ; do
    $remove_stuff
    # We can still use make and order a build, even if we have probably
    # lost the dependency information registered in removed the .Po files.
    # TODO: maybe we should detect such a situation and force a clean
    # TODO: rebuild?
    $MAKE
    # But if we force a rebuild by hand by cleaning out the existing
    # objects, everything works out as expected.
    $MAKE clean
    $MAKE
    test -f $depdir/main.Po
    test -f $depdir/foo.Po
    test -f sub/src/$depdir/main.Po
    test -f sub/src/$depdir/foo.Po
  done

  cd $srcdir

done

:
