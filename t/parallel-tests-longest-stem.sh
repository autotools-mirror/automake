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

# The parallel-tests driver must prefer tests with an extension to
# extension-less tests.  This is required to allow the user to have
# a, say, 'all.test' test case even in the face of the 'all' target.

am_parallel_tests=yes
. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

cat > foo <<'END'
#!/bin/sh
echo "foo without suffix run" >&2
exit 99
END

cat > foo.test <<'END'
#!/bin/sh
echo "$0 has been run"
END
chmod a+x foo.test

cp foo.test all.test
cp foo.test dist.test
cp foo.test install.test
cp foo.test bad-target.test


cat > Makefile.am << 'END'
bad-target:
	@echo $@ has been run >&2; exit 1
install-data-local:
	@echo $@ has been run >&2; exit 1
TESTS = foo.test all.test install.test dist.test bad-target.test
EXTRA_DIST = oops-this-does-not-exist
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure --prefix="`pwd`/inst"

$MAKE check
ls -l # For debugging.
test ! -d inst
for t in foo all install dist bad-target; do
  grep "$t\.test has been run" $t.log
done

:
