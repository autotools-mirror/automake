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

# The filename-length-max=N option must accept file names of exactly N
# characters, and reject only the longer ones.  See automake bug#81558.

. test-init.sh

echo AC_OUTPUT >> configure.ac

# Long enough to be the longest file name of the distribution.
long=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

mkdir dir
: > dir/$long

# The maximum we ask for is the length of the name under which tar would
# store that file, that is, including the "$distdir/" prefix.  Word
# splitting gets rid of the padding some 'wc' implementations write.
set -- $(printf '%s' "$distdir/dir/$long" | wc -c)
max=$1
echo "maximum file name length: $max" # For debugging.

cat > Makefile.am << END
AUTOMAKE_OPTIONS = filename-length-max=$max
EXTRA_DIST = dir
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

# A file name of exactly $max characters is not too long.
$MAKE dist
test -f $distdir.tar.gz

# One character more, and it is.
: > dir/a$long
run_make -E -e FAIL dist
grep 'filenames are too long' stderr
# And only that file gets reported.
test 1 -eq $(grep -c "$long" stderr)

:
