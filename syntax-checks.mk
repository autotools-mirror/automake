# Maintainer checks for Automake-NG.

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
       ls $$d/t/*.$$s $$d/t/ax/*.$$s 2>/dev/null; \
     done; \
   done | sort)

xdefs = $(srcdir)/t/ax/test-init.sh $(srcdir)/defs $(srcdir)/defs-static.in

ams := $(shell find $(srcdir) -name '*.dir' -prune -o -name '*.am' -print)
pms := $(dist_perllib_DATA)

# Some simple checks, and then ordinary check.  These are only really
# guaranteed to work on my machine.
syntax_check_rules = \
$(sc_tests_plain_check_rules) \
sc_diff_automake \
sc_diff_aclocal \
sc_perl_syntax \
sc_no_brace_variable_expansions \
sc_rm_minus_f \
sc_no_for_variable_in_macro \
sc_old_includes_vars \
sc_mkinstalldirs \
sc_pre_normal_post_install_uninstall \
sc_perl_no_undef \
sc_perl_no_split_regex_space \
sc_no_am_cd \
sc_perl_at_uscore_in_scalar_context \
sc_perl_local \
sc_AMDEP_TRUE_in_automake_in \
sc_tests_no_gmake_requirement \
sc_tests_no_gmake_checking \
sc_tests_make_can_chain_suffix_rules \
sc_tests_make_dont_do_useless_vpath_rebuilds \
sc_no_dotmake_target \
sc_no_am_makeflags \
$(sc_obsolete_requirements_rules) \
$(sc_renamed_variables_rules) \
$(sc_variable_typos_rules) \
sc_no_RECHECK_LOGS \
sc_tests_no_make_e \
sc_docs_no_make_e \
sc_make_simple_include \
sc_tests_make_simple_include \
sc_tests_obsolete_variables \
sc_tests_here_document_format \
sc_tests_command_subst \
sc_tests_Exit_not_exit \
sc_tests_automake_fails \
sc_tests_required_after_defs \
sc_tests_plain_sleep \
sc_tests_ls_t \
sc_m4_am_plain_egrep_fgrep \
sc_tests_PATH_SEPARATOR \
sc_tests_logs_duplicate_prefixes \
sc_perl_at_substs \
sc_unquoted_DESTDIR \
sc_tabs_in_texi \
sc_at_in_texi

## These check avoids accidental configure substitutions in the source.
## There are exactly 8 lines that should be modified from automake.in to
## automake, and 10 lines that should be modified from aclocal.in to
## aclocal.
automake_diff_no = 8
aclocal_diff_no = 10
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

## Syntax check with default Perl (on my machine, Perl 5).
sc_perl_syntax:
	@perllibdir="./lib$(PATH_SEPARATOR)$(srcdir)/lib" $(PERL) -c -w automake
	@perllibdir="./lib$(PATH_SEPARATOR)$(srcdir)/lib" $(PERL) -c -w aclocal

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

## Older, deprecated, and now invalid aliases for $(AM_CPPFLAGS).
sc_old_includes_vars:
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	"; \
	if grep -E '\bINCLUDES\b' $$files; then \
	  echo '$$(INCLUDES) is deprecated, use $$(AM_CPPFLAGS) instead' >&2; \
	  exit 1; \
	else :; fi

## The script and variable 'mkinstalldirs' are obsolete.
sc_mkinstalldirs:
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	"; \
	if grep 'mkinstalldirs' $$files; then \
	  echo "Found use of mkinstalldirs; that is obsolete" 1>&2; \
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

sc_no_am_cd:
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	"; \
	if grep -F 'am__cd' $$files; then \
	  echo "Found uses of 'am__cd', which is obsolete" 1>&2; \
	  echo "Using a simple 'cd' should be enough" 1>&2; \
	  exit 1; \
	else :; fi

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

## Tests should never require GNU make explicitly: automake-ng assumes
## it unconditionally.
sc_tests_no_gmake_requirement:
	@if grep -iE '^ *required=.*\b(g|gnu)make\b' $(xtests) $(xdefs); \
	then \
	  echo 'Tests should never require GNU make explicitly.' 1>&2; \
	  exit 1; \
	fi

## Tests should never check explicitly whether the make program being
## used in the test suite is indeed GNU make: automake-ng assumes it
## unconditionally.
sc_tests_no_gmake_checking:
	@if grep -E '\b(is|using)_g(nu)?make\b' $(xtests) $(xdefs); \
	then \
	  echo 'Tests should never explicitly check whether $$MAKE' \
	       'is GNU make.' 1>&2; \
	  exit 1; \
	fi

## GNU make can obviously chain suffix rules, so don't try to check
## whether this is the case.
sc_tests_make_can_chain_suffix_rules:
	@if grep 'chain_suffix_rule' $(xtests); then \
	  echo 'GNU make can implicitly chain suffix rules; tests' \
	       'should just assume that without checking.' 1>&2; \
	  exit 1; \
	fi

## Automake bug#7884 affects only FreeBSD make, so that we don't
## need to work around in any of our tests anymore.
sc_tests_make_dont_do_useless_vpath_rebuilds:
	@if grep -E 'useless_vpath_rebuild|yl_distcheck' $(xtests); then \
	  echo 'No need to work around automake bug#7884 anymore;' \
	       'it only affects FreeBSD make.' 1>&2; \
	  exit 1; \
	fi

## GNU make supports POSIX-style runtime include directives.
sc_grep_for_bad_make_include = \
  if grep -E 'AM_MAKE_INCLUDE|am__(include|quote)' $$files; then \
    echo 'GNU make supports runtime "include" directive.' 1>&2; \
    echo 'Neither am__{include,quote} nor AM_MAKE_INCLUDE' \
         'should be used anymore.' 1>&2; \
    exit 1; \
  fi
sc_tests_make_simple_include: sc_ensure_testsuite_has_run
	@files='t/*.log'; $(sc_grep_for_bad_make_include)
sc_make_simple_include:
	@files=" \
	   $(xtests) \
	   $(ams) \
	   $(srcdir)/m4/*.m4 \
	   $(srcdir)/automake.in \
	   $(srcdir)/doc/*.texi \
	   aclocal.m4 \
	   configure \
	 "; \
	 $(sc_grep_for_bad_make_include)

## The '.MAKE' special target is NetBSD-make specific, and not supported
## by GNU make.  No point in using it.
sc_no_dotmake_target:
	@files="\
	  `find $(srcdir) -name '*.am'` \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	 "; \
	if grep '\.MAKE' $$files; then \
	  echo "Special target '.MAKE' not supported by GNU make." 1>&2; \
	  echo "Use the '+' recipe modifier instead, or put the" \
	       "'\$$(MAKE)' string somewhere in the recipe text." 1>&2; \
	  exit 1; \
	fi

## $(AM_MAKEFLAGS) is obsolete now that we assume GNU make, since it
## is smart enough to correctly pass the values of macros redefined on
## the command line to sub-make invocations.
sc_no_am_makeflags:
	@files="\
	  $(xtests) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	 "; \
	if grep '\bAM_MAKEFLAGS\b' $$files; then \
	  echo "\$$(AM_MAKEFLAGS) is obsolete, don't use it." 1>&2; \
	  exit 1; \
	fi

# Modern names for internal variables that had a bad name once.
modern.DISTFILES = am__dist_files
modern.DIST_COMMON = am__dist_common
modern.DIST_SOURCES = am__dist_sources
modern.am__TEST_BASES = am__test_bases
modern.am__TEST_LOGS = am__test_logs
modern.am__TEST_RESULTS = am__test_results
modern.CONFIG_HEADER = AM_CONFIG_HEADERS
modern.DEFAULT_INCLUDES = AM_DEFAULT_INCLUDES

sc_renamed_variables_rules = \
  $(patsubst modern.%,sc_no_%,$(filter modern.%,$(.VARIABLES)))

$(sc_renamed_variables_rules): sc_no_% :
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	"; \
	if grep -E '\b$*\b' $$files; then \
	  echo "'\$$($*)' is obsolete and no more used." >&2; \
	  echo "You should use '$(modern.$*)' instead." >&2; \
	  exit 1; \
	fi

# Variables whose name is prone to typos.
fixtypo.am__distfiles = am__dist_files
fixtypo.am__distcommon = am__dist_common
fixtypo.am__distsources = am__dist_sources

define typos-for-clean

fixtypo.am__mostlyclean$1 = am__mostlyclean_$1
fixtypo.am__clean$1 = am__clean_$1
fixtypo.am__distclean$1 = am__distclean_$1
fixtypo.am__maintclean$1 = am__maintclean_$1

fixtypo.am__mostly_clean_$1 = am__mostlyclean_$1
fixtypo.am__dist_clean_$1 = am__distclean_$1

fixtypo.am__maint_clean_$1 = am__maintclean_$1
fixtypo.am__maintainerclean_$1 = am__maintclean_$1
fixtypo.am__maintainer_clean_$1 = am__maintclean_$1

endef

$(eval $(call typos-for-clean,files))
$(eval $(call typos-for-clean,dirs))

sc_variables_typos_rules = \
  $(patsubst fixtypo.%,sc_no_%,$(filter fixtypo.%,$(.VARIABLES)))

$(sc_variable_typos_rules) : sc_no_% :
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/automake.in \
	  $(srcdir)/doc/*.texi \
	"; \
	if grep -E '\b$*\b' $$files; then \
	  echo "'\$$($*)' is probably a typo." >&2; \
	  echo "You should use '$(fixtypo.$*)' instead." >&2; \
	  exit 1; \
	fi


sc_no_RECHECK_LOGS:
	@files="\
	  $(xtests) \
	  $(pms) \
	  $(ams) \
	  $(srcdir)/doc/*.texi \
	  $(srcdir)/automake.in \
	  README t/README \
	"; \
	if grep -F 'RECHECK_LOGS' $$files; then \
	  echo "'RECHECK_LOGS' is obsolete and no more used." >&2; \
	  echo "You should use 'AM_LAZY_CHECK' instead." >&2; \
	  exit 1; \
	fi

## "make -e" is brittle and unsafe, since it let *all* the environment
## win over the macro definitions in the Makefiles.  We needed it when
## we couldn't assume GNU make, but now that the tide has turned, it's
## better to prohibit it altogether.
sc_tests_no_make_e:
	@if grep -E '\$$MAKE\b.* -[a-zA-Z0-9]*e' $(xtests); then \
	  echo "\"make -e\" is brittle, don't use it." 1>&2; \
	  exit 1; \
	fi
sc_docs_no_make_e:
	@if grep '\bmake\b.* -[a-zA-Z0-9]*e' README t/README; then \
	  echo "Don't advocate the use of \"make -e\" in the manual or" \
	       " in the README files." 1>&2; \
	  exit 1; \
	fi

## Look out for some obsolete variables.
sc_tests_obsolete_variables:
	@vars=" \
	  using_tap \
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

## Tests should never call exit directly, but use Exit.
## This is so that the exit status is transported correctly across the 0 trap.
## Ignore comments and our testsuite's own self tests.
sc_tests_Exit_not_exit:
	@found=false; for file in $(xtests); do \
	  case $$file in */self-check-*) continue;; esac; \
	  res=`sed -n -e '/^#/d' -e '/<<.*END/,/^END/b' -e '/<<.*EOF/,/^EOF/b' \
	              -e '/exit [$$0-9]/p' $$file`; \
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

## Setting 'required' after sourcing './defs' is a bug.
sc_tests_required_after_defs:
	@for file in $(xtests); do \
	  if out=`sed -n '/defs/,$${/required=/p;}' $$file`; test -n "$$out"; then \
	    echo 'Do not set "required" after sourcing "defs" in '"$$file: $$out" 1>&2; \
	    exit 1; \
	  fi; \
	done

## Prefer use of our 'is_newest' auxiliary script over the more hacky
## idiom "test $(ls -1t new old | sed 1q) = new", which is both more
## cumbersome and more fragile.
sc_tests_ls_t:
	@if LC_ALL=C grep -E '\bls(\s+-[a-zA-Z0-9]+)*\s+-[a-zA-Z0-9]*t' \
	    $(xtests); then \
	  echo "Use 'is_newest' rather than hacks based on 'ls -t'" 1>&2; \
	  exit 1; \
	fi

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

## Rule to ensure that the testsuite has been run before.  We don't depend
## on 'check' here, because that would be very wasteful in the common case.
## We could run "make check AM_LAZY_CHECK=yes" and avoid toplevel races with
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
	@if grep '	' $(srcdir)/doc/*.texi; then \
	  echo 'Do not use tabs in the manual.' 1>&2; \
	  exit 1; \
	fi

sc_at_in_texi:
	@if grep -E '([^@]|^)@([	 ][^@]|$$)' $(srcdir)/doc/*.texi; \
	then \
	  echo 'Unescaped @.' 1>&2; \
	  exit 1; \
	fi

$(syntax_check_rules): automake aclocal
maintainer-check: $(syntax_check_rules)
.PHONY: maintainer-check $(syntax_check_rules)
