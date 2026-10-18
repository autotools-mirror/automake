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

required='zstd'
. test-init.sh

cat >> configure.ac <<'END'
AC_OUTPUT
END
cat > Makefile.am <<'END'
AUTOMAKE_OPTIONS = dist-zstd no-dist-gzip
EXTRA_DIST = payload
END
echo 'distribution contents' > payload

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

for mode in clevel default options precedence; do
  unset ZSTD_CLEVEL ZSTD_OPT
  case $mode in
    clevel) ZSTD_CLEVEL=3; export ZSTD_CLEVEL; level=3 ;;
    default) level=19 ;;
    options) ZSTD_OPT=-1; export ZSTD_OPT; level=1 ;;
    precedence)
      ZSTD_CLEVEL=3; ZSTD_OPT=--invalid-option
      export ZSTD_CLEVEL ZSTD_OPT
      level=3
      # A numeric filename must never be mistaken for the input tarball.
      echo 'not a tarball' > 3 ;;
  esac
  $MAKE dist
  zstd -dc "$distdir.tar.zst" > archive.tar
  zstd -c -$level < archive.tar > expected.zst
  cmp "$distdir.tar.zst" expected.zst
  mkdir unpack
  (cd unpack && tar xf ../archive.tar)
  cmp payload "unpack/$distdir/payload"
  rm -rf unpack
  rm -f "$distdir.tar.zst" archive.tar expected.zst
done

:
