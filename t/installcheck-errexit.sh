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

# Collect all standard-option failures and remove temporary files under -e.

required='cc native'
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CC
AC_OUTPUT
END
cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = std-options
bin_PROGRAMS = badprog
bin_SCRIPTS = badscript
END
cat > badprog.c <<'END'
#include <stdio.h>
int main (void) { puts ("failure"); return 7; }
END
cat > badscript <<'END'
#!/bin/sh
echo failure
exit 7
END
chmod +x badscript
$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure --prefix="$(pwd)/inst"
$MAKE install
for target in installcheck-binPROGRAMS installcheck-binSCRIPTS; do
  run_make -E -e FAIL "$target" SHELL='/bin/sh -e'
  grep 'does not support --help: exit code 7' stderr
  grep 'does not support --version: exit code 7' stderr
  for file in c*.out c*.err; do
    test ! -f "$file"
  done
done

:
