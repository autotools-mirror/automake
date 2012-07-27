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

# Check parallel-tests features: empty TESTS

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub1/Makefile sub2/Makefile])
AC_OUTPUT
END

cat > Makefile.am << 'END'
SUBDIRS = sub1 sub2
END

mkdir sub1 sub2

cat > sub1/Makefile.am << 'END'
TESTS =
check-local:
	echo \
          $(am.test-suite.test-logs) \
          $(am.test-suite.test-results) \
          $(am.test-suite.test-bases) \
	| grep . && exit 1; exit 0
END

cat > sub2/Makefile.am << 'END'
TESTS = foo.test
END

cat > sub2/foo.test <<'END'
#! /bin/sh
exit 0
END
chmod a+x sub2/foo.test

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

no_test_has_run ()
{
  ls -1 *.log | grep -v '^test-suite\.log$' | grep . && exit 1
  grep '^# TOTAL: *0$' test-suite.log
  :
}

for vpath in : false; do
  if $vpath; then
    mkdir build
    cd build
    srcdir=..
  else
    srcdir=.
  fi
  $srcdir/configure
  cd sub1
  $MAKE check VERBOSE=yes
  no_test_has_run
  cd ../sub2
  $MAKE check VERBOSE=yes TESTS=''
  no_test_has_run
  cd ..
  $MAKE check
  cat sub2/foo.log
  $MAKE distclean
  cd $srcdir
done

:
