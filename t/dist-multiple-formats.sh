#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Regression tests for multiple distribution formats and for isolation of
# internal cleanup controls from recursive makes run while building distdir.

required='xz'
. test-init.sh

cat > configure.ac << END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([foreign dist-xz])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
VERSION = `echo 1.0`
EXTRA_DIST = child.mk recursive-result

recursive-result:
	$(MAKE) -f $(srcdir)/child.mk $@
END

cat > child.mk <<'END'
recursive-result:
	test -z '$(am__post_remove_distdir)'
	echo made >$@
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure

run_make -O dist-gzip dist-xz
test -f $distdir.tar.gz
test -f $distdir.tar.xz
xz -t $distdir.tar.xz
test ! -e $distdir.tar
test ! -d $distdir

tar_runs=$(grep -c 'am__tar_msg=' stdout) || tar_runs=0
echo "tar runs: $tar_runs" # For debugging.
if using_gmake; then
  test $tar_runs -eq 1
else
  test $tar_runs -ge 1
fi

rm -f $distdir.tar.*
run_make -O dist-xz
test -f $distdir.tar.xz
test ! -e $distdir.tar
test ! -d $distdir

rm -f $distdir.tar.*
rm -f recursive-result
run_make -O dist
test -f $distdir.tar.gz
test -f $distdir.tar.xz
test ! -e $distdir.tar
test ! -d $distdir

:
