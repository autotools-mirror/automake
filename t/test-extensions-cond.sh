#! /bin/sh
# Copyright (C) 2011-2013 Free Software Foundation, Inc.
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

# Conditional definition of TEST_EXTENSIONS is supported.

. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AM_CONDITIONAL([COND1], [test x"$cond1" = x"yes"])
AM_CONDITIONAL([COND2], [test x"$cond2" = x"yes"])
AC_OUTPUT
END

mkdir sub

cat > Makefile.am << 'END'
SUBDIRS = sub
TESTS = foo.sh bar.test
if COND1
TEST_EXTENSIONS = .sh
endif
END

cat > sub/Makefile.am << 'END'
TESTS = 1.sh 2.bar 3.x
TEST_EXTENSIONS = .sh
if COND1
if !COND2
TEST_EXTENSIONS += .x
endif
else
TEST_EXTENSIONS += .bar
endif
END

cat > foo.sh << 'END'
#!/bin/sh
exit 0
END
chmod a+x foo.sh

cp foo.sh bar.test
cp foo.sh sub/1.sh
cp foo.sh sub/2.bar
cp foo.sh sub/3.x

do_setup ()
{
  ./configure "$@"
  $MAKE check
  ls -l . sub
}

do_clean ()
{
  $MAKE clean
  test "$(find . -name '*.log')" = ./config.log
}

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

do_setup cond1=yes cond2=yes
test -f foo.log
test -f bar.test.log
test -f sub/1.log
test -f sub/2.bar.log
test -f sub/3.x.log
do_clean

do_setup cond1=yes cond2=no
test -f foo.log
test -f bar.test.log
test -f sub/1.log
test -f sub/2.bar.log
test -f sub/3.log
do_clean

do_setup cond1=no cond2=yes
test -f foo.sh.log
test -f bar.log
test -f sub/1.log
test -f sub/2.log
test -f sub/3.x.log
do_clean

do_setup cond1=no cond2=no
test -f foo.sh.log
test -f bar.log
test -f sub/1.log
test -f sub/2.log
test -f sub/3.x.log
do_clean

:
