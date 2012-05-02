#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Check that cygnus mode forbids creation of distribution tarball.

. ./defs || Exit 1

echo AM_MAINTAINER_MODE >> configure.ac
mv -f configure.ac configure.stub

cat configure.stub - > configure.ac <<'END'
AC_OUTPUT
END

: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --cygnus -Wno-obsolete

./configure
$MAKE

for target in dist distdir distcheck dist-all dist-gzip; do
  $MAKE -n $target >out 2>&1 && { cat out; Exit 1; }
  cat out
  grep $target out
done

# Now check that cygnus mode in a subdirectory disables
# distribution-building in that subdirectory.

cat > Makefile.am <<'END'
SUBDIRS = sub1 sub2
END

mkdir sub1 sub2
: > sub1/Makefile.am
cat > sub2/Makefile.am <<'END'
# The '-Wall' after 'cygnus' should ensure no warning gets
# unintentionally disabled.  We are particularly interested
# in override warnings, for when (below) we add the 'distdir'
# target.
AUTOMAKE_OPTIONS = cygnus -Wall
# This is required because the 'cygnus' option is now deprecated.
AUTOMAKE_OPTIONS += -Wno-obsolete
END

cat configure.stub - > configure.ac <<'END'
AC_CONFIG_FILES([sub1/Makefile sub2/Makefile])
AC_OUTPUT
END

$AUTOCONF
$AUTOMAKE

./configure
$MAKE
cd sub2
$MAKE -n distdir >out 2>&1 && { cat out; Exit 1; }
grep distdir out
cd ..

cat >> sub2/Makefile.am <<'END'
distdir:
END
$AUTOMAKE sub2/Makefile
./config.status sub2/Makefile

$MAKE distdir
$MAKE dist

:
