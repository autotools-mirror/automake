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

# Parallel testsuite harness: check APIs for the registering the
# "global test result" in '*.trs' files, as documented in the automake
# manual.

am_create_testdir=empty
. ./defs || Exit 1

sed -n '/^am__rst_[a-z_][a-z_]* =/p' "$am_amdir"/check.am > Makefile \
  || framework_failure_ "fetching definitions from check.am"

cat >> Makefile << 'END'
test:
	printf '%s\n' "$$in" | $(am__rst_title) > title-got
	printf '%s\n' "$$in" | $(am__rst_section) > section-got
	cat title-exp
	cat title-got
	diff title-exp title-got
	cat section-exp
	cat section-got
	diff section-exp section-got
END

# -------------------------------------------------------------------------

cat > title-exp <<'END'
==============
   ab cd ef
==============

END

cat > section-exp <<'END'
ab cd ef
========

END

env in='ab cd ef' $MAKE test

# -------------------------------------------------------------------------

cat > title-exp <<'END'
============================================================================
   0123456789012345678901234567890123456789012345678901234567890123456789
============================================================================

END

cat > section-exp <<'END'
0123456789012345678901234567890123456789012345678901234567890123456789
======================================================================

END

in=0123456789012345678901234567890123456789012345678901234567890123456789
env in=$in $MAKE test

# -------------------------------------------------------------------------

cat > title-exp <<'END'
=======
   x
=======

END

cat > section-exp <<'END'
x
=

END

env in=x $MAKE test

# -------------------------------------------------------------------------

:
