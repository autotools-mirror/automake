#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# Check that the automatic variable '$<' always undergoes VPATH rewrite.
# We use that assumption in some of our rules, so it better explicitly
# check that it truly holds.

. test-init.sh

ocwd=$(pwd) || fatal_ "couldn't get current working directory"

mkdir src
cd src

cat > mk <<'END'
.SUFFIXES:
.SUFFIXES: .a .b .a2 .b2 .a3 .b3 .a4 .b4

empty =
source = $<

all: one.b two.b2 three.b3 four.b4
all: www.d xxx.d2 yyy.d3 zzz.d4
all: bar/mu.x is.ok zardoz
all: here here2 he/re

.a.b:
	cp $< $@

.a2.b2:
	cp '$<' $@

.a3.b3:
	cp $(empty)$<$(empty) $@

.a4.b4:
	cp $(source) $@

%.d: %.c
	cp $< $@

%.d2: %.c2
	cp '$(source)' $@

%.d3: %.c3 %.cc
	cp `echo '$<'` $@

%.d4: %.c4 ignore-me
	orig=x$(<)x && orig=`expr "$$orig" : 'x\(.*\)x$$'` && cp $$orig $@

bar/%: foo/%
	mkdir $(dir $@)
	cp $< $@

%.ok: zap/%
	cp "$<" $@

%: zap/sub/%
	cp '$<' $@

here: there
	cp $< $@

here2: there2 ignore-me
	cp '$<' $@

he/re: the/re
	mkdir $(dir $@)
	cp "$(source)" $@
END

mkdir foo zap zap/sub the
for file in \
  one.a \
  two.a2 \
  three.a3 \
  four.a4 \
  www.c \
  xxx.c2 \
  yyy.c3 \
  zzz.c4 \
  foo/mu.x \
  zap/is \
  zap/sub/zardoz \
  there \
  there2 \
  the/re \
; do
  echo $file > $file
done
touch yyy.cc ignore-me

do_test ()
{
  srcdir=$1
  cp $srcdir/mk Makefile
  $MAKE -k all VPATH=$srcdir
  if test "$srcdir" != "."; then
    test ! -f $srcdir/bar && test ! -d $srcdir/bar || exit 1
    test ! -f $srcdir/he && test ! -d $srcdir/he || exit 1
  fi
  diff $srcdir/one.a one.b
  diff $srcdir/two.a2 two.b2
  diff $srcdir/three.a3 three.b3
  diff $srcdir/four.a4 four.b4
  diff $srcdir/www.c www.d
  diff $srcdir/xxx.c2 xxx.d2
  diff $srcdir/yyy.c3 yyy.d3
  diff $srcdir/zzz.c4 zzz.d4
  diff $srcdir/foo/mu.x bar/mu.x
  diff $srcdir/zap/is is.ok
  diff $srcdir/zap/sub/zardoz zardoz
  diff $srcdir/there here
  diff $srcdir/the/re he/re
}

cd "$ocwd"
mkdir build
cd build
do_test ../src

cd "$ocwd"
mkdir build2
cd build2
do_test "$ocwd"/src

cd "$ocwd"
cd src
mkdir build
cd build
do_test ..

cd "$ocwd"
cd src
do_test .

:
