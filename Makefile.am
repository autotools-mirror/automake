## Process this file with automake to create Makefile.in

AUTOMAKE_OPTIONS = gnits 1.4
MAINT_CHARSET = latin1

## We need `.' in SUBDIRS because we want `check' to build `.' before
## tests.
SUBDIRS = . m4 tests

bin_SCRIPTS = automake aclocal
info_TEXINFOS = automake.texi

amfiles = check.am clean-hdr.am clean-kr.am clean.am comp-vars.am \
compile.am data-clean.am data.am dejagnu.am depend.am depend2.am \
dist.am distdir.am dist-vars.am footer.am header-vars.am header.am \
java-clean.am java.am kr-extra.am library.am libs-clean.am libs.am \
libtool.am lisp-clean.am lisp.am ltlib-clean.am ltlib.am ltlibrary.am \
mans-vars.am mans.am multilib.am program.am progs-clean.am progs.am \
python.am python-clean.am remake-hdr.am remake.am scripts.am \
subdirs.am tags-clean.am tags.am texi-vers.am texinfos.am

dist_pkgdata_DATA = COPYING INSTALL texinfo.tex ansi2knr.c ansi2knr.1 \
$(amfiles)

## These must all be executable when installed.  However, if we use
## _SCRIPTS, then the program transform will be applied, which is not
## what we want.  So we make them executable by hand.
scriptdir = $(pkgdatadir)
dist_script_DATA = config.guess config.sub install-sh mdate-sh missing \
mkinstalldirs elisp-comp ylwrap acinstall depcomp compile py-compile

install-data-hook:
	@$(POST_INSTALL)
	@for prog in $(dist_script_DATA); do \
	  echo " chmod +x $(DESTDIR)$(scriptdir)/$$prog"; \
	  chmod +x $(DESTDIR)$(scriptdir)/$$prog; \
	done

TAGS_FILES = automake.in aclocal.in $(amfiles)

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' $(srcdir)/automake.texi
TAGS_DEPENDENCIES = automake.texi

## `test -x' is not portable.  So we use Perl instead.  If Perl
## doesn't exist, then this test is meaningless anyway.
installcheck-local:
	for file in $(dist_script_DATA); do \
	  $(PERL) -e "exit ! -x '$(pkgdatadir)/$$file';" || exit 1; \
	done

EXTRA_DIST = ChangeLog.1996 ChangeLog.1998

################################################################
##
## Everything past here is useful to the maintainer, but probably not
## to anybody else
##

# Some simple checks, and then ordinary check.  These are only really
# guaranteed to work on my machine.
maintainer-check: automake aclocal
## This check avoids accidental configure substitutions in the source.
## There are exactly 7 lines that should be modified.  This works out
## to 22 lines of diffs.
	@if test `diff $(srcdir)/automake.in automake | wc -l` -ne 22; then \
	  echo "found too many diffs between automake.in and automake"; 1>&2; \
	  diff -c $(srcdir)/automake.in automake; \
	  exit 1; \
	fi
## Syntax check with default Perl (on my machine, Perl 5).
	$(PERL) -c -w automake
	$(PERL) -c -w aclocal
## expect no instances of '${...}'.  However, $${...} is ok, since that
## is a shell construct, not a Makefile construct.
## The backslash in `$${' is needed for some versions of bash.
	@if fgrep '\$${' $(srcdir)/[a-z]*.am | \
	       fgrep -v '$$$$' | \
	       grep . ; then \
	  echo "Found too many uses of '\$${' in the lines above." 1>&2; \
	  exit 1;				\
	else :; fi
## Make sure all invocations of mkinstalldirs are correct.
	@if fgrep -n 'mkinstalldirs' $(srcdir)/[a-z]*.am | \
	      fgrep -v '$$(mkinstalldirs)' | \
	      grep . ; then \
	  echo "Found incorrect use of mkinstalldirs in the lines above" 1>&2; \
	  exit 1; \
	else :; fi
## We never want to use "undef", only "delete".
	@if grep -n -w undef $(srcdir)/automake.in; then \
	  echo "Found undef in automake.in; use delete instead" 1>&2; \
	  exit 1; \
	fi
## We never want split (/ /,...), only split (' ', ...).
	@if fgrep -n 'split (/ /' $(srcdir)/automake.in; then \
	  echo "Found bad split in the lines above." 1>&2; \
	  exit 1; \
	fi
## Look for cd within backquotes without CDPATH=:
	@if grep -n '` *cd ' $(srcdir)/automake.in $(srcdir)/*.am \
	      $(srcdir)/m4/*.m4; then \
	  echo "Consider setting CDPATH in the lines above" 1>&2; \
	  exit 1; \
	fi
## Using @_ in a scalar context is most probably a programming error.
	@if grep -Hn '[^) ] *= *@_' $(srcdir)/automake.in; then \
	  echo "Using @_ in a scalar context in the lines above." 1>&2; \
	  exit 1; \
	fi

# Tag before making distribution.  Also, don't make a distribution if
# checks fail.  Also, make sure the NEWS file is up-to-date.
cvs-dist: maintainer-check distcheck
	@if sed 1q $(srcdir)/NEWS | grep -e "$(VERSION)" > /dev/null; then :; else \
	  echo "NEWS not updated; not releasing" 1>&2; \
	  exit 1;				\
	fi
	cd $(srcdir) && cvs -q tag `echo "Release-$(VERSION)" | sed 's/\./-/g'`
	$(MAKE) dist

cvs-diff:
	thisver=`echo "Release-$(VERSION)" | sed 's/\./-/g'`; \
	if test -z "$$OLDVERSION"; then \
	  prevno=`echo "$(VERSION)" - 0.01 | bc | sed 's/^\./0./'`; \
	else prevno="$$OLDVERSION"; fi; \
	prevver=Release-`echo $$prevno | sed 's/\./-/g'`; \
	cvs -f rdiff -c -r $$prevver -r $$thisver $(PACKAGE) \
	    > $(PACKAGE)-$$prevno-$(VERSION).diff

## Check our path lengths.
path-check: distdir
	(cd $(distdir) && \
## FIXME there's got to be a better way!  pathchk should take the list
## of files on stdin, at least.
	  find . -print | xargs pathchk -p); \
	  status=$$?; \
	  chmod -R a+w $(distdir) > /dev/null 2>&1; rm -rf $(distdir); \
	  exit $$status
