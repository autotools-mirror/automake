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

# Test the delete-on-error option, given either to AM_INIT_AUTOMAKE or
# in AUTOMAKE_OPTIONS.

. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([sub/Makefile])
AC_OUTPUT
END

mkdir sub

cat > Makefile.am << 'END'
SUBDIRS = sub
END

cat > sub/Makefile.am << 'END'
AUTOMAKE_OPTIONS = delete-on-error
foo.h:
	echo partial > $@; exit 1
END

$ACLOCAL
$AUTOMAKE

# The option is per-directory when given in AUTOMAKE_OPTIONS.
grep '^\.DELETE_ON_ERROR:' Makefile.in && exit 1
test $(grep -c '^\.DELETE_ON_ERROR:' sub/Makefile.in) -eq 1

# The default:, .SUFFIXES and .DELETE_ON_ERROR lines come before any rule.
sed -n '1,/^\.DELETE_ON_ERROR:/p' sub/Makefile.in > head.txt
grep '^foo\.h:' head.txt && exit 1

$AUTOCONF
./configure

# Only check the runtime behavior with a make known to honor the target.
cat > probe.mk << 'END'
.DELETE_ON_ERROR:
probe.out:
	echo x > $@; exit 1
END
if $MAKE -f probe.mk >/dev/null 2>&1 || test -f probe.out; then
  echo "$me: make does not honor .DELETE_ON_ERROR, skipping runtime check"
else
  cd sub
  run_make -e FAIL foo.h
  test ! -e foo.h
  # The generated Makefile is .PRECIOUS, so it must survive.
  test -f Makefile
  cd ..
fi

# Now the global form.
sed 's/AM_INIT_AUTOMAKE/AM_INIT_AUTOMAKE([delete-on-error])/' \
  configure.ac > configure.tmp
cmp configure.ac configure.tmp && fatal_ 'failed to edit configure.ac'
mv -f configure.tmp configure.ac

$ACLOCAL --force
$AUTOMAKE
test $(grep -c '^\.DELETE_ON_ERROR:' Makefile.in) -eq 1
# Given twice, it is still emitted once.
test $(grep -c '^\.DELETE_ON_ERROR:' sub/Makefile.in) -eq 1

:
