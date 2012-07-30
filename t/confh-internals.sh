#!/bin/sh
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

# Check internal make variable populated from AC_CONFIG_HEADERS calls.

. ./defs || exit 1

cat >>configure.ac <<'EOF'
AC_SUBST([BOT], [bot])
AC_CONFIG_HEADERS([defs.h config.h:sub1/config.top:sub2/config.${BOT}],,
                  [BOT=$BOT])
AC_CONFIG_HEADERS([sub0/CFG.h:sub0/CFG-H.in])
AC_CONFIG_FILES([sub0/Makefile])
AC_OUTPUT
EOF

mkdir sub0 sub1 sub2

echo TOP > sub1/config.top
echo BOT > sub2/config.bot

cat > Makefile.am << 'END'
SUBDIRS = sub0
.PHONY: test-vapth test-intree
test-intree:
	is $(am.config-hdr.local) == defs.h config.h
	is $(am.config-hdr.local.in) == ./defs.h.in
test-vpath:
	is $(am.config-hdr.local) == defs.h config.h
	is $(am.config-hdr.local.in) == ../defs.h.in
END

cat > sub0/Makefile.am << 'END'
.PHONY: test-vapth test-intree
test-intree:
	is $(am.config-hdr.local) == CFG.h
	is $(am.config-hdr.local.in) == ../sub0/CFG-H.in
test-vpath:
	is $(am.config-hdr.local) == CFG.h
	is $(am.config-hdr.local.in) == ../../sub0/CFG-H.in
END

: > sub0/CFG-H.in

$ACLOCAL
$AUTOCONF
$AUTOHEADER
test -f defs.h.in
$AUTOMAKE

./configure
$MAKE test-intree
$MAKE distclean
mkdir build
cd build
../configure
$MAKE test-vpath
$MAKE distcleancheck

:
