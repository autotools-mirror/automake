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
# tests might be in `$(builddir)' rather than in `$(srcdir)'), TAP-based
# tests script (which have a `.tap' extension) and helper scripts used
# by other test cases (which have a `.sh' extension).
xtests := $(shell \
  if test $(srcdir) = .; then \
     dirs=.; \
   else \
     dirs='$(srcdir) .'; \
   fi; \
   for d in $$dirs; do \
     for s in test tap sh; do \
       ls $$d/tests/*.$$s 2>/dev/null; \
     done; \
   done | sort)

ams := $(shell find $(srcdir) -name '*.am')

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
sc_tests_obsolete_variables \
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
sc_tests_tap_plan \
sc_tests_overriding_macros_on_cmdline \
sc_tests_plain_sleep \
sc_tests_plain_egrep_fgrep \
sc_tests_PATH_SEPARATOR \
sc_tests_logs_duplicate_prefixes \
sc_tests_makefile_variable_order \
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
	$(MAKE) -C tests $@
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
	 if { \
	   for t in $(xtests); do echo $$t; done \
	     | LC_ALL=C grep -E "$$m4_macro_rx"; \
	 }; then \
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
	@if grep -F '$${' $(ams) | grep -F -v '$$$$'; then \
	  echo "Found too many uses of '\$${' in the lines above." 1>&2; \
	  exit 1;				\
	else :; fi

## Make sure `rm' is called with `-f'.
sc_rm_minus_f:
	@if grep -v '^#' $(ams) $(xtests) \
	   | grep -E '\<rm ([^-]|\-[^f ]*\>)'; \
	then \
	  echo "Suspicious 'rm' invocation." 1>&2; \
	  exit 1;				\
	else :; fi

## Never use something like `for file in $(FILES)', this doesn't work
## if FILES is empty or if it contains shell meta characters (e.g. $ is
## commonly used in Java filenames).
sc_no_for_variable_in_macro:
	@if grep 'for .* in \$$(' $(ams); then \
	  echo 'Use "list=$$(mumble); for var in $$$$list".' 1>&2 ; \
	  exit 1; \
	else :; fi

## Make sure all invocations of mkinstalldirs are correct.
sc_mkinstalldirs:
	@if grep -n 'mkinstalldirs' $(ams) | \
	      grep -F -v '$$(mkinstalldirs)'; then \
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
	@if grep '^[^#].*(MAKE) ' $(ams) $(srcdir)/automake.in | \
		grep -v 'AM_MAKEFLAGS'; then \
	  echo 'Use $$(MAKE) $$(AM_MAKEFLAGS).' 1>&2; \
	  exit 1; \
	fi

## Look out for some obsolete variables.
sc_tests_obsolete_variables:
	@vars=" \
	  using_tap \
	  parallel_tests \
	  test_prefer_config_shell \
	  original_AUTOMAKE \
	  original_ACLOCAL \
	"; \
	seen=""; \
	for v in $$vars; do \
	  if grep -E "\b$$v\b" \
	    $(xtests) $(srcdir)/tests/defs \
	    $(srcdir)/tests/defs-static.in \
	  ; then \
	    seen="$$seen $$v"; \
	  fi; \
	done; \
	if test -n "$$seen"; then \
	  for v in $$seen; do \
	    echo "Variable '$$v' is obsolete, use 'am_$$v' instead." 1>&2; \
	  done; \
	  exit 1; \
	else :; fi

## Tests should never call make directly.
sc_tests_plain_make:
	@if grep -v '^#' $(xtests) | $(EGREP) ':[ 	]*make( |$$)'; then \
	  echo 'Do not run "make" in the above tests.  Use "$$MAKE" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call autoconf directly.
sc_tests_plain_autoconf:
	@if grep -v '^#' $(xtests) | grep ':[	]*autoconf\>'; then \
	  echo 'Do not run "autoconf" in the above tests.  Use "$$AUTOCONF" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call autoupdate directly.
sc_tests_plain_autoupdate:
	@if grep -v '^#' $(xtests) | grep ':[	]*autoupdate\>'; then \
	  echo 'Do not run "autoupdate" in the above tests.  Use "$$AUTOUPDATE" instead.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call automake directly.
sc_tests_plain_automake:
	@if grep -v '^#' $(xtests) | grep -E ':[	]*automake\>([^:]|$$)'; then \
	  echo 'Do not run "automake" in the above tests.  Use "$$AUTOMAKE" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autoheader directly.
sc_tests_plain_autoheader:
	@if grep -v '^#' $(xtests) | grep ':[	]*autoheader\>'; then \
	  echo 'Do not run "autoheader" in the above tests.  Use "$$AUTOHEADER" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autoreconf directly.
sc_tests_plain_autoreconf:
	@if grep -v '^#' $(xtests) | grep ':[	]*autoreconf\>'; then \
	  echo 'Do not run "autoreconf" in the above tests.  Use "$$AUTORECONF" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call autom4te directly.
sc_tests_plain_autom4te:
	@if grep -v '^#' $(xtests) | grep ':[	]*autom4te\>'; then \
	  echo 'Do not run "autom4te" in the above tests.  Use "$$AUTOM4TE" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should only use END and EOF for here documents
## (so that the next test is effective).
sc_tests_here_document_format:
	@if grep '<<' $(xtests) | grep -v 'END' | grep -v 'EOF'; then \
	  echo 'Use here documents with "END" and "EOF" only, for greppability.' 1>&2; \
	  exit 1; \
	fi

## Tests should never call exit directly, but use Exit.
## This is so that the exit status is transported correctly across the 0 trap.
## Ignore comments, testsuite self tests, and one perl line in ext2.test.
sc_tests_Exit_not_exit:
	@found=false; for file in $(xtests); do \
	  case $$file in */self-check-*) continue;; esac; \
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
	@if grep -v '^#' $(xtests) | grep '\$$AUTOMAKE.*&&.*[eE]xit'; then \
	  echo 'Use AUTOMAKE_fails + grep to catch automake failures in the above tests.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call aclocal directly.
sc_tests_plain_aclocal:
	@if grep -v '^#' $(xtests) | grep ':[	]*aclocal\>'; then \
	  echo 'Do not run "aclocal" in the above tests.  Use "$$ACLOCAL" instead.' 1>&2;  \
	  exit 1; \
	fi

## Tests should never call perl directly.
sc_tests_plain_perl:
	@if grep -v '^#' $(xtests) | grep ':[	]*perl\>'; then \
	  echo 'Do not run "perl" in the above tests.  Use "$$PERL" instead.' 1>&2; \
	  exit 1; \
	fi

## Setting `required' after sourcing `./defs' is a bug.
sc_tests_required_after_defs:
	@for file in $(xtests); do \
	  if out=`sed -n '/defs/,$${/required=/p;}' $$file`; test -n "$$out"; then \
	    echo 'Do not set "required" after sourcing "defs" in '"$$file: $$out" 1>&2; \
	    exit 1; \
	  fi; \
	done

## TAP-based test scripts should not forget to declare a TAP plan.  In
## case it is not known in advance how many tests will be run, a "lazy"
## plan can be used; but its use should be deliberate, explicitly declared
## with a "plan_ later" call, rather than the result of an oversight.
## This check helps to ensure this is indeed the case.
sc_tests_tap_plan:
	@with_plan=`grep -l '^ *plan_ ' $(srcdir)/tests/*.tap`; \
	 with_plan=`echo $$with_plan`; \
	 ok=:; \
	 for t in $(srcdir)/tests/*.tap; do \
	   case " $$with_plan " in *" $$t "*) continue;; esac; \
	   case $$t in \
	     *-w.tap) \
	       : it is ok for an *auto-generated* test sourcing an \
	       : hand-written one not to declare a TAP plan: that will \
	       : be done by the sourced test; \
	       t2=`echo $$t | sed -e 's|.*/||' -e 's/-w\.tap$$/.tap/'` \
	         && grep -E "^ *\\.  *[^ 	]*/$$t2\\b" $$t >/dev/null \
	         && continue || : ;; \
	   esac; \
	   ok=false; echo $$t; \
	 done; \
	 $$ok || { \
	  echo 'The tests above do not declare a TAP plan.' 1>&2; \
	  exit 1; \
	 }

## Overriding a Makefile macro on the command line is not portable when
## recursive targets are used.  Better use an envvar.  SHELL is an
## exception, POSIX says it can't come from the environment.  V, DESTDIR,
## DISTCHECK_CONFIGURE_FLAGS and DISABLE_HARD_ERRORS are exceptions, too,
## as package authors are urged not to initialize them anywhere.
sc_tests_overriding_macros_on_cmdline:
	@if grep -E '\$$MAKE .*(SHELL=.*=|=.*SHELL=)' $(xtests); then \
	  echo 'Rewrite "$$MAKE foo=bar SHELL=$$SHELL" as "foo=bar $$MAKE -e SHELL=$$SHELL"' 1>&2; \
	  echo ' in the above lines, it is more portable.' 1>&2; \
	  exit 1; \
	fi
# The first s/// tries to account for usages like "$MAKE || st=$?".
# DISTCHECK_CONFIGURE_FLAGS is allowed to contain whitespace in its
# definition, hence the more complex last three substitutions below.
	@if sed -e 's/ || .*//' -e 's/ && .*//' \
	        -e 's/ DESTDIR=[^ ]*/ /' -e 's/ SHELL=[^ ]*/ /' \
	        -e 's/ V=[^ ]*/ /' -e 's/ DISABLE_HARD_ERRORS=[^ ]*/ /' \
	        -e "s/ DISTCHECK_CONFIGURE_FLAGS='[^']*'/ /" \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS="[^"]*"/ /' \
		-e 's/ DISTCHECK_CONFIGURE_FLAGS=[^ ]/ /' \
	      $(xtests) | grep '\$$MAKE .*='; then \
	  echo 'Rewrite "$$MAKE foo=bar" as "foo=bar $$MAKE -e" in the above lines,' 1>&2; \
	  echo 'it is more portable.' 1>&2; \
	  exit 1; \
	fi
	@if grep 'SHELL=.*\$$MAKE' $(xtests); then \
	  echo '$$MAKE ignores the SHELL envvar, use "$$MAKE SHELL=$$SHELL" in' 1>&2; \
	  echo 'the above lines.' 1>&2; \
	  exit 1; \
	fi

## Never use `sleep 1' to create files with different timestamps.
## Use `$sleep' instead.  Some filesystems (e.g., Windows') have only
## a 2sec resolution.
sc_tests_plain_sleep:
	@if grep -E '\bsleep +[12345]\b' $(xtests); then \
	  echo 'Do not use "sleep x" in the above tests.  Use "$$sleep" instead.' 1>&2; \
	  exit 1; \
	fi

## fgrep and egrep are not required by POSIX.
sc_tests_plain_egrep_fgrep:
	@if grep -E '\b[ef]grep\b' $(xtests) ; then \
	  echo 'Do not use egrep or fgrep in test cases.  Use $$FGREP or $$EGREP.' 1>&2; \
	  exit 1; \
	fi
	@if grep -E '\b[ef]grep\b' $(ams) $(srcdir)/m4/*.m4; then \
	  echo 'Do not use egrep or fgrep in the above files, they are not portable.' 1>&2; \
	  exit 1; \
	fi

## Rule to ensure that the testsuite has been run before.  We don't depend on `check'
## here, because that would be very wasteful in the common case.  We could run
## `make check RECHECK_LOGS=' and avoid toplevel races with AM_RECURSIVE_TARGETS.
## Suggest keeping test directories around for greppability of the Makefile.in files.
sc_ensure_testsuite_has_run:
	@if test ! -f tests/test-suite.log; then \
	  echo "Run \`env keep_testdirs=yes make check' before \`maintainer-check'" >&2; \
	  exit 1; \
	fi
.PHONY: sc_ensure_testsuite_has_run

## Ensure our warning and error messages do not contain duplicate 'warning:' prefixes.
## This test actually depends on the testsuite having been run before.
sc_tests_logs_duplicate_prefixes: sc_ensure_testsuite_has_run
	@if grep -E '(warning|error):.*(warning|error):' tests/*.log; then \
	  echo 'Duplicate warning/error message prefixes seen in above tests.' >&2; \
	  exit 1; \
	fi

## Ensure variables are listed before rules in Makefile.in files we generate.
sc_tests_makefile_variable_order: sc_ensure_testsuite_has_run
	@st=0; \
	for file in `find tests -name Makefile.in -print`; do \
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

## Using `:' as a PATH separator is not portable.
sc_tests_PATH_SEPARATOR:
	@if grep -E '\bPATH=.*:.*' $(xtests) ; then \
	  echo "Use \`\$$PATH_SEPARATOR', not \`:', in PATH definitions above." 1>&2; \
	  exit 1; \
	fi

sc_mkdir_p:
	@if grep 'mkdir_p' $(srcdir)/automake.in $(ams) $(xtests); then \
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
