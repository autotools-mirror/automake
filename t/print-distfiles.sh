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

# The 'print-distfiles' target lists exactly the files that 'make dist'
# puts in the tarball, in VPATH builds and across subdirectories, without
# creating any distribution directory.

required=cc
. test-init.sh

cat >> configure.ac << 'END'
AC_PROG_CC
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub
bin_PROGRAMS = foo
foo_SOURCES = foo.c foo.h
nodist_foo_SOURCES = gen.c
EXTRA_DIST = data
END

mkdir sub sub/sd data data/x

cat > sub/Makefile.am << 'END'
EXTRA_DIST = notes.txt sd $(top_srcdir)/top.txt $(srcdir)/../other.txt
dist_noinst_DATA = d.dat
END

touch foo.c foo.h gen.c data/x/y sub/sd/z sub/notes.txt sub/d.dat \
      top.txt other.txt

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

mkdir build
cd build
../configure
# A file generated in a distributed directory of the build tree.
mkdir data data/x
touch data/x/built

run_make -O print-distfiles
mv stdout list
cat list
test ! -e $distdir
test ! -e am-dlist.tmp

for f in Makefile.in configure foo.c foo.h data/x/y data/x/built \
         sub/sd/z sub/notes.txt sub/d.dat sub/Makefile.am top.txt other.txt
do
  grep "^$f\$" list
done
grep 'gen\.c' list && exit 1
grep '\.\./' list && exit 1
grep '^\./' list && exit 1
grep '^data$' list && exit 1
LC_ALL=C sort -u list > sorted
diff list sorted

# The list matches the contents of the tarball.
$MAKE dist
gzip -dc $distdir.tar.gz | tar tf - \
  | sed -e "s|^$distdir/||" -e '/\/$/d' -e '/^$/d' | LC_ALL=C sort > tarlist
diff tarlist list

# In a subdirectory, the names are relative to it.
cd sub
run_make -O print-distfiles
grep '^notes\.txt$' stdout
grep '^sd/z$' stdout
grep '^\.\./top\.txt$' stdout
cd ..

# The helper target refuses to run on its own.
run_make -E -e FAIL print-distfiles-am
grep 'use print-distfiles instead' stderr

:
