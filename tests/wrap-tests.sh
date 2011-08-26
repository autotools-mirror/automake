#! /bin/sh
# Copyright (C) 2011 Free Software Foundation, Inc.
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

# Wrap en existing test script of the automake testsuite by pre-defining
# some influential variables and then sourcing it.

set -e

# Will be properly overridden once the wrapped test script is sourced.
fatal_ () { echo "$0: $*" >&2; exit 99; }

# Ensure proper definition of $testsrcdir.
. ./defs-static || fatal_ "couldn't source ./defs-static"
test x"$testsrcdir" != x || fatal_ "\$testsrcdir is empty or undefined"

echo "args: $*" # For debugging.

typ=
while test $# -gt 0; do
  case $1 in
    --define)
      test $# -ge 3 || fatal_ "option \`$1': two arguments required"
      echo "define: $2='$3'" # For debugging.
      eval "$2=\$3"
      shift; shift;;
    --type)
      test $# -ge 2 || fatal_ "option \`$1': argument required"
      typ=$2
      shift;;
    --)
      shift; break;;
     *)
      break;;
    -*)
      fatal_ "invalid option: \`$1'";;
  esac
  shift
done
test -n "$typ" || fatal_ "suffix not specified"

case $#,$1 in
  0,) fatal_ "missing argument";;
  1,*-w.$typ) test_name=`expr x/"$1" : ".*/\\\\(.*\\\\)-w\\\\.$typ$"`;;
  1,*) fatal_ "invalid argument \`$1'";;
  *) fatal_ "too many arguments";;
esac

set -x
# This is required to have the wrapped test use a proper temporary
# directory to run into.
me=${test_name}-w
# In the spirit of VPATH, we prefer a test in the build tree
# over one in the source tree.
for dir in . "$testsrcdir"; do
  # The testsuite shouldn't have a TAP and plain test with the same
  # basename (they would end up sharing the same basename and thus the
  # same `.log' and `.trs' files, wreaking havoc).  So just test for
  # the two flavors in random order.
  for suf in tap test; do
    if test -f "$dir/$test_name.$suf"; then
      # We must let the code in ./defs which kind of test script it is
      # dealing with -- TAP or "plain".  It won't be able to guess
      # automatically, since it uses `$0' for such a guess, and with
      # the present usage `$0' is always `wrap-tests.sh'.
      if test $suf = tap; then
        using_tap=yes
      else
        using_tap=no
      fi
      # Shell traces will be properly re-enabled later by the sourced
      # test script.
      set +x
      . "$dir/$test_name.$suf"
      exit $?
    fi
  done
done

fatal_ "cannot find wrapped test \`$test_name'"
