#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Automake-NG still accepts old-fashioned suffix rules.

. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub
foobar: ; cp $< $@
.mu.um:
	cp $< $@
.SUFFIXES: foo bar .mu .um
data_DATA = xbar question.um
END

mkdir sub
cat > sub/Makefile.am << 'END'
SUFFIXES = .1 2 .3 4
.1.3 24:
	sed 's/@/O/' $< >$@
all-local: bar.3 bar4
END

$ACLOCAL
$AUTOMAKE

grep SUFFIXES Makefile.in sub/Makefile.in # For debugging.

$AUTOCONF
echo foofoofoo > xfoo
echo 'What is the sound of one hand?' > question.mu
echo '@NE' > sub/bar.1
echo 'TW@' > sub/bar2

mkdir build
cd build
../configure
$MAKE
diff ../xfoo xbar
diff ../question.mu question.um
test "$(cat sub/bar.3)" = ONE
test "$(cat sub/bar4)" = TWO

cd ..
./configure
$MAKE

diff xfoo xbar
diff question.mu question.um
test "$(cat sub/bar.3)" = ONE
test "$(cat sub/bar4)" = TWO

:
