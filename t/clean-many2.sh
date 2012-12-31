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

# Check that our cleaning rules do not hit errors due to an exceeded
# command line length when there are many files to clean.  Here, we
# fake a very low command line length limit for 'rm' (max 50 arguments).
# The sister test 'clean-many.sh' try to hit the real command line length
# limit of the system, by declaring a huge number of files to be cleaned.

. test-init.sh

echo AC_OUTPUT >> configure.ac

oPATH=$PATH; export oPATH
mkdir bin
# Redundant quoting of 'rm' (here and below) to please maintainer-check.
cat > bin/'rm' <<'END'
#!/bin/sh
PATH=$oPATH; export PATH
if test $# -eq 0; then
  echo "rm: missing argument" >&2
  exit 1
elif test $# -gt 50; then
  echo "rm: argument list too long ($# arguments)" >&2
  exit 1
fi
exec 'rm' "$@"
END
chmod a+x bin/rm
PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH

cat > Makefile.am <<'END'
MOSTLYCLEANFILES = $(files)
CLEANFILES = $(files)
DISTCLEANFILES = $(files)
MAINTANERCLEANFILES = $(files)
include files.am
END

echo foo bar > t
i=1
while test $i -le 10; do
  cat t t > t2 && mv -f t2 t || exit 99
  i=$(($i + 1))
done

# Sanity check.
rm -f $(cat t) && fatal_ "setting up 'rm' wrapper"

(echo 'files = \' && sed '$!s/$/ \\/' t) >files.am
rm -f t

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a
./configure
cp config.status config-status.sav \

for target in mostlyclean clean distclean maintainer-clean; do
  echo dummy > foo
  echo dummy > bar
  $MAKE $target
  test ! -e foo
  test ! -e foo
  cp config-status.sav config.status && ./config.status Makefile \
    || fatal_ "resetting Makefile after cleanup"
done

:
