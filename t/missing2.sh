#! /bin/sh
# Copyright (C) 2003-2012 Free Software Foundation, Inc.
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

# Test missing with version mismatches.

. ./defs || Exit 1

cat >>configure.ac <<'EOF'
m4_include([v.m4])
AC_OUTPUT
EOF

: > v.m4

: > Makefile.am

get_shell_script missing

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

# See missing.test for explanations about this.
MYAUTOCONF="./missing --run $AUTOCONF"
unset AUTOCONF

./configure AUTOCONF="$MYAUTOCONF"

$MAKE
$sleep
# Hopefully the install version of Autoconf cannot compete with this one...
echo 'AC_PREREQ(9999)' > v.m4
$MAKE distdir

# Run again, but without missing, to ensure that timestamps were updated.
export AUTOMAKE ACLOCAL
./configure AUTOCONF="$MYAUTOCONF"
$MAKE

# Make sure $MAKE fail when timestamps aren't updated and missing is not used.
$sleep
touch v.m4
$MAKE && Exit 1

:
