#! /bin/sh
# Copyright (C) 2001-2012 Free Software Foundation, Inc.
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

# The 'all-local', 'check-local' and 'installdirs-local' targets can
# also be defined by included or wrapper Makefiles that Automake never
# sees, as well as through GNU make constructs that Automake does not
# parse.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_SUBST([SafeInclude], [include])
AC_OUTPUT
END

cat > Makefile.am <<'END'
@SafeInclude@ ./inc.mk
$(foreach x,all check installdirs,$(eval $(x)-local:: ; : > main-$(x)))
END

cat > inc.mk << 'END'
all-local check-local installdirs-local:: %-local:
	: > incl-$*
END

cat > GNUmakefile << 'END'
include ./Makefile
all-local check-local installdirs-local:: %-local:
	: > wrap-$*
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

$MAKE check installdirs
test -f wrap-all
test -f wrap-check
test -f wrap-installdirs
test -f incl-all
test -f incl-check
test -f incl-installdirs
test -f main-all
test -f main-check
test -f main-installdirs

:
