#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Test vi-style tags.

required=${CTAGS:=ctags}
. test-init.sh

cat >> configure.ac << 'END'
AC_SUBST([CC], [false])
AM_CONDITIONAL([COND_FALSE], [false])
AC_CONFIG_FILES([sub1/Makefile
                 sub3/Makefile
                 sub2/Makefile
                 sub2/subsub/Makefile])
AC_OUTPUT
END

mkdir sub1 sub2 sub3 sub2/subsub

cat > Makefile.am << 'END'
SUBDIRS = sub1 sub2 sub3
test-ctags: ctags
	test ! -f tags
	cat sub1/tags
	cat sub2/tags
	cat sub2/subsub/tags
	test ! -f sub3/tags
	grep 'iguana\.c' sub1/tags
	grep 'zap_zap' sub1/tags
	grep 'main' sub1/tags
	grep 'choke_me' sub1/tags && exit 1; :
	grep 'subsub/foo\.h' sub2/tags
	grep 'IsBigger' sub2/tags
	grep 'bar\.f77' sub2/subsub/tags
	grep 'foo\.cxx' sub2/subsub/tags
	grep 'foo\.h' sub2/subsub/tags && exit 1; :
check-local: test-ctags
END

cat > sub1/Makefile.am << 'END'
if COND_FALSE
bin_PROGRAMS = iguana
endif
END

cat > sub1/iguana.c <<'END'
int main (void) { return zap_zap (0); }

int
zap_zap (int x)
{
  return x + choke_me ();
}
END

cat > sub2/Makefile.am << 'END'
SUBDIRS = subsub .
noinst_HEADERS = subsub/foo.h
subsub/foo.h:
	# Use and inlined function, not a #define, for the sake of
	# Emacs and XEmacs ctags (at least up to version 23).
	echo 'inline int IsBigger (int a, int b) { return (a > b); }' >$@
CLEANFILES = $(noinst_HEADERS)
END

cat > sub2/subsub/Makefile.am << 'END'
TAGS_FILES =
EXTRA_DIST = bar.f77
TAGS_FILES += bar.f77
nodist_noinst_DATA = foo.cxx
TAGS_FILES += foo.cxx
CLEANFILES = foo.cxx
foo.cxx:
	echo "int cxx_func (void) { return 0; }" >$@
END

cat > sub2/subsub/bar.f77 << 'END'
      subroutine foobarbaz
      return
      end
END

# No files to tag here, deliberately.
: > sub3/Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE -i

./configure
$MAKE test-ctags CTAGS="$CTAGS"
$MAKE distcheck CTAGS="$CTAGS"

$MAKE distclean
find . -name tags | grep . && exit 1

:
