## Process this file with automake to create Makefile.in

AUTOMAKE_OPTIONS = gnits
MAINT_CHARSET = latin1
PERL = @PERL@

SUBDIRS = tests

bin_SCRIPTS = automake
info_TEXINFOS = automake.texi
# SUBDIRS = intl po
# CONFIG_HEADER = config.h

pkgdata_DATA = clean-kr.am clean.am compile-kr.am compile-vars.am \
compile.am data.am dejagnu.am depend.am dist-vars.am footer.am \
header.am header-vars.am kr-vars.am libraries.am library.am \
mans-vars.am program.am programs.am remake-hdr.am remake-subd.am \
remake.am scripts.am subdirs.am tags.am tags-subd.am tags-clean.am \
texi-version.am texinfos-vars.am texinfos.am libraries-clean.am \
programs-clean.am data-clean.am COPYING INSTALL texinfo.tex ansi2knr.c \
ansi2knr.1 aclocal.m4

## These must all be executable when installed.
pkgdata_SCRIPTS = config.guess config.sub install-sh mdate-sh mkinstalldirs

CLEANFILES = automake

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = automake.in --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' automake.texi
TAGS_DEPENDENCIES = automake.in automake.texi

## `test -x' is not portable.  So we use Perl instead.  If Perl
## doesn't exist, then this test is meaningless anyway.
# Check to make sure some installed files are executable.
installcheck-local:
	$(PERL) -e "exit ! -x '$(pkgdatadir)/config.guess';"
	$(PERL) -e "exit ! -x '$(pkgdatadir)/config.sub';"
	$(PERL) -e "exit ! -x '$(pkgdatadir)/install-sh';"
	$(PERL) -e "exit ! -x '$(pkgdatadir)/mdate-sh';"
	$(PERL) -e "exit ! -x '$(pkgdatadir)/mkinstalldirs';"

# Some simple checks:
# * syntax check with perl4 and perl5.
# * make sure the scripts don't use 'true'
# * expect no instances of '${...}'
# These are only really guaranteed to work on my machine.
maintainer-check: automake
## Do syntax, etc, checks before make check.
	$(PERL) -c -w automake
	@if grep '^[^#].*true' $(srcdir)/[a-z]*.am; then \
	  echo "can't use 'true' in GNU Makefile" 1>&2; \
	  exit 1;				\
	else :; fi
	@if test `fgrep '$${' $(srcdir)/[a-z]*.am | wc -l` -ne 0; then \
	  echo "found too many uses of '\$${'" 1>&2; \
	  exit 1;				\
	fi
	if $(SHELL) -c 'perl4.036 -v' >/dev/null 2>&1; then \
	  perl4.036 -c -w automake; \
	else :; fi
	$(MAKE) check

# Tag before making distribution.  Also, don't make a distribution if
# checks fail.  Also, make sure the NEWS file is up-to-date.
cvs-dist: maintainer-check
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
