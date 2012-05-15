#! /bin/sh
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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

# Colorized output from the testsuite report shouldn't end up in log files.

. ./defs || Exit 1

esc=''

# Check that grep can parse nonprinting characters.
# BSD 'grep' works from a pipe, but not a seekable file.
# GNU or BSD 'grep -a' works on files, but is not portable.
case `echo "$esc" | $FGREP "$esc"` in
  "$esc") ;;
# Creative quoting below to please maintainer-check.
  *) echo "$me: f""grep can't parse nonprinting characters" >&2; Exit 77;;
esac

TERM=ansi; export TERM

cat >>configure.ac <<END
AC_OUTPUT
END

cat >Makefile.am <<'END'
LOG_COMPILER = $(SHELL)
AUTOMAKE_OPTIONS = color-tests parallel-tests
TESTS = pass fail skip xpass xfail error
XFAIL_TESTS = xpass xfail
END

# Creative quoting to please maintainer-check.
echo exit '0' > pass
echo exit '0' > xpass
echo exit '1' > fail
echo exit '1' > xfail
echo exit '77' > skip
echo exit '99' > error

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

./configure
mv config.log config-log # Avoid possible false positives below.
AM_COLOR_TESTS=always $MAKE -e check && Exit 1
$FGREP "$esc" *.log && Exit 1

:
