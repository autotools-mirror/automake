## Process this file with automake to create Makefile.in

# Copyright (C) 1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011, 2012 Free Software Foundation,
# Inc.

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

XFAIL_TESTS = \
all.test \
auxdir2.test \
cond17.test \
dist-auxfile.test \
dist-auxfile-2.test \
gcj6.test \
java-nobase.test \
objext-pr10128.test \
pr8365-remake-timing.test \
lex-subobj-nodep.test \
remake-am-pr10111.test \
remake-m4-pr10111.test \
txinfo5.test

include $(srcdir)/parallel-tests.am

$(srcdir)/parallel-tests.am: gen-parallel-tests Makefile.am
	$(AM_V_GEN)(cd $(srcdir) && $(SHELL) ./gen-parallel-tests) >$@

$(parallel_tests): $(parallel_tests:-p.test=.test) Makefile.am
	$(AM_V_GEN)input=`echo $@ | sed 's,.*/,,; s,-p.test$$,.test,'` \
	  && sed 's|^\. \./defs.*|parallel_tests=yes; &|' \
	       < $(srcdir)/$$input >$@ \
	  && chmod a+rx $@

MAINTAINERCLEANFILES = $(parallel_tests)

# Some testsuite-influential variables should be overridable from the
# test scripts, but not from the environment.
TESTS_ENVIRONMENT = \
  test x"$$me" = x || unset me; \
  test x"$$required" = x || unset required; \
  test x"$$parallel_tests" = x || unset parallel_tests;

TEST_EXTENSIONS = .pl .test

PL_LOG_COMPILER = $(PERL)
AM_PL_LOG_FLAGS = -Mstrict -I $(top_builddir)/lib -I $(top_srcdir)/lib -w

include $(srcdir)/list-of-tests.mk

TESTS = $(handwritten_TESTS) $(parallel_tests)

# FIXME: make these automatically computed once we are merged into
# FIXME: the `testsuite-work' branch.
ar-lib4.log: libtool-macros.log
ar-lib6a.log: libtool-macros.log
ar-lib6b.log: libtool-macros.log
depcomp4.log: libtool-macros.log
depcomp7.log: libtool-macros.log
depcomp8b.log: libtool-macros.log
extradep2.log: libtool-macros.log
fort5.log: libtool-macros.log
instdir-ltlib.log: libtool-macros.log
instfail-libtool.log: libtool-macros.log
ldadd.log: libtool-macros.log
ldflags.log: libtool-macros.log
libobj13.log: libtool-macros.log
libtoo10.log: libtool-macros.log
libtoo11.log: libtool-macros.log
libtool.log: libtool-macros.log
libtool2.log: libtool-macros.log
libtool3.log: libtool-macros.log
libtool5.log: libtool-macros.log
libtool6.log: libtool-macros.log
libtool7.log: libtool-macros.log
libtool8.log: libtool-macros.log
libtool9.log: libtool-macros.log
listval.log: libtool-macros.log
ltcond.log: libtool-macros.log
ltcond2.log: libtool-macros.log
ltconv.log: libtool-macros.log
ltdeps.log: libtool-macros.log
ltinit.log: libtool-macros.log
ltinstloc.log: libtool-macros.log
ltlibobjs.log: libtool-macros.log
ltlibsrc.log: libtool-macros.log
ltorder.log: libtool-macros.log
nobase-libtool.log: libtool-macros.log
pr211.log: libtool-macros.log
pr300-ltlib.log: libtool-macros.log
pr307.log: libtool-macros.log
pr401b.log: libtool-macros.log
pr72.log: libtool-macros.log
reqd2.log: libtool-macros.log
silent3.log: libtool-macros.log
silent4.log: libtool-macros.log
silent9.log: libtool-macros.log
stdlib2.log: libtool-macros.log
strip3.log: libtool-macros.log
subobj9.log: libtool-macros.log
suffix10.log: libtool-macros.log
suffix2.log: libtool-macros.log
suffix5.log: libtool-macros.log
suffix8.log: libtool-macros.log
vala.log: libtool-macros.log
vala1.log: libtool-macros.log
vala2.log: libtool-macros.log
vala3.log: libtool-macros.log
vala4.log: libtool-macros.log
vala5.log: libtool-macros.log

# FIXME: make these automatically computed once we are merged into
# FIXME: the `testsuite-work' branch.
gettext.log: gettext-macros.log
gettext2.log: gettext-macros.log
gettext3.log: gettext-macros.log
subcond.log: gettext-macros.log

EXTRA_DIST = ChangeLog-old gen-parallel-tests $(TESTS)

distcheck-missing-m4.log distcheck-outdated-m4.log: distcheck-hook-m4.am
EXTRA_DIST += distcheck-hook-m4.am

# Each test case depends on defs, aclocal, and automake.
check_SCRIPTS = defs aclocal-$(APIVERSION) automake-$(APIVERSION)

## Checking the list of tests.
test_subdirs = . pm
include $(srcdir)/CheckListOfTests.am
maintainer-check-list-of-tests: $(parallel_tests)

clean-local: clean-local-check
.PHONY: clean-local-check
clean-local-check:
	-set x *.dir; shift; \
	 if test "$$#,$$1" = "1,*.dir"; then \
	   : there is no test directory to clean; \
	 else \
	   find "$$@" -type d ! -perm -700 -exec chmod u+rwx {} ';'; \
	   rm -rf "$$@"; \
	 fi;
