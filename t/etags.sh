#! /bin/sh
# Copyright (C) 1997-2013 Free Software Foundation, Inc.
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

# Test to make sure tags and subdirs work correctly.  Bug report by
# François Pinard, and later by Akim Demaille.

required=${ETAGS:=etags}
. test-init.sh

cat >> configure.ac << 'END'
AC_SUBST([CC], [false])
AM_CONDITIONAL([CONF_FALSE], [false])
AC_CONFIG_FILES([sub1/Makefile])
AC_CONFIG_FILES([sub2/Makefile])
AC_CONFIG_FILES([sub2/subsub/Makefile])
AC_CONFIG_FILES([sub3/Makefile])
AC_OUTPUT
END

mkdir sub1 sub2 sub3 sub2/subsub

cat > Makefile.am << 'END'
SUBDIRS = sub1 sub2 sub3
test-tags: tags
	cat sub1/TAGS
	cat sub2/TAGS
	cat sub2/subsub/TAGS
	test ! -f sub3/TAGS
	grep 'sub1/TAGS' TAGS
	grep 'sub2/TAGS' TAGS
	grep 'sub3/TAGS' TAGS && exit 1; :
	grep 'iguana\.c' sub1/TAGS
	grep 'subsub/TAGS' sub2/TAGS
	grep 'subsub/foo\.h' sub2/TAGS
	grep 'bar\.baz' sub2/subsub/TAGS
	grep 'foo\.off' sub2/subsub/TAGS
	grep 'foo\.h' sub2/subsub/TAGS && exit 1; :
check-local: test-tags
END

cat > sub1/Makefile.am << 'END'
if COND_FALSE
bin_PROGRAMS = iguana
endif
END
echo 'int main () { return choke_me (); }' > sub1/iguana.c

cat > sub2/Makefile.am << 'END'
SUBDIRS = subsub .
noinst_HEADERS = subsub/foo.h
subsub/foo.h:
	echo dummy >$@
CLEANFILES = $(noinst_HEADERS)
END

cat > sub2/subsub/Makefile.am << 'END'
EXTRA_DIST = bar.baz
nodist_noinst_DATA = foo.off
TAGS_FILES = $(EXTRA_DIST) $(nodist_noinst_DATA)
MOSTLYCLEANFILES = $(nodist_noinst_DATA)
foo.off:
	echo $@ >$@
END
: > sub2/subsub/bar.baz

# No file to tag here, deliberately.
: > sub3/Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE -i

./configure
$MAKE test-tags ETAGS="$ETAGS"
$MAKE distcheck ETAGS="$ETAGS"

$MAKE distclean
find . -name TAGS | grep . && exit 1

:
