#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# Check that our cleaning rules do not hit errors due to a huge number
# of files to be removed.  Checks similar in spirit are done by sister
# test 'clean-many2.sh', which fakes an artificially low command line
# length limit for 'rm'.

. ./defs || exit 1

cat >> configure.ac << 'END'
AC_SUBST([safe_include], [include])
AC_OUTPUT
END

cat > Makefile.am <<'END'
# Don't use 'include' here: we want this processed at make runtime,
# not at automake runtime.  Otherwise Automake runs too slow.
@safe_include@ files.mk
MOSTLYCLEANFILES = $(files)
CLEANFILES = $(files)
DISTCLEANFILES = $(files)
MAINTANERCLEANFILES = $(files)
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

# Yes, we want to clean ~ 130 thousands files.  So what?
i=2
echo foo bar > t
while test $i -le 17; do
  i=$(($i + 1))
  cat t t > t2
  mv -f t2 t
done
(echo 'files = \' && sed 's/$/ \\/' t && echo '$(am__empty)') > files.mk
rm -f t

# 2^17 + 2 = 131074.
test $(wc -l <files.mk) -eq 65538 || fatal_ "populating 'files.mk'"

touch foo bar
$MAKE maintainer-clean
test ! -e foo
test ! -e bar

:
