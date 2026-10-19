#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Regression test for bug#79049: unconditional inclusion of ChangeLog in
# distribution when its rule is guarded by a conditional.

. test-init.sh

cat > configure.ac << 'END'
AC_INIT([foobar], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_CONDITIONAL([GEN_CL], [test x"$want_changelog" = xyes])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
if GEN_CL
ChangeLog:
	echo generated > $@
endif
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

# ChangeLog is only distributed under the condition guarding its rule.
grep '^@GEN_CL_TRUE@am__DIST_COMMON.*= *ChangeLog$' Makefile.in
grep '^am__DIST_COMMON.*ChangeLog' Makefile.in && exit 1

# With the condition false, ChangeLog is neither required nor distributed.
./configure
$MAKE dist
$MAKE distdir
test ! -f foobar-1.0/ChangeLog

# With the condition true, ChangeLog is built and distributed.
./configure want_changelog=yes
$MAKE distdir
test -f foobar-1.0/ChangeLog
grep generated foobar-1.0/ChangeLog

# With the condition false, a ChangeLog that exists anyway (for example,
# in a tarball) is still distributed.
rm -rf foobar-1.0
./configure
$MAKE dist
$MAKE distdir
grep generated foobar-1.0/ChangeLog
rm -rf foobar-1.0 ChangeLog

# Without a rule, README falls back on README.md; this must also hold
# where a conditional README rule does not apply.
cat >> Makefile.am << 'END'
if GEN_CL
README:
	echo generated-readme > $@
endif
END
echo markdown > README.md
$AUTOMAKE
./configure
$MAKE distdir
test ! -f foobar-1.0/README
grep markdown foobar-1.0/README.md
rm -rf foobar-1.0
./configure want_changelog=yes
$MAKE distdir
grep generated-readme foobar-1.0/README
test ! -f foobar-1.0/README.md

:
