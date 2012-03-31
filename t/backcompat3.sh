#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
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

# Backward-compatibility test: check what happens when AC_INIT and
# AM_INIT_AUTOMAKE are both given two or more arguments.

am_create_testdir=empty
. ./defs || Exit 1

empty=''

AUTOMAKE="$AUTOMAKE -Wno-obsolete"

cat > Makefile.am <<'END'
## Leading ':;' here required to work around bugs of (at least) bash 3.2
got: Makefile
	@:; { \
	  echo 'PACKAGE = $(PACKAGE)'; \
	  echo 'VERSION = $(VERSION)'; \
	  echo 'PACKAGE_NAME = $(PACKAGE_NAME)'; \
	  echo 'PACKAGE_VERSION = $(PACKAGE_VERSION)'; \
	  echo 'PACKAGE_STRING = $(PACKAGE_STRING)'; \
	  echo 'PACKAGE_TARNAME = $(PACKAGE_TARNAME)'; \
	  echo 'PACKAGE_BUGREPORT = $(PACKAGE_BUGREPORT)'; \
	  echo 'PACKAGE_URL = $(PACKAGE_URL)'; \
	} >$@
END


### Run 1 ###

cat > configure.in <<END
AC_INIT([ac_name], [ac_version])
AM_INIT_AUTOMAKE([am_name], [am_version])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat configure.in

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure

cat >exp <<END
PACKAGE = am_name
VERSION = am_version
PACKAGE_NAME = ac_name
PACKAGE_VERSION = ac_version
PACKAGE_STRING = ac_name ac_version
PACKAGE_TARNAME = ac_name
PACKAGE_BUGREPORT = $empty
PACKAGE_URL = $empty
END

$MAKE got

diff exp got


### Run 2 ###

cat > configure.in <<'END'
dnl: 'AC_INIT' in Autoconf <= 2.63 doesn't have an URL argument.
dnl: Luckily, 'AC_AUTOCONF_VERSION' and 'm4_version_prereq' are
dnl: both present in autoconf 2.62, which we require; so that we
dnl: can at least use the following workaround.
m4_version_prereq([2.64],
    [AC_INIT([ac_name], [ac_version], [ac_bugreport], [ac_tarname],
             [ac_url])],
    [AC_INIT([ac_name], [ac_version], [ac_bugreport], [ac_tarname])
     AC_SUBST([PACKAGE_URL], [ac_url])])
AM_INIT_AUTOMAKE([am_name], [am_version])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat configure.in

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

cat >exp <<END
PACKAGE = am_name
VERSION = am_version
PACKAGE_NAME = ac_name
PACKAGE_VERSION = ac_version
PACKAGE_STRING = ac_name ac_version
PACKAGE_TARNAME = ac_tarname
PACKAGE_BUGREPORT = ac_bugreport
PACKAGE_URL = ac_url
END

$MAKE got

diff exp got


### Run 3 ###

cat > configure.in <<END
AC_INIT([ac_name], [ac_version])
AM_INIT_AUTOMAKE([am_name], [am_version], [am_foo_quux])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END

cat configure.in

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

cat >exp <<END
PACKAGE = am_name
VERSION = am_version
PACKAGE_NAME = ac_name
PACKAGE_VERSION = ac_version
PACKAGE_STRING = ac_name ac_version
PACKAGE_TARNAME = ac_name
PACKAGE_BUGREPORT = $empty
PACKAGE_URL = $empty
END

$MAKE got

diff exp got

$FGREP am_foo_quux Makefile.in Makefile configure config.status && Exit 1


### Done ###

:
