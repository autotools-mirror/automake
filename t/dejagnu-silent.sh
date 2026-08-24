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

# See automake bug#79086.

. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = dejagnu
END

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

# A stand-in for dejagnu...
cat > fake-runtest <<'END'
#! /bin/sh
echo "FAKE-RUNTEST RAN"
END
chmod a+x fake-runtest

fake=./fake-runtest

# Silent rules are disabled by default.
./configure
run_make -M RUNTEST=$fake check-DEJAGNU
cat output
grep 'FAKE-RUNTEST RAN' output
grep 'export srcdir' output

run_make -M V=0 RUNTEST=$fake check-DEJAGNU
cat output
grep 'FAKE-RUNTEST RAN' output
grep 'export srcdir' output && exit 1

$MAKE distclean

./configure --enable-silent-rules
run_make -M RUNTEST=$fake check-DEJAGNU
cat output
grep 'FAKE-RUNTEST RAN' output
grep 'export srcdir' output && exit 1
grep 'exit_status' output && exit 1

# 'make V=1' still shows the guts.
run_make -M V=1 RUNTEST=$fake check-DEJAGNU
cat output
grep 'FAKE-RUNTEST RAN' output
grep 'export srcdir' output

:
