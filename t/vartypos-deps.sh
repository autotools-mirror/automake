#! /bin/sh
# Copyright (C) 2010-2013 Free Software Foundation, Inc.
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

# Make sure we warn about possible variable typos for the
# *_DEPENDENCIES when we should, and do not warn about them
# when we should not.

. test-init.sh

subdirs='ok1 ok2 ko1 ko2'
mkdir $subdirs

errgrep ()
{
  grep "variable '${1}_DEPENDENCIES' is defined" stderr
  grep "'$1' as canonical name" stderr
}

cat >> configure.ac <<END
AC_CONFIG_FILES([$(for d in $subdirs; do echo $d/Makefile; done)])
AC_OUTPUT
END

cat > Makefile.am <<'END'
AM_LDFLAGS = unused
ETAGS_ARGS = --unused
TAGS_DEPENDENCIES = foo.c
CONFIG_STATUS_DEPENDENCIES = cvs-version.sh
CONFIGURE_DEPENDENCIES = cvs-version.sh
foo.c:
	echo 'int main (void) { return 0; }' > $@
END

: > cvs-version.sh

cat > ok1/Makefile.am <<'END'
TESTS = unused ignored.test
LOG_DEPENDENCIES = unused
TEST_LOG_DEPENDENCIES = unused
END

cat > ok2/Makefile.am <<'END'
TESTS = ignored.sh notseen.tap
TEST_EXTENSIONS = .sh .tap
LOG_DEPENDENCIES = unused
SH_LOG_DEPENDENCIES = unused
TAP_LOG_DEPENDENCIES = unused
END

cat > ko1/Makefile.am <<'END'
LOG_DEPENDENCIES =
TEST_LOG_DEPENDENCIES =
END

cat > ko2/Makefile.am <<'END'
TESTS = unused ignored.test
TEST_LOG_DEPENDENCIES =
LOG_DEPENDENCIES =
SH_LOG_DEPENDENCIES =
CONFIGSTATUS_DEPENDENCIES =
CONFIG_DEPENDENCIES =
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

$MAKE
(cd ok1 && $MAKE)
(cd ok2 && $MAKE)

cd ko1
$MAKE 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
errgrep LOG
errgrep TEST_LOG
cd ..

cd ko2
$MAKE 2>stderr && { cat stderr >&2; exit 1; }
cat stderr >&2
errgrep SH_LOG
errgrep CONFIG
errgrep CONFIGSTATUS
$EGREP "'(TEST_)?LOG" stderr && exit 1
cd ..

:
