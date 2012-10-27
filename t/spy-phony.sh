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

# Check that the '.PHONY' semantics we expect truly hold.

am_create_testdir=empty
. test-init.sh

cat > Makefile <<'END'
.PHONY: pdir pfile
pdir rdir:
	echo foo > $@/foo
pfile rfile:
	echo bar >$@
.PHONY: other
other:
	echo baz >> dummy
indirect: other
	echo run > $@
END

: > rfile
mkdir rdir
$MAKE rdir rfile
test ! -s rfile
test ! -f rdir/foo

: > pfile
mkdir pdir
$MAKE pdir pfile
test "$(cat pfile)" = bar
test "$(cat pdir/foo)" = foo

$MAKE other
test "$(cat dummy)" = baz
$MAKE other
test "$(cat dummy)" = "baz${nl}baz"

echo not run > indirect
$MAKE indirect
test "$(cat indirect)" = run
test "$(cat dummy)" = "baz${nl}baz${nl}baz"

:
