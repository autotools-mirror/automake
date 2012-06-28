#!/bin/sh
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

# Some checks about silent-rules mode and warnings.

. ./defs || exit 1

cat >>configure.ac <<'EOF'
AM_SILENT_RULES
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
my_verbose = $(my_verbose_$(V))
my_verbose_ = $(my_verbose_$(AM_DEFAULT_VERBOSITY))
my_verbose_0 = @echo " PKG-GEN    $@";
foo: foo.in
	$(my_verbose)cp $(srcdir)/foo.in $@
EOF

$ACLOCAL
$AUTOMAKE --add-missing

cat > configure.ac <<'END'
AC_INIT([silent6], [1.0])
AM_INIT_AUTOMAKE([-Wall])
AC_CONFIG_FILES([Makefile])
END

rm -rf autom4te*.cache
$ACLOCAL
AUTOMAKE_fails
grep 'my_verbose_\$(V.*non-POSIX ' stderr
$AUTOMAKE -Wno-error

# AM_SILENT_RULES should turn off the warning.
echo 'AM_SILENT_RULES' >> configure.ac
rm -rf autom4te*.cache
$ACLOCAL
$AUTOMAKE
grep 'AM_V_GEN' Makefile.in
$AUTOMAKE --force -Wno-all -Wportability
grep 'AM_V_GEN' Makefile.in

# The 'silent-rules' option to AM_INIT_AUTOMAKE should work likewise.
cat > configure.ac <<'END'
AC_INIT([silent6], [1.0])
AM_INIT_AUTOMAKE([silent-rules])
AC_CONFIG_FILES([Makefile])
END
rm -rf autom4te*.cache
$ACLOCAL
$AUTOMAKE
grep 'AM_V_GEN' Makefile.in
$AUTOMAKE --force -Wno-all -Wportability
grep 'AM_V_GEN' Makefile.in

:
