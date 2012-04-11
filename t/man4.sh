#! /bin/sh
# Copyright (C) 2008-2012 Free Software Foundation, Inc.
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

# Ensure 'make dist' fails when help2man replacement man pages are created.
#
# The assumption here is the following: if the developer uses help2man to
# generate man pages from --help output, then these man pages may not be
# stored in VCS.  However, they should be distributed, so that the end user
# that receives the tarball doesn't have to install help2man.  If they are
# not distributed, then the developer should make help2man a prerequisite
# to building the package from a tarball, e.g., with a configure check for
# help2man that errors out if it is unavailable.  In both cases it is
# sufficient to check only distributed man pages.
#
# Idea of this whole shenanigan is to allow somebody to check out sources from
# a VCS and build and install them without needing help2man installed.  The
# installed man pages will be bogus in this case.  Typically, this happens
# when developers ask users to try out a fix from VCS; the developers themselves
# will usually have help2man installed (or should install it).

. ./defs || Exit 1

cat > Makefile.am << 'END'
dist_man_MANS = $(srcdir)/foo.1 bar.1
dist_bin_SCRIPTS = foo bar
$(srcdir)/foo.1:
	$(HELP2MAN) --output=$@ $(srcdir)/foo
bar.1:
	$(HELP2MAN) --output=$(srcdir)/bar.1 $(srcdir)/bar
END

cat >>configure.ac <<'END'
AM_MISSING_PROG([HELP2MAN], [help2man])
AC_OUTPUT
END

cat > foo <<'END'
#! /bin/sh
while test $# -gt 0; do
  case $1 in
    -h | --help) echo "usage: $0 [OPTIONS]..."; exit 0;;
    -v | --version) echo "$0 1.0"; exit 0;;
  esac
  shift
done
END
cp foo bar
chmod +x foo bar

mkdir bin
cat > bin/help2man <<'END'
#! /bin/sh
# Fake help2man script that lets 'missing' think it is not installed.
exit 127
END
chmod +x bin/help2man
PATH=`pwd`/bin$PATH_SEPARATOR$PATH

grep_error_messages()
{
  grep ' man pages contain.*missing help2man.* replacement text' stderr \
   && grep 'install help2man' stderr \
   && grep 'regenerate the man pages' stderr \
   || Exit 1
}

$ACLOCAL
$AUTOMAKE
$AUTOCONF

./configure
$MAKE
$MAKE dist 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep_error_messages
$MAKE distcheck 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep_error_messages
$MAKE distclean

mkdir build
cd build
../configure
$MAKE
$MAKE dist 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep_error_messages
$MAKE distcheck 2>stderr && { cat stderr >&2; Exit 1; }
cat stderr >&2
grep_error_messages

:
