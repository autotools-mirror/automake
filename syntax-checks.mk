# Maintainer checks for Automake.  Requires GNU make.

# Copyright (C) 2012 Free Software Foundation, Inc.
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

# We also have to take into account VPATH builds (where some generated
# tests might be in '$(builddir)' rather than in '$(srcdir)'), TAP-based
# tests script (which have a '.tap' extension) and helper scripts used
# by other test cases (which have a '.sh' extension).
xtests := $(shell \
  if test $(srcdir) = .; then \
     dirs=.; \
   else \
     dirs='$(srcdir) .'; \
   fi; \
   for d in $$dirs; do \
     for s in tap sh; do \
       ls $$d/t/ax/*.$$s $$d/t/*.$$s $$d/contrib/t/*.$$s 2>/dev/null; \
     done; \
   done | sort)

xdefs = \
  $(srcdir)/t/ax/am-test-lib.sh \
  $(srcdir)/t/ax/test-lib.sh \
  $(srcdir)/t/ax/test-defs.in

ams := $(shell find $(srcdir) -name '*.dir' -prune -o -name '*.am' -print)

# Some simple checks, and then ordinary check.  These are only really
# guaranteed to work on my machine.
syntax_check_rules = \
$(sc_tests_plain_check_rules) \
sc_diff_automake \
sc_diff_aclocal \
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
sc_perl_local \
sc_AMDEP_TRUE_in_automake_in \
sc_tests_make_without_am_makeflags \
$(sc_obsolete_requirements_rules) \
sc_tests_no_source_defs \
sc_tests_obsolete_variables \
sc_tests_here_document_format \
sc_tests_command_subst \
sc_tests_exit_not_Exit \
sc_tests_automake_fails \
sc_tests_required_after_defs \
sc_tests_overriding_macros_on_cmdline \
sc_tests_plain_sleep \
sc_tests_ls_t \
sc_tests_executable \
sc_m4_am_plain_egrep_fgrep \
sc_tests_no_configure_in \
sc_tests_PATH_SEPARATOR \
sc_tests_logs_duplicate_prefixes \
sc_tests_makefile_variable_order \
sc_perl_at_substs \
sc_unquoted_DESTDIR \
sc_tabs_in_texi \
sc_at_in_texi

## These check avoids accidental configure substitutions in the source.
## There are exactly 8 lines that should be modified from automake.in to
## automake, and 9 lines that should be modified from aclocal.in to
## aclocal.
automake_diff_no = 8
aclocal_diff_no = 9
sc_diff_automake sc_diff_aclocal: sc_diff_% :
	@set +e; tmp=$*-diffs.tmp; \
	 diff -u $(srcdir)/$*.in $* > $$tmp; test $$? -eq 1 || exit 1; \
	 added=`grep -v '^+++ ' $$tmp | grep -c '^+'` || exit 1; \
	 removed=`grep -v '^--- ' $$tmp | grep -c '^-'` || exit 1; \
	 test $$added,$$removed = $($*_diff_no),$($*_diff_no) \
	  || { \
	    echo "Found unexpected diffs between $*.in and $*"; \
	    echo "Lines added:   $$added"  ; \
	    echo "Lines removed: $$removed"; \
	    cat $$tmp >&2; \
	    exit 1; \
	  } >&1; \
	rm -f $$tmp

## Expect no instances of '${...}'.  However, $${...} is ok, since that
## is a shell construct, not a Makefile construct.
sc_no_brace_variable_expansions:
	@if grep -v '^ *#' $(ams) | grep -F '$${' | grep -F -v '$$$$'; then \
	  echo "Found too many uses of '\$${' in the lines above." 1>&2; \
	  exit 1;				\
	else :; fi

## Make sure 'rm' is called with '-f'.
sc_rm_minus_f:
	@if grep -v '^#' $(ams) $(xtests) \
	   | grep -vE '/(spy-rm\.tap|subobj-clean.*-pr10697\.sh):' \
	   | grep -E '\<rm ([^-]|\-[^f ]*\>)'; \
	then \
	  echo "Suspicious 'rm' invocation." 1>&2; \
	  exit 1;				\
	else :; fi

## Never use something like "for file in $(FILES)", this doesn't work
## if FILES is empty or if it contains shell meta characters (e.g. $ is
## commonly used in Java filenames).
sc_no_for_variable_in_macro:
	@if grep 'for .* in \$$(' $(ams) | grep -v '/Makefile\.am:'; then \
	  echo 'Use "list=$$(mumble); for var in $$$$list".' 1>&2 ; \
	  exit 1; \
	else :; fi

## Make sure all invocations of mkinstalldirs are correct.
sc_mkinstalldirs:
	@if grep -n 'mkinstalldirs' $(ams) \
	      | grep -F -v '$$(mkinstalldirs)' \
	      | grep -v '^\./Makefile.am:[0-9][0-9]*:  *lib/mkinstalldirs \\$$'; \
	then \
	  echo "Found incorrect use of mkinstalldirs in the lines above" 1>&2; \
	  exit 1; \
	else :; fi

## Make sure all calls to PRE/NORMAL/POST_INSTALL/UNINSTALL
sc_pre_normal_post_install_uninstall:
	@if grep -E -n '\((PRE|NORMAL|POST)_(|UN)INSTALL\)' $(ams) | \
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
	@if grep -n '^[^#]*` *cd ' $(srcdir)/automake.in $(ams); then \
	  echo "Consider using \$$(am__cd) in the lines above." 1>&2; \
	  exit 1; \
	fi

## Look for cd to a relative directory (may be influenced by CDPATH).
## Skip some known directories that are OK.
sc_cd_relative_dir:
	@if grep -n '^[^#]*cd ' $(srcdir)/automake.in $(ams) | \
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

## Allow only few variables to be localized in Automake.
sc_perl_local:
	@if egrep -v '^[ \t]*local \$$[_~]( *=|;)' $(srcdir)/automake.in | \
	        grep '^[ \t]*local [^*]'; then \
	  echo "Please avoid 'local'." 1>&2; \
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
	@if grep '^[^#].*(MAKE) ' $(ams) $(srcdir)/automake.in \
	    | grep -v 'AM_MAKEFLAGS' \
	    | grep -v '/am/header-vars\.am:.*am--echo.*| $$(MAKE) -f *-'; \
	then \
	  echo 'Use $$(MAKE) $$(AM_MAKEFLAGS).' 1>&2; \
	  exit 1; \
	fi

## Look out for some obsolete variables.
sc_tests_obsolete_variables:
	@vars=" \
	  using_tap \
	  am_using_tap \
	  test_prefer_config_shell \
	  original_AUTOMAKE \
	  original_ACLOCAL \
	  parallel_tests \
	  am_parallel_tests \
	"; \
	seen=""; \
	for v in $$vars; do \
	  if grep -E "\b$$v\b" $(xtests) $(xdefs); then \
	    seen="$$seen $$v"; \
	  fi; \
	done; \
	if test -n "$$seen"; then \
	  for v in $$seen; do \
	    case $$v in \
	      parallel_tests|am_parallel_tests) v2=am_serial_tests;; \
	      *) v2=am_$$v;; \
	    esac; \
	    echo "Variable '$$v' is obsolete, use '$$v2' instead." 1>&2; \
	  done; \
	  exit 1; \
	else :; fi

## Look out for obsolete requirements specified in the test cases.
sc_obsolete_requirements_rules = sc_no_texi2dvi-o sc_no_makeinfo-html
modern-requirement.texi2dvi-o = texi2dvi
modern-requirement.makeinfo-html = makeinfo

$(sc_obsolete_requirements_rules): sc_no_% :
	@if grep -E 'required=.*\b$*\b' $(xtests); then \
	  echo "Requirement '$*' is obsolete and shouldn't" \
	       "be used anymore." >&2; \
	  echo "You should use '$(modern-requirement.$*)' instead." >&2; \
	  exit 1; \
	fi

## Tests should never call some programs directly, but only through the
## corresponding variable (e.g., '$MAKE', not 'make').  This will allow
## the programs to be overridden at configure time (for less brittleness)
## or by the user at make time (to allow better testsuite coverage).
sc_tests_plain_check_rules = \
  sc_tests_plain_egrep \
  sc_tests_plain_fgrep \
  sc_tests_plain_make \
  sc_tests_plain_perl \
  sc_tests_plain_automake \
  sc_tests_plain_aclocal \
  sc_tests_plain_autoconf \
  sc_tests_plain_autoupdate \
  sc_tests_plain_autom4te \
  sc_tests_plain_autoheader \
  sc_tests_plain_autoreconf

toupper = $(shell echo $(1) | LC_ALL=C tr '[a-z]' '[A-Z]')

$(sc_tests_plain_check_rules): sc_tests_plain_% :
	@# The leading ':' in the grep below is what is printed by the
	@# preceding 'grep -v' after the file name.
	@# It works here as a poor man's substitute for beginning-of-line
	@# marker.
	@if grep -v '^[ 	]*#' $(xtests) \
	   | $(EGREP) '(:|\bif|\bnot|[;!{\|\(]|&&|\|\|)[ 	]*?$*\b'; \
	 then \
	   echo 'Do not run "$*" in the above tests.' \
	        'Use "$$$(call toupper,$*)" instead.' 1>&2; \
	   exit 1; \
	fi

## Tests should only use END and EOF for here documents
## (so that the next test is effective).
sc_tests_here_document_format:
	@if grep '<<' $(xtests) | grep -Ev '\b(END|EOF)\b|\bcout <<'; then \
	  echo 'Use here documents with "END" and "EOF" only, for greppability.' 1>&2; \
	  exit 1; \
	fi

## Our test case should use the $(...) POSIX form for command substitution,
## rather than the older `...` form.
## The point of ignoring text on here-documents is that we want to exempt
## Makefile.am rules, configure.ac code and helper shell script created and
## used by out shell scripts, because Autoconf (as of version 2.69) does not
## yet ensure that $CONFIG_SHELL will be set to a proper POSIX shell.
sc_tests_command_subst:
	@found=false; \
	scan () { \
	  sed -n -e '/^#/d' \
	         -e '/<<.*END/,/^END/b' -e '/<<.*EOF/,/^EOF/b' \
	         -e 's/\\`/\\{backtick}/' \
	         -e "s/[^\\]'\([^']*\`[^']*\)*'/'{quoted-text}'/g" \
	         -e '/`/p' $$*; \
	}; \
	for file in $(xtests); do \
	  res=`scan $$file`; \
	  if test -n "$$res"; then \
	    echo "$$file:$$res"; \
	    found=true; \
	  fi; \
	done; \
	if $$found; then \
	  echo 'Use $$(...), not `...`, for command substitutions.' >&2; \
	  exit 1; \
	fi

## Tests should no longer call 'Exit', just 'exit'.  That's because we
## now have in place a better workaround to ensure the exit status is
## transported correctly across the exit trap.
sc_tests_exit_not_Exit:
	@if grep 'Exit' $(xtests) $(xdefs) | grep -Ev '^[^:]+: *#' | grep .; then \
	  echo "Use 'exit', not 'Exit'; it's obsolete now." 1>&2; \
	  exit 1; \
	fi

## Guard against obsolescent uses of ./defs in tests.  Now,
## 'test-init.sh' should be used instead.
sc_tests_no_source_defs:
	@if grep -E '\. .*defs($$| )' $(xtests); then \
	  echo "Source 'test-init.sh', not './defs'." 1>&2; \
	  exit 1; \
	fi

## Use AUTOMAKE_fails when appropriate
sc_tests_automake_fails:
	@if grep -v '^#' $(xtests) | grep '\$$AUTOMAKE.*&&.*exit'; then \
	  echo 'Use AUTOMAKE_fails + grep to catch automake failures in the above tests.' 1>&2;  \
	  exit 1; \
	fi

## Setting 'required' after sourcing './defs' is a bug.
sc_tests_required_after_defs:
	@for file in $(xtests); do \
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
## Finally, 'exp' is used by some ad-hoc checks, where we ensure it's
## ok to override it from the command line.
sc_tests_overriding_macros_on_cmdline:
	@if grep -E '\$$MAKE .*(SHELL=.*=|=.*SHELL=)' $(xtests); then \
	  echo 'Rewrite "$$MAKE foo=bar SHELL=$$SHELL" as "foo=bar $$MAKE -e SHELL=$$SHELL"' 1>&2; \
	  echo ' in the above lines, it is more portable.' 1>&2; \
	  exit 1; \
	fi
# The first s/// tries to account for usages like "$MAKE || st=$?".
# 'DISTCHECK_CONFIGURE_FLAGS' and 'exp' are allowed to contain whitespace in
# their definitions, hence the more complex last three substitutions below.
# Also, the 'make-dryrun.sh' is whitelisted, since there we need to
# override variables from the command line in order to cover the expected
# code paths.
	@tests=`for t in $(xtests); do \
	          case $$t in */make-dryrun.sh);; *) echo $$t;; esac; \
		done`; \
	if sed -e 's/ || .*//' -e 's/ && .*//' \
	        -e 's/ DESTDIR=[^ ]*/ /' -e 's/ SHELL=[^ ]*/ /' \
	        -e 's/ V=[^ ]*/ /' -e 's/ DISABLE_HARD_ERRORS=[^ ]*/ /' \
	        -e "s/ DISTCHECK_CONFIGURE_FLAGS='[^']*'/ /" \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS="[^"]*"/ /' \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS=[^ ]/ /' \
	        -e "s/ exp='[^']*'/ /" \
		-e 's/ exp="[^"]*"/ /' \
		-e 's/ exp=[^ ]/ /' \
	      $$tests | grep '\$$MAKE .*='; then \
	  echo 'Rewrite "$$MAKE foo=bar" as "foo=bar $$MAKE -e" in the above lines,' 1>&2; \
	  echo 'it is more portable.' 1>&2; \
	  exit 1; \
	fi
	@if grep 'SHELL=.*\$$MAKE' $(xtests); then \
	  echo '$$MAKE ignores the SHELL envvar, use "$$MAKE SHELL=$$SHELL" in' 1>&2; \
	  echo 'the above lines.' 1>&2; \
	  exit 1; \
	fi

## Prefer use of our 'is_newest' auxiliary script over the more hacky
## idiom "test $(ls -1t new old | sed 1q) = new", which is both more
## cumbersome and more fragile.
sc_tests_ls_t:
	@if LC_ALL=C grep -E '\bls(\s+-[a-zA-Z0-9]+)*\s+-[a-zA-Z0-9]*t' \
	    $(xtests); then \
	  echo "Use 'is_newest' rather than hacks based on 'ls -t'" 1>&2; \
	  exit 1; \
	fi

## Test scripts must be executable.
sc_tests_executable:
	@st=0; \
	for f in $(xtests); do \
	  case $$f in \
	    t/ax/*|./t/ax/*|$(srcdir)/t/ax/*);; \
	    *) test -x $$f || { echo "$$f: not executable" >&2; st=1; }; \
	  esac; \
	done; \
	test $$st -eq 0 || echo '$@: some test scripts are not executable' >&2; \
	exit $$st;


## Never use 'sleep 1' to create files with different timestamps.
## Use '$sleep' instead.  Some filesystems (e.g., Windows) have only
## a 2sec resolution.
sc_tests_plain_sleep:
	@if grep -E '\bsleep +[12345]\b' $(xtests); then \
	  echo 'Do not use "sleep x" in the above tests.  Use "$$sleep" instead.' 1>&2; \
	  exit 1; \
	fi

## fgrep and egrep are not required by POSIX.
sc_m4_am_plain_egrep_fgrep:
	@if grep -E '\b[ef]grep\b' $(ams) $(srcdir)/m4/*.m4; then \
	  echo 'Do not use egrep or fgrep in the above files,' \
	       'they are not portable.' 1>&2; \
	  exit 1; \
	fi

## Prefer 'configure.ac' over the obsolescent 'configure.in' as the name
## for configure input files in our testsuite.  The latter  has been
## deprecated for several years (at least since autoconf 2.50).
sc_tests_no_configure_in:
	@if grep -E '\bconfigure\\*\.in\b' $(xtests) $(xdefs) \
	      | grep -Ev '/backcompat.*\.(sh|tap):' \
	      | grep -Ev '/autodist-configure-no-subdir\.sh:' \
	      | grep -Ev '/(configure|help)\.sh:' \
	      | grep .; \
	then \
	  echo "Use 'configure.ac', not 'configure.in', as the name" >&2; \
	  echo "for configure input files in the test cases above." >&2; \
	  exit 1; \
	fi

## Rule to ensure that the testsuite has been run before.  We don't depend
## on 'check' here, because that would be very wasteful in the common case.
## We could run "make check RECHECK_LOGS=" and avoid toplevel races with
## AM_RECURSIVE_TARGETS.  Suggest keeping test directories around for
## greppability of the Makefile.in files.
sc_ensure_testsuite_has_run:
	@if test ! -f '$(TEST_SUITE_LOG)'; then \
	  echo 'Run "env keep_testdirs=yes make check" before' \
	       'running "make maintainer-check"' >&2; \
	  exit 1; \
	fi
.PHONY: sc_ensure_testsuite_has_run

## Ensure our warning and error messages do not contain duplicate 'warning:' prefixes.
## This test actually depends on the testsuite having been run before.
sc_tests_logs_duplicate_prefixes: sc_ensure_testsuite_has_run
	@if grep -E '(warning|error):.*(warning|error):' t/*.log; then \
	  echo 'Duplicate warning/error message prefixes seen in above tests.' >&2; \
	  exit 1; \
	fi

## Ensure variables are listed before rules in Makefile.in files we generate.
sc_tests_makefile_variable_order: sc_ensure_testsuite_has_run
	@st=0; \
	for file in `find t -name Makefile.in -print`; do \
	  latevars=`sed -n \
	    -e :x -e 's/#.*//' \
	    -e '/\\\\$$/{' -e N -e 'b x' -e '}' \
	    -e '# Literal TAB.' \
	    -e '1,/^	/d' \
	    -e '# Allow @ so we match conditionals.' \
	    -e '/^ *[a-zA-Z_@]\{1,\} *=/p' $$file`; \
	  if test -n "$$latevars"; then \
	    echo "Variables are expanded too late in $$file:" >&2; \
	    echo "$$latevars" | sed 's/^/  /' >&2; \
	    st=1; \
	  fi; \
	done; \
	test $$st -eq 0 || { \
	  echo 'Ensure variables are expanded before rules' >&2; \
	  exit 1; \
	}

## Using ':' as a PATH separator is not portable.
sc_tests_PATH_SEPARATOR:
	@if grep -E '\bPATH=.*:.*' $(xtests) ; then \
	  echo "Use '\$$PATH_SEPARATOR', not ':', in PATH definitions" \
	       "above." 1>&2; \
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
	@if grep -E "[^\'\"]\\\$$\(DESTDIR" $(ams); then \
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

$(syntax_check_rules): automake aclocal
maintainer-check: $(syntax_check_rules)
.PHONY: maintainer-check $(syntax_check_rules)

## Check that the list of tests given in the Makefile is equal to the
## list of all test scripts in the Automake testsuite.
maintainer-check: maintainer-check-list-of-tests
