## Process this file with automake to create Makefile.in

## Makefile for Automake.

# Copyright (C) 1995-2013 Free Software Foundation, Inc.

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

## Might be updated later.
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =

## ------------ ##
##  Top level.  ##
## ------------ ##

# We want a handful of substitutions to be fully-expanded by make;
# then use config.status to substitute the remainder where a single
# expansion is sufficient.  We use a funny notation here to avoid
# configure substitutions in our text.
do_subst = ( sed \
  -e "s,[@]configure_input[@],Generated from $$in; do not edit by hand.,g" \
  -e 's,[@]datadir[@],$(datadir),g' \
  -e 's,[@]amdir[@],$(amdir),g' \
  -e 's,[@]bindir[@],$(bindir),g' \
  -e 's,[@]docdir[@],$(docdir),g' \
  -e 's,[@]pkgvdatadir[@],$(pkgvdatadir),g' \
  -e 's,[@]scriptdir[@],$(scriptdir),g' \
  -e 's,[@]automake_acdir[@],$(automake_acdir),g' \
  -e 's,[@]system_acdir[@],$(system_acdir),g' \
## Hack to avoid a spurious substitution in the Automake script (part 1).
  -e 's,[@]am__isrc[@],!!@!!am__isrc!!@!!,g' \
  | $(SHELL) ./config.status --file=- \
## Hack to avoid a spurious substitution in the Automake script (part 2).
  | sed -e 's,!!@!!am__isrc!!@!!,@''am__isrc@,g' \
  )

# Generated  files shouldn't contain unexpanded '@substitutions@', and
# should be made read-only, to prevent them from being edited by mistake
# instead of the file the are generated from.
generated_file_finalize = $(AM_V_at) \
  if LC_ALL=C grep '@[a-zA-Z0-9_][a-zA-Z0-9_]*@' $@-t; then \
    echo "$@ contains unexpanded substitution (see lines above)"; \
    exit 1; \
  fi; \
  chmod a-w $@-t && mv -f $@-t $@

bin_SCRIPTS = automake aclocal

CLEANFILES += $(bin_SCRIPTS)
AUTOMAKESOURCES = automake.in aclocal.in

TAGS_FILES = $(AUTOMAKESOURCES)

EXTRA_DIST += \
  $(AUTOMAKESOURCES) \
  bootstrap.sh \
  GNUmakefile \
  maint.mk \
  syntax-checks.mk \
  HACKING

# For some tests or targets, we need to have the just-build automake and
# aclocal scripts avaiable on PATH.
extend_PATH = \
  { PATH='$(abs_builddir)/t/wrap'$(PATH_SEPARATOR)$$PATH && export PATH; }

# Make versioned links.  We only run the transform on the root name;
# then we make a versioned link with the transformed base name.  This
# seemed like the most reasonable approach.
install-exec-hook:
	@$(POST_INSTALL)
	@for p in $(bin_SCRIPTS); do \
	  f=`echo $$p | sed '$(transform)'`; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
	  echo " $(LN) '$(DESTDIR)$(bindir)/$$f' '$(DESTDIR)$(bindir)/$$fv'"; \
	  $(LN) "$(DESTDIR)$(bindir)/$$f" "$(DESTDIR)$(bindir)/$$fv"; \
	done

uninstall-hook:
	@for p in $(bin_SCRIPTS); do \
	  f=`echo $$p | sed '$(transform)'`; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
	done

# These files depend on Makefile so they are rebuilt if $(VERSION),
# $(datadir) or other do_subst'ituted variables change.
automake: automake.in
aclocal: aclocal.in
automake aclocal: Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_GEN)in=$@.in; $(do_subst) <$(srcdir)/$@.in >$@-t
## We can't use '$(generated_file_finalize)' here, because currently
## Automake contains occurrences of unexpanded @substitutions@ in
## comments, and that is perfectly legit.
	$(AM_V_at)chmod a+x,a-w $@-t && mv -f $@-t $@

# The master location for INSTALL is lib/INSTALL.
# This is where "make fetch" will install new versions.
# Make sure we also update this copy.
INSTALL: lib/INSTALL
	$(AM_V_GEN)cp $(srcdir)/lib/INSTALL $@

# We don't use the default name for the autom4te cache directory,
# so we need this.
maintainer-clean-local:
	rm -rf .autom4te.cache

# So that automake won't complain about the missing ChangeLog.
# The real rule for ChangeLog generation is now in maint.mk (as
# it is maintainer-specific).
ChangeLog:


## -------------------------------------------------------------------- ##
##  Auxiliary scripts and files for use with "automake --add-missing".  ##
## -------------------------------------------------------------------- ##

dist_pkgvdata_DATA = \
  lib/COPYING \
  lib/INSTALL \
  lib/texinfo.tex

# These must all be executable when installed.  However, if we use
# _SCRIPTS, then the program transform will be applied, which is not
# what we want.  So we make them executable by hand.
dist_script_DATA = \
  lib/config.guess \
  lib/config.sub \
  lib/install-sh \
  lib/mdate-sh \
  lib/missing \
  lib/mkinstalldirs \
  lib/ylwrap \
  lib/depcomp \
  lib/compile \
  lib/py-compile \
  lib/ar-lib \
  lib/test-driver \
  lib/tap-driver.sh \
  lib/tap-driver.pl

install-data-hook:
	@$(POST_INSTALL)
	@for f in $(dist_script_DATA); do echo $$f; done \
	  | sed 's,^lib/,,' \
	  | ( st=0; \
	      while read f; do \
	        echo " chmod +x '$(DESTDIR)$(scriptdir)/$$f'"; \
	        chmod +x "$(DESTDIR)$(scriptdir)/$$f" || st=1; \
	      done; \
	      exit $$st )

installcheck-local: installcheck-executable-scripts
installcheck-executable-scripts:
	@for f in $(dist_script_DATA); do echo $$f; done \
	  | sed 's,^lib/,,' \
	  | while read f; do \
	      path="$(pkgvdatadir)/$$f"; \
	      test -x "$$path" || echo $$path; \
	    done \
	  | sed 's/$$/: not executable/' \
	  | grep . 1>&2 && exit 1; exit 0


## ---------------------------------------------------- ##
##  Private perl modules used by automake and aclocal.  ##
## ---------------------------------------------------- ##

perllibdir = $(pkgvdatadir)/Automake
dist_perllib_DATA = \
  lib/Automake/ChannelDefs.pm \
  lib/Automake/Channels.pm \
  lib/Automake/Condition.pm \
  lib/Automake/Configure_ac.pm \
  lib/Automake/DisjConditions.pm \
  lib/Automake/FileUtils.pm \
  lib/Automake/General.pm \
  lib/Automake/Getopt.pm \
  lib/Automake/Item.pm \
  lib/Automake/ItemDef.pm \
  lib/Automake/Location.pm \
  lib/Automake/Options.pm \
  lib/Automake/Rule.pm \
  lib/Automake/RuleDef.pm \
  lib/Automake/Variable.pm \
  lib/Automake/VarDef.pm \
  lib/Automake/Version.pm \
  lib/Automake/XFile.pm \
  lib/Automake/Wrap.pm

nodist_perllib_DATA = lib/Automake/Config.pm
CLEANFILES += $(nodist_perllib_DATA)

lib/Automake/Config.pm: lib/Automake/Config.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_at)test -d lib/Automake || $(MKDIR_P) lib/Automake
	$(AM_V_GEN)in=Config.in \
	  && $(do_subst) <$(srcdir)/lib/Automake/Config.in >$@-t
	$(generated_file_finalize)
EXTRA_DIST += lib/Automake/Config.in


## --------------------- ##
##  Makefile fragments.  ##
## --------------------- ##

dist_am_DATA = \
  lib/am/check.am \
  lib/am/check2.am \
  lib/am/clean-hdr.am \
  lib/am/clean.am \
  lib/am/compile.am \
  lib/am/configure.am \
  lib/am/data.am \
  lib/am/dejagnu.am \
  lib/am/depend.am \
  lib/am/depend2.am \
  lib/am/distdir.am \
  lib/am/footer.am \
  lib/am/header-vars.am \
  lib/am/header.am \
  lib/am/install.am \
  lib/am/inst-vars.am \
  lib/am/java.am \
  lib/am/lang-compile.am \
  lib/am/lex.am \
  lib/am/library.am \
  lib/am/libs.am \
  lib/am/libtool.am \
  lib/am/lisp.am \
  lib/am/ltlib.am \
  lib/am/ltlibrary.am \
  lib/am/mans-vars.am \
  lib/am/mans.am \
  lib/am/program.am \
  lib/am/progs.am \
  lib/am/python.am \
  lib/am/remake-hdr.am \
  lib/am/scripts.am \
  lib/am/subdirs.am \
  lib/am/tags.am \
  lib/am/texi-vers.am \
  lib/am/texibuild.am \
  lib/am/texinfos.am \
  lib/am/vala.am \
  lib/am/yacc.am


## ------------------------------ ##
##  Automake-provided m4 macros.  ##
## ------------------------------ ##

dist_automake_ac_DATA = \
  m4/amversion.m4 \
  m4/ar-lib.m4 \
  m4/as.m4 \
  m4/auxdir.m4 \
  m4/cond.m4 \
  m4/cond-if.m4 \
  m4/depend.m4 \
  m4/depout.m4 \
  m4/dmalloc.m4 \
  m4/extra-recurs.m4 \
  m4/gcj.m4 \
  m4/init.m4 \
  m4/install-sh.m4 \
  m4/lead-dot.m4 \
  m4/lex.m4 \
  m4/lispdir.m4 \
  m4/maintainer.m4 \
  m4/make.m4 \
  m4/minuso.m4 \
  m4/missing.m4 \
  m4/mkdirp.m4 \
  m4/obsolete.m4 \
  m4/options.m4 \
  m4/python.m4 \
  m4/runlog.m4 \
  m4/sanity.m4 \
  m4/silent.m4 \
  m4/strip.m4 \
  m4/substnot.m4 \
  m4/tar.m4 \
  m4/upc.m4 \
  m4/vala.m4

automake_internal_acdir = $(automake_acdir)/internal
dist_automake_internal_ac_DATA = m4/internal/ac-config-macro-dirs.m4

dist_system_ac_DATA = m4/acdir/README

# We build amversion.m4 here, instead of from config.status,
# because config.status is rerun each time one of configure's
# dependencies change and amversion.m4 happens to be a configure
# dependency.  configure and amversion.m4 would be rebuilt in
# loop otherwise.
# Use '$(top_srcdir)/m4' for the benefit of non-GNU makes: this is
# how amversion.m4 appears in our dependencies.
$(top_srcdir)/m4/amversion.m4: $(srcdir)/configure.ac $(srcdir)/m4/amversion.in
	$(AM_V_at)rm -f $@-t $@
	$(AM_V_GEN)in=amversion.in \
	  && $(do_subst) <$(srcdir)/m4/amversion.in >$@-t
	$(generated_file_finalize)
EXTRA_DIST += m4/amversion.in


## ------------ ##
##  Testsuite.  ##
## ------------ ##

# Run the tests with a proper shell detected at configure time.
LOG_COMPILER = $(AM_TEST_RUNNER_SHELL)

TEST_EXTENSIONS = .pl .sh .tap
SH_LOG_COMPILER = $(LOG_COMPILER)
TAP_LOG_COMPILER = $(LOG_COMPILER)
PL_LOG_COMPILER = $(PERL)
AM_PL_LOG_FLAGS = -Mstrict -I $(builddir)/lib -I $(srcdir)/lib -w

TAP_LOG_DRIVER = AM_TAP_AWK='$(AWK)' $(SHELL) $(srcdir)/lib/tap-driver.sh

AM_TAP_LOG_DRIVER_FLAGS = --merge

EXTRA_DIST += t/README t/ax/is t/ax/is_newest t/ax/deltree.pl

## Will be updated later.
TESTS =

# Some testsuite-influential variables should be overridable from the
# test scripts, but not from the environment.
# Keep this in sync with the similar list in 'runtest.in'.
AM_TESTS_ENVIRONMENT = \
  for v in \
    required \
    am_test_protocol \
    am_serial_tests \
    am_test_prefer_config_shell \
    am_original_AUTOMAKE \
    am_original_ACLOCAL \
    am_test_lib_sourced \
    test_lib_sourced \
  ; do \
    eval test x"\$${$$v}" = x || unset $$v; \
  done;
# We want warning messages and explanations for skipped tests to go to
# the console if possible, so set up 'stderr_fileno_' properly.
AM_TESTS_FD_REDIRECT = 9>&2
AM_TESTS_ENVIRONMENT += stderr_fileno_=9; export stderr_fileno_;

# For sourcing of extra "shell libraries" by our test scripts.  As per
# POSIX, sourcing a file with '.' will cause it to be looked up in $PATH
# in case it is given with a relative name containing no slashes.
AM_TESTS_ENVIRONMENT += \
  if test $(srcdir) != .; then \
    PATH='$(abs_srcdir)/t/ax'$(PATH_SEPARATOR)$$PATH; \
  fi; \
  PATH='$(abs_builddir)/t/ax'$(PATH_SEPARATOR)$$PATH; \
  export PATH;

# Hand-written tests.

include $(srcdir)/t/list-of-tests.mk

TESTS += $(handwritten_TESTS)
EXTRA_DIST += $(handwritten_TESTS)

# Automatically-generated tests wrapping hand-written ones.
# Also, automatically-computed dependencies for tests.

include $(srcdir)/t/testsuite-part.am

TESTS += $(generated_TESTS)
EXTRA_DIST += $(generated_TESTS)

$(srcdir)/t/testsuite-part.am:
	$(AM_V_at)rm -f t/testsuite-part.tmp $@
	$(AM_V_GEN)$(PERL) $(srcdir)/gen-testsuite-part \
	  --srcdir $(srcdir) > t/testsuite-part.tmp
	$(AM_V_at)chmod a-w t/testsuite-part.tmp
	$(AM_V_at)mv -f t/testsuite-part.tmp $@
EXTRA_DIST += gen-testsuite-part

# The dependecies declared here are not truly complete, but such
# completeness would cause more issues than it would solve.  See
# automake bug#11347.
$(generated_TESTS): $(srcdir)/gen-testsuite-part
$(srcdir)/t/testsuite-part.am: $(srcdir)/gen-testsuite-part Makefile.am

# Hand-written tests for stuff in 'contrib/'.
include $(srcdir)/contrib/t/local.am
TESTS += $(contrib_TESTS)
EXTRA_DIST += $(contrib_TESTS)

# Static dependencies valid for each test case (also further
# extended later).  Note that use 'noinst_' rather than 'check_'
# as the prefix, because we really want them to be built by
# "make all".  This makes it easier to run the test cases by
# hand after having simply configured and built the package.

nodist_noinst_SCRIPTS = \
  t/wrap/aclocal-$(APIVERSION) \
  t/wrap/automake-$(APIVERSION)

dist_noinst_DATA = \
  t/ax/test-init.sh \
  t/ax/test-lib.sh \
  t/ax/am-test-lib.sh \
  t/ax/tap-functions.sh

# Few more static dependencies.
t/distcheck-missing-m4.log: t/ax/distcheck-hook-m4.am
t/distcheck-outdated-m4.log: t/ax/distcheck-hook-m4.am
EXTRA_DIST += t/ax/distcheck-hook-m4.am

t/ax/test-defs.sh: t/ax/test-defs.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_at)$(MKDIR_P) t/ax
	$(AM_V_GEN)in=t/ax/test-defs.in \
	  && $(do_subst) <$(srcdir)/$$in >$@-t
	$(generated_file_finalize)
EXTRA_DIST += t/ax/test-defs.in
CLEANFILES += t/ax/test-defs.sh
nodist_noinst_DATA = t/ax/test-defs.sh

## Will be updated soon.
noinst_SCRIPTS =

t/ax/shell-no-trail-bslash: t/ax/shell-no-trail-bslash.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_GEN)in=t/ax/shell-no-trail-bslash.in \
	  && $(MKDIR_P) t/ax \
	  && $(do_subst) <$(srcdir)/$$in >$@-t \
	  && chmod a+x $@-t
	$(generated_file_finalize)
EXTRA_DIST += t/ax/shell-no-trail-bslash.in
CLEANFILES += t/ax/shell-no-trail-bslash
noinst_SCRIPTS += t/ax/shell-no-trail-bslash

runtest: runtest.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_GEN)in=runtest.in \
	  && $(MKDIR_P) t/ax \
	  && $(do_subst) <$(srcdir)/runtest.in >$@-t \
	  && chmod a+x $@-t
	$(generated_file_finalize)
EXTRA_DIST += runtest.in
CLEANFILES += runtest
noinst_SCRIPTS += runtest

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

# Check that our test cases are syntactically correct.
# See automake bug#11898.
check-tests-syntax:
	@st=0; \
	err () { echo "$@: $$*" >&2; st=1; }; \
## The user might do something like "make check TESTS=t/foo" or
## "make check TESTS_LOGS=t/foo.log" and expect (say) the test
## 't/foo.sh' to be run; this has worked well until today, and
## we want to continue supporting this use case.
	bases=`for log in : $(TEST_LOGS); do echo $$log; done \
	  | sed -e '/^:$$/d' -e 's/\.log$$//'`; \
	for bas in $$bases; do \
	  for suf in sh tap pl; do \
	    tst=$$bas.$$suf; \
## Emulate VPATH search.
	    if test -f $$tst; then \
	      break; \
	    elif test -f $(srcdir)/$$tst; then \
	      tst=$(srcdir)/$$tst; \
	      break; \
	    else \
	      tst=''; \
	    fi; \
	  done; \
	  test -n "$$tst" || err "couldn't find test '$$bas'"; \
## Don't check that perl tests are valid shell scripts!
	  test $$suf = pl && continue; \
	  $(AM_V_P) && echo " $(AM_TEST_RUNNER_SHELL) -n $$tst"; \
	  $(AM_TEST_RUNNER_SHELL) -n "$$tst" \
	    || err "test '$$tst' syntactically invalid"; \
	done; \
	exit $$st
check-local: check-tests-syntax
.PHONY: check-tests-syntax

# Recipes with a trailing backslash character (possibly followed by
# blank characters only) can cause spurious syntax errors with at
# least older bash versions (e.g., bash 2.05b), and can be potentially
# be unportable to other weaker shells.  Run the testsuite in a way
# that helps catching such problems in Automake-generated recipes.
# See automake bug#10436.
check-no-trailing-backslash-in-recipes:
	$(AM_V_at)$(MAKE) $(AM_MAKEFLAGS) check \
	  CONFIG_SHELL='$(abs_top_builddir)/t/ax/shell-no-trail-bslash'
.PHONY: check-no-trailing-backslash-in-recipes

# Automake-generated Makefiles should work when run with parallel make.
check-parallel:
	$(AM_V_GEN)$(MAKE) $(AM_MAKEFLAGS) check \
	  AM_TESTSUITE_MAKE="$${AM_TESTSUITE_MAKE-$${MAKE-make}} -j4"
.PHONY: check-parallel

## Checking the list of tests.
test_subdirs = t t/pm contrib/t
include $(srcdir)/t/CheckListOfTests.am

# Run the testsuite with the installed aclocal and automake.
installcheck-local: installcheck-testsuite
installcheck-testsuite:
	am_running_installcheck=yes $(MAKE) $(AM_MAKEFLAGS) check

# Performance tests.
.PHONY: perf
perf: all
	$(MAKE) $(AM_MAKEFLAGS) TEST_SUITE_LOG='$(PERF_TEST_SUITE_LOG)'	\
	                        TESTS='$(perf_TESTS)' check
PERF_TEST_SUITE_LOG = t/perf/test-suite.log
CLEANFILES += $(PERF_TEST_SUITE_LOG)
EXTRA_DIST += $(perf_TESTS)

clean-local: clean-local-check
.PHONY: clean-local-check
clean-local-check:
	$(AM_V_GEN)$(PERL) $(srcdir)/t/ax/deltree.pl t/*.dir t/*/*.dir */t/*.dir


## ---------------- ##
##  Documentation.  ##
## ---------------- ##

info_TEXINFOS = doc/automake.texi doc/automake-history.texi
doc_automake_TEXINFOS = doc/fdl.texi
doc_automake_history_TEXINFOS = doc/fdl.texi

man1_MANS = \
  doc/aclocal.1 \
  doc/automake.1 \
  doc/aclocal-$(APIVERSION).1 \
  doc/automake-$(APIVERSION).1

$(man1_MANS): $(srcdir)/configure.ac

CLEANFILES += $(man1_MANS)
EXTRA_DIST += doc/help2man

update_mans = \
  $(AM_V_GEN): \
    && $(MKDIR_P) doc \
    && $(extend_PATH) \
    && $(PERL) $(srcdir)/doc/help2man --output=$@

doc/aclocal.1 doc/automake.1:
	$(AM_V_GEN): \
	  && $(MKDIR_P) doc \
	  && f=`echo $@ | sed 's|.*/||; s|\.1$$||; $(transform)'` \
	  && echo ".so man1/$$f-$(APIVERSION).1" > $@

doc/aclocal-$(APIVERSION).1: aclocal.in aclocal lib/Automake/Config.pm
	$(update_mans) aclocal-$(APIVERSION)
doc/automake-$(APIVERSION).1: automake.in automake lib/Automake/Config.pm
	$(update_mans) automake-$(APIVERSION)


## ---------------------------- ##
##  Example package "amhello".  ##
## ---------------------------- ##

amhello_sources = \
  doc/amhello/configure.ac \
  doc/amhello/Makefile.am \
  doc/amhello/README \
  doc/amhello/src/main.c \
  doc/amhello/src/Makefile.am

amhello_configury = \
  aclocal.m4 \
  autom4te.cache \
  Makefile.in \
  config.h.in \
  configure \
  depcomp \
  install-sh \
  missing \
  src/Makefile.in

dist_noinst_DATA += $(amhello_sources)
dist_doc_DATA = $(srcdir)/doc/amhello-1.0.tar.gz

setup_autotools_paths = { \
  $(extend_PATH) \
    && ACLOCAL=aclocal-$(APIVERSION) && export ACLOCAL \
    && AUTOMAKE=automake-$(APIVERSION) && export AUTOMAKE \
    && AUTOCONF='$(am_AUTOCONF)' && export AUTOCONF \
    && AUTOM4TE='$(am_AUTOM4TE)' && export AUTOM4TE \
    && AUTORECONF='$(am_AUTORECONF)' && export AUTORECONF \
    && AUTOHEADER='$(am_AUTOHEADER)' && export AUTOHEADER \
    && AUTOUPDATE='$(am_AUTOUPDATE)' && export AUTOUPDATE \
    && true; \
}

# We depend on configure.ac so that we regenerate the tarball
# whenever the Automake version changes.
$(srcdir)/doc/amhello-1.0.tar.gz: $(amhello_sources) $(srcdir)/configure.ac
	$(AM_V_GEN)tmp=amhello-output.tmp \
	  && $(am__cd) $(srcdir)/doc/amhello \
	  && : Make our	aclocal and automake avaiable before system ones. \
	  && $(setup_autotools_paths) \
	  && ( \
	    { $(AM_V_P) || exec 5>&2 >$$tmp 2>&1; } \
	      && $(am_AUTORECONF) -vfi \
	      && ./configure \
	      && $(MAKE) $(AM_MAKEFLAGS) distcheck \
	      && $(MAKE) $(AM_MAKEFLAGS) distclean \
	      || { \
	        if $(AM_V_P); then :; else \
	          echo "$@: recipe failed." >&5; \
	          echo "See file '`pwd`/$$tmp' for details" >&5; \
		fi; \
	        exit 1; \
	      } \
	  ) \
	  && rm -rf $(amhello_configury) $$tmp \
	  && mv -f amhello-1.0.tar.gz ..


## ------------------------------------------------- ##
##  Third-party, obsolescent or experimental stuff.  ##
## ------------------------------------------------- ##

EXTRA_DIST += \
  contrib/check-html.am \
  contrib/multilib/README \
  contrib/multilib/config-ml.in \
  contrib/multilib/symlink-tree \
  contrib/multilib/multilib.am \
  contrib/multilib/multi.m4 \
  contrib/README


## --------------------------------------------------- ##
##  Older files, kept mostly for historical interest.  ##
## --------------------------------------------------- ##

EXTRA_DIST += \
  old/ChangeLog-tests \
  old/ChangeLog.96 \
  old/ChangeLog.98 \
  old/ChangeLog.00 \
  old/ChangeLog.01 \
  old/ChangeLog.02 \
  old/ChangeLog.03 \
  old/ChangeLog.04 \
  old/ChangeLog.09 \
  old/ChangeLog.11 \
  old/TODO
