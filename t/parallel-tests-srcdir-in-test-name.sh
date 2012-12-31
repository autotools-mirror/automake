#! /bin/sh
# Copyright (C) 2009-2013 Free Software Foundation, Inc.
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

# Check parallel-tests features: listing $(srcdir)/ in TESTS works.

. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << 'END'
TESTS = \
  $(srcdir)/foo \
  @srcdir@/foo2 \
  @srcdir@/bar.test \
  ${srcdir}/sub/baz.test \
  built.test

XFAIL_TESTS = $(srcdir)/bar.test foo2

built.test:
	(echo '#!/bin/sh' && echo 'exit 77') >$@-t
	chmod a-w,a+x $@-t && mv -f $@-t $@
END

cat > foo <<'END'
#!/bin/sh
exit 0
END
chmod a+x foo

cat > foo2 <<'END'
#!/bin/sh
exit 1
END
chmod a+x foo2

cp foo2 bar.test

mkdir sub
cp foo sub/baz.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

mkdir build
cd build
../configure
$MAKE check

ls -l . .. # For debugging.

test -f built.log
test -f foo.log
test -f bar.log
test -f sub/baz.log
test -f test-suite.log

test ! -f ../built.log
test ! -f ../foo.log
test ! -f ../bar.log
test ! -f ../sub/baz.log
test ! -f ../test-suite.log

:
