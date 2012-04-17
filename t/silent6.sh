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

# Check user extensibility of silent-rules mode.

. ./defs || Exit 1

cat >>configure.ac <<'EOF'
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
my_verbose = $(my_verbose_$(V))
my_verbose_ = $(my_verbose_$(AM_DEFAULT_VERBOSITY))
my_verbose_0 = @echo GEN $@;

all-local: foo

foo: foo.in
	$(my_verbose)cp $(srcdir)/foo.in $@
EXTRA_DIST = foo.in
CLEANFILES = foo
EOF

: >foo.in

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

./configure --enable-silent-rules
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
grep '^ *GEN foo *$' stdout
grep 'cp ' stdout && Exit 1

$MAKE clean
$MAKE V=1 >stdout || { cat stdout; Exit 1; }
cat stdout
grep 'GEN ' stdout && Exit 1
grep 'cp \.*/foo\.in foo' stdout

$MAKE distclean

./configure --disable-silent-rules
$MAKE >stdout || { cat stdout; Exit 1; }
cat stdout
grep 'GEN ' stdout && Exit 1
grep 'cp \.*/foo\.in foo' stdout

$MAKE clean
$MAKE V=0 >stdout || { cat stdout; Exit 1; }
cat stdout
grep '^ *GEN foo *$' stdout
grep 'cp ' stdout && Exit 1

:
