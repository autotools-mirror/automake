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

# AM_OPTIONAL_AUTOMAKE archives must be made from the same distdir and
# tarball as the mandatory ones, so that dist-hook runs only once, and
# their compressors must honor the same variables as the dist-XXX rules.

. test-init.sh

# Stub compressors that log their arguments and relevant environment.
mkdir bin
for prog in bzip2 xz lzip zstd; do
  cat > bin/$prog <<END
#! /bin/sh
echo "$prog \$* BZIP2=\${BZIP2-unset} XZ_OPT=\${XZ_OPT-unset}" \
  >>"\$stub_log"
cat
END
  chmod a+x bin/$prog
done
PATH=`pwd`/bin$PATH_SEPARATOR$PATH; export PATH
stub_log=`pwd`/stub.log; export stub_log

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-bzip2 dist-xz dist-lzip dist-zstd])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat > Makefile.am <<'END'
dist-hook:
	echo hook >>$(abs_top_builddir)/hook.log
DISTCLEANFILES = hook.log
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing
./configure

check_dist ()
{
  rm -f hook.log stub.log $distdir.tar.*
  run_make -O -- "$@" dist
  cat stub.log
  test `wc -l <hook.log` -eq 1
  tar_runs=`grep -c 'am__tar_msg=' stdout` || tar_runs=0
  if using_gmake; then
    test $tar_runs -eq 1
  else
    test $tar_runs -ge 1
  fi
  test -f $distdir.tar.gz
  test -f $distdir.tar.bz2
  test -f $distdir.tar.xz
  test -f $distdir.tar.lz
  test -f $distdir.tar.zst
}

check_dist
grep '^bzip2 -c BZIP2=-9 ' stub.log
grep '^xz -c .*XZ_OPT=-e$' stub.log
grep '^lzip -c -9 ' stub.log
grep '^zstd -c -q -19 ' stub.log

BZIP2=-1 XZ_OPT=-2 LZIP_OPT=-3 ZSTD_OPT=-4
export BZIP2 XZ_OPT LZIP_OPT ZSTD_OPT
check_dist
grep '^bzip2 -c BZIP2=-1 ' stub.log
grep '^xz -c .*XZ_OPT=-2$' stub.log
grep '^lzip -c -3 ' stub.log
grep '^zstd -c -q -4 ' stub.log
unset BZIP2 XZ_OPT LZIP_OPT ZSTD_OPT

# As with dist-zstd, zstd reads ZSTD_CLEVEL from the environment.
ZSTD_CLEVEL=5; export ZSTD_CLEVEL
check_dist
grep '^zstd -c -q  *BZIP2' stub.log
unset ZSTD_CLEVEL

rm -f stub.log
$MAKE distcheck

:
