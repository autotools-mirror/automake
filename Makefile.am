## Process this file with automake to create Makefile.in

## Makefile for Automake.

# Copyright (C) 1995, 1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004,
# 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Free Software
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

## lib goes first, because it builds Config.pm, used by aclocal and
## automake (run in doc, tests, and in the rebuild rules.)
## `.' goes before doc and tests, because the latter two directories
## run aclocal and automake.
SUBDIRS = lib . contrib doc m4 tests

bin_SCRIPTS = automake aclocal

CLEANFILES = $(bin_SCRIPTS)
AUTOMAKESOURCES = automake.in aclocal.in

TAGS_FILES = $(AUTOMAKESOURCES)

EXTRA_DIST = \
  GNUmakefile \
  syntax-checks.mk \
  HACKING \
  ChangeLog.96 \
  ChangeLog.98 \
  ChangeLog.00 \
  ChangeLog.01 \
  ChangeLog.02 \
  ChangeLog.03 \
  ChangeLog.04 \
  ChangeLog.09 \
  ChangeLog.11 \
  bootstrap \
  $(AUTOMAKESOURCES)

## Make versioned links.  We only run the transform on the root name;
## then we make a versioned link with the transformed base name.  This
## seemed like the most reasonable approach.
install-exec-hook:
	@$(POST_INSTALL)
	@for p in $(bin_SCRIPTS); do \
	  f="`echo $$p|sed '$(transform)'`"; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f $(DESTDIR)$(bindir)/$$fv; \
	  echo " $(LN) $(DESTDIR)$(bindir)/$$f $(DESTDIR)$(bindir)/$$fv"; \
	  $(LN) $(DESTDIR)$(bindir)/$$f $(DESTDIR)$(bindir)/$$fv; \
	done

uninstall-hook:
	@for p in $(bin_SCRIPTS); do \
	  f="`echo $$p|sed '$(transform)'`"; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f $(DESTDIR)$(bindir)/$$fv; \
	done


## We can't use configure to do the substitution here; we must do it
## by hand.  We use a funny notation here to avoid configure
## substitutions in our text.
do_subst = sed \
  -e 's,[@]APIVERSION[@],$(APIVERSION),g' \
  -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
  -e 's,[@]PACKAGE_BUGREPORT[@],$(PACKAGE_BUGREPORT),g' \
  -e 's,[@]PACKAGE_URL[@],$(PACKAGE_URL),g' \
  -e 's,[@]PATH_SEPARATOR[@],$(PATH_SEPARATOR),g' \
  -e 's,[@]PERL[@],$(PERL),g' \
  -e 's,[@]PERL_THREADS[@],$(PERL_THREADS),g' \
  -e 's,[@]SHELL[@],$(SHELL),g' \
  -e 's,[@]am_AUTOCONF[@],$(am_AUTOCONF),g' \
  -e 's,[@]am_AUTOM4TE[@],$(am_AUTOM4TE),g' \
  -e 's,[@]VERSION[@],$(VERSION),g' \
  -e 's,[@]configure_input[@],Generated from $@.in; do not edit by hand.,g' \
  -e 's,[@]datadir[@],$(datadir),g'

## These files depend on Makefile so they are rebuilt if $(VERSION),
## $(datadir) or other do_subst'ituted variables change.
## Use chmod a-w to prevent people from editing the wrong file by accident.
automake: automake.in
aclocal: aclocal.in
automake aclocal: Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_GEN)$(do_subst) $(srcdir)/$@.in >$@-t
	$(AM_V_at)chmod a+x,a-w $@-t && mv -f $@-t $@

## The master location for INSTALL is lib/INSTALL.
## This is where `make fetch' will install new versions.
## Make sure we also update this copy.
INSTALL: lib/INSTALL
	$(AM_V_GEN)cp $(srcdir)/lib/INSTALL $@

# Run the testsuite with the installed aclocal and automake.
installcheck-local:
	am_running_installcheck=yes $(MAKE) $(AM_MAKEFLAGS) check

# Convenience proxy target for the test suites.
recheck:
	$(am__cd) tests && $(MAKE) $(AM_MAKEFLAGS) $@
.PHONY: recheck

################################################################
##
## Everything past here is useful to the maintainer, but probably not
## to anybody else
##

gitlog_to_changelog_command = $(PERL) $(srcdir)/lib/gitlog-to-changelog
gitlog_to_changelog_options = --since='2011-12-28 00:00:00' \
                              --no-cluster --format '%s%n%n%b'

# Automatic generation of the ChangeLog from git history.
#
# When executed from a git checkout, generate the ChangeLog from the git
# history.  When executed from an extracted distribution tarball, just
# copy the distributed ChangeLog in the build directory (and if this
# fails, or if no distributed ChangeLog file is present, complain and
# give an error).
#
# We need the apparently useless dependency from another .PHONY target
# `am--changelog-regen-hook' to work around a bug of Solaris make, which
# doesn't execute the recipe of a target named as an existing file, even
# if such target is declared `.PHONY' (yikes!)
#
.PHONY: am--changelog-regen-hook
am--changelog-regen-hook:
ChangeLog: am--changelog-regen-hook
	$(AM_V_GEN)set -e; set -u; \
## The ChangeLog should be regenerated unconditionally when working from
## checked-out sources; otherwise, if we're working from a distribution
## tarball, we expect the ChangeLog to be distributed, so check that it
## is indeed present in the source directory.
	if test -d $(srcdir)/.git; then \
	  rm -f $@-t \
	    && $(gitlog_to_changelog_command) \
	       $(gitlog_to_changelog_options) >$@-t \
	    && chmod a-w $@-t \
	    && mv -f $@-t $@ \
	    || exit 1; \
	elif test ! -f $(srcdir)/$@; then \
	  echo "Source tree is not a git checkout, and no pre-existent" \
	       "$@ file has been found there" >&2; \
	  exit 1; \
	fi

# Ensure tests are world-executable
dist-hook:
	$(am__cd) $(distdir)/tests && chmod a+rx *.test


# Perl coverage statistics.
PERL_COVERAGE_DB = $(abs_top_builddir)/cover_db
PERL_COVERAGE_FLAGS = -MDevel::Cover=-db,$(PERL_COVERAGE_DB),-silent,on,-summary,off
PERL_COVER = cover

check-coverage-run recheck-coverage-run: all
	$(mkinstalldirs) $(PERL_COVERAGE_DB)
	PERL5OPT="$$PERL5OPT $(PERL_COVERAGE_FLAGS)"; export PERL5OPT; \
	WANT_NO_THREADS=yes; export WANT_NO_THREADS; unset AUTOMAKE_JOBS; \
	$(MAKE) $(AM_MAKEFLAGS) `echo $@ | sed 's/-coverage-run//'`

check-coverage-report:
	@if test ! -d "$(PERL_COVERAGE_DB)"; then \
	  echo "No coverage database found in \`$(PERL_COVERAGE_DB)'." >&2; \
	  echo "Please run \`make check-coverage' first" >&2; \
	  exit 1; \
	fi
	$(PERL_COVER) $(PERL_COVER_FLAGS) "$(PERL_COVERAGE_DB)"

# We don't use direct dependencies here because we'd like to be able
# to invoke the report even after interrupted check-coverage.
check-coverage: check-coverage-run
	$(MAKE) $(AM_MAKEFLAGS) check-coverage-report

recheck-coverage: recheck-coverage-run
	$(MAKE) $(AM_MAKEFLAGS) check-coverage-report

clean-coverage:
	rm -rf "$(PERL_COVERAGE_DB)"
clean-local: clean-coverage

.PHONY: check-coverage recheck-coverage check-coverage-run \
	recheck-coverage-run check-coverage-report clean-coverage

git-dist: maintainer-check
## Make sure the NEWS file is up-to-date.
	@if sed 1q $(srcdir)/NEWS | grep -e "$(VERSION)" > /dev/null; then :; else \
	  echo "NEWS not updated; not releasing" 1>&2; \
	  exit 1;				\
	fi
## Build the distribution.  We expect the developer to have already run
## "make check" and "make distcheck" on his own (as required in the
## HACKING file, section "Release procedure").
	$(MAKE) $(AM_MAKEFLAGS) dist
## Finally, if anything was successful, commit the last changes and tag
## the release in the repository.  We don't use RCS keywords so it's OK
## to distribute the files before they were committed.
	$(am__cd) $(srcdir) && git commit -a -s && \
	   git tag -s "v$(VERSION)" -m "Release $(VERSION)"

git-release: git-dist
	case $(VERSION) in \
	  *[a-z]) dest=alpha;; \
	  *)      dest=ftp;; \
	esac; \
	$(srcdir)/lib/gnupload $(GNUPLOADFLAGS) \
	  --to $$dest.gnu.org:automake $(DIST_ARCHIVES)

## Visually comparing differences between the Makefile.in files in
## automake's own build system as generated in two different branches
## might help to catch bugs and blunders.  This has already happened a
## few times in the past, when we used to version-control Makefile.in.
autodiffs:
	@set -u; \
	 NEW_COMMIT=$${NEW_COMMIT-"HEAD"}; \
	 OLD_COMMIT=$${OLD_COMMIT-"HEAD~1"}; \
	 am_gitdir='$(abs_top_srcdir)/.git'; \
	 get_autofiles_from_rev () \
	 { \
	     rev=$$1 dir=$$2 \
	       && echo "$@: will get files from revision $$rev" \
	       && git clone -q --depth 1 "$$am_gitdir" tmp \
	       && cd tmp \
	       && git checkout -q "$$rev" \
	       && echo "$@: bootstrapping $$rev" \
	       && $(SHELL) ./bootstrap \
	       && echo "$@: copying files from $$rev" \
	       && makefile_ins=`find . -name Makefile.in` \
	       && (tar cf - configure aclocal.m4 $$makefile_ins) | \
	          (cd .. && cd "$$dir" && tar xf -) \
	       && cd .. \
	       && rm -rf tmp; \
	 }; \
	 outdir=$@.dir \
## Before proceeding, ensure the specified revisions truly exist.
	   && git --git-dir="$$am_gitdir" describe $$OLD_COMMIT >/dev/null \
	   && git --git-dir="$$am_gitdir" describe $$NEW_COMMIT >/dev/null \
	   && rm -rf $$outdir \
	   && mkdir $$outdir \
	   && cd $$outdir \
	   && mkdir new old \
	   && get_autofiles_from_rev $$OLD_COMMIT old \
	   && get_autofiles_from_rev $$NEW_COMMIT new \
	   && exit 0
## With lots of eye candy; we like our developers pampered and spoiled :-)
compare-autodiffs: autodiffs
	@set -u; \
	: $${COLORDIFF=colordiff} $${DIFF=diff}; \
	dir=autodiffs.dir; \
	if test ! -d "$$dir"; then \
	  echo "$@: $$dir: Not a directory" >&2; \
	  exit 1; \
	fi; \
	mydiff=false mypager=false; \
	if test -t 1; then \
	  if ($$COLORDIFF -r . .) </dev/null >/dev/null 2>&1; then \
	    mydiff=$$COLORDIFF; \
	    mypager="less -R"; \
	  else \
	    mypager=less; \
	  fi; \
	else \
	  mypager=cat; \
	fi; \
	if test "$$mydiff" = false; then \
	  if ($$DIFF -r -u . .); then \
	    mydiff=$$DIFF; \
	  else \
	    echo "$@: no good-enough diff program specified" >&2; \
	    exit 1; \
	  fi; \
	fi; \
	st=0; $$mydiff -r -u $$dir/old $$dir/new | $$mypager || st=$$?; \
	rm -rf $$dir; \
	exit $$st
.PHONY: autodiffs compare-autodiffs

## Program to use to fetch files.
WGET = wget
WGET_SV_CVS = $(WGET) http://savannah.gnu.org/cgi-bin/viewcvs/~checkout~/
WGET_SV_GIT_CF = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;hb=HEAD;f='
WGET_SV_GIT_AC = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=autoconf.git;a=blob_plain;hb=HEAD;f='
WGET_SV_GIT_GL = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=blob_plain;hb=HEAD;f='

## Files that we fetch and which we compare against.
## FIXME should be a lot more here
FETCHFILES = \
INSTALL \
config.guess \
config.sub \
gnupload \
gitlog-to-changelog \
texinfo.tex

## Fetch the latest versions of files we care about.
fetch:
	rm -rf Fetchdir > /dev/null 2>&1
	mkdir Fetchdir
## If a get fails then that is a problem.
	($(am__cd) Fetchdir && \
	$(WGET_SV_GIT_CF)config.guess -O config.guess && \
	$(WGET_SV_GIT_CF)config.sub -O config.sub && \
	$(WGET_SV_CVS)texinfo/texinfo/doc/texinfo.tex -O texinfo.tex && \
	$(WGET_SV_GIT_GL)doc/INSTALL -O INSTALL && \
	$(WGET_SV_GIT_GL)build-aux/gnupload -O gnupload && \
	$(WGET_SV_GIT_GL)build-aux/gitlog-to-changelog -O gitlog-to-changelog)
## Don't exit after test because we want to give as many errors as
## possible.
	@stat=0; for file in $(FETCHFILES); do \
	  if diff -u $(srcdir)/lib/$$file Fetchdir/$$file \
	          >>Fetchdir/update.patch 2>/dev/null; then :; \
	  else \
	    stat=1; \
	    echo "Updating $(srcdir)/lib/$$file ..."; \
	    cp Fetchdir/$$file $(srcdir)/lib/$$file; \
	  fi; \
	done; \
	test $$stat = 0 || \
	  echo "See Fetchdir/update.patch for a log of the changes."; \
	exit $$stat
.PHONY: fetch

## Generate release statistics, for the table in automake.texi.
## This has to be run in an up to date build tree, but there must
## be no temp files nor unused other files lying around!
release-stats: ps
	$(AM_V_GEN): && \
	am=`wc -l < automake` && \
	acl=`wc -l < aclocal` && \
	pmfiles="lib/Automake/*.pm" && \
	if test . != '$(srcdir)'; then pmfiles="$$pmfiles $(srcdir)/lib/Automake/*.pm"; \
	else :; fi && \
	pm=`cat $$pmfiles | wc -l` && \
	dot_am_files=`ls -1 $(srcdir)/lib/am/*.am | grep -v Makefile.am` && \
	amf=`echo "$$dot_am_files" | wc -l` && \
	aml=`cat $$dot_am_files | wc -l` && \
	m4f=`ls -1 $(srcdir)/m4/*.m4 | wc -l` && \
	m4l=`cat $(srcdir)/m4/*.m4 | wc -l` && \
	doc_text=`$(am__cd) doc && LC_ALL=C pstops 0 automake.ps unused.ps 2>&1` && \
	echo "$$doc_text" && \
	rm -f doc/unused.ps && \
	doc=`echo "$$doc_text" | sed -n 's/.*Wrote \([1-9][0-9]*\) pages.*/\1/p'` && \
	tests="tests/*.test"; \
	if test . != '$(srcdir)'; then tests="$$tests $(srcdir)/tests/*.test"; \
	else :; fi && \
	t=`ls -1 $$tests | wc -l` && \
	tgen=`grep 'GENERATED AUTOMATICALLY' $$tests | wc -l` && \
	today=`date +%Y-%m-%d` && \
	echo "add this to the table in doc/automake.texi after verification:" && \
	printf '@item %s @tab %-6s @tab %4d @tab %4d @tab %4d @tab %4d %-4s @tab %4d %-4s @tab %3d @tab %d %-4s\n' \
	              $$today $(VERSION) $$am    $$acl    $$pm   $$aml "($$amf)" $$m4l "($$m4f)" $$doc $$t "($$tgen)"
.PHONY: release-stats
