## Process this file with automake to create Makefile.in

# Copyright (C) 1996-2012 Free Software Foundation, Inc.

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

TEST_EXTENSIONS = .pl .test .tap
TEST_LOG_COMPILER = $(LOG_COMPILER)
TAP_LOG_COMPILER = $(LOG_COMPILER)
PL_LOG_COMPILER = $(PERL)
AM_PL_LOG_FLAGS = -Mstrict -I $(top_builddir)/lib -I $(top_srcdir)/lib -w

TAP_LOG_DRIVER = AM_TAP_AWK='$(AWK)' $(SHELL) $(top_srcdir)/lib/tap-driver.sh

AM_TAP_LOG_DRIVER_FLAGS = --merge

EXTRA_DIST = ax/is ChangeLog-old

TESTS = ## Will be updated later.

XFAIL_TESTS = \
all.test \
yacc-bison-skeleton-cxx.test \
yacc-bison-skeleton.test \
cond17.test \
gcj6.test \
override-conditional-2.test \
java-nobase.test \
objext-pr10128.test \
parallel-tests-many.test \
pr8365-remake-timing.test \
lex-subobj-nodep.test \
remake-am-pr10111.test \
remake-m4-pr10111.test \
txinfo5.test \
## FIXME: this "expected failures" are in truth an hack used to
## FIXME: to verify that some incorrect usages of our perl: libraries
## FIXME: raise an error.  We should find a cleaner way to check that.
pm/Cond2.pl \
pm/Cond3.pl \
pm/DisjCon2.pl \
pm/DisjCon3.pl \
pm/Version2.pl \
pm/Version3.pl

# Some testsuite-influential variables should be overridable from the
# test scripts, but not from the environment.
AM_TESTS_ENVIRONMENT = \
  for v in \
    me \
    required \
    am_using_tap \
    am_parallel_tests \
    am_test_prefer_config_shell \
    am_original_AUTOMAKE \
    am_original_ACLOCAL \
  ; do \
    eval test x"\$${$$v}" = x || unset $$v; \
  done;
# The 'AM_TESTS_REEXEC=no' setting tells the tests not to needlessly
# re-execute themselves with the shell detected at configure time, since
# we are already running them under it explicitly in our setup (see e.g.
# the definition of TEST_LOG_COMPILER above).
AM_TESTS_ENVIRONMENT += AM_TESTS_REEXEC=no; export AM_TESTS_REEXEC;
# We want warning messages and explanations for skipped tests to go to
# the console if possible, so set up 'stderr_fileno_' properly.
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
check_SCRIPTS = wrap/aclocal-$(APIVERSION) wrap/automake-$(APIVERSION)
check_DATA = defs defs-static plain-functions.sh tap-functions.sh
EXTRA_DIST += tap-functions.sh plain-functions.sh

# Few more static dependencies.
distcheck-missing-m4.log distcheck-outdated-m4.log: distcheck-hook-m4.am
EXTRA_DIST += distcheck-hook-m4.am

# Keep in sync with AC_SUBST'd stuff in defs-static.in.
do_subst = sed \
  -e 's|@abs_srcdir[@]|$(abs_srcdir)|g' \
  -e 's|@abs_top_srcdir[@]|$(abs_top_srcdir)|g' \
  -e 's|@abs_builddir[@]|$(abs_builddir)|g' \
  -e 's|@abs_top_builddir[@]|$(abs_top_builddir)|g' \
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
  -e 's|@CPPFLAGS[@]|$(CPPFLAGS)|g' \
  -e 's|@CC[@]|$(CC)|g' \
  -e 's|@CFLAGS[@]|$(CFLAGS)|g' \
  -e 's|@CXX[@]|$(CXX)|g' \
  -e 's|@CXXFLAGS[@]|$(CXXFLAGS)|g' \
  -e 's|@F77[@]|$(F77)|g' \
  -e 's|@FFLAGS[@]|$(FFLAGS)|g' \
  -e 's|@FC[@]|$(FC)|g' \
  -e 's|@FCFLAGS[@]|$(FCFLAGS)|g' \
  -e 's|@GNU_CC[@]|$(GNU_CC)|g' \
  -e 's|@GNU_CFLAGS[@]|$(GNU_CFLAGS)|g' \
  -e 's|@GNU_CXX[@]|$(GNU_CXX)|g' \
  -e 's|@GNU_CXXFLAGS[@]|$(GNU_CXXFLAGS)|g' \
  -e 's|@GNU_F77[@]|$(GNU_F77)|g' \
  -e 's|@GNU_FFLAGS[@]|$(GNU_FFLAGS)|g' \
  -e 's|@GNU_FC[@]|$(GNU_FC)|g' \
  -e 's|@GNU_FCFLAGS[@]|$(GNU_FCFLAGS)|g' \
  -e 's|@GNU_GCJ[@]|$(GNU_GCJ)|g' \
  -e 's|@GNU_GCJFLAGS[@]|$(GNU_GCJFLAGS)|g' \
  -e 's|@YACC[@]|$(YACC)|g' \
  -e 's|@LEX[@]|$(LEX)|g' \
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
test_subdirs = . pm
include $(srcdir)/CheckListOfTests.am

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

## Run the testsuite through the 'prove' utility.  Mostly for maintainers,
## and to find out possible incompatibilities between 'prove' and the
## Automake own TAP driver.

PROVE = prove
AM_PROVEFLAGS = --timer
AM_PROVECMD = \
  test -z "$$tests" || \
    { \
      $(AM_TESTS_ENVIRONMENT) $(TESTS_ENVIRONMENT) \
      $(PROVE) $(AM_PROVEFLAGS) -e $(srcdir)/prove-runner $(PROVEFLAGS) \
      $$tests $(AM_TESTS_FD_REDIRECT); \
    }

EXTRA_DIST += prove-runner

.PHONY: prove installprove
prove installprove: $(TESTS) prove-runner defs-static
	@exit_status=0; \
## The testsuite can be run either using the automake build tree or
## the already-installed automake package.
	case '$@' in \
	  install*) am_running_installcheck=yes;; \
	  *) am_running_installcheck=no;; \
	esac; \
	export am_running_installcheck; \
## XXX Our poor-man way to handle inter-tests dependencies without the
## XXX help of make.  This is obviously fragile and doesn't scale,
## XXX but for now it's good enough since we have only one possible
## XXX inter-tests dependency at the moment.
	need_tap_common_setup=no; \
	lst=' $(TESTS) '; for t in $$lst; do \
	  case ' $(on_tap_with_common_setup_TESTS) ' in \
	    *" $$t "*) need_tap_common_setup=yes; break;; \
	  esac; \
	done; \
## For VPATH builds.
	if test $$need_tap_common_setup = yes; then \
	  t=tap-common-setup.test; \
	  if test -f ./$$t; then \
	    tests=./$$t; \
	  else \
	    tests=$(srcdir)/$$t; \
	  fi; \
## Do not stop if there's a failure here, we want to run the following
## tests anyway.
	  echo "$@: running pre-requisite tests ..."; \
	  $(AM_PROVECMD) || exits_status=$$?; \
	  echo "$@: done.  We'll shortly run the main testsuite."; \
	fi; \
## Handle VPATH builds, and ensure that the tests have a properly
## qualified path.
	tests=`\
	  for t in $(TESTS); do \
## XXX In next line, another hack for inter-tests dependencies: this
## XXX can't run concurrently to the tests that use the data files it
## XXX generates.
	    case "$$need_tap_common_setup,/$$t" in \
	      yes,*/tap-common-setup.test) continue;; \
	    esac; \
	    if test -f ./$$t; then \
	      echo ./$$t; \
	    else \
	      echo $(srcdir)/$$t; \
	    fi; \
	  done`; \
## Extra environment, mostly for use by 'prove-runner'.
## XFAIL_TESTS gets normalized to play nicer with VPATH builds.
	XFAIL_TESTS=`\
	  for t in $(XFAIL_TESTS); do \
	    echo $$t; echo ./$$t; echo $(srcdir)/$$t; \
	  done | LC_ALL=C sort | uniq`; \
	XFAIL_TESTS=`echo $$XFAIL_TESTS`; \
	TAP_RUNNER='$(TAP_LOG_COMPILE)' \
	TEST_RUNER='$(TEST_LOG_COMPILE)' \
	export XFAIL_TESTS TAP_RUNNER TEST_RUNNER; \
## For consistency with the Automake testsuite harness, that exports
## this unconditionally in the test scripts' environment.
	srcdir='$(srcdir)'; export srcdir; \
## Here we go.
	$(AM_PROVECMD) || exit_status=$$?; \
	exit $$exit_status;
