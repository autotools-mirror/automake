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

# Check that, in cygnus mode, target "check" does not depend target
# "all".

. ./defs || Exit 1

cat >> configure.ac <<'END'
AM_MAINTAINER_MODE
AC_OUTPUT
END

cat > Makefile.am <<'END'
all-local:
	: > all-target-has-failed
	exit 1
check-local:
	touch check-target-has-run
END

$ACLOCAL
$AUTOMAKE --cygnus -Wno-obsolete

$EGREP '(^| )all.*(:|:.* )check' Makefile.in && Exit 1

$AUTOCONF
./configure

$MAKE check
test -f check-target-has-run
test ! -r all-target-has-failed
# Sanity checks.
$MAKE && Exit 1
test -f all-target-has-failed

:
