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

# Backward-compatibility test: try to build and distribute a package
# using obsoleted forms of AC_INIT, AM_INIT_AUTOMAKE and AC_OUTPUT.
# This script can also serve as mild stress-testing for Automake.
# See also the similar test 'backcompat6.test'.

am_serial_tests=yes
am_create_testdir=empty
. ./defs || Exit 1

makefiles='hacky/Makefile src/Makefile data/Makefile tests/Makefile'

# Yuck!
cat > configure.in <<END
dnl: Everything here is *deliberately* underquoted!
AC_INIT(src/foo.input)
AM_INIT_AUTOMAKE(foo, 1.0)
AC_CONFIG_FILES(Makefile:mkfile.in)
AC_OUTPUT($makefiles)
END

distdir=foo-1.0

cat > mkfile.am <<'END'
SUBDIRS = src data tests hacky
installcheck-local:
	grep DataDataData $(DESTDIR)$(prefix)/data/$(PACKAGE)-$(VERSION)/bar
END

mkdir hacky src tests data

echo 'This is a dummy package' > README

cat > src/foo.input <<'END'
#!sh
echo Zardoz
END

cat > tests/a.test <<'END'
#!/bin/sh
"$srcdir/../src/foo" | grep Zardoz
END
chmod a+x tests/a.test

cat > data/bar <<'END'
line1
line2
line3
END

cat >hacky/Makefile.am <<'END'
dist-hook:
	find $(top_distdir) -print
	chmod a+rx $(top_distdir)/tests/*.test
END

cat > src/Makefile.am <<'END'
dist_bin_SCRIPTS = foo
foo: foo.input
	sed '1s,^#!.*$$,#!/bin/sh,' $(srcdir)/foo.input >$@
	chmod a+x $@
EXTRA_DIST = foo.input
DISTCLEANFILES = foo
END

cat > data/Makefile.am <<'END'
nodist_data_DATA = bar
datadir = $(prefix)/data/$(PACKAGE)-$(VERSION)
bar:
	echo DataDataData >$@
distclean-local:
	rm -f bar
END

cat > tests/Makefile.am <<'END'
TESTS = a.test
EXTRA_DIST = $(TESTS)
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a -Wno-obsolete
test -f install-sh
for f in $makefiles; do mv -f $f.in $f.sav; done
$AUTOMAKE -Wno-obsolete
for f in $makefiles; do diff $f.sav $f.in; done

./configure
ls -l . hacky src data tests # For debugging.
test ! -f mkfile
$MAKE
$MAKE distdir
test ! -f $distdir/Makefile.in
test ! -f $distdir/data/bar
test -f $distdir/src/foo
diff README $distdir/README
diff mkfile.in $distdir/mkfile.in
diff tests/a.test $distdir/tests/a.test
diff src/foo.input $distdir/src/foo.input

$MAKE check
$MAKE distcheck

test -f $distdir.tar.gz

chmod a-x tests/a.test
# dist-hook should take care of making test files executables.
$MAKE distcheck

:
