## Process this file with automake to create Makefile.in

AUTOMAKE_OPTIONS = 1.4 dist-bzip2

## We need `.' in SUBDIRS because we want `check' to build `.' before
## tests.
SUBDIRS = . m4 lib tests

bin_SCRIPTS = automake aclocal
info_TEXINFOS = automake.texi


TAGS_FILES = automake.in aclocal.in

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' $(srcdir)/automake.texi
TAGS_DEPENDENCIES = automake.texi

EXTRA_DIST = ChangeLog.1996 ChangeLog.1998 ChangeLog.2000

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
	@if test `diff $(srcdir)/automake.in automake | wc -l` -ne 28; then \
	  echo "found too many diffs between automake.in and automake"; 1>&2; \
	  diff -c $(srcdir)/automake.in automake; \
	  exit 1; \
	fi
## Syntax check with default Perl (on my machine, Perl 5).
	perllibdir=$(srcdir)/lib $(PERL) -c -w automake
	perllibdir=$(srcdir)/lib $(PERL) -c -w aclocal
## expect no instances of '${...}'.  However, $${...} is ok, since that
## is a shell construct, not a Makefile construct.
## The backslash in `$${' is needed for some versions of bash.
	@if fgrep '\$${' $(srcdir)/lib/am/[a-z]*.am | \
	       fgrep -v '$$$$'; then \
	  echo "Found too many uses of '\$${' in the lines above." 1>&2; \
	  exit 1;				\
	else :; fi
## Make sure `rm' is called with `-f'.
	@if egrep '\<rm ([^-]|\-[^f ]*\>)' \
	          $(srcdir)/lib/am/[a-z]*.am $(srcdir)/tests/*.test | \
	      fgrep -v '##'; then \
	  echo "Suspicious 'rm' invocation." 1>&2; \
	  exit 1;				\
	else :; fi
## Make sure all invocations of mkinstalldirs are correct.
	@if fgrep -n 'mkinstalldirs' $(srcdir)/lib/am/[a-z]*.am | \
	      fgrep -v '$$(mkinstalldirs)'; then \
	  echo "Found incorrect use of mkinstalldirs in the lines above" 1>&2; \
	  exit 1; \
	else :; fi
## We never want to use "undef", only "delete", but for $/.
	@if grep -n -w 'undef ' $(srcdir)/automake.in | \
	      fgrep -v 'undef $$/'; then \
	  echo "Found undef in automake.in; use delete instead" 1>&2; \
	  exit 1; \
	fi
## We never want split (/ /,...), only split (' ', ...).
	@if fgrep -n 'split (/ /' $(srcdir)/automake.in; then \
	  echo "Found bad split in the lines above." 1>&2; \
	  exit 1; \
	fi
## Look for cd within backquotes without CDPATH=:
	@if grep -n '^[^#]*` *cd ' $(srcdir)/automake.in \
	      $(srcdir)/lib/am/*.am $(srcdir)/m4/*.m4; then \
	  echo "Consider setting CDPATH in the lines above" 1>&2; \
	  exit 1; \
	fi
## Using @_ in a scalar context is most probably a programming error.
	@if grep -Hn '[^) ] *= *@_' $(srcdir)/automake.in; then \
	  echo "Using @_ in a scalar context in the lines above." 1>&2; \
	  exit 1; \
	fi
## Forbid using parens with `local' to ease counting.
	@if grep '^[ \t]*local *(' $(srcdir)/automake.in; then \
	  echo "Don't use \`local' with parens: use several \`local' above." >&2; \
	  exit 1; \
	fi
## Up to now we manage to limit to 1 use of local.
	@locals=`grep -c '^[ \t]*local [^*]' $(srcdir)/automake.in`; \
	case $$locals in \
	  [0] ) \
	    echo "Wow, congrats!  There are no \`local' now!." >&2; \
	    echo "Please update Makefile.am (maintainer-check)." >&2; \
	    exit 1; \
	  ;; \
	  1 ) ;; \
	  * ) \
	    echo "Too many \`local'!  Are you sure you need $$locals of them?" >&2; \
	    echo "Up to now 1 was enough." >&2; \
	    exit 1; \
	  ;; \
	esac
## Don't let AMDEP_TRUE substitution appear in automake.in.
	@if grep '@AMDEP''_TRUE@' $(srcdir)/automake.in; then \
	  echo "Don't put AMDEP_TRUE substitution in automake.in" 1>&2; \
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

## Program to use to fetch files.
WGET = wget

## Files that we fetch and which we compare against.
## FIXME should be a lot more here
## Sadly we can't fetch ansi2knr.1 from the same location :-(
FETCHFILES = config.guess config.sub ansi2knr.c

## Fetch the latest versions of files we care about.
fetch:
	rm -rf Fetchdir > /dev/null 2>&1
	mkdir Fetchdir
## If a get fails then that is a problem.
	(cd Fetchdir && \
	$(WGET) ftp://ftp.gnu.org/gnu/config/config.guess; \
	$(WGET) ftp://ftp.gnu.org/gnu/config/config.sub; \
	$(WGET) ftp://ftp.cs.wisc.edu/ghost/ansi2knr.c)
## Don't exit after test because we want to give as many errors as
## possible.
	@stat=0; for file in $(FETCHFILES); do \
	  if diff $(srcdir)/lib/$$file Fetchdir/$$file > /dev/null 2>&1; then :; \
	  else \
	    stat=1; \
	    echo "install Fetchdir/$$file into srcdir and commit"; \
	  fi; \
	done; exit $$stat
