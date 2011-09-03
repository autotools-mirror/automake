## Process this file with automake to create Makefile.in

# Copyright (C) 1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Free Software Foundation, Inc.

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

# Run the tests with the shell detected at configure time.
LOG_COMPILER = $(SHELL)

TEST_EXTENSIONS = .test .tap
TEST_LOG_COMPILER = $(LOG_COMPILER)
TAP_LOG_COMPILER = $(LOG_COMPILER)

TAP_LOG_DRIVER = AM_TAP_AWK='$(AWK)' $(SHELL) $(top_srcdir)/lib/tap-driver.sh

AM_TAP_LOG_DRIVER_FLAGS = --merge --comments
## Avoid spurious TAP diagnostic.  We use an awful indirection with a
## shell command substitution here, since the string needs to contain
## `#' characters, and these can't be escaped portably in a make macro
## definition.
## FIXME: this is quite inefficient though, as it adds one extra fork
## FIXME: per TAP test script; this is OK for the moment, since we have
## FIXME: few such scripts, but might become an issue in the future.
## Keep this in sync with the definition of $diag_string_ in tests/defs.
AM_TAP_LOG_DRIVER_FLAGS += --diagnostic-string `printf '\043%%\043\n'`

EXTRA_DIST = ChangeLog-old

TESTS = ## Will be updated later.

XFAIL_TESTS = \
all.test \
cond17.test \
gcj6.test \
override-conditional-2.test \
pr8365-remake-timing.test \
yacc-dist-nobuild-subdir.test \
vala-vpath.test \
txinfo5.test

# Some testsuite-influential variables should be overridable from the
# test scripts, but not from the environment.
AM_TESTS_ENVIRONMENT = \
  test x"$$me" = x || unset me; \
  test x"$$required" = x || unset required; \
  test x"$$using_tap" = x || unset using_tap; \
  test x"$$parallel_tests" = x || unset parallel_tests; \
  test x"$$test_prefer_config_shell" || unset test_prefer_config_shell; \
  test x"$$original_AUTOMAKE" = x || unset original_AUTOMAKE; \
  test x"$$original_ACLOCAL" = x || unset original_ACLOCAL;
# The `AM_TESTS_REEXEC=no' setting tells the tests not to needlessly
# re-execute themselves with the shell detected at configure time, since
# we are already running them under it explicitly in our setup (see e.g.
# the definition of TEST_LOG_COMPILER above).
AM_TESTS_ENVIRONMENT += AM_TESTS_REEXEC=no; export AM_TESTS_REEXEC;
# We want warning messages and explanations for skipped tests to go to
# the console if possible, so set up `stderr_fileno_' properly.
AM_TESTS_FD_REDIRECT = 9>&2
AM_TESTS_ENVIRONMENT += stderr_fileno_=9; export stderr_fileno_;

# Hand-written tests.

include $(srcdir)/list-of-tests.mk

TESTS += $(handwritten_TESTS)
EXTRA_DIST += $(handwritten_TESTS)

# Automatically-generated tests wrapping hand-written ones.
# Also, automatically-computed dependencies for tests.

include $(srcdir)/testsuite-part.am

TESTS += $(generated_TESTS)
EXTRA_DIST += $(generated_TESTS)

$(srcdir)/testsuite-part.am:
	$(AM_V_at)rm -f testsuite-part.tmp $@
	$(AM_V_GEN)$(PERL) $(srcdir)/gen-testsuite-part \
	  --srcdir $(srcdir) > testsuite-part.tmp
	$(AM_V_at)chmod a-w testsuite-part.tmp
	$(AM_V_at)mv -f testsuite-part.tmp $@
EXTRA_DIST += gen-testsuite-part

$(generated_TESTS) $(srcdir)/testsuite-part.am: \
  gen-testsuite-part list-of-tests.mk Makefile.am $(handwritten_TESTS)

# Static dependencies valid for each test case.
$(TEST_LOGS): defs defs-static aclocal-$(APIVERSION) automake-$(APIVERSION)
# FIXME: this should be made more granular once we have a cleaner
# subdivision of the tests.
$(TEST_LOGS): plain-functions.sh tap-functions.sh
EXTRA_DIST += tap-functions.sh plain-functions.sh

