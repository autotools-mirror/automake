#! /bin/sh
# Copyright (C) 2009-2012 Free Software Foundation, Inc.
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

# Check parallel-tests features: generated distributed tests.

am_parallel_tests=yes
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
TESTS = foo.test
%.test: %.in
	cp $< $@ && chmod +x $@
check_SCRIPTS = $(TESTS)
EXTRA_DIST = foo.in foo.test
DISTCLEANFILES = foo.test
END

cat > foo.in <<'END'
#! /bin/sh
echo "this is $0"
exit 0
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE check
$MAKE distcheck
$MAKE distclean

mkdir build
cd build
../configure
$MAKE check
test ! -f ../foo.log
$MAKE distcheck

:
