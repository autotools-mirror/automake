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

# Automake-NG should reject suffix rules in favor of pattern rules.

. ./defs || Exit 1

$ACLOCAL

cat > Makefile.am << 'END'
.SUFFIXES: .w
END

cat > Makefile2.am <<'END'
## Dummy comments ...
## ... whose only purpose is ...
## ... to alter ...
## ... the line count.
SUFFIXES = .w
END

cat > Makefile3.am << 'END'
.foo.bar: ; cp $< $@
.mu.um:
	cp $< $@
.1.2 .3.4:
	who cares
END

msg='use pattern rules, not old-fashioned suffix rules'

AUTOMAKE_fails -Wno-error -Wnone Makefile
grep "^Makefile\\.am:1:.*$msg" stderr
AUTOMAKE_fails -Wno-error -Wnone Makefile2
grep "^Makefile2\\.am:5:.*$msg" stderr
AUTOMAKE_fails -Wno-error -Wnone Makefile3
grep "^Makefile3\\.am:1:.*$msg" stderr
grep "^Makefile3\\.am:2:.*$msg" stderr
grep "^Makefile3\\.am:4:.*$msg" stderr
test `grep -c "$msg" stderr` -eq 3

:
