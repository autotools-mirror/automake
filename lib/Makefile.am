## Process this file with automake to create Makefile.in

SUBDIRS = Automake am

dist_pkgdata_DATA = COPYING INSTALL texinfo.tex ansi2knr.c ansi2knr.1

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

## `test -x' is not portable.  So we use Perl instead.  If Perl
## doesn't exist, then this test is meaningless anyway.
installcheck-local:
	for file in $(dist_script_DATA); do \
	  $(PERL) -e "exit ! -x '$(pkgdatadir)/$$file';" || exit 1; \
	done
