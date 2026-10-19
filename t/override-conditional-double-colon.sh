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

# Double-colon rules have independent recipes, including conditional ones.

. test-init.sh

cat >> configure.ac << 'END'
AM_CONDITIONAL([FOO], [test "$foo" = yes])
AC_OUTPUT
END

cat > Makefile.am << 'END'
all-local: foo bar baz
foo::
if FOO
	@echo foo-first >> seen
endif
foo::
	@echo foo-second >> seen
if FOO
bar:: ; @echo bar-first >> seen
baz:: \
 ; @echo baz-first >> seen
endif
bar:: ; @echo bar-second >> seen
baz:: ; @echo baz-second >> seen
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a -Werror
for foo in yes no; do
  ./configure foo=$foo
  rm -f seen
  $MAKE all
  cat > expected << 'END'
bar-second
baz-second
foo-second
END
  if test "$foo" = yes; then
    printf '%s\n' bar-first baz-first foo-first >> expected
  fi
  sort expected > expected.sorted
  sort seen > seen.sorted
  diff expected.sorted seen.sorted
done

:
