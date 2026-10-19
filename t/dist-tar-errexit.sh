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

# A failed archiver must be diagnosed and its partial output removed under -e.

. test-init.sh

echo AC_OUTPUT >> configure.ac
: > Makefile.am
cat > badtar <<'END'
#!/bin/sh
echo partial
exit 7
END
chmod +x badtar
$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure
run_make -E -e FAIL am__distdir.tar am__tar=./badtar SHELL='/bin/sh -e'
grep 'cannot create the distribution archive' stderr
test ! -e am__distdir.tar

:
