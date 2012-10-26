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

# Test AM_PROG_VALAC.

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_VALAC([1.2.3])
AC_OUTPUT
END

cat > Makefile.am << 'END'
has-valac:
	case '$(VALAC)' in *valac) exit 0;; *) exit 1;; esac
no-valac:
	test x'$(VALAC)' = x':'
END

mkdir bin
cat > bin/valac << 'END'
#! /bin/sh
if test "x$1" = x--version; then
  echo "${vala_version-1.2.3}"
fi
exit 0
END
chmod +x bin/valac

cat > bin/valac.old << 'END'
#! /bin/sh
if test "x$1" = x--version; then
  echo 0.1
fi
exit 0
END
chmod +x bin/valac.old

PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH

# Avoid interferences from the environment.
VALAC= vala_version=; unset VALAC vala_version

$ACLOCAL
$AUTOMAKE -a
$AUTOCONF

# The "|| exit 1" are required here even if 'set -e' is active,
# because ./configure might exit with status 77, and in that case
# we want to FAIL, not to SKIP.
./configure || exit 1
$MAKE has-valac
vala_version=99.9 ./configure || exit 1
$MAKE has-valac

st=0; vala_version=0.1.2 ./configure 2>stderr || st=$?
cat stderr >&2
test $st -eq 77 || exit 1
#$MAKE no-valac

st=0; ./configure VALAC="$(pwd)/bin/valac.old" 2>stderr || st=$?
cat stderr >&2
test $st -eq 77 || exit 1
#$MAKE no-valac

sed 's/^\(AM_PROG_VALAC\).*/\1([1], [: > ok], [: > ko])/' <configure.ac >t
mv -f t configure.ac
rm -rf autom4te*.cache
$ACLOCAL
$AUTOCONF

./configure
test -f ok
test ! -e ko
$MAKE has-valac
rm -f ok ko

vala_version=0.1.2 ./configure
test ! -e ok
test -f ko
$MAKE no-valac
rm -f ok ko

./configure VALAC="$(pwd)/bin/valac.old"
test ! -e ok
test -f ko
$MAKE no-valac
rm -f ok ko

:
