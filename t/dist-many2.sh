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

# Check that our dist rules do not hit errors due to an exceeded
# command line length when there are many files to distribute.  Here,
# we fake a very low command line length limit for 'mkdir' (max 50
# arguments) and the shell (max 4000 chars in its command line).
# The sister test 'dist-many.sh' try to hit the real command line length
# limit of the system, by declaring a huge number of files to be cleaned.

. test-init.sh

mkdir bin

cat > bin/mkdir << END
#!$AM_TEST_RUNNER_SHELL -u
PATH='$PATH'; export PATH
END
cat >> bin/mkdir << 'END'
if test $# -eq 0; then
  echo "mkdir: missing argument" >&2
  exit 1
elif test $# -gt 50; then
  echo "mkdir: argument list too long ($# arguments)" >&2
  exit 1
fi
exec mkdir "$@"
END

cat > bin/am--sh << END
#!$AM_TEST_RUNNER_SHELL -u
sh='$SHELL'
END
cat >> bin/am--sh << 'END'
cmdline=$*
cmdline_len=${#cmdline}
test $cmdline_len -le 4000 || {
  echo "sh: command line to long (~ $cmdline_len characters)" >&2
  exit 1
}
exec $sh "$@"
END

chmod a+x bin/mkdir bin/am--sh
PATH=$(pwd)/bin$PATH_SEPARATOR$PATH; export PATH
CONFIG_SHELL=$(pwd)/bin/am--sh; export CONFIG_SHELL

echo AC_OUTPUT >> configure.ac

file=an-empty-file-with-a-long-name
dir1=a-directory-with-a-long-name
dir2=another-long-named-directory

# Distributed files will be 3 * $count.
count=200

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

test -f $distdir/$file.87
test -f $distdir/$dir1.32/foo
test -f $distdir/$dir2.15/$file.15

$MAKE distcheck

:
