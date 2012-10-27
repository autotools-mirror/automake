#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
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

# Test for PR 34.
# > Description:
#  Automake fails to add -I option to include configuration
#  header indicated like AM_CONFIG_HEADER(magick/config.h)
# > How-To-Repeat:
#  Use AM_CONFIG_HEADER(subdir/config.h) to place configuration
#  header in subdirectory and observe that it is not included.
# Also check that our preprocessing code is smart enough not to pass
# repeated '-I<DIR>' options on the compiler command line.

. test-init.sh

cat >> configure.ac << 'END'
AC_CONFIG_FILES([include/Makefile sub/Makefile])
AC_CONFIG_HEADERS([include/config.h])
AC_PROG_FGREP
AC_OUTPUT
END

mkdir include sub
: > include/config.h.in

cat > c-defs.am << 'END'
## To bring in the definition of AM_DEFAULT_INCLUDES
CC = who-cares
AUTOMAKE_OPTIONS = no-dependencies
bin_PROGRAMS = foo
END

cat > Makefile.am << 'END'
include $(top_srcdir)/c-defs.am
.PHONY: test-default-includes
test-default-includes:
	echo ' ' $(AM_DEFAULT_INCLUDES) ' ' \
	  | $(FGREP) ' -I$(top_builddir)/include '
END

cp Makefile.am sub

cat > include/Makefile.am << 'END'
include $(top_srcdir)/c-defs.am
.PHONY: test-default-includes
test-default-includes:
	echo ' ' $(AM_DEFAULT_INCLUDES) ' ' | $(FGREP) ' -I. '
	case ' $(AM_DEFAULT_INCLUDES) ' in \
	  *'$(top_builddir)'*) exit 1;; \
	  *include*) exit 1;; \
	  *-I.*-I.*) exit 1;; \
	  *' -I. ') exit 0;; \
	  *) exit 1;; \
	esac
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure

$MAKE test-default-includes
$MAKE -C sub test-default-includes
$MAKE -C include test-default-includes

:
