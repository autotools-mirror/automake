# -*- shell-script -*-
#
# Copyright (C) 2011 Free Software Foundation, Inc.
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

# Helper functions used by TAP-producing tests of the Automake testsuite.

#
# IMPORTANT: All the functions defined in this file can *not* be used
#            from within a subshell, unless explicitly noted otherwise.
#

# The count of the TAP test results seen so far.
tap_count_=0

# The first "test -n" tries to avoid extra forks when possible.
if test -n "${ZSH_VERSION}${BASH_VERSION}" \
     || (eval 'test $((1 + 1)) = 2') >/dev/null 2>&1
then
  # Use of 'eval' needed to protect dumber shells from parsing errors.
  eval 'incr_tap_count_ () { tap_count_=$(($tap_count_ + 1)); }'
else
  incr_tap_count_ () { tap_count_=`expr $tap_count_ + 1`; }
fi

# plan_ NUMBER-OF-PLANNED-TESTS
# -----------------------------
# Print a TAP plan for the given number of tests.  This must be called
# before reporting any test result; in fact, it must be called before
# emitting anything on standard output.
plan_ ()
{
  echo "1..$1"
  have_tap_plan_=yes
}

# late_plan_
# ----------
# Print a TAP plan that accounts for the number of tests seen so far.
# This must be called after all the tests result have been reported;
# in fact, after this has been called, nothing more can be print on
# standard output.
late_plan_ ()
{
  echo "1..$tap_count_"
  have_tap_plan_=yes
}

# Initialize it to avoid interferences from the environment.
have_tap_plan_=no

# diag_ [EXPLANATION]
# ------------------
# Report the given text as TAP diagnostic.  Assumes the string denoting
# TAP diagnostic lines is stored in the `$diag_string_' variable; this is
# done to allow better interplay with TAP drivers that allow such a string
# to be configured.
diag_ ()
{
  test $# -eq 0 || echo "$diag_string_ $*"
}

# Used by the `diag_' function above.  User-overridable.
diag_string_="#"

# warn_ [EXPLANATION]
# ------------------
# Give a warning (using TAP diagnostic).
warn_ ()
{
  diag_ "WARNING:" ${1-"(unknown warning)"} ${1+"$@"}
}

# result_ RESULT [-D DIRECTIVE] [-r REASON] [--] [DESCRIPTION...]
# ---------------------------------------------------------------
# Report a test case with the given RESULT (valid values are "ok" and
# "not ok") and the given DESCRIPTION (if any).  If DIRECTIVE is given
# and non-empty (valid values being "TODO" and "SKIP"), it will be
# reported too, with the REASON (if given) appended.
result_ ()
{
  set +x # Don't pollute the log files.
  test $# -gt 0 || bailout_ "result_: missing argument"
  tap_result_=$1; shift
  case $tap_result_ in
    "ok"|"not ok") ;;
    *) bailout_ "result_: invalid result '$tap_result'" ;;
  esac
  tap_directive_= tap_reason_=
  while test $# -gt 0; do
    case $1 in
      -D|--directive) tap_directive_=$2; shift;;
      -r|--reason) tap_reason_=$2; shift;;
      --) shift; break;;
      -*) bailout_ "result_: invalid option '$1'";;
       *) break;;
    esac
    shift
  done
  case $tap_directive_ in
    ""|TODO|SKIP) ;;
    *) bailout_ "result_: invalid directive '$directive_'" ;;
  esac
  incr_tap_count_
  tap_text_="$tap_result_ $tap_count_"
  if test x"$*" != x; then
    tap_text_="$tap_text_ - $*"
  fi
  if test x"$tap_directive_" != x; then
    tap_text_="$tap_text_ # $tap_directive_"${tap_reason_:+" $tap_reason_"}
  fi
  printf '%s\n' "$tap_text_"
  set -x # Restore shell xtraces.
}

# ok_ [DESCRIPTION...]
# --------------------
# Report a successful test.
ok_ ()
{
  result_ 'ok' -- ${1+"$@"}
}

# not_ok_ [DESCRIPTION...]
# ------------------------
# Report a failed test.
not_ok_ ()
{
  result_ 'not ok' -- ${1+"$@"}
}

# skip_ [-r REASON] [--] [DESCRIPTION...]
# ---------------------------------------
# Report a skipped test.  If the `-r' option is present, its argument is
# give as the reason of the skip.
skip_ ()
{
  result_ 'ok' -D SKIP ${1+"$@"}
}

# skip_row_ COUNT [-r REASON] [--] [DESCRIPTION...]
# -------------------------------------------------
# Report a COUNT of skipped test, with the given reason and descriptions
# (if any).  Useful to avoid cascade failures in case a fair number of
# tests depend on an earlier one that failed.
skip_row_ ()
{
  skip_count_=$1; shift
  for i_ in `seq $skip_count_`; do skip_ ${1+"$@"}; done
}

# xfail_ [-r REASON] [DESCRIPTION...]
# ----------------------------------
# Report a test that failed expectedly.  If the `-r' option is present, its
# argument is give as the reason why the failure is expected.
xfail_ ()
{
  result_ 'not ok' -D TODO ${1+"$@"}
}

# xpass_ [-r REASON] [DESCRIPTION...]
# -----------------------------------
# Report a test that failed unexpectedly.  If the `-r' option is present, its
# argument is give as the reason why the failure is expected.
xpass_ ()
{
  result_ 'ok' -D TODO ${1+"$@"}
}

# skip_all_ [REASON ...]
# ----------------------
# Skip all the tests in a test script.  Must be used before calling `plan_'
# or reporting any test result.  Can't be used from within a subshell.
skip_all_ ()
{
  echo "1..0 # SKIP" ${1+"$@"}
  Exit 0
}

# bailout_ [REASON ...]
# ---------------------
# Stop the execution of the current test suite right now, due to an
# unrecoverable error.  Can be called at any point, but cannot be used
# from within a subshell.
bailout_ ()
{
  echo 'Bail out!' ${1+"$@"}
  Exit 99
}

# fatal_ [REASON ...]
# -------------------
# Same as `bailout_'; for compatibility with `plain-functions.sh'.
fatal_ ()
{
  bailout_ ${1+"$@"}
}

# framework_failure_ [REASON ...]
# -------------------------------
# Stop the execution of the current test suite right now, due to an
# unrecoverable error in the set-up of the test case.  Can be called
# at any point, but cannot be used from within a subshell.
framework_failure_ ()
{
  bailout_ "set-up failure"${1+": $*"}
}

# command_ok_ TEST-DESCRIPTION [--] CMD [ARGS...]
# -----------------------------------------------
# Report a passed test if the given command returns with success,
# a failed test otherwise.
command_ok_ ()
{
  tap_desc_=$1; shift
  test x"$1" != x"--" || shift
  if "$@"; then
    ok_ "$tap_desc_"
  else
    not_ok_ "$tap_desc_"
  fi
}

# command_not_ok_ TEST-DESCRIPTION [--] CMD [ARGS...]
# ---------------------------------------------------
# Report a failed test if the given command returns with success,
# a failed test otherwise.
command_not_ok_ ()
{
  tap_desc_=$1; shift
  test x"$1" != x"--" || shift
  if "$@"; then
    not_ok_ "$tap_desc_"
  else
    ok_ "$tap_desc_"
  fi
}

# reset_test_count_ COUNT
# -----------------------
# Reset the count of the TAP test results seen so far to COUNT.
# This function is for use in corner cases only (e.g., when `ok_' and
# `not_ok_' must be used inside a subshell).  Be careful when using it!
reset_test_count_ ()
{
  tap_count_=$1
}

:
