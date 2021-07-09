#! /bin/sh
# Copyright (C) 2021 Free Software Foundation, Inc.
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

# Test the presence and absence of the option no-dist-built-sources.

. test-init.sh

# the tests are almost the same, so do a loop with a couple conditionals.
for testopt in no-built-sources dist-built-sources; do

  if test "$testopt" = no-built-sources; then
    sed -e 's/AM_INIT_AUTOMAKE/AM_INIT_AUTOMAKE([no-dist-built-sources])/' \
        configure.ac >configure.tmp
    cmp configure.ac configure.tmp && fatal_ 'failed to edit configure.ac'
    mv -f configure.tmp configure.ac
  fi

  cat >> configure.ac << 'END'
AC_OUTPUT
END

  cat > Makefile.am <<EOF
BUILT_SOURCES = x.c
EXTRA_DIST = y.c

x.c:
	touch \$@

y.c:
	cp x.c y.c # simulate 'undetectable' dependency on x.c
EOF

  if test "$testopt" = no-built-sources; then
    touch y.c # no-built-sources dist needs to have all files already there
  else
    : # with default $(BUILT_SOURCES) dep, will try to build y.c by the rule
  fi

  $ACLOCAL
  $AUTOMAKE
  $AUTOCONF
  ./configure
  run_make dist

  # In any case, the tarball should contain y.c, but not x.c.
  # The tarball is always named based on $0, regardless of our options.
  pkg_ver=$me-1.0
  ! tar tf "${pkg_ver}".tar.gz "${pkg_ver}"/x.c
  tar tf "${pkg_ver}".tar.gz "${pkg_ver}"/y.c

  # And x.c should have been built only for the built-sources version.
  if test "$testopt" = no-built-sources; then
    # no-built-sources should not have generated this
    ! test -e x.c
  else
    # built-sources build should have it
    test -e x.c
  fi
done
