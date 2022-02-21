#!/bin/sh
# Copyright (C) 2022 Free Software Foundation, Inc.
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

# Check verbose mode defaults and behavior.

. test-init.sh

: > Makefile.am

# Default behavior is currently verbose.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User doesn't pick a silent mode default before AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_SILENT_RULES
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User disables silent mode default before AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_SILENT_RULES([no])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User enables silent mode default before AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_SILENT_RULES([yes])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User doesn't pick a silent mode default after AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_INIT_AUTOMAKE
AM_SILENT_RULES
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User disables silent mode default after AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_INIT_AUTOMAKE
AM_SILENT_RULES([no])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

# User enables silent mode default after AM_INIT_AUTOMAKE.
cat <<EOF >configure.ac
AC_INIT([silent-defaults], [1.0])
AM_INIT_AUTOMAKE
AM_SILENT_RULES([yes])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
EOF

$AUTOCONF

./configure -C
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --enable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 0' Makefile

./configure -C --disable-silent-rules
grep '^AM_DEFAULT_VERBOSITY = 1' Makefile

:
