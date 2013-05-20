#! /bin/sh
# Copyright (C) 2013 Free Software Foundation, Inc.
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

# Check that the Automake-generated recursive rules are resilient against
# false positives in deciding whether make is running with the '-k'
# option, and thus whether a failure into one of the $(SUBDIRS) should
# still prevent recursion in the following $(SUBDIRS) entries.  See
# automake bug#12544.

. test-init.sh

cat >> configure.ac <<'END'
AC_CONFIG_FILES([sub1/Makefile sub2/Makefile])
AC_OUTPUT
END

mkdir k ./--keep-going sub1 sub2

cat > Makefile.am <<'END'
SUBDIRS = sub1 sub2
END

cat > sub1/Makefile.am <<'END'
all-local:
	touch ko
	false
END
cat > sub2/Makefile.am <<'END'
all-local:
	test -f ../sub1/ko
	touch ok
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

$MAKE -I k -I --keep-going TESTS='k --keep-going -k' && exit 1
test ! -r sub2/ok

# Sanity check.
! $MAKE -k && test -f sub2/ok || fatal_ '"make -k" not working as expected'

:
