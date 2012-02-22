#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# Automake do not complain about nor messes up pattern rules.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
foo/%.out: bar/%.in
	test -d $(dir $@) || $(MKDIR_P) $(dir $@)
	cp $< $@
%.sh: %/z
	cp $< $@
%:
	echo True > $@
noinst_DATA = foo/one.out
noinst_SCRIPTS = two.sh mu.py
END

mkdir bar two
echo "123456789" > bar/one.in
echo "#!/bin/sh" > two/z

$ACLOCAL
$AUTOCONF
$AUTOMAKE

for vpath in : false; do
  if $vpath; then
    mkdir build
    cd build
    srcdir=..
  else
    srcdir=.
  fi
  $srcdir/configure
  $MAKE
  diff $srcdir/bar/one.in ./foo/one.out
  diff $srcdir/two/z ./two.sh
  test `cat mu.py` = True
  cd $srcdir
done

:
