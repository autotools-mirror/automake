## Process this file with automake to create Makefile.in

## Makefile for Automake.

# Copyright (C) 1995-2012 Free Software Foundation, Inc.

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

## '.' goes before tests, because this latter directory runs
## aclocal and automake.
SUBDIRS = . tests

## Might be updated later.
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =

## ------------ ##
##  Top level.  ##
## ------------ ##

bin_SCRIPTS = automake aclocal

CLEANFILES += $(bin_SCRIPTS)
AUTOMAKESOURCES = automake.in aclocal.in

TAGS_FILES = $(AUTOMAKESOURCES)

EXTRA_DIST += \
  $(AUTOMAKESOURCES) \
  bootstrap \
  GNUmakefile \
  syntax-checks.mk \
  HACKING

## Make versioned links.  We only run the transform on the root name;
## then we make a versioned link with the transformed base name.  This
## seemed like the most reasonable approach.
install-exec-hook:
	@$(POST_INSTALL)
	@for p in $(bin_SCRIPTS); do \
	  f="`echo $$p|sed '$(transform)'`"; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
	  echo " $(LN) '$(DESTDIR)$(bindir)/$$f' '$(DESTDIR)$(bindir)/$$fv'"; \
	  $(LN) "$(DESTDIR)$(bindir)/$$f" "$(DESTDIR)$(bindir)/$$fv"; \
	done

uninstall-hook:
	@for p in $(bin_SCRIPTS); do \
	  f="`echo $$p|sed '$(transform)'`"; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
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
## This is where "make fetch" will install new versions.
## Make sure we also update this copy.
INSTALL: lib/INSTALL
	$(AM_V_GEN)cp $(srcdir)/lib/INSTALL $@

# Convenience proxy target for the test suites.
recheck:
	$(am__cd) tests && $(MAKE) $(AM_MAKEFLAGS) $@
.PHONY: recheck

# We don't use the default name for the autom4te cache directory,
# so we need this.
maintainer-clean-local:
	rm -rf .autom4te.cache


## -------------------------------------------------------------------- ##
##  Auxiliary scripts and files for use with "automake --add-missing".  ##
## -------------------------------------------------------------------- ##

dist_pkgvdata_DATA = \
  lib/COPYING \
  lib/INSTALL \
  lib/texinfo.tex

## These must all be executable when installed.  However, if we use
## _SCRIPTS, then the program transform will be applied, which is not
## what we want.  So we make them executable by hand.
dist_script_DATA = \
  lib/config.guess \
  lib/config.sub \
  lib/install-sh \
  lib/mdate-sh \
  lib/missing \
  lib/mkinstalldirs \
  lib/elisp-comp \
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

installcheck-local:
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

## This file depends on Makefile so it is rebuilt if $(VERSION),
## $(datadir) or other do_subst'ituted variables change.
## Use chmod a-w to prevent people from editing the wrong file by accident.
lib/Automake/Config.pm: lib/Automake/Config.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_at)test -d lib/Automake || $(MKDIR_P) lib/Automake
	$(AM_V_GEN)sed <$(srcdir)/lib/Automake/Config.in >$@-t \
	  -e 's,[@]APIVERSION[@],$(APIVERSION),g' \
	  -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
	  -e 's,[@]PACKAGE_BUGREPORT[@],$(PACKAGE_BUGREPORT),g' \
	  -e 's,[@]PERL[@],$(PERL),g' \
	  -e 's,[@]PERL_THREADS[@],$(PERL_THREADS),g' \
	  -e 's,[@]SHELL[@],$(SHELL),g' \
	  -e 's,[@]VERSION[@],$(VERSION),g' \
	  -e "s,[@]configure_input[@],Generated from Config.in; do not edit by hand.,g" \
	  -e 's,[@]datadir[@],$(datadir),g'
	$(AM_V_at)chmod a-w $@-t && mv -f $@-t $@
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
  m4/ccstdc.m4 \
  m4/cond.m4 \
  m4/cond-if.m4 \
  m4/depend.m4 \
  m4/depout.m4 \
  m4/dmalloc.m4 \
  m4/gcj.m4 \
  m4/header.m4 \
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
  m4/obsol-gt.m4 \
  m4/obsol-lt.m4 \
  m4/obsolete.m4 \
  m4/options.m4 \
  m4/protos.m4 \
  m4/python.m4 \
  m4/runlog.m4 \
  m4/sanity.m4 \
  m4/silent.m4 \
  m4/strip.m4 \
  m4/substnot.m4 \
  m4/tar.m4 \
  m4/upc.m4 \
  m4/vala.m4

dist_system_ac_DATA = m4/acdir/README

# We build amversion.m4 here, instead of from config.status,
# because config.status is rerun each time one of configure's
# dependencies change and amversion.m4 happens to be a configure
# dependency.  configure and amversion.m4 would be rebuilt in
# loop otherwise.
# Use '$(top_srcdir)/m4' for the benefit of non-GNU makes: this is
# how amversion.m4 appears in our dependencies.
$(top_srcdir)/m4/amversion.m4: $(srcdir)/configure.ac $(srcdir)/m4/amversion.in
	$(AM_V_at)sed \
	    -e 's,[@]VERSION[@],$(VERSION),g' \
	    -e 's,[@]APIVERSION[@],$(APIVERSION),g' \
	    -e "s,[@]configure_input[@],Generated from amversion.in; do not edit by hand.,g" \
	    $(srcdir)/m4/amversion.in > $@-t
	$(AM_V_at)chmod a-w $@-t && mv -f $@-t $@
EXTRA_DIST += m4/amversion.in


## ---------------- ##
##  Documentation.  ##
## ---------------- ##

info_TEXINFOS = doc/automake.texi doc/automake-history.texi
doc_automake_TEXINFOS = doc/fdl.texi
doc_automake_history_TEXINFOS = doc/fdl.texi

dist_man1_MANS = \
  $(srcdir)/doc/aclocal.1 \
  $(srcdir)/doc/automake.1 \
  $(srcdir)/doc/aclocal-$(APIVERSION).1 \
  $(srcdir)/doc/automake-$(APIVERSION).1

$(dist_man1_MANS): $(srcdir)/configure.ac

MAINTAINERCLEANFILES += $(dist_man1_MANS)

update_mans = \
  $(AM_V_GEN): \
    && $(MAKE) $(AM_MAKEFLAGS) lib/Automake/Config.pm \
    && PATH="$(abs_builddir)/tests/wrap$(PATH_SEPARATOR)$$PATH" \
    && export PATH \
    && $(HELP2MAN) --output=$@

$(srcdir)/doc/aclocal.1 $(srcdir)/doc/automake.1:
	$(AM_V_GEN): \
	  && f=`echo $@ | sed 's|.*/||; s|\.1$$||; $(transform)'` \
	  && echo ".so man1/$$f-$(APIVERSION).1" > $@

$(srcdir)/doc/aclocal-$(APIVERSION).1: $(srcdir)/aclocal.in
	$(update_mans) aclocal-$(APIVERSION)
$(srcdir)/doc/automake-$(APIVERSION).1: $(srcdir)/automake.in
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

dist_noinst_DATA = $(amhello_sources)
dist_doc_DATA = $(srcdir)/doc/amhello-1.0.tar.gz

# We depend on configure.ac so that we regenerate the tarball
# whenever the Automake version changes.
# aclocal-$(APIVERSION) and automake-$(APIVERSION) are generated by
# configure in tests/.
$(srcdir)/doc/amhello-1.0.tar.gz: $(amhello_sources) $(srcdir)/configure.ac
	$(AM_V_GEN): \
	  && PATH="$(abs_top_builddir)/tests/wrap$(PATH_SEPARATOR)$$PATH" \
	  && export PATH \
	  && $(am__cd) $(srcdir)/doc/amhello \
	  && ACLOCAL=aclocal-$(APIVERSION) && export ACLOCAL \
	  && AUTOMAKE=automake-$(APIVERSION) && export AUTOMAKE \
	  && AUTOCONF='$(am_AUTOCONF)' && export AUTOCONF \
	  && AUTOM4TE='$(am_AUTOM4TE)' && export AUTOM4TE \
	  && AUTORECONF='$(am_AUTORECONF)' && export AUTORECONF \
	  && AUTOHEADER='$(am_AUTOHEADER)' && export AUTOHEADER \
	  && AUTOUPDATE='$(am_AUTOUPDATE)' && export AUTOUPDATE \
	  && $(am_AUTORECONF) -vfi \
	  && ./configure \
	  && $(MAKE) $(AM_MAKEFLAGS) distcheck \
	  && $(MAKE) $(AM_MAKEFLAGS) distclean \
	  && rm -rf $(amhello_configury) \
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


##########################################################################

## Everything past here is useful to the maintainer, but probably not
## to anybody else.

##########################################################################


## --------------------------------------------------------- ##
##  Automatic generation of the ChangeLog from git history.  ##
## --------------------------------------------------------- ##

gitlog_to_changelog_command = $(PERL) $(srcdir)/lib/gitlog-to-changelog
gitlog_to_changelog_fixes = $(srcdir)/.git-log-fix
gitlog_to_changelog_options = --amend=$(gitlog_to_changelog_fixes) \
                              --since='2011-12-28 00:00:00' \
                              --no-cluster --format '%s%n%n%b'

EXTRA_DIST += lib/gitlog-to-changelog
EXTRA_DIST += $(gitlog_to_changelog_fixes)

# When executed from a git checkout, generate the ChangeLog from the git
# history.  When executed from an extracted distribution tarball, just
# copy the distributed ChangeLog in the build directory (and if this
# fails, or if no distributed ChangeLog file is present, complain and
# give an error).
#
# We need the apparently useless dependency from another .PHONY target
# 'am--changelog-regen-hook' to work around a bug of Solaris make, which
# doesn't execute the recipe of a target named as an existing file, even
# if such target is declared '.PHONY' (yikes!)
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

# Ensure tests are world-executable.
# FIXME: this should be turned into a maintainer check...
dist-hook:
	$(am__cd) $(distdir)/tests && chmod a+rx *.test


## --------------------------- ##
##  Perl coverage statistics.  ##
## --------------------------- ##

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
	  echo "No coverage database found in '$(PERL_COVERAGE_DB)'." >&2; \
	  echo "Please run \"make check-coverage\" first" >&2; \
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


## ---------------------------------------------------- ##
##  Tagging and/or uploading stable and beta releases.  ##
## ---------------------------------------------------- ##

GIT = git

EXTRA_DIST += lib/gnupload

version_rx = ^[1-9][0-9]*\.[0-9][0-9]*(\.[0-9][0-9]*)?
stable_version_rx = $(version_rx)$$
beta_version_rx = $(version_rx)[bdfhjlnprtvxz]$$
match_version = echo "$(VERSION)" | $(EGREP) >/dev/null

## Check that we don't have uncommitted or unstaged changes.
## TODO: Maybe the git suite already offers a shortcut to verify if the
## TODO: working directory is "clean" or not?  If yes, use that instead
## TODO: of duplicating the logic here.
git_must_have_clean_workdir = \
  $(GIT) rev-parse --verify HEAD >/dev/null \
    && $(GIT) update-index -q --refresh \
    && $(GIT) diff-files --quiet \
    && $(GIT) diff-index --quiet --cached HEAD \
    || fatal "you have uncommitted or unstaged changes"

determine_release_type = \
  if $(match_version) '$(stable_version_rx)'; then \
    release_type='Release' dest=ftp; \
  elif $(match_version) '$(beta_version_rx)'; then \
    release_type='Beta release' dest=alpha; \
  else \
    fatal "invalid version '$(VERSION)' for a release"; \
  fi

git-tag-release: maintainer-check
	@set -e; set -u; \
	fatal () { echo "$@: $$*; not tagging" >&2; exit 1; }; \
	case '$(AM_TAG_DRYRUN)' in \
	  ""|[nN]|[nN]o|NO) run="";; \
	  *) run="echo Running:";; \
	esac; \
	$(determine_release_type); \
	$(git_must_have_clean_workdir); \
## Make sure the NEWS file is up-to-date.
	sed 1q $(srcdir)/NEWS | grep '$(VERSION)' >/dev/null \
	  || fatal "NEWS not updated"; \
## If all was successful, tag the release in the local repository.
	$$run $(GIT) tag -s "v$(VERSION)" -m "$$release_type $(VERSION)"

git-upload-release:
	@set -e; set -u; \
	fatal () { echo "$@: $$*; not releasing" >&2; exit 1; }; \
	$(determine_release_type); \
	dest=$$dest.gnu.org:automake; \
	$(git_must_have_clean_workdir); \
## Check that we are releasing from a valid tag.
	tag=`$(GIT) describe` \
	  && case $$tag in "v$(VERSION)") true;; *) false;; esac \
	  || fatal "you can only create a release from a tagged version"; \
## Build and upload the distribution tarball(s).
	$(MAKE) $(AM_MAKEFLAGS) dist || exit 1; \
	echo Will upload to $$dest: $(DIST_ARCHIVES); \
	$(srcdir)/lib/gnupload $(GNUPLOADFLAGS) --to $$dest $(DIST_ARCHIVES)

.PHONY: git-upload-release git-tag-release


## ------------------------------------------------------------------ ##
##  Explore differences of autogenerated files in different commits.  ##
## ------------------------------------------------------------------ ##

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
	       && $(GIT) clone -q --depth 1 "$$am_gitdir" tmp \
	       && $(am__cd) tmp \
	       && $(GIT) checkout -q "$$rev" \
	       && echo "$@: bootstrapping $$rev" \
	       && $(SHELL) ./bootstrap \
	       && echo "$@: copying files from $$rev" \
	       && makefile_ins=`find . -name Makefile.in` \
	       && (tar cf - configure aclocal.m4 $$makefile_ins) | \
	          (cd .. && $(am__cd) "$$dir" && tar xf -) \
	       && cd .. \
	       && rm -rf tmp; \
	 }; \
	 outdir=$@.dir \
## Before proceeding, ensure the specified revisions truly exist.
	   && $(GIT) --git-dir="$$am_gitdir" describe $$OLD_COMMIT >/dev/null \
	   && $(GIT) --git-dir="$$am_gitdir" describe $$NEW_COMMIT >/dev/null \
	   && rm -rf $$outdir \
	   && mkdir $$outdir \
	   && $(am__cd) $$outdir \
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


## --------------------------------------------------------------------- ##
##  Synchronize third-party files that are committed in our repository.  ##
## --------------------------------------------------------------------- ##

## Program to use to fetch files.
WGET = wget
WGET_SV_CVS = $(WGET) http://savannah.gnu.org/cgi-bin/viewcvs/~checkout~/
WGET_SV_GIT_CF = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;hb=HEAD;f='
WGET_SV_GIT_AC = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=autoconf.git;a=blob_plain;hb=HEAD;f='
WGET_SV_GIT_GL = $(WGET) 'http://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=blob_plain;hb=HEAD;f='

## Files that we fetch and which we compare against.
## The 'lib/COPYING' file must still be synced by hand.
FETCHFILES = \
INSTALL \
config.guess \
config.sub \
gnupload \
gitlog-to-changelog \
texinfo.tex \
update-copyright

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
	$(WGET_SV_GIT_GL)build-aux/update-copyright -O update-copyright && \
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


## ------------------------------------------------ ##
##  Update copyright years of all committed files.  ##
## ------------------------------------------------ ##

EXTRA_DIST += lib/update-copyright

update_copyright_env = \
  UPDATE_COPYRIGHT_FORCE=1 \
  UPDATE_COPYRIGHT_USE_INTERVALS=2

.PHONY: update-copyright
update-copyright:
	$(AM_V_GEN)excluded_re=`echo $(FETCHFILES) \
	  | sed -e 's|^|lib/|' -e 's| | lib/|g' -e 's, ,|,g'`; \
	$(GIT) ls-files \
	  | grep -Ev '^(lib/)?(COPYING|INSTALL)$$' \
	  | grep -Ev "^($$excluded_re)$$" \
	  | $(update_copyright_env) xargs $(srcdir)/lib/$@
