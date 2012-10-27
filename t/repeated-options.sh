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

# Check that automake does not complain on repeated options, nor
# generate broken or incorrect makefiles.

. test-init.sh

cat >configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([foreign foreign no-installman serial-tests \
                  no-installman])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS =  no-installman no-installman serial-tests
AUTOMAKE_OPTIONS += serial-tests foreign
TESTS = foo
EXTRA_DIST = foo
CLEANFILES = bar.out
END

cat > foo <<'END'
#!/bin/sh
echo RUN RUN
: > bar.out
END
chmod a+x foo

$ACLOCAL
$AUTOCONF
$AUTOMAKE --foreign --foreign -Wall 2>stderr && test ! -s stderr \
  || { cat stderr >&2; exit 1; }

./configure

$MAKE check
test -f bar.out
test ! -e foo.log
test ! -e test-suite.log
$MAKE distcheck

:
