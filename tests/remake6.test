#! /bin/sh
# Copyright (C) 2008-2012 Free Software Foundation, Inc.
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

# Make sure remaking rules work when subdir Makefile.in has been removed.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
SUBDIRS = sub
END
mkdir sub
: > sub/Makefile.am

$ACLOCAL
$AUTOMAKE
$AUTOCONF
./configure
$MAKE

# Now, we are set up.  Ensure that, for either missing Makefile.in,
# or updated Makefile.am, rebuild rules are run, and run exactly once
# only.

rm -f Makefile.in
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
test `grep -c " --run " stdout` -eq 1

rm -f sub/Makefile.in
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
test `grep -c " --run " stdout` -eq 1

$sleep  # Let touched files appear newer.

touch Makefile.am
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
test `grep -c " --run " stdout` -eq 1

touch sub/Makefile.am
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
test `grep -c " --run " stdout` -eq 1

:
