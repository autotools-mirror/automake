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

# Check that, if we have two pattern rules from which the same file (or
# set of files) can be built, and both are applicable, the first one wins.
# This is used at least in our 'parallel-tests' support.

am_create_testdir=empty
. ./defs || Exit 1

cat > Makefile <<'END'
default:

%.foo: %
	cp $< $@
%.foo: %.x
	cp $< $@

%.bar: %.x
	cp $< $@
%.bar: %

%.mu %.fu: %.1
	cp $< $*.mu && cp $< $*.fu
%.mu %.fu: %.2
	cp $< $*.mu && cp $< $*.fu
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

:
