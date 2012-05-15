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

# Check that the new testsuite harness do not generate recipes that can
# have a trailing '\', since that can cause spurious syntax errors with
# older bash versions (e.g., bash 2.05b).
# See automake bug#10436.

. ./defs || Exit 1

echo AC_OUTPUT >> configure.ac

cat > Makefile.am <<'END'
TESTS = foo.test
EXTRA_DIST = $(TESTS)
am__backslash = \\ # foo
.PHONY: bad-recipe
bad-recipe:
	@printf '%s\n' $(am__backslash)
END

cat > foo.test <<'END'
#!/bin/sh
exit 0
END
chmod +x foo.test

am__SHELL=$SHELL; export am__SHELL
am__PERL=$PERL; export am__PERL

cat > my-shell <<'END'
#!/bin/sh -e
set -u
tab='	'
nl='
'
am__shell_flags=
am__shell_command=; unset am__shell_command
while test $# -gt 0; do
  case $1 in
    # If the shell is invoked by make e.g. as "sh -ec" (seen on
    # GNU make in POSIX mode) or "sh -ce" (seen on Solaris make).
    -*c*)
        flg=`echo x"$1" | sed -e 's/^x-//' -e 's/c//g'`
        if test x"$flg" != x; then
          am__shell_flags="$am__shell_flags -$flg"
        fi
        am__shell_command=$2
        shift
        ;;
    -?*)
        am__shell_flags="$am__shell_flags $1"
        ;;
      *)
        break
        ;;
  esac
  shift
done
if test x${am__shell_command+"set"} != x"set"; then
  # Some make implementations, like *BSD's, pass the recipes to the shell
  # through its standard input.  Trying to run our extra checks in this
  # case would be too tricky, so we just skip them.
  exec $am__SHELL $am__shell_flags ${1+"$@"}
else
  am__tweaked_shell_command=`printf '%s\n' "$am__shell_command" \
    | tr -d " $tab$nl"`
  case ${am__tweaked_shell_command-} in
    *\\)
      echo "my-shell: recipe ends with backslash character" >&2
      printf '%s\n' "=== BEGIN recipe" >&2
      printf '%s\n' "${am__shell_command-}" >&2
      printf '%s\n' "=== END recipe" >&2
      exit 99
      ;;
  esac
  exec $am__SHELL $am__shell_flags -c "$am__shell_command" ${1+"$@"}
fi
END
chmod a+x my-shell

cat my-shell

CONFIG_SHELL=`pwd`/my-shell; export CONFIG_SHELL

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure CONFIG_SHELL="$CONFIG_SHELL"

st=0
$MAKE bad-recipe 2>stderr && st=1
cat stderr >&2
$FGREP "my-shell: recipe ends with backslash character" stderr || st=1
test $st -eq 0 || skip_ "can't catch trailing backslashes in make recipes"

$MAKE check

:
