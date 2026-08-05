#! /bin/sh
# Copyright (C) 2013-2026 Free Software Foundation, Inc.
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

# Check support for no-dist-gzip with dist-shar.

required='shar unshar'
. test-init.sh

errmsg='support for shar .*deprecated'

echo AUTOMAKE_OPTIONS = dist-shar > Makefile.am
$ACLOCAL
AUTOMAKE_fails -Wnone -Wobsolete
grep "^Makefile\\.am:1:.*$errmsg" stderr

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([no-dist-gzip dist-shar])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

rm -rf autom4te*.cache
$ACLOCAL
AUTOMAKE_run -Wno-error
grep "^configure\\.ac:2:.*$errmsg" stderr

$AUTOCONF
./configure
$MAKE distcheck
test -f $distdir.shar.gz

# A failure of shar must not go unnoticed just because its output used
# to be fed to gzip, which happily succeeded.  See automake bug#19614.

mkdir bin
echo '#!/bin/sh' > bin/shar
echo 'echo "fake shar: cannot do that" >&2; exit 1' >> bin/shar
chmod a+x bin/shar

rm -f $distdir.shar.gz
saved_PATH=$PATH
PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH
$MAKE dist-shar > output 2>&1 && { cat output; exit 1; }
PATH=$saved_PATH; export PATH

cat output
grep 'cannot do that' output
test ! -e $distdir.shar
test ! -e $distdir.shar.gz

:
