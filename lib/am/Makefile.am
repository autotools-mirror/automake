bin_SCRIPTS = automake
TEXINFOS = automake.texi
# SUBDIRS = intl po
# CONFIG_HEADER = config.h

pkgdata_DATA = clean-kr.am clean.am compile-kr.am compile-vars.am \
compile.am data.am depend.am dist-subd-top.am \
dist-subd.am dist-vars.am dist.am footer.am header-vars.am \
kr-vars.am libraries-vars.am \
libraries.am library.am mans-vars.am \
program.am programs.am remake-hdr.am \
remake-subd.am remake.am scripts.am subdirs.am tags.am tags-subd.am \
tags-clean.am \
texi-clean.am texi-version.am texinfos-vars.am texinfos.am \
libraries-clean.am scripts-clean.am programs-clean.am data-clean.am \
COPYING INSTALL install-sh mdate-sh mkinstalldirs texinfo.tex

DIST_OTHER = automake.in

# Gross.
DIST_SUBDIRS = samples/cpio/*Makefile.am

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = automake.in --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' automake.texi

# Some simple checks:
# * syntax check with perl4 and perl5.
# * make sure the scripts don't use 'true'
# * expect exactly two instance of '${...}'
# These are only really guaranteed to work on my machine.
maintainer-check: automake
	@PERL@ -c -w automake
	@if grep '^[^#].*true' $(srcdir)/[a-z]*.am; then \
	  echo "can't use 'true' in GNU Makefile" 1>&2; \
	  exit 1;				\
	else :; fi
	@if test `fgrep '$${' $(srcdir)/[a-z]*.am | wc -l` -ne 2; then \
	  echo "found too many uses of '\$${'" 1>&2; \
	  exit 1;				\
	fi
	if test -f /usr/local/bin/perl4.036; then \
	  /usr/local/bin/perl4.036 -c -w automake; \
	else :; fi

automake: automake.in
	CONFIG_FILES=$@ CONFIG_HEADERS= ./config.status

# Tag before making distribution.  Also, don't make a distribution if
# checks fail.  Also, make sure the NEWS file is up-to-date.
cvs-dist: maintainer-check
	@if sed 1q NEWS | grep -e "$(VERSION)" > /dev/null; then :; else \
	  echo "NEWS not updated; not releasing" 1>&2; \
	  exit 1;				\
	fi
	cvs tag `echo "Release-$(VERSION)" | sed 's/\./-/g'`
	$(MAKE) dist
