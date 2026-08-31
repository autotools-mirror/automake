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

# Check AM_OPTIONAL_AUTOMAKE.  Five scenarios:
#  (1) The tool is on PATH at configure time -> dist-bzip3 produces
#      $distdir.tar.bz3 alongside the always-built $distdir.tar.gz.
#  (2) An unknown option produces an autoreconf-time `syntax' warning
#      but does not break configure or make dist.
#  (3) The tool is missing at configure time -> no extra rule is
#      appended; `make dist' runs cleanly and does not produce
#      $distdir.tar.bz3.
#  (4) The tool is present at configure time but fails when invoked
#      by `make dist' -> the recipe cleans up, prints a warning to
#      stderr, `make dist' still succeeds, and no $distdir.tar.bz3
#      appears.
#  (5) dist-shar and dist-tarZ, the two non-tar-pipe formats.

required='bzip3'
. test-init.sh

: "Test 1: bzip3 on PATH at configure time."

cat > configure.ac <<'END'
AC_INIT([am-optional-automake], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-bzip3])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
echo 'VERSION = `echo 1.0`' > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing
./configure
$MAKE dist
test -s am-optional-automake-1.0.tar.gz
test -s am-optional-automake-1.0.tar.bz3
# These archives are not in $(DIST_ARCHIVES); distcheck must still
# pass (its in-tree copies get cleaned before distcleancheck).
$MAKE distcheck
test -s am-optional-automake-1.0.tar.bz3

rm -rf autom4te*.cache aclocal.m4 configure Makefile.in install-sh \
       missing config.status config.log Makefile \
       am-optional-automake-1.0 am-optional-automake-1.0.tar.*

: "Test 2: Unknown option is a warning, not an error."

cat > configure.ac <<'END'
AC_INIT([am-optional-automake], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-banana dist-bzip3])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

# aclocal/autoconf must succeed.  The `syntax' warning is emitted by
# m4_warn() during macro expansion, which happens when autoconf runs
# (aclocal only scans).  We don't promote it to error here: AM_INIT's
# default warning set is plenty.  Capture autoconf's stderr and
# assert the warning mentions the offending token.
$ACLOCAL
$AUTOCONF -Wno-error 2>stderr
grep "dist-banana" stderr

$AUTOMAKE --add-missing
./configure
$MAKE dist
test -s am-optional-automake-1.0.tar.bz3

rm -rf autom4te*.cache aclocal.m4 configure Makefile.in install-sh \
       missing config.status config.log Makefile stderr \
       am-optional-automake-1.0 am-optional-automake-1.0.tar.*

: "Test 3: bzip3 missing at configure time."

cat > configure.ac <<'END'
AC_INIT([am-optional-automake], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-bzip3])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

# Make AC_CHECK_PROG see bzip3 as absent without touching PATH, by
# pre-seeding its cache variable to the empty string.
$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing
ac_cv_prog_am__optional_bzip3= ./configure
$MAKE dist
test -s am-optional-automake-1.0.tar.gz
test ! -e am-optional-automake-1.0.tar.bz3

rm -rf autom4te*.cache aclocal.m4 configure Makefile.in \
       install-sh missing config.status config.log Makefile \
       am-optional-automake-1.0 am-optional-automake-1.0.tar.*

: "Test 4: bzip3 present at configure, vanished at make dist."

cat > configure.ac <<'END'
AC_INIT([am-optional-automake], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-bzip3])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing
./configure  # bzip3 IS visible here, so the rule is appended

# Shadow bzip3 with a stub that exits non-zero.  The recipe must
# catch the failure, clean up the partial archive, print a warning,
# leave the rest of `make dist' running, and exit 0.
mkdir stub-bin
cat > stub-bin/bzip3 <<'END'
#! /bin/sh
exit 1
END
chmod +x stub-bin/bzip3

saved_PATH=$PATH
PATH=$(pwd)/stub-bin$PATH_SEPARATOR$PATH; export PATH
run_make -E dist
PATH=$saved_PATH; export PATH

test -s am-optional-automake-1.0.tar.gz
test ! -e am-optional-automake-1.0.tar.bz3
grep 'am-optional:.*dist-bzip3 failed' stderr

rm -rf stub-bin autom4te*.cache aclocal.m4 configure Makefile.in \
       install-sh missing config.status config.log Makefile stderr \
       am-optional-automake-1.0 am-optional-automake-1.0.tar.*

: "Test 5: dist-shar and dist-tarZ alongside the tar-pipe forms."
# These two formats do not follow the single-tool tar-pipe pattern,
# so they get their own exercise.  shar and compress are rarely
# installed, so only assert the archive when the tool is actually
# present; otherwise we just check that `make dist' did not fail.

cat > configure.ac <<'END'
AC_INIT([am-optional-automake], [1.0])
AM_INIT_AUTOMAKE([foreign])
AM_OPTIONAL_AUTOMAKE([dist-shar dist-tarZ])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing
./configure
$MAKE dist
test -s am-optional-automake-1.0.tar.gz

if (command -v shar) >/dev/null 2>&1; then
  test -s am-optional-automake-1.0.shar.gz
  # The intermediate uncompressed .shar must not be left behind.
  test ! -e am-optional-automake-1.0.shar
fi
if (command -v compress) >/dev/null 2>&1; then
  test -s am-optional-automake-1.0.tar.Z
fi

:
