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

# Two checks are done here:
# - if there are two pattern rules from which the same file (or set of
#   files) can be built, and both are applicable, and both results in
#   the same target stem, then the first one wins.
# - if there are two pattern rules from which the same file (or set of
#   files) can be built, and both are applicable, but the resulting
#   target stems are different, then the "most specific" one (i.e.,
#   that which result in the *shortest* stem) is used.
# We take advantage of such features at least in our 'parallel-tests'
# support.

am_create_testdir=empty
. test-init.sh

cat > Makefile <<'END'
default:
	@echo recipe for $@ should not run >&2; exit 1;

%.foo: %
	cp $< $@
%.foo: %.x
	cp $< $@

%.bar: %.x
	cp $< $@
%.bar: %
	cp $< $@

%.mu %.fu: %.1
	cp $< $*.mu && cp $< $*.fu
%.mu %.fu: %.2
	cp $< $*.mu && cp $< $*.fu

%.o: %.c
	@cp $< $@ && echo TOP >> $@
lib/%.o: lib/%.c
	@cp $< $@ && echo LIB >> $@

bar%: foo%
	echo .$* >$@
ba%: foo%
	@echo '$@: longest stem rule selected!' >&2; exit 1
END

echo one > all
echo two > all.x
$MAKE all.foo all.bar
diff all all.foo
diff all.x all.bar

echo one > x.1
echo two > x.2
$MAKE x.mu
diff x.mu x.1
diff x.fu x.1

mkdir lib
echo foo > a.c
echo bar > lib/a.c
$MAKE a.o lib/a.o
test "$(cat a.o)" = "foo${nl}TOP"
test "$(cat lib/a.o)" = "bar${nl}LIB"

: > foozap
: > foo-mu
: > foox
$MAKE barzap bar-mu
test "$(cat barzap)" = .zap
test "$(cat bar-mu)" = .-mu

# Sanity check.
$MAKE bax && exit 99
$MAKE bax 2>&1 | grep '^bax: longest stem rule selected!' || exit 99

:
