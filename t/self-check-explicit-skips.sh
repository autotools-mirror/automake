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

# Sanity check for the automake testsuite.
# Check creation/removal of temporary test working directory by './defs'.

am_create_testdir=empty
. ./defs || Exit 1

# We still need a little hack to make ./defs work outside automake's
# tree 'tests' subdirectory.  Not a big deal.
sed "s|^am_top_builddir=.*|am_top_builddir='`pwd`'|" \
  "$am_top_builddir"/defs-static > defs-static
diff "$am_top_builddir"/defs-static defs-static \
  && fatal_ "failed to edit defs-static"
cp "$am_top_builddir"/defs .

set +e

unset am_explicit_skips stderr_fileno_
AM_TESTS_REEXEC=no; export AM_TESTS_REEXEC

# I'm a lazy typist.
sh=$AM_TEST_RUNNER_SHELL

$sh -c '. ./defs; (exit 77); exit 77' dummy.test
test $? -eq 77 || Exit 1

am_explicit_skips=no $sh -c '. ./defs; sh -c "exit 77"' dummy.test
test $? -eq 77 || Exit 1

am_explicit_skips=yes $sh -c '. ./defs; (exit 77); exit 77' dummy.test
test $? -eq 78 || Exit 1

am_explicit_skips=y $sh -c '. ./defs; sh -c "exit 77"' dummy.test
test $? -eq 78 || Exit 1

am_explicit_skips=yes $sh -c '. ./defs; Exit 77' dummy.test
test $? -eq 77 || Exit 1

am_explicit_skips=y $sh -c '. ./defs; skip_ "foo"' dummy.test
test $? -eq 77 || Exit 1

:
