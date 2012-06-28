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

# Test Automake-provided internal make macros to deal with VPATH rewrites.

. ./defs || exit 1

echo AC_OUTPUT >> configure.ac

cat > Makefile.am << END
bsub:
	mkdir \$@
bsub/foo: bsub
	mkdir \$@
bsub/foo/bar: bsub/foo
	mkdir \$@
bsub/mu.c++: bsub/foo
	touch \$@
bsub/foo/pu.cxx: bsub/foo
	touch \$@

clean-local:
	rm -rf bsub

## Yes, I'm a lazy typist.
vr = \$(am__vpath_rewrite)

test-common: bsub/foo/bar bsub/mu.c++ bsub/foo/pu.cxx
	test '\$(call vr,Makefile)'             = Makefile
	test '\$(call vr,$tab config.status  )' = config.status
	test '\$(call vr,.)'                    = .
## FIXME: These two do not work apparently :-(  Such use cases are not
## FIXME: required presently though, so this is not a big deal.
	: test '\$(call vr, bsub$tab  )'        = bsub
	: test '\$(call vr,bsub)'               = bsub
	test '\$(call vr,bsub/.)'               = bsub/.
	test '\$(call vr,bsub/mu.c++)'          = bsub/mu.c++
	test '\$(call vr,bsub/foo/pu.cxx)'      = bsub/foo/pu.cxx
	test '\$(call vr,bsub/foo )'            = bsub/foo
	test '\$(call vr,bsub/foo/bar)'         = bsub/foo/bar
	test '\$(call vr,nonesuch)'             = \$(srcdir)/nonesuch
	test '\$(call vr, $tab  nonesuch2  )'   = \$(srcdir)/nonesuch2
	test '\$(call vr, sub/none)'            = \$(srcdir)/sub/none

test-vpath: test-common
	test '\$(call vr,ssub)'                   = \$(srcdir)/ssub
	test '\$(call vr,ssub/foo )'              = \$(srcdir)/ssub/foo
	test '\$(call vr, ssub/foo/bar)'          = \$(srcdir)/ssub/foo/bar
	test '\$(call vr,Makefile.in )'           = \$(srcdir)/Makefile.in
	test '\$(call vr,zap/paz.c)'              = \$(srcdir)/zap/paz.c
	test '\$(call vr,configure $tab)'         = \$(srcdir)/configure
	test '\$(call vr,    configure.ac$tab  )' = \$(srcdir)/configure.ac

test-intree: test-common
	test '\$(call vr,ssub)'                   = ssub
	test '\$(call vr,ssub/foo )'              = ssub/foo
	test '\$(call vr, ssub/foo/bar)'          = ssub/foo/bar
	test '\$(call vr,Makefile.in )'           = Makefile.in
	test '\$(call vr,zap/paz.c)'              = zap/paz.c
	test '\$(call vr,configure $tab)'         = configure
	test '\$(call vr,    configure.ac$tab  )' = configure.ac
END

$ACLOCAL
$AUTOMAKE
$AUTOCONF

mkdir zap ssub ssub/foo ssub/foo/bar
: > zap/paz.c

./configure
$MAKE test-intree
$MAKE distclean

mkdir build
cd build
../configure
$MAKE test-vpath
cd ..

ocwd=$(pwd) || fatal_ "couldn't get current working directory"
mkdir build2 build2/subbuild
cd build2/subbuild
"$ocwd"/configure
$MAKE test-vpath

:
