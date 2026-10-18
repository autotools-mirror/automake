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

# distcheck must reject uninstall rules that leave symbolic links behind.

. test-init.sh

ln -s missing probe || skip_ "cannot create symbolic links"
rm -f probe

echo AC_OUTPUT >> configure.ac
cat > Makefile.am <<'END'
dist_pkgdata_DATA = payload
install-data-hook:
	ln -s payload "$(DESTDIR)$(pkgdatadir)/shortcut"
	ln -s . "$(DESTDIR)$(pkgdatadir)/directory-shortcut"
END
echo 'installed data' > payload

$ACLOCAL
$AUTOCONF
$AUTOMAKE
./configure

# uninstall removes the payload but leaves the shortcut dangling.
run_make -E -e FAIL distcheck
grep 'ERROR: files left after uninstall:' stderr
grep '/shortcut$' stderr
grep '/directory-shortcut$' stderr

cat >> Makefile.am <<'END'
uninstall-local:
	rm -f "$(DESTDIR)$(pkgdatadir)/shortcut"
	rm -f "$(DESTDIR)$(pkgdatadir)/directory-shortcut"
END
$AUTOMAKE
./config.status
$MAKE distcheck

:
