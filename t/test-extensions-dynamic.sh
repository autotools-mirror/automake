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

# TEST_EXTENSIONS with contents dynamically determined at make time

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_SUBST([suf], [.tap])
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

mkdir sub

cat > Makefile.am << 'END'
SUBDIRS = sub
TESTS = foo.sh bar.test baz.t1 mu.t1.t2 zardoz.tap
TEST_EXTENSIONS = .test @suf@ $(foreach i,1 2,.t$(i))
TEST_EXTENSIONS += $(subst &,.,$(call am.util.tolower,&SH))
END

cat > sub/Makefile.am << 'END'
TESTS = 1.sh 2.bar 3
TEST_EXTENSIONS = $(suffix $(TESTS))
END

cat > foo.sh << 'END'
#!/bin/sh
exit 0
END
chmod a+x foo.sh

cp foo.sh bar.test
cp foo.sh baz.t1
cp foo.sh mu.t1.t2
cp foo.sh zardoz.tap
cp foo.sh sub/1.sh
cp foo.sh sub/2.bar
cp foo.sh sub/3

do_setup ()
{
  $MAKE check ${1+"$@"}
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
./configure

do_setup
test -f foo.log
test -f bar.log
test -f baz.log
test -f mu.t1.log
test -f zardoz.log
test -f sub/1.log
test -f sub/2.log
test -f sub/3.log

do_clean

do_setup TEST_EXTENSIONS='.sh .t2 $(subst o,e,.tost) ${suf}'
test -f foo.log
test -f bar.log
test -f baz.t1.log
test -f mu.t1.log
test -f zardoz.log
test -f sub/1.log
test -f sub/2.bar.log
test -f sub/3.log

:
