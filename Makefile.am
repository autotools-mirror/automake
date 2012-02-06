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
	cd $(distdir)/tests && chmod a+rx *.test

# Some simple checks, and then ordinary check.  These are only really
# guaranteed to work on my machine.
syntax_check_rules = \
sc_test_names \
sc_diff_automake_in_automake \
sc_diff_aclocal_in_automake \
sc_perl_syntax \
sc_no_brace_variable_expansions \
sc_rm_minus_f \
sc_no_for_variable_in_macro \
sc_mkinstalldirs \
sc_pre_normal_post_install_uninstall \
sc_perl_no_undef \
sc_perl_no_split_regex_space \
sc_cd_in_backquotes \
sc_cd_relative_dir \
sc_perl_at_uscore_in_scalar_context \
sc_perl_local_no_parens \
sc_perl_local \
sc_AMDEP_TRUE_in_automake_in \
sc_tests_make_without_am_makeflags \
sc_tests_plain_make \
sc_tests_plain_autoconf \
sc_tests_plain_autoupdate \
sc_tests_plain_automake \
sc_tests_plain_autom4te \
sc_tests_plain_autoheader \
sc_tests_plain_autoreconf \
sc_tests_here_document_format \
sc_tests_Exit_not_exit \
sc_tests_automake_fails \
sc_tests_plain_aclocal \
sc_tests_plain_perl \
sc_tests_required_after_defs \
sc_tests_overriding_macros_on_cmdline \
sc_tests_plain_sleep \
sc_tests_plain_egrep_fgrep \
sc_tests_PATH_SEPARATOR \
sc_mkdir_p \
sc_perl_at_substs \
sc_unquoted_DESTDIR \
sc_tabs_in_texi \
sc_at_in_texi

$(syntax_check_rules): automake aclocal
maintainer-check: $(syntax_check_rules)
.PHONY: maintainer-check $(syntax_check_rules)

## Check that the list of tests given in the Makefile is equal to the
## list of all test scripts in the Automake testsuite.
.PHONY: maintainer-check-list-of-tests
maintainer-check-list-of-tests:
	$(am__cd) tests && $(MAKE) $(AM_MAKEFLAGS) $@
maintainer-check: maintainer-check-list-of-tests

## Look for test whose names can cause spurious failures when used as
## first argument to AC_INIT (chiefly because they might contain an
## m4/m4sugar builtin or macro name).
m4_builtins = \
  __gnu__ \
  __unix__ \
  bpatsubst \
  bregexp \
  builtin \
  changecom \
  changequote \
  changeword \
  debugfile \
  debugmode \
  decr \
  define \
  defn \
  divert \
  divnum \
  dnl \
  dumpdef \
  errprint \
  esyscmd \
  eval \
  format \
  ifdef \
  ifelse \
  include \
  incr \
  index \
  indir \
  len \
  m4exit \
  m4wrap \
  maketemp \
  mkstemp \
  patsubst \
  popdef \
  pushdef \
  regexp \
  shift \
  sinclude \
  substr \
  symbols \
  syscmd \
  sysval \
  traceoff \
  traceon \
  translit \
  undefine \
  undivert
sc_test_names:
	@m4_builtin_rx=`echo $(m4_builtins) | sed 's/ /|/g'`; \
	 m4_macro_rx="\\<($$m4_builtin_rx)\\>|\\<_?(A[CUMHS]|m4)_"; \
	 if ls tests/*.test | LC_ALL=C grep -E "$$m4_macro_rx"; then \
	   echo "the names of the tests above can be problematic" 1>&2; \
	   echo "Avoid test names that contain names of m4 macros" 1>&2; \
	   exit 1; \
	 fi

## These check avoids accidental configure substitutions in the source.
## There are exactly 9 lines that should be modified from automake.in to
## automake, and 10 lines that should be modified from aclocal.in to
## aclocal; these wors out to 32 and 34 lines of diffs, respectively.
sc_diff_automake_in_automake:
	@if test `diff $(srcdir)/automake.in automake | wc -l` -ne 32; then \
	  echo "found too many diffs between automake.in and automake" 1>&2; \
	  diff -c $(srcdir)/automake.in automake; \
	  exit 1; \
	fi
sc_diff_aclocal_in_aclocal:
	@if test `diff $(srcdir)/aclocal.in aclocal | wc -l` -ne 34; then \
	  echo "found too many diffs between aclocal.in and aclocal" 1>&2; \
	  diff -c $(srcdir)/aclocal.in aclocal; \
	  exit 1; \
	fi

## Syntax check with default Perl (on my machine, Perl 5).
sc_perl_syntax:
	@perllibdir="./lib$(PATH_SEPARATOR)$(srcdir)/lib" $(PERL) -c -w automake
	@perllibdir="./lib$(PATH_SEPARATOR)$(srcdir)/lib" $(PERL) -c -w aclocal

## expect no instances of '${...}'.  However, $${...} is ok, since that
## is a shell construct, not a Makefile construct.
sc_no_brace_variable_expansions:
	@if grep -F '$${' $(srcdir)/lib/am/[a-z]*.am | \
	       grep -F -v '$$$$'; then \
	  echo "Found too many uses of '\$${' in the lines above." 1>&2; \
	  exit 1;				\
	else :; fi

## Make sure `rm' is called with `-f'.
sc_rm_minus_f:
	@if grep -v '^#' $(srcdir)/lib/am/[a-z]*.am $(srcdir)/tests/*.test | \
	    grep -E '\<rm ([^-]|\-[^f ]*\>)'; then \
	  echo "Suspicious 'rm' invocation." 1>&2; \
	  exit 1;				\
	else :; fi

## Never use something like `for file in $(FILES)', this doesn't work
## if FILES is empty or if it contains shell meta characters (e.g. $ is
## commonly used in Java filenames).
sc_no_for_variable_in_macro:
	@if grep 'for .* in \$$(' $(srcdir)/lib/am/[a-z]*.am; then \
	  echo 'Use "list=$$(mumble); for var in $$$$list".' 1>&2 ; \
	  exit 1; \
	else :; fi

## Make sure all invocations of mkinstalldirs are correct.
sc_mkinstalldirs:
	@if grep -n 'mkinstalldirs' $(srcdir)/lib/am/[a-z]*.am | \
	      grep -F -v '$$(mkinstalldirs)'; then \
	  echo "Found incorrect use of mkinstalldirs in the lines above" 1>&2; \
	  exit 1; \
	else :; fi

## Make sure all calls to PRE/NORMAL/POST_INSTALL/UNINSTALL
sc_pre_normal_post_install_uninstall:
	@if grep -E -n '\((PRE|NORMAL|POST)_(|UN)INSTALL\)' \
                 $(srcdir)/lib/am/[a-z]*.am | \
	      grep -v ':##' | grep -v ':	@\$$('; then \
	  echo "Found incorrect use of PRE/NORMAL/POST_INSTALL/UNINSTALL in the lines above" 1>&2; \
	  exit 1; \
	else :; fi

## We never want to use "undef", only "delete", but for $/.
sc_perl_no_undef:
	@if grep -n -w 'undef ' $(srcdir)/automake.in | \
	      grep -F -v 'undef $$/'; then \
	  echo "Found undef in automake.in; use delete instead" 1>&2; \
	  exit 1; \
	fi

## We never want split (/ /,...), only split (' ', ...).
sc_perl_no_split_regex_space:
	@if grep -n 'split (/ /' $(srcdir)/automake.in; then \
	  echo "Found bad split in the lines above." 1>&2; \
	  exit 1; \
	fi

## Look for cd within backquotes
sc_cd_in_backquotes:
	@if grep -n '^[^#]*` *cd ' $(srcdir)/automake.in \
	      $(srcdir)/lib/am/*.am; then \
	  echo "Consider using \$$(am__cd) in the lines above." 1>&2; \
	  exit 1; \
	fi

## Look for cd to a relative directory (may be influenced by CDPATH).
## Skip some known directories that are OK.
sc_cd_relative_dir:
	@if grep -n '^[^#]*cd ' $(srcdir)/automake.in \
	      $(srcdir)/lib/am/*.am | \
	      grep -v 'echo.*cd ' | \
	      grep -v 'am__cd =' | \
	      grep -v '^[^#]*cd [./]' | \
	      grep -v '^[^#]*cd \$$(top_builddir)' | \
	      grep -v '^[^#]*cd "\$$\$$am__cwd' | \
	      grep -v '^[^#]*cd \$$(abs' | \
	      grep -v '^[^#]*cd "\$$(DESTDIR)'; then \
	  echo "Consider using \$$(am__cd) in the lines above." 1>&2; \
	  exit 1; \
	fi

## Using @_ in a scalar context is most probably a programming error.
sc_perl_at_uscore_in_scalar_context:
	@if grep -Hn '[^@_A-Za-z0-9][_A-Za-z0-9]*[^) ] *= *@_' $(srcdir)/automake.in; then \
	  echo "Using @_ in a scalar context in the lines above." 1>&2; \
	  exit 1; \
	fi

## Forbid using parens with `local' to ease counting.
sc_perl_local_no_parens:
	@if grep '^[ \t]*local *(' $(srcdir)/automake.in; then \
	  echo "Don't use \`local' with parens: use several \`local' above." >&2; \
	  exit 1; \
	fi

## Allow only few variables to be localized in Automake.
sc_perl_local:
	@if egrep -v '^[ \t]*local \$$[_~]( *=|;)' $(srcdir)/automake.in | \
	        grep '^[ \t]*local [^*]'; then \
	  echo "Please avoid \`local'." 1>&2; \
	  exit 1; \
	fi

## Don't let AMDEP_TRUE substitution appear in automake.in.
sc_AMDEP_TRUE_in_automake_in:
	@if grep '@AMDEP''_TRUE@' $(srcdir)/automake.in; then \
	  echo "Don't put AMDEP_TRUE substitution in automake.in" 1>&2; \
	  exit 1; \
	fi

## Recursive make invocations should always pass $(AM_MAKEFLAGS)
## to $(MAKE), for portability to non-GNU make.
sc_tests_make_without_am_makeflags:
	@if grep '^[^#].*(MAKE) ' $(srcdir)/lib/am/*.am $(srcdir)/automake.in |\
		grep -v 'AM_MAKEFLAGS'; then \
	  echo 'Use $$(MAKE) $$(AM_MAKEFLAGS).' 1>&2; \
	  exit 1; \
	fi

## Tests should never call make directly.
sc_tests_plain_make:
	@if grep -v '^#' $(srcdir)/tests/*.test | $(EGREP) ':[ 	]*make( |$$)'; then \
	  echo 'Do not run "make" in the above tests.  Use "$$MAKE" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call autoconf directly.
sc_tests_plain_autoconf:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*autoconf\>'; then \
	  echo 'Do not run "autoconf" in the above tests.  Use "$$AUTOCONF" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call autoupdate directly.
sc_tests_plain_autoupdate:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*autoupdate\>'; then \
	  echo 'Do not run "autoupdate" in the above tests.  Use "$$AUTOUPDATE" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call automake directly.
sc_tests_plain_automake:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep -E ':[	]*automake\>([^:]|$$)'; then \
	  echo 'Do not run "automake" in the above tests.  Use "$$AUTOMAKE" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autoheader directly.
sc_tests_plain_autoheader:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*autoheader\>'; then \
	  echo 'Do not run "automake" in the above tests.  Use "$$AUTOHEADER" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autoreconf directly.
sc_tests_plain_autoreconf:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*autoreconf\>'; then \
	  echo 'Do not run "automake" in the above tests.  Use "$$AUTORECONF" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autom4te directly.
sc_tests_plain_autom4te:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*autom4te\>'; then \
	  echo 'Do not run "automake" in the above tests.  Use "$$AUTOM4TE" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should only use END and EOF for here documents
## (so that the next test is effective).
sc_tests_here_document_format:
	@if grep '<<' $(srcdir)/tests/*.test | grep -v 'END' | grep -v 'EOF'; then \
	  echo 'Use here documents with "END" and "EOF" only, for greppability.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call exit directly, but use Exit.
## This is so that the exit status is transported correctly across the 0 trap.
## Ignore comments, testsuite self tests, and one perl line in ext2.test.
sc_tests_Exit_not_exit:
	@found=false; for file in $(srcdir)/tests/*.test; do \
	  case $$file in */self-check-*.test) continue;; esac; \
	  res=`sed -n -e '/^#/d; /^\$$PERL/d' -e '/<<.*END/,/^END/b' \
		      -e '/<<.*EOF/,/^EOF/b' -e '/exit [$$0-9]/p' $$file`; \
	  if test -n "$$res"; then \
	    echo "$$file:$$res"; \
	    found=true; \
	  fi; \
	done; \
	if $$found; then \
	  echo 'Do not call plain "exit", use "Exit" instead, in above tests.' 1>&2; \
	  exit 1; \
	fi

## Use AUTOMAKE_fails when appropriate
sc_tests_automake_fails:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep '\$$AUTOMAKE.*&&.*[eE]xit'; then \
	  echo 'Use AUTOMAKE_fails + grep to catch automake failures in the above tests.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call aclocal directly.
sc_tests_plain_aclocal:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*aclocal\>'; then \
	  echo 'Do not run "aclocal" in the above tests.  Use "$$ACLOCAL" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call perl directly.
sc_tests_plain_perl:
	@if grep -v '^#' $(srcdir)/tests/*.test | grep ':[	]*perl\>'; then \
	  echo 'Do not run "perl" in the above tests.  Use "$$PERL" instead.' 1>&2; \
	  exit 1; \
	fi

## Setting `required' after sourcing `./defs' is a bug.
sc_tests_required_after_defs:
	@for file in $(srcdir)/tests/*.test; do \
	  if out=`sed -n '/defs/,$${/required=/p;}' $$file`; test -n "$$out"; then \
	    echo 'Do not set "required" after sourcing "defs" in '"$$file: $$out" 1>&2; \
	    exit 1; \
	  fi; \
	done

## Overriding a Makefile macro on the command line is not portable when
## recursive targets are used.  Better use an envvar.  SHELL is an
## exception, POSIX says it can't come from the environment.  V, DESTDIR,
## DISTCHECK_CONFIGURE_FLAGS and DISABLE_HARD_ERRORS are exceptions, too,
## as package authors are urged not to initialize them anywhere.
sc_tests_overriding_macros_on_cmdline:
	@if grep -E '\$$MAKE .*(SHELL=.*=|=.*SHELL=)' $(srcdir)/tests/*.test; then \
	  echo 'Rewrite "$$MAKE foo=bar SHELL=$$SHELL" as "foo=bar $$MAKE -e SHELL=$$SHELL"' 1>&2; \
	  echo ' in the above lines, it is more portable.' 1>&2; \
	  exit 1; \
	fi
## Also try to account for usages like "$MAKE || st=$?".
	@if sed -e 's/ || .*//' -e 's/ && .*//' \
	        -e 's/ DESTDIR=[^ ]*/ /' -e 's/ SHELL=[^ ]*/ /' \
	        -e 's/ V=[^ ]*/ /' -e 's/ DISABLE_HARD_ERRORS=[^ ]*/ /' \
## DISTCHECK_CONFIGURE_FLAGS is allowed to contain whitespace in its
## definition, so the more complex substitutions below.
	        -e "s/ DISTCHECK_CONFIGURE_FLAGS='[^']*'/ /" \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS="[^"]*"/ /' \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS=[^ ]/ /' \
	      $(srcdir)/tests/*.test | grep '\$$MAKE .*='; then \
	  echo 'Rewrite "$$MAKE foo=bar" as "foo=bar $$MAKE -e" in the above lines,' 1>&2; \
	  echo 'it is more portable.' 1>&2; \
	  exit 1; \
	fi
	@if grep 'SHELL=.*\$$MAKE' $(srcdir)/tests/*.test; then \
	  echo '$$MAKE ignores the SHELL envvar, use "$$MAKE SHELL=$$SHELL" in' 1>&2; \
	  echo 'the above lines.' 1>&2; \
	  exit 1; \
	fi

## Never use `sleep 1' to create files with different timestamps.
## Use `$sleep' instead.  Some filesystems (e.g., Windows') have only
## a 2sec resolution.
sc_tests_plain_sleep:
	@if grep -E '\bsleep +[12345]\b' $(srcdir)/tests/*.test; then \
	  echo 'Do not use "sleep x" in the above tests.  Use "$$sleep" instead.' 1>&2; \
	  exit 1; \
	fi

## fgrep and egrep are not required by POSIX.
sc_tests_plain_egrep_fgrep:
	@if grep -E '\b[ef]grep\b' $(srcdir)/tests/*.test ; then \
	  echo 'Do not use egrep or fgrep in test cases.  Use $$FGREP or $$EGREP.' 1>&2; \
	  exit 1; \
	fi
	@if grep -E '\b[ef]grep\b' $(srcdir)/lib/am/*.am $(srcdir)/m4/*.m4; then \
	  echo 'Do not use egrep or fgrep in the above files, they are not portable.' 1>&2; \
	  exit 1; \
	fi

## Using `:' as a PATH separator is not portable.
sc_tests_PATH_SEPARATOR:
	@if grep -E '\bPATH=.*:.*' $(srcdir)/tests/*.test ; then \
	  echo "Use \`\$$PATH_SEPARATOR', not \`:', in PATH definitions above." 1>&2; \
	  exit 1; \
	fi

sc_mkdir_p:
	@if grep 'mkdir_p' $(srcdir)/automake.in \
	      $(srcdir)/lib/am/*.am $(srcdir)/tests/*.test; then \
	  echo 'Do not use mkdir_p in the above files, use MKDIR_P.' 1>&2; \
	  exit 1; \
	fi

## Try to make sure all @...@ substitutions are covered by our
## substitution rule.
sc_perl_at_substs:
	@if test `grep -E '^[^#]*@[A-Za-z_0-9]+@' aclocal | wc -l` -ne 0; then \
	  echo "Unresolved @...@ substitution in aclocal" 1>&2; \
	  exit 1; \
	fi
	@if test `grep -E '^[^#]*@[A-Za-z_0-9]+@' automake | wc -l` -ne 0; then \
	  echo "Unresolved @...@ substitution in automake" 1>&2; \
	  exit 1; \
	fi

sc_unquoted_DESTDIR:
	@if grep -E "[^\'\"]\\\$$\(DESTDIR" $(srcdir)/lib/am/*.am; then \
	  echo 'Suspicious unquoted DESTDIR uses.' 1>&2 ; \
	  exit 1; \
	fi

sc_tabs_in_texi:
	@if grep '	' $(srcdir)/doc/automake.texi; then \
	  echo 'Do not use tabs in the manual.' 1>&2; \
	  exit 1; \
	fi

sc_at_in_texi:
	@if grep -E '([^@]|^)@([	 ][^@]|$$)' $(srcdir)/doc/automake.texi; \
	then \
	  echo 'Unescaped @.' 1>&2; \
	  exit 1; \
	fi

## Tagging and/or uploading stable and beta releases.

GIT = git

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
## The 'lib/COPYING' file must still be synced by hand.
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
	(cd Fetchdir && \
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
	    echo "Updating $(srcdir)/lib/$$file..."; \
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
	doc_text=`cd doc && LC_ALL=C pstops 0 automake.ps unused.ps 2>&1` && \
	echo "$$doc_text" && \
	rm -f doc/unused.ps && \
	doc=`echo "$$doc_text" | sed -n 's/.*Wrote \([1-9][0-9]*\) pages.*/\1/p'` && \
	tests="tests/*.test"; \
	if test . != '$(srcdir)'; then tests="$$tests $(srcdir)/tests/*.test"; \
	else :; fi && \
	t=`ls -1 $$tests | wc -l` && \
	tgen=`ls -1 $$tests | grep '.-p\.test' | wc -l` && \
	today=`date +%Y-%m-%d` && \
	echo "add this to the table in doc/automake.texi after verification:" && \
	printf '@item %s @tab %-6s @tab %4d @tab %4d @tab %4d @tab %4d %-4s @tab %4d %-4s @tab %3d @tab %d %-4s\n' \
	              $$today $(VERSION) $$am    $$acl    $$pm   $$aml "($$amf)" $$m4l "($$m4f)" $$doc $$t "($$tgen)"
.PHONY: release-stats
