## Process this file with automake to create Makefile.in

# Copyright (C) 2002, 2003, 2008, 2009, 2010, 2011 Free Software
# Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PL_LOG_COMPILER = $(PERL)
AM_TESTS_ENVIRONMENT = \
  case $$am_running_installcheck in \
    yes) am_pl_I_flags='-I $(pkgvdatadir)';; \
      *) am_pl_I_flags='-I ../.. -I $(top_srcdir)/lib';; \
  esac;
AM_PL_LOG_FLAGS = -Mstrict -w $$am_pl_I_flags
TEST_EXTENSIONS = .pl

TESTS = \
Condition.pl \
Condition-t.pl \
Cond2.pl \
Cond3.pl \
DisjConditions.pl \
DisjConditions-t.pl \
DisjCon2.pl \
DisjCon3.pl \
Version.pl \
Version2.pl \
Version3.pl \
Wrap.pl

XFAIL_TESTS = \
Cond2.pl \
Cond3.pl \
DisjCon2.pl \
DisjCon3.pl \
Version2.pl \
Version3.pl

EXTRA_DIST = $(TESTS)

include $(top_srcdir)/CheckListOfTests.am

# Run the testsuite with the installed aclocal and automake.
installcheck-local:
	am_running_installcheck=yes $(MAKE) $(AM_MAKEFLAGS) check
