## Process this file with automake to create Makefile.in

AUTOMAKE_OPTIONS = gnits
MAINT_CHARSET = latin1
PERL = @PERL@

SUBDIRS = tests m4

bin_SCRIPTS = automake aclocal
info_TEXINFOS = automake.texi

pkgdata_DATA = clean-kr.am clean.am compile-kr.am comp-vars.am \
compile.am data.am dejagnu.am depend.am depend2.am dist-vars.am footer.am \
header.am header-vars.am kr-extra.am libs.am library.am \
mans-vars.am program.am progs.am remake-hdr.am remake-subd.am \
remake.am scripts.am subdirs.am tags.am tags-subd.am tags-clean.am \
texi-vers.am texinfos.am libs-clean.am \
progs-clean.am data-clean.am COPYING INSTALL texinfo.tex ansi2knr.c \
ansi2knr.1 lisp.am lisp-clean.am

## These must all be executable when installed.
pkgdata_SCRIPTS = config.guess config.sub install-sh interlock mdate-sh \
mkinstalldirs elisp-comp ylwrap acinstall

EXTRA_DIST = acinstall $(pkgdata_DATA)

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = automake.in aclocal.in --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' automake.texi
TAGS_DEPENDENCIES = automake.in aclocal.in automake.texi

## `test -x' is not portable.  So we use Perl instead.  If Perl
## doesn't exist, then this test is meaningless anyway.
# Check to make sure some installed files are executable.
installcheck-local:
	for file in $(pkgdata_SCRIPTS); do \
	  $(PERL) -e "exit ! -x '$(pkgdatadir)/$$file';" || exit 1; \
	done

################################################################
##
## Everything past here is useful to the maintainer, but probably not
## to anybody else
##

# Some simple checks, and then ordinary check.  These are only really
# guaranteed to work on my machine.
maintainer-check: automake aclocal
## Syntax check with default Perl (on my machine, Perl 5).
	$(PERL) -c -w automake
	$(PERL) -c -w aclocal
## Ensure `true' is never used; I've accidentally used it before.
	@if grep '^[^#].*true' $(srcdir)/[a-z]*.am; then \
	  echo "can't use 'true' in GNU Makefile" 1>&2; \
	  exit 1;				\
	else :; fi
## expect no instances of '${...}'.  However, $${...} is ok, since that
## is a shell construct, not a Makefile construct.
	@if test `fgrep '$${' $(srcdir)/[a-z]*.am | fgrep -v '$$$$' | wc -l` -ne 0; then \
	  echo "found too many uses of '\$${'" 1>&2; \
	  exit 1;				\
	else :; fi
## Make sure all invocations of mkinstalldirs are correct.
	@if test `fgrep 'mkinstalldirs' $(srcdir)/[a-z]*.am | fgrep -v '$$(mkinstalldirs)' | wc -l` -ne 0; then \
	  echo "found incorrect use of mkinstalldirs" 1>&2; \
	  exit 1; \
	else :; fi
## Another syntax check, this time with Perl 4, if it exists.
	@if $(SHELL) -c 'perl4.036 -v' >/dev/null 2>&1; then \
	  perl4.036 -c -w automake; \
	  perl4.036 -c -w aclocal; \
	else :; fi

# Tag before making distribution.  Also, don't make a distribution if
# checks fail.  Also, make sure the NEWS file is up-to-date.
cvs-dist: maintainer-check distcheck
	@if sed 1q $(srcdir)/NEWS | grep -e "$(VERSION)" > /dev/null; then :; else \
	  echo "NEWS not updated; not releasing" 1>&2; \
	  exit 1;				\
	fi
	cvs -q tag `echo "Release-$(VERSION)" | sed 's/\./-/g'`
	$(MAKE) dist

cvs-diff:
	thisver=`echo "Release-$(VERSION)" | sed 's/\./-/g'`; \
	prevno=`echo "$(VERSION)" - 0.01 | bc | sed 's/^\./0./'`; \
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
	  rm -rf $(distdir); \
	  exit $$status
