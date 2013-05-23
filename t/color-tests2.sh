#! /bin/sh
# Copyright (C) 2007-2013 Free Software Foundation, Inc.
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

# Test Automake TESTS color output, using the expect(1) program.
# Keep this in sync with the sister test 'color-tests.sh'.

required='grep-nonprint'
# For gen-testsuite-part: ==> try-with-serial-tests <==
. test-init.sh

# Escape '[' for grep, below.
red="$esc\[0;31m"
grn="$esc\[0;32m"
lgn="$esc\[1;32m"
blu="$esc\[1;34m"
mgn="$esc\[0;35m"
std="$esc\[m"

# This test requires a working a working 'expect' program.
(set +e; expect -c 'exit 77'; test $? -eq 77) \
  || skip_ "requires a working expect program"

# Do the tests.

cat >>configure.ac << 'END'
if $testsuite_colorized; then :; else
  AC_SUBST([AM_COLOR_TESTS], [no])
fi
AC_OUTPUT
END

cat >Makefile.am <<'END'
TESTS = $(check_SCRIPTS)
check_SCRIPTS = pass fail skip xpass xfail error
XFAIL_TESTS = xpass xfail
END

cat >pass <<END
#! /bin/sh
exit 0
END

cat >fail <<END
#! /bin/sh
exit 1
END

cat >skip <<END
#! /bin/sh
exit 77
END

cat >error <<END
#! /bin/sh
exit 99
END

cp fail xfail
cp pass xpass
chmod +x pass fail skip xpass xfail error

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

test_color ()
{
  # Not a useless use of cat; see above comments "grep-nonprinting"
  # requirement in 'test-init.sh'.
  cat stdout | grep "^${grn}PASS${std}: .*pass"
  cat stdout | grep "^${red}FAIL${std}: .*fail"
  cat stdout | grep "^${blu}SKIP${std}: .*skip"
  cat stdout | grep "^${lgn}XFAIL${std}: .*xfail"
  cat stdout | grep "^${red}XPASS${std}: .*xpass"
  # The old serial testsuite driver doesn't distinguish between failures
  # and hard errors.
  if test x"$am_serial_tests" = x"yes"; then
    cat stdout | grep "^${red}FAIL${std}: .*error"
  else
    cat stdout | grep "^${mgn}ERROR${std}: .*error"
  fi
  :
}

test_no_color ()
{
  # Not a useless use of cat; see above comments "grep-nonprinting"
  # requirement in 'test-init.sh'.
  cat stdout | grep "$esc" && exit 1
  :
}

our_make ()
{
  set "MAKE=$MAKE" ${1+"$@"}
  env "$@" expect -f $srcdir/expect-make >stdout || { cat stdout; exit 1; }
  cat stdout
}

cat >expect-make <<'END'
eval spawn $env(MAKE) check
expect eof
END

for vpath in false :; do

  if $vpath; then
    mkdir build
    cd build
    srcdir=..
  else
    srcdir=.
  fi

  $srcdir/configure

  our_make TERM=ansi
  test_color

  our_make TERM=dumb
  test_no_color

  our_make TERM=ansi MAKE="$MAKE AM_COLOR_TESTS=no"
  test_no_color

  $srcdir/configure testsuite_colorized=false

  our_make TERM=ansi
  test_no_color

  our_make TERM=dumb MAKE="$MAKE AM_COLOR_TESTS=always"
  test_color

  $MAKE distclean
  cd $srcdir

done

:
