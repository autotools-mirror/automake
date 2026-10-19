#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# make dist must honor package overrides of the public archive targets.

. test-init.sh

echo AC_OUTPUT >> configure.ac
cat > Makefile.am <<'END'
dist-gzip: distdir extra-archive-work
	tar cf - $(distdir) | gzip -c >$(distdir).tar.gz
	$(am__post_remove_distdir)
extra-archive-work:
	echo done > marker
.PHONY: extra-archive-work
END
$ACLOCAL
$AUTOCONF
$AUTOMAKE -Wno-override
./configure
$MAKE dist
test -f marker
test ! -d "$distdir"
test ! -f am__distdir.tar

:
