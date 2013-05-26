#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Check that dynamic content for $(TESTS) is supported, both when set from
# inside the Makefile.am and when overridden from the command line.

. test-init.sh

echo AC_OUTPUT >> configure.ac

cat > ok <<'END'
#!/bin/sh
exit 0
END

cat > ko <<'END'
#!/bin/sh
exit 1
END

cat > sk <<'END'
#!/bin/sh
exit 77
END

cat > er << 'END'
#!/bin/sh
echo $0 should not be run >&2
exit 99
END

chmod a+x ko ok sk

mkdir t
cp ok t/nosuffix

cp ok g1.sh
cp ok g2.sh
cp ok g3.sh
cp ok g4.sh
cp er g5.sh

cp ok t00-foo.sh
cp ok t02.sh
cp ok t57_mu.sh
cp ok t7311.sh
cp ko t98S.sh
cp ko t99.sh
cp er t1.sh
cp er t9.sh
cp er tx98.sh

cp sk fu.sh
cp sk mu

cat > get-tests-list <<END
#!/bin/sh
echo "g1.sh  ${tab}g2.sh "
if :; then echo '  g3.sh'; fi
echo
echo g4.sh
END
chmod a+x get-tests-list

cat > Makefile.am << 'END'
my_add_dirprefix = $(strip $(1))/$(strip $(2))
EXTRA_DIST = $(TESTS) get-tests-list
TEST_EXTENSIONS = .sh

t1 = fu
t2 = mux

# Also try an empty match suffix, to ensure that the ':=' in there is
# not confused by the parser with an immediate assignment operator.
TESTS = $(t1:=.sh) $(t2:x=)
TESTS += $(wildcard $(srcdir)/t[0-9][0-9]*.sh)
TESTS += $(shell $(srcdir)/get-tests-list)
TESTS += $(call my_add_dirprefix, t, nosuffix)
XFAIL_TESTS = $(wildcard $(srcdir)/t9[0-9]*.sh)
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

run_make -O check
count_test_results total=13 pass=9 fail=0 xpass=0 xfail=2 skip=2 error=0

grep '^PASS: t/nosuffix$'  stdout
grep '^PASS: g1\.sh$'      stdout
grep '^PASS: g2\.sh$'      stdout
grep '^PASS: g3\.sh$'      stdout
grep '^PASS: g4\.sh$'      stdout
grep '^PASS: t00-foo\.sh$' stdout
grep '^PASS: t02\.sh$'     stdout
grep '^PASS: t57_mu\.sh$'  stdout
grep '^PASS: t7311\.sh$'   stdout
grep '^XFAIL: t98S\.sh$'   stdout
grep '^XFAIL: t99\.sh$'    stdout
grep '^SKIP: fu\.sh$'      stdout
grep '^SKIP: mu$'          stdout

$MAKE mostlyclean
test "$(find . -name '*.log')" = ./config.log

run_make -O distcheck
count_test_results total=13 pass=9 fail=0 xpass=0 xfail=2 skip=2 error=0

run_make -O check \
  tests1='$(wildcard t00*.sh t98?.sh)' \
  tests2='$(shell ./get-tests-list | sed 1d)' \
  TESTS='$(tests1) $(tests2)'

count_test_results total=4 pass=3 fail=0 xpass=0 xfail=1 skip=0 error=0

grep '^PASS: g3\.sh$'     stdout
grep '^PASS: g4\.sh$'     stdout
grep '^PASS: t00-foo\.sh' stdout
grep '^XFAIL: t98S\.sh'   stdout

$MAKE mostlyclean
test "$(find . -name '*.log')" = ./config.log

$MAKE check TESTS='$(shell echo t00 | sed "s/$$/-foo/") t99'
test -f t00-foo.log
test -f t99.log

run_make -O check \
  foo='E9E9E' \
  a='t00.err' \
  b='${a:.err=-foo}' \
  TESTS='$(b) t$(subst E,,$(foo)) $(call my_add_dirprefix,t,nosuffix)'

count_test_results total=3 pass=2 fail=0 xpass=0 xfail=1 skip=0 error=0
grep '^PASS: t/nosuffix'  stdout
grep '^PASS: t00-foo\.sh' stdout
grep '^XFAIL: t99\.sh'    stdout

:
