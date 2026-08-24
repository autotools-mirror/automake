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

# 'make dist' must fail when the archiver fails, even though its output
# used to be fed to a compressor that exits successfully.  Also check
# that the archiver is run only once, whatever the number of requested
# formats.  See automake bug#19614.

. test-init.sh

cat > configure.ac << END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([dist-xz dist-bzip2])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

# Stub compressors, so that this test does not depend on 'xz' and
# 'bzip2' being installed ('gzip' is assumed to be available on every
# reasonable portability target).  They just copy their input, which is
# all the checks below care about.
mkdir bin
for c in xz bzip2; do
  echo '#!/bin/sh' > bin/$c
  echo 'exec cat' >> bin/$c
  chmod a+x bin/$c
done
PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH

# Stub archivers, to be used in place of $(am__tar).  Their names
# contain no whitespace, so that overriding am__tar from the 'make'
# command line works with any make implementation.

cat > tar-fails << 'END'
#!/bin/sh
echo "fake tar: cannot archive that" >&2
exit 2
END

# Some tar implementations merely warn about the files they cannot
# archive, and still exit successfully.
cat > tar-warns << 'END'
#!/bin/sh
echo "fake tar: cannot archive that" >&2
echo "definitely not a valid tar archive"
END

cat > tar-counts << 'END'
#!/bin/sh
echo x >> tar-runs
echo "definitely not a valid tar archive"
END

chmod a+x tar-fails tar-warns tar-counts

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

for fake_tar in tar-fails tar-warns; do
  run_make -M -e FAIL dist am__tar=./$fake_tar
  grep 'cannot archive that' output
  grep "$distdir\.tar: cannot create the distribution archive" output
  # No archive, and no leftovers, must have been created.
  test ! -e $distdir.tar
  test ! -e $distdir.tar.gz
  test ! -e $distdir.tar.xz
  test ! -e $distdir.tar.bz2
done

# Diagnostics from tar can be declared harmless by the user.
run_make -M dist am__tar=./tar-warns AM_DIST_TAR_IGNORE_STDERR=yes
grep 'cannot archive that' output
test ! -e $distdir.tar
test -s $distdir.tar.gz
test -s $distdir.tar.xz
test -s $distdir.tar.bz2

rm -f $distdir.tar.*

# Three formats, but a single run of the archiver.
run_make dist am__tar=./tar-counts
cat tar-runs # For debugging.
test "$(cat tar-runs)" = x
test ! -e $distdir.tar
test -s $distdir.tar.gz
test -s $distdir.tar.xz
test -s $distdir.tar.bz2

:
