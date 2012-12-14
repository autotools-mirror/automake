# Maintainer makefile rules for Automake.
#
# Copyright (C) 1995-2012 Free Software Foundation, Inc.
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

# Avoid CDPATH issues.
unexport CDPATH

# --------------------------------------------------------- #
#  Automatic generation of the ChangeLog from git history.  #
# --------------------------------------------------------- #

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
# The ChangeLog should be regenerated unconditionally when working from
# checked-out sources; otherwise, if we're working from a distribution
# tarball, we expect the ChangeLog to be distributed, so check that it
# is indeed present in the source directory.
ChangeLog:
	$(AM_V_GEN)set -e; set -u; \
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
.PHONY: ChangeLog


# --------------------------- #
#  Perl coverage statistics.  #
# --------------------------- #

PERL_COVERAGE_DB = $(abs_top_builddir)/cover_db
PERL_COVERAGE_FLAGS = -MDevel::Cover=-db,$(PERL_COVERAGE_DB),-silent,on,-summary,off
PERL_COVER = cover

check-coverage-run recheck-coverage-run: %-coverage-run: all
	$(mkinstalldirs) $(PERL_COVERAGE_DB)
	PERL5OPT="$$PERL5OPT $(PERL_COVERAGE_FLAGS)"; export PERL5OPT; \
	WANT_NO_THREADS=yes; export WANT_NO_THREADS; unset AUTOMAKE_JOBS; \
	$(MAKE) $*

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
	$(MAKE) check-coverage-report

recheck-coverage: recheck-coverage-run
	$(MAKE) check-coverage-report

clean-coverage:
	rm -rf "$(PERL_COVERAGE_DB)"
clean-local: clean-coverage

.PHONY: check-coverage recheck-coverage check-coverage-run \
	recheck-coverage-run check-coverage-report clean-coverage


# ---------------------------------------------------- #
#  Tagging and/or uploading stable and beta releases.  #
# ---------------------------------------------------- #

GIT = git

EXTRA_DIST += lib/gnupload

base_version_rx = ^[1-9][0-9]*\.[0-9][0-9]*
stable_major_version_rx = $(base_version_rx)$$
stable_minor_version_rx = $(base_version_rx)\.[0-9][0-9]*$$
beta_version_rx = $(base_version_rx)(\.[0-9][0-9]*)?[bdfhjlnprtvxz]$$
match_version = echo "$(VERSION)" | $(EGREP) >/dev/null

# Check that we don't have uncommitted or unstaged changes.
# TODO: Maybe the git suite already offers a shortcut to verify if the
# TODO: working directory is "clean" or not?  If yes, use that instead
# TODO: of duplicating the logic here.
git_must_have_clean_workdir = \
  $(GIT) rev-parse --verify HEAD >/dev/null \
    && $(GIT) update-index -q --refresh \
    && $(GIT) diff-files --quiet \
    && $(GIT) diff-index --quiet --cached HEAD \
    || { echo "$@: you have uncommitted or unstaged changes" >&2; exit 1; }

determine_release_type = \
  if $(match_version) '$(stable_major_version_rx)'; then \
    release_type='Major release'; \
    announcement_type='major release'; \
    dest=ftp; \
  elif $(match_version) '$(stable_minor_version_rx)'; then \
    release_type='Minor release'; \
    announcement_type='maintenance release'; \
    dest=ftp; \
  elif $(match_version) '$(beta_version_rx)'; then \
    release_type='Beta release'; \
    announcement_type='test release'; \
    dest=alpha; \
  else \
    echo "$@: invalid version '$(VERSION)' for a release" >&2; \
    exit 1; \
  fi

# Help the debugging of $(determine_release_type) and related code.
print-release-type:
	@$(determine_release_type); \
	 echo "$$release_type $(VERSION);" \
	      "it will be announced as a $$announcement_type"

git-tag-release: maintainer-check
	@set -e -u; \
	case '$(AM_TAG_DRYRUN)' in \
	  ""|[nN]|[nN]o|NO) run="";; \
	  *) run="echo Running:";; \
	esac; \
	$(determine_release_type); \
	$(git_must_have_clean_workdir); \
	$$run $(GIT) tag -s "v$(VERSION)" -m "$$release_type $(VERSION)"

git-upload-release:
	@# Check this a version we can cut a release release from the
	@# current repository: we must have a beta version, and the
	@# repository must be clean.
	@$(determine_release_type)
	@$(git_must_have_clean_workdir)
	@# Check that we are releasing from a valid tag.
	tag=`$(GIT) describe` \
	  && case $$tag in "v$(VERSION)") true;; *) false;; esac \
	  || { echo "$@: you can only create a release from a tagged" \
	            "version" >&2; \
	       exit 1; }
	@# Build the distribution tarball(s).
	$(MAKE) dist
	@# Upload it to the correct FTP repository.
	@$(determine_release_type) \
	  && dest=$$dest.gnu.org:automake \
	  && echo "Will upload to $$dest: $(DIST_ARCHIVES)" \
	  && $(srcdir)/lib/gnupload $(GNUPLOADFLAGS) --to $$dest \
	                            $(DIST_ARCHIVES)

.PHONY: print-release-type git-upload-release git-tag-release


# ------------------------------------------------------------------ #
#  Explore differences of autogenerated files in different commits.  #
# ------------------------------------------------------------------ #

# Visually comparing differences between the Makefile.in files in
# automake's own build system as generated in two different branches
# might help to catch bugs and blunders.  This has already happened a
# few times in the past, when we used to version-control Makefile.in.
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
	       && cd tmp \
	       && $(GIT) checkout -q "$$rev" \
	       && echo "$@: bootstrapping $$rev" \
	       && $(SHELL) ./bootstrap.sh \
	       && echo "$@: copying files from $$rev" \
	       && makefile_ins=`find . -name Makefile.in` \
	       && (tar cf - configure aclocal.m4 $$makefile_ins) | \
	          (cd .. && cd "$$dir" && tar xf -) \
	       && cd .. \
	       && rm -rf tmp; \
	 }; \
	 outdir=$@.dir \
	   && : Before proceeding, ensure the specified revisions truly exist. \
	   && $(GIT) --git-dir="$$am_gitdir" describe $$OLD_COMMIT >/dev/null \
	   && $(GIT) --git-dir="$$am_gitdir" describe $$NEW_COMMIT >/dev/null \
	   && rm -rf $$outdir \
	   && mkdir $$outdir \
	   && cd $$outdir \
	   && mkdir new old \
	   && get_autofiles_from_rev $$OLD_COMMIT old \
	   && get_autofiles_from_rev $$NEW_COMMIT new \
	   && exit 0

# With lots of eye candy; we like our developers pampered and spoiled :-)
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

# ---------------------------------------------- #
#  Help writing the announcement for a release.  #
# ---------------------------------------------- #

PACKAGE_MAILINGLIST = automake@gnu.org

announcement: NEWS
	$(AM_V_GEN): \
	  && rm -f $@ $@-t \
	  && $(determine_release_type) \
	  && ftp_base="ftp://$$dest.gnu.org/gnu/$(PACKAGE)" \
	  && X () { printf '%s\n' "$$*" >> $@-t; } \
	  && X "We are pleased to announce the $(PACKAGE_NAME) $(VERSION)" \
	       "$$announcement_type." \
	  && X \
	  && X "**TODO** Brief description of the release here." \
	  && X \
	  && X "**TODO** This description can span multiple paragraphs." \
	  && X \
	  && X "See below for the detailed list of changes since the" \
	  && X "previous version, as summarized by the NEWS file." \
	  && X \
	  && X "Download here:" \
	  && X \
	  && X "  $$ftp_base/$(PACKAGE)-$(VERSION).tar.gz" \
	  && X "  $$ftp_base/$(PACKAGE)-$(VERSION).tar.xz" \
	  && X \
	  && X "Please report bugs and problems to" \
	       "<$(PACKAGE_BUGREPORT)>," \
	  && X "and send general comments and feedback to" \
	       "<$(PACKAGE_MAILINGLIST)>." \
	  && X \
	  && X "Thanks to everyone who has reported problems, contributed" \
	  && X "patches, and helped testing Automake!" \
	  && X \
	  && X "-*-*-*-" \
	  && X \
	  && sed -n -e '/^~~~/q' -e p $(srcdir)/NEWS >> $@-t \
	  && mv -f $@-t $@
.PHONY: announcement
CLEANFILES += announcement

# --------------------------------------------------------------------- #
#  Synchronize third-party files that are committed in our repository.  #
# --------------------------------------------------------------------- #

# Program to use to fetch files.
WGET = wget

# Some repositories we sync files from.
SV_CVS    = 'http://savannah.gnu.org/cgi-bin/viewcvs/~checkout~/'
SV_GIT_CF = 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;hb=HEAD;f='
SV_GIT_AC = 'http://git.savannah.gnu.org/gitweb/?p=autoconf.git;a=blob_plain;hb=HEAD;f='
SV_GIT_GL = 'http://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=blob_plain;hb=HEAD;f='

# Files that we fetch and which we compare against.
# Note that the 'lib/COPYING' file must still be synced by hand.
FETCHFILES = \
  $(SV_GIT_CF)config.guess \
  $(SV_GIT_CF)config.sub \
  $(SV_CVS)texinfo/texinfo/doc/texinfo.tex \
  $(SV_CVS)texinfo/texinfo/util/gendocs.sh \
  $(SV_CVS)texinfo/texinfo/util/gendocs_template \
  $(SV_GIT_GL)build-aux/gitlog-to-changelog \
  $(SV_GIT_GL)build-aux/gnupload \
  $(SV_GIT_GL)build-aux/update-copyright \
  $(SV_GIT_GL)doc/INSTALL

# Fetch the latest versions of few scripts and files we care about.
# A retrieval failure or a copying failure usually mean serious problems,
# so we'll just bail out if 'wget' or 'cp' fail.
fetch:
	$(AM_V_at)rm -rf Fetchdir
	$(AM_V_at)mkdir Fetchdir
	$(AM_V_GEN)set -e; \
	if $(AM_V_P); then wget_opts=; else wget_opts=-nv; fi; \
	for url in $(FETCHFILES); do \
	   file=`printf '%s\n' "$$url" | sed 's|^.*/||; s|^.*=||'`; \
	   $(WGET) $$wget_opts "$$url" -O Fetchdir/$$file || exit 1; \
	   if cmp Fetchdir/$$file $(srcdir)/lib/$$file >/dev/null; then \
	     : Nothing to do; \
	   else \
	     echo "$@: updating file $$file"; \
	     cp Fetchdir/$$file $(srcdir)/lib/$$file || exit 1; \
	   fi; \
	done
	$(AM_V_at)rm -rf Fetchdir
.PHONY: fetch

# ---------------------------------------------------------------------- #
#  Generate and upload manuals in several formats, for the GNU website.  #
# ---------------------------------------------------------------------- #

web_manual_dir = doc/web-manual

RSYNC = rsync
CVS = cvs
CVSU = cvsu
CVS_USER = $${USER}
WEBCVS_ROOT = cvs.savannah.gnu.org:/web
CVS_RSH = ssh
export CVS_RSH

.PHONY: web-manual web-manual-update
web-manual web-manual-update: t = $@.dir

# Build manual in several formats.  Note to the recipe:
# 1. The symlinking of automake.texi into the temporary directory is
#    required to pacify extra checks from gendocs.sh.
# 2. The redirection to /dev/null before the invocation of gendocs.sh
#    is done to better respect silent rules.
web-manual:
	$(AM_V_at)rm -rf $(web_manual_dir) $t
	$(AM_V_at)mkdir $t
	$(AM_V_at)$(LN_S) '$(abs_srcdir)/doc/$(PACKAGE).texi' '$t/'
	$(AM_V_GEN)cd $t \
	  && GENDOCS_TEMPLATE_DIR='$(abs_srcdir)/lib' \
	  && export GENDOCS_TEMPLATE_DIR \
	  && if $(AM_V_P); then :; else exec >/dev/null 2>&1; fi \
	  && $(SHELL) '$(abs_srcdir)/lib/gendocs.sh' \
	     -I '$(abs_srcdir)/doc' --email $(PACKAGE_BUGREPORT) \
	     $(PACKAGE) '$(PACKAGE_NAME)'
	$(AM_V_at)mkdir $(web_manual_dir)
	$(AM_V_at)mv -f $t/manual/* $(web_manual_dir)
	$(AM_V_at)rm -rf $t
	@! $(AM_V_P) || ls -l $(web_manual_dir)

# Upload manual to www.gnu.org, using CVS (sigh!)
web-manual-update:
	$(AM_V_at)$(determine_release_type); \
	case $$release_type in \
	  [Mm]ajor\ release|[Mm]inor\ release);; \
	  *) echo "Cannot upload manuals from a \"$$release_type\"" >&2; \
	     exit 1;; \
	esac
	$(AM_V_at)test -f $(web_manual_dir)/$(PACKAGE).html || { \
	  echo 'You have to run "$(MAKE) web-manuals" before' \
	       'invoking "$(MAKE) $@"' >&2; \
	  exit 1; \
	}
	$(AM_V_at)rm -rf $t
	$(AM_V_at)mkdir $t
	$(AM_V_at)cd $t \
	  && $(CVS) -z3 -d :ext:$(CVS_USER)@$(WEBCVS_ROOT)/$(PACKAGE) \
	            co $(PACKAGE)
	@# According to the rsync manpage, "a trailing slash on the
	@# source [...] avoids creating an additional directory
	@# level at the destination".  So the trailing '/' after
	@# '$(web_manual_dir)' below is intended.
	$(AM_V_at)$(RSYNC) -avP $(web_manual_dir)/ $t/$(PACKAGE)/manual
	$(AM_V_GEN): \
	  && cd $t/$(PACKAGE)/manual \
	  && new_files=`$(CVSU) --types='?'` \
	  && new_files=`echo "$$new_files" | sed s/^..//` \
	  && { test -z "$$new_files" || $(CVS) add -ko $$new_files; } \
	  && $(CVS) ci -m $(VERSION)
	$(AM_V_at)rm -rf $t
.PHONY: web-manual-update

clean-web-manual:
	$(AM_V_at)rm -rf $(web_manual_dir)
.PHONY: clean-web-manual
clean-local: clean-web-manual

EXTRA_DIST += lib/gendocs.sh lib/gendocs_template

# ------------------------------------------------ #
#  Update copyright years of all committed files.  #
# ------------------------------------------------ #

EXTRA_DIST += lib/update-copyright

update_copyright_env = \
  UPDATE_COPYRIGHT_FORCE=1 \
  UPDATE_COPYRIGHT_USE_INTERVALS=2

# In addition to the several README files, these as well are
# not expected to have a copyright notice.
files_without_copyright = \
  .autom4te.cfg \
  .git-log-fix \
  .gitattributes \
  .gitignore \
  INSTALL \
  COPYING \
  AUTHORS \
  THANKS \
  lib/INSTALL \
  lib/COPYING

# This script is in the public domain.
files_without_copyright += lib/mkinstalldirs

# This script has an MIT-style license
files_without_copyright += lib/install-sh

.PHONY: update-copyright
update-copyright:
	$(AM_V_GEN)set -e; \
	current_year=`date +%Y` && test -n "$$current_year" \
	  || { echo "$@: cannot get current year" >&2; exit 1; }; \
	sed -i "/^RELEASE_YEAR=/s/=.*$$/=$$current_year/" \
	  bootstrap.sh configure.ac; \
	excluded_re=`( \
	  for url in $(FETCHFILES); do echo "$$url"; done \
	    | sed -e 's!^.*/!!' -e 's!^.*=!!' -e 's!^!lib/!' \
	  && for f in $(files_without_copyright); do echo $$f; done \
	) | sed -e '$$!s,$$,|,' | tr -d '\012\015'`; \
	$(GIT) ls-files \
	  | grep -Ev '(^|/)README$$' \
	  | grep -Ev "^($$excluded_re)$$" \
	  | $(update_copyright_env) xargs $(srcdir)/lib/$@
