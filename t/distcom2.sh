#! /bin/sh
# Copyright (C) 2001-2012 Free Software Foundation, Inc.
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

# Test to make sure that depcomp and compile are added to am.dist.common-files.
# Report from Pavel Roskin.  Report of problems with '--no-force' from
# Scott James Remnant (Debian #206299)

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_CC_C_O
AC_CONFIG_FILES([subdir/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = subdir
END

mkdir subdir
: > subdir/foo.c

cat > subdir/Makefile.am << 'END'
noinst_PROGRAMS = foo
foo_SOURCES = foo.c
foo_CFLAGS = -DBAR
END

$ACLOCAL

for opt in '' --no-force; do

  $AUTOMAKE $opt --add-missing

  test -f compile
  test -f depcomp

  for dir in . subdir; do
    sed -n 's/^am.dist.common-files = *\(.*\)$/ \1 /p' \
      <$dir/Makefile.in >$dir/dc.txt
  done

  cat dc.txt # For debugging.
  cat subdir/dc.txt # Likewise.

  $FGREP ' $(am__config_aux_dir)/depcomp ' subdir/dc.txt
  # The 'compile' script will be listed in the am.dist.common-files of
  # the top-level Makefile because it's required in configure.ac
  # (by AM_PROG_CC_C_O).
  $FGREP ' $(am__config_aux_dir)/compile ' dc.txt \
    || $FGREP ' compile ' dc.txt

done

:
