#!/bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Check silent-rules mode for C++.
# This test requires the GNU C++ compiler; keep it in sync with sister
# test 'silentcxx.sh', which should work with generic compilers.

required=g++
. ./defs || exit 1

mkdir sub

cat >>configure.ac <<'EOF'
AC_PROG_CXX
AC_OUTPUT
EOF

cat > Makefile.am <<'EOF'
# Need generic and non-generic rules.
bin_PROGRAMS = foo1 foo2 bar1 bar2
foo1_SOURCES = foo.cpp baz.cxx quux.cc
foo2_SOURCES = $(foo1_SOURCES)
foo2_CXXFLAGS = $(AM_CXXFLAGS)
bar1_SOURCES = sub/bar.cpp
bar2_SOURCES = $(bar1_SOURCES)
bar2_CXXFLAGS = $(AM_CXXFLAGS)
EOF

cat > foo.cpp <<'EOF'
using namespace std; /* C compilers fail on this. */
int main (void) { return 0; }
EOF

# Let's try out other extensions too.
echo 'class Baz  { public: int i;  };' > baz.cxx
echo 'class Quux { public: bool b; };' > quux.cc

cp foo.cpp sub/bar.cpp

$ACLOCAL
$AUTOMAKE --add-missing
$AUTOCONF

# Sanity check: make sure the cache variable we force is really used
# by configure.
$FGREP am_cv_CXX_dependencies_compiler_type configure

# Force gcc ("fast") depmode.
# This apparently useless "for" loop is here to simplify the syncing
# with sister test 'silentcxx.sh'.
for config_args in \
  am_cv_CXX_dependencies_compiler_type=gcc
do
  ./configure $config_args --enable-silent-rules
  $MAKE >stdout || { cat stdout; exit 1; }
  cat stdout

  $EGREP ' (-c|-o)' stdout && exit 1
  grep 'mv ' stdout && exit 1

  grep ' CXX  *foo\.o'          stdout
  grep ' CXX  *baz\.o'          stdout
  grep ' CXX  *quux\.o'         stdout
  grep ' CXX  *foo2-foo\.o'     stdout
  grep ' CXX  *foo2-baz\.o'     stdout
  grep ' CXX  *foo2-quux\.o'    stdout
  grep ' CXX  *sub/bar\.o'      stdout
  grep ' CXX  *sub/bar2-bar\.o' stdout
  grep ' CXXLD  *foo1'          stdout
  grep ' CXXLD  *bar1'          stdout
  grep ' CXXLD  *foo2'          stdout
  grep ' CXXLD  *bar2'          stdout

  # Ensure a clean rebuild.
  $MAKE clean

  $MAKE V=1 >stdout || { cat stdout; exit 1; }
  cat stdout

  grep ' -c ' stdout
  grep ' -o quux' stdout
  grep ' -o bar2' stdout

  $EGREP '(CC|CXX|LD) ' stdout && exit 1

  # Ensure a clean reconfiguration/rebuild.
  $MAKE clean
  $MAKE maintainer-clean

done

:
