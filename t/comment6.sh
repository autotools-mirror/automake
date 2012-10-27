#! /bin/sh
# Copyright (C) 2002-2012 Free Software Foundation, Inc.
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

# Test for PR/322.
# Automake 1.6.1 seems to have a problem parsing comments that use
# '\' to span multiple lines.

. test-init.sh

cat >> configure.ac <<'EOF'
AC_OUTPUT
EOF

SOME_FILES=; unset SOME_FILES # Avoid spurious environment interference.

## There are two tests: one with backslashed comments at the top
## of the file, and one with a rule first.  This is because
## Comments at the top of the file are handled specially
## since Automake 1.5.

cat > Makefile.am << 'EOF'
# SOME_FILES = \
         file1 \
         file2 \
         file3

.PHONY: test
test:
	test -z '$(SOME_FILES)'
EOF

do_check ()
{
  $MAKE test
  grep '^# SOME_FILES =' Makefile
  # No useless munging please.
  grep '#.*file[123]' Makefile && exit 1
  :
}

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure
do_check

cat > Makefile.am << 'EOF'
test: test2
.PHONY: test test2

# SOME_FILES = \
         file1 \
         file2 \
         file3

test:
	test -z '$(SOME_FILES)'
EOF

$AUTOMAKE
./config.status
do_check

:
