#! /bin/sh
# Copyright (C) 2011-2013 Free Software Foundation, Inc.
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

# Make sure that Automake can handle "funny chars" in TEST_EXTENSIONS,
# as long as they can be used in GNU make variable names.

. test-init.sh

fetch_tap_driver

echo AC_OUTPUT >> configure.ac

cat >> Makefile.am <<'END'
TEST_EXTENSIONS = .@ .2 .f-o-o .l!Nu.x
TESTS = foo.@ bar.f-o-o baz.2 zardoz.l!Nu.x
XFAIL_TESTS = zardoz.l!Nu.x
@_LOG_COMPILER = $(SHELL)
2_LOG_COMPILER = $(SHELL)
F-O-O_LOG_DRIVER = $(srcdir)/tap-driver
L!NU.X_LOG_COMPILER = false
EXTRA_DIST = $(TESTS) tap-driver
END

touch foo.@ bar.f-o-o zardoz.l!Nu.x \
  || skip_ "your file system doesn't support funny characters"

# Try to ensure this file fails if executed directly.
cat > foo.@ << 'END'
#! /bin/false
echo @K @K @K
exit 0
END
cp foo.@ baz.2
# We don't want them to be executable, either.  So do this for
# extra safety.
chmod a-x foo.@ baz.2

cat > bar.f-o-o << 'END'
#! /bin/sh
echo 1..4
echo "ok - good"
echo "ok 2 # SKIP"
echo "not ok 3 # TODO"
echo ok
END
chmod a+x bar.f-o-o

cat > zardoz.l!Nu.x << 'END'
#! /bin/sh
echo Hello Zardoz
exit 0
END
chmod a+x zardoz.l!Nu.x

count_all ()
{
  count_test_results total=7 pass=4 fail=0 skip=1 xfail=2 xpass=0 error=0
  grep '^PASS: foo\.@$'                 stdout
  grep '^PASS: baz\.2$'                 stdout
  grep '^XFAIL: zardoz.l!Nu\.x$'        stdout
  grep '^PASS: bar\.f-o-o 1 - good'     stdout
  grep '^SKIP: bar\.f-o-o 2 # SKIP'     stdout
  grep '^XFAIL: bar\.f-o-o 3 # TODO'    stdout
  grep '^PASS: bar\.f-o-o 4$'           stdout
}

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

run_make -e IGNORE -O check
ls -l
cat test-suite.log
cat foo.log
grep '@K @K @K' foo.log
cat baz.log
grep '@K @K @K' baz.log
cat bar.log
cat zardoz.log
grep 'Hello Zardoz' zardoz.log && exit 1
test $am_make_rc -eq 0
count_all

$MAKE clean
test ! -f test-suite.log
test ! -f foo.log
test ! -f bar.log
test ! -f baz.log
test ! -f zardoz.log

run_make -e IGNORE -O check TESTS=zardoz L!NU.X_LOG_COMPILER=/bin/sh
count_test_results total=1 pass=0 fail=0 skip=0 xfail=0 xpass=1 error=0
cat test-suite.log
test ! -f foo.log
test ! -f bar.log
test ! -f baz.log
cat zardoz.log
grep 'Hello Zardoz' zardoz.log
test $am_make_rc -gt 0

run_make -O recheck
count_test_results total=1 pass=0 fail=0 skip=0 xfail=1 xpass=0 error=0
grep '^XFAIL: zardoz.l!Nu\.x$' stdout

run_make -O recheck
count_test_results total=0 pass=0 fail=0 skip=0 xfail=0 xpass=0 error=0

run_make -O distcheck
count_all

:
