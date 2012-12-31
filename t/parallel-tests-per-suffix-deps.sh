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

# The user should be able to easily specify extra dependencies for
# the test cases, depending on their extension (or lack thereof).
# We do so with the help of "${prefix}LOG_DEPENDENCIES" variables.
# See the last wishlist in automake bug#11287.

. test-init.sh

cat >> configure.ac <<'END'
AC_SUBST([EXEEXT], [.bin])
AC_OUTPUT
END

cat > Makefile.am << 'END'
TEST_EXTENSIONS = .test .sh
TESTS = foo.test foo2.test bar.sh baz zard.oz quux.bin mu.test.bin

TEST_LOG_DEPENDENCIES = test-dep
SH_LOG_DEPENDENCIES = sh-dep1 sh-dep2
LOG_DEPENDENCIES = dep

DEPS = test-dep sh-dep1 sh-dep2 dep new-test-dep
$(DEPS):
	echo dummy > $@
CLEANFILES = $(DEPS)

.PHONY: setup
setup:
	chmod a+x $(TESTS)
EXTRA_DIST = $(TESTS)
END

cat > foo.test <<'END'
#! /bin/sh
test -f test-dep || test -f new-test-dep
END

cat > foo2.test <<'END'
#! /bin/sh
test -f test-dep
END

cp foo2.test mu.test.bin

cat > bar.sh <<'END'
#! /bin/sh
test -f sh-dep1 && test -f sh-dep2
END

cat > baz <<'END'
#! /bin/sh
test -f dep
END

cp baz quux.bin

cat > zard.oz <<'END'
#! /bin/sh
test -f dep
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE setup

cleanup () { rm -f test-dep sh-dep1 sh-dep2 dep; }

$MAKE check -j4
test ! -f new-test-dep
test -f test-dep
test -f sh-dep1
test -f sh-dep2
test -f dep
test -f quux.log  # Sanity check.
test -f mu.log    # Likewise.

cleanup

$MAKE check TESTS=foo.test
test -f test-dep
test ! -f sh-dep1
test ! -f sh-dep2
test ! -f dep

cleanup
rm -f bar.log
$MAKE check TESTS=bar.sh AM_LAZY_CHECK=yes
test ! -f test-dep
test -f sh-dep1
test -f sh-dep2
test ! -f dep

cleanup
$MAKE check TESTS=baz
test ! -f test-dep
test ! -f sh-dep1
test ! -f sh-dep2
test -f dep

cleanup
$MAKE check TESTS='foo bar'
test -f test-dep
test -f sh-dep1
test -f sh-dep2
test ! -f dep

cleanup
$MAKE check TESTS=zard.oz
test ! -f test-dep
test ! -f sh-dep1
test ! -f sh-dep2
test -f dep

cleanup
$MAKE check TESTS=mu.test.bin
test -f test-dep
test ! -f sh-dep1
test ! -f sh-dep2
test ! -f dep

cleanup
$MAKE check TESTS='quux.bin bar.sh'
test ! -f test-dep
test -f sh-dep1
test -f sh-dep2
test -f dep

cleanup
$MAKE check TESTS=foo TEST_LOG_DEPENDENCIES=new-test-dep
test -f new-test-dep
test ! -f test-dep
test ! -f sh-dep1
test ! -f sh-dep2
test ! -f dep

cleanup
$MAKE check TESTS=baz XFAIL_TESTS=baz LOG_DEPENDENCIES=
test ! -f dep
grep ':test-result: XFAIL' baz.trs

$MAKE distcheck

:
