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

# Check that our dist rules do not hit errors due to a huge number
# of files to be distributed.  Checks similar in spirit are done by
# sister test 'dist-many2.sh', which fakes an artificially low
# command line length limit for 'mkdir' and the shell.

. ./defs || exit 1

echo AC_OUTPUT >> configure.ac

file=an-empty-file-with-a-long-name
dir1=a-directory-with-a-long-name
dir2=another-long-named-directory

# Distributed files will be 3 * $count.
count=10000

i=1
while test $i -le $count; do
  files="
    $file.$i
    $dir1.$i/foo
    $dir2.$i/$file.$i
  "
  mkdir $dir1.$i $dir2.$i
  for f in $files; do
    : > $f
    echo $f
  done
  i=$(($i + 1))
  # Disable shell traces after the first iteration, to avoid
  # polluting the test logs.
  set +x
done > t
set -x # Re-enable shell traces.
echo 'EXTRA_DIST = \'   >> Makefile.am
sed '$!s/$/ \\/' t      >> Makefile.am
rm -f t

test $(wc -l <Makefile.am) -eq $(( 1 + (3 * $count) )) \
  || fatal_ "populating 'EXTRA_DIST'"

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

$MAKE distdir

# Only check head, tail, and a random sample.

test -f $distdir/$file.1
test -f $distdir/$dir1.1/foo
test -f $distdir/$dir2.1/$file.1

test -f $distdir/$file.$count
test -f $distdir/$dir1.$count/foo
test -f $distdir/$dir2.$count/$file.$count

test -f $distdir/$file.163
test -f $distdir/$dir1.7645/foo
test -f $distdir/$dir2.4077/$file.4077

$MAKE distcheck

:
