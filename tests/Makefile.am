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

MAINTAINERCLEANFILES =
EXTRA_DIST = ChangeLog-old

XFAIL_TESTS = \
all.test \
cond17.test \
gcj6.test \
override-conditional-2.test \
pr8365-remake-timing.test \
yacc-dist-nobuild-subdir.test \
txinfo5.test


include $(srcdir)/parallel-tests.am

$(srcdir)/parallel-tests.am: gen-parallel-tests Makefile.am
	$(AM_V_GEN)($(am__cd) $(srcdir) \
	  && $(MAKE) $(AM_MAKEFLAGS) -s print-list-of-test \
	    | $(SHELL) ./gen-parallel-tests) >$@
EXTRA_DIST += gen-parallel-tests

TEST_EXTENSIONS += .ptest
PTEST_LOG_COMPILER = $(LOG_COMPILER) $(srcdir)/parallel-tests.sh
EXTRA_DIST += parallel-tests.sh

# All `*-p.ptest' tests work by sourcing the script `parallel-tests.sh'.
$(parallel_tests:.ptest=.log): parallel-tests.sh
# This dummy declaration is required to have make actually produce
# expected log files from the `.ptest.log' suffix rule.
$(parallel_tests):


include $(srcdir)/config-shell-tests.am

$(srcdir)/config-shell-tests.am: gen-config-shell-tests Makefile.am
	$(AM_V_GEN)($(am__cd) $(srcdir) \
	  && $(MAKE) $(AM_MAKEFLAGS) print-list-of-test \
	    | $(SHELL) ./gen-config-shell-tests) >$@
EXTRA_DIST += gen-config-shell-tests

TEST_EXTENSIONS += .shtst
SHTST_LOG_COMPILER = $(LOG_COMPILER) $(srcdir)/config-shell-tests.sh
EXTRA_DIST += config-shell-tests.sh

# All `*-w.shtst' tests work by sourcing the script `config-shell-tests.sh'.
$(config_shell_tests:.shtst=.log): config-shell-tests.sh
# This dummy declaration is required to have make actually produce
# expected log files from the `.shtst.log' suffix rule.
$(config_shell_tests):


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

# Include definition of list of hand-written tests.  We keep that in a
# separate file to simplify bootstrapping of Automake from a VCS checkout.
include $(srcdir)/list-of-tests.mk

EXTRA_DIST += $(handwritten_TESTS)

TESTS = \
  $(handwritten_TESTS) \
  $(config_shell_tests) \
  $(parallel_tests)

# Extra dependencies for hand-written tests.

test-driver-custom-multitest.log: trivial-test-driver
test-driver-custom-multitest-recheck.log: trivial-test-driver
test-driver-custom-multitest-recheck2.log: trivial-test-driver
test-driver-custom-html.log: trivial-test-driver
EXTRA_DIST += trivial-test-driver

testsuite-summary-color.log testsuite-summary-count.log: \
  testsuite-summary-checks.sh extract-testsuite-summary
EXTRA_DIST += testsuite-summary-checks.sh
EXTRA_DIST += extract-testsuite-summary

testsuite-summary-count-many.log: trivial-test-driver
testsuite-summary-count-many.log: extract-testsuite-summary

$(tap_with_common_setup_TESTS:.test=.log): tap-common-setup.log tap-setup.sh
EXTRA_DIST += tap-setup.sh

tap-summary.log tap-summary-color.log: tap-summary-aux.sh
EXTRA_DIST += tap-summary-aux.sh

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
checked_test_extensions = .test .tap
expected_list_of_tests = $(handwritten_TESTS)
include $(top_srcdir)/CheckListOfTests.am

# Dependencies valid for each test case.
$(TEST_LOGS): defs defs-static aclocal-$(APIVERSION) automake-$(APIVERSION)
# FIXME: this should be made more granular once we have a cleaner
# subdivision of the tests.
$(TEST_LOGS): plain-functions.sh tap-functions.sh

## Files containing auxiliary functions used by our test cases.
EXTRA_DIST += tap-functions.sh plain-functions.sh

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