# Keep in sync with AC_SUBST'd stuff in defs-static.in.
do_subst = sed \
  -e 's|@abs_srcdir[@]|$(abs_srcdir)|g' \
  -e 's|@abs_top_srcdir[@]|$(abs_top_srcdir)|g' \
  -e 's|@abs_builddir[@]|$(abs_builddir)|g' \
  -e 's|@prefix[@]|$(prefix)|g' \
  -e 's|@amdir[@]|$(amdir)|g' \
  -e 's|@bindir[@]|$(bindir)|g' \
  -e 's|@datadir[@]|$(datadir)|g' \
  -e 's|@docdir[@]|$(docdir)|g' \
  -e 's|@automake_acdir[@]|$(automake_acdir)|g' \
  -e 's|@system_acdir[@]|$(system_acdir)|g' \
  -e 's|@scriptdir[@]|$(scriptdir)|g' \
  -e 's|@pkgvdatadir[@]|$(pkgvdatadir)|g' \
  -e 's|@host_alias[@]|$(host_alias)|g' \
  -e 's|@build_alias[@]|$(build_alias)|g' \
  -e 's|@APIVERSION[@]|$(APIVERSION)|g' \
  -e 's|@PATH_SEPARATOR[@]|$(PATH_SEPARATOR)|g' \
  -e 's|@SHELL[@]|$(SHELL)|g' \
  -e 's|@PERL[@]|$(PERL)|g' \
  -e 's|@EGREP[@]|$(EGREP)|g' \
  -e 's|@FGREP[@]|$(FGREP)|g' \
  -e 's|@TEX[@]|$(TEX)|g' \
  -e 's|@MODIFICATION_DELAY[@]|$(MODIFICATION_DELAY)|g' \
  -e 's|@am_AUTOCONF[@]|$(am_AUTOCONF)|g' \
  -e 's|@am_AUTOM4TE[@]|$(am_AUTOM4TE)|g' \
  -e 's|@am_AUTORECONF[@]|$(am_AUTORECONF)|g' \
  -e 's|@am_AUTOHEADER[@]|$(am_AUTOHEADER)|g' \
  -e 's|@am_AUTOUPDATE[@]|$(am_AUTOUPDATE)|g' \
  -e 's|@sh_errexit_works[@]|$(sh_errexit_works)|g' \
  -e 's|@configure_input[@]|Generated from $@.in.  DO NOT EDIT BY HAND!|'

defs-static: defs-static.in
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_GEN)$(do_subst) $(srcdir)/defs-static.in >$@-t
	$(AM_V_at) : Sanity check on the substitutions; \
	if LC_ALL=C grep '@[a-zA-Z0-9_][a-zA-Z0-9_]*@' $@-t; then \
	  echo "$@ contains unexpanded substitution (see lines above)"; \
	  exit 1; \
	fi
	$(AM_V_at)chmod a-w $@-t && mv -f $@-t $@
EXTRA_DIST += defs-static.in
CLEANFILES = defs-static

# If two test scripts have the same basename, they will end up sharing
# the same log file, leading to all sort of undefined and undesired
# behaviours.
check-no-repeated-test-name:
	@LC_ALL=C; export LC_ALL; \
	 lst='$(TEST_LOGS)'; for log in $$lst; do echo $$log; done \
	   | sort | uniq -c | awk '($$1 > 1) { print }' \
	   | sed 's/\.log$$//' | grep . >&2 \
	   && { \
	     echo $@: test names listed above are duplicated >&2; \
	     exit 1; \
	   }; :
check-local: check-no-repeated-test-name
.PHONY: check-no-repeated-test-name

## Checking the list of tests.
include $(top_srcdir)/CheckListOfTests.am

# Run the testsuite with the installed aclocal and automake.
installcheck-local:
	am_running_installcheck=yes $(MAKE) $(AM_MAKEFLAGS) check

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
