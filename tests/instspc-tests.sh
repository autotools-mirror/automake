#! /bin/sh
# Copyright (C) 2010, 2011 Free Software Foundation, Inc.
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

#
# Driver script to run tests checking that building from, or installing
# to, directories with shell metacharacters succeed.
#
# Original report from James Amundson about file names with spaces.
# Other characters added by Paul Eggert.
#
# This script fulfills a threefold role:
#   1. It is called to generate a Makefile.am snippet, containing the
#      definition of proper lists of tests.
#   2. It is called to set up a directory containing some common data
#      files and autotools-generated files used by the aforementioned
#      tests (this is done for speed reasons only).
#   3. It is called to properly run those tests, one at a time.
#

# Be more Bourne compatible (snippet copied from `tests/defs').
DUALCASE=1; export DUALCASE # for MKS sh
if test -n "${ZSH_VERSION+set}" && (emulate sh) >/dev/null 2>&1; then
  emulate sh
  NULLCMD=:
  # Pre-4.2 versions of Zsh do word splitting on ${1+"$@"}, which
  # is contrary to our usage.  Disable this feature.
  alias -g '${1+"$@"}'='"$@"'
  setopt NO_GLOB_SUBST
else
  case `(set -o) 2>/dev/null` in *posix*) set -o posix;; esac
fi

set -e

case $# in
  0) echo "$0: missing argument" >&2; exit 99;;
  1) ;;
  *) echo "$0: too many arguments" >&2; exit 99;;
esac

case $1 in
  --generate-makefile|--generate-data)
    instspc_action=`expr x"$1" : x'--\(.*\)'`
    ;;
  build-*.instspc|*/build-*.instspc)
    instspc_action=test-build
    instspc_test_name=`expr /"$1" : '.*/build-\(.*\)\.instspc'`
    ;;
  install-*.instspc|*/install-*.instspc)
    instspc_action=test-install
    instspc_test_name=`expr /"$1" : '.*/install-\(.*\)\.instspc'`
    ;;
  *)
    echo "$0: invalid argument '$1'" >&2
    exit 99
    ;;
esac

# Helper subroutine for test data definition.
# Usage: define_problematic_string NAME STRING
define_problematic_string ()
{
  tst=$1
  shift
  eval "instspc__$tst=\$1" || exit 99
  shift
  instspc_names_list="$instspc_names_list $tst"
  # Some of the "problematic" characters cannot be used in the name of
  # a build or install directory on a POSIX host.  These lists should
  # be empty, but are not due to limitations in Autoconf, Automake, Make,
  # M4, or the shell.
  case " $* " in *' fail-build '*|*' build-fail '*)
    instspc_xfail_builds_list="$instspc_xfail_builds_list $tst";;
  esac
  case " $* " in *' fail-install '*|*' install-fail '*)
    instspc_xfail_installs_list="$instspc_xfail_installs_list $tst";;
  esac
}

# Helper subroutines for creation of input data files.

create_input_data ()
{
  mkdir sub

  unindent > configure.in << 'EOF'
    AC_INIT([instspc], [1.0])
    AM_INIT_AUTOMAKE
    AC_CONFIG_FILES([Makefile])
    AC_PROG_CC
    AC_PROG_RANLIB
    AC_OUTPUT
EOF

  : > sub/base.h
  : > sub/nobase.h
  : > sub/base.dat
  : > sub/nobase.dat
  : > sub/base.sh
  : > sub/nobase.sh

  unindent > source.c << 'EOF'
    int
    main (int argc, char **argv)
    {
      return 0;
    }
EOF

  unindent > Makefile.am << 'EOF'
    foodir = $(prefix)/foo
    fooexecdir = $(prefix)/foo

    foo_HEADERS = sub/base.h
    nobase_foo_HEADERS = sub/nobase.h

    dist_foo_DATA = sub/base.dat
    nobase_dist_foo_DATA = sub/nobase.dat

    dist_fooexec_SCRIPTS = sub/base.sh
    nobase_dist_fooexec_SCRIPTS = sub/nobase.sh

    fooexec_PROGRAMS = sub/base
    nobase_fooexec_PROGRAMS = sub/nobase
    sub_base_SOURCES = source.c
    sub_nobase_SOURCES = source.c

    fooexec_LIBRARIES = sub/libbase.a
    nobase_fooexec_LIBRARIES = sub/libnobase.a
    sub_libbase_a_SOURCES = source.c
    sub_libnobase_a_SOURCES = source.c

    .PHONY: test-install-sep
    test-install-sep: install
	test   -f '$(DESTDIR)/$(file)-prefix/foo/sub/nobase.h'
	test ! -f '$(DESTDIR)/$(file)-prefix/foo/nobase.h'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/base.h'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/sub/nobase.dat'
	test ! -f '$(DESTDIR)/$(file)-prefix/foo/nobase.dat'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/base.dat'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/sub/nobase.sh'
	test ! -f '$(DESTDIR)/$(file)-prefix/foo/nobase.sh'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/base.sh'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/sub/nobase$(EXEEXT)'
	test ! -f '$(DESTDIR)/$(file)-prefix/foo/nobase$(EXEEXT)'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/base$(EXEEXT)'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/sub/libnobase.a'
	test ! -f '$(DESTDIR)/$(file)-prefix/foo/libnobase.a'
	test   -f '$(DESTDIR)/$(file)-prefix/foo/libbase.a'
EOF

  $ACLOCAL
  $AUTOCONF
  $AUTOMAKE -a

  : > success
}

# Be sure to avoid interferences from the environment.
instspc_names_list=''
instspc_xfail_builds_list=''
instspc_xfail_installs_list=''


# ================= #
#  Test data begin  #
# ----------------- #

# Some control characters that are white space.
bs=''   # back space
cr=''   # carriage return
ff=''   # form feed
ht='	' # horizontal tab
lf='
'         # line feed (aka newline)

# Hack to save typing and make code visually clearer.
def=define_problematic_string

$def    squote          \'          fail-build  fail-install
$def    dquote          '"'         fail-build  fail-install
$def    bquote          '`'         fail-build  fail-install
$def    sharp           '#'         fail-build  fail-install
$def    dollar          '$'         fail-build  fail-install
$def    bang            '!'
$def    bslash          '\'         fail-build
$def    ampersand       '&'         fail-build
$def    percent         '%'
$def    leftpar         '('
$def    rightpar        ')'
$def    pipe            '|'
$def    caret           '^'
$def    tilde           '~'
$def    qmark           '?'
$def    star            '*'
$def    plus            '+'
$def    minus           '-'
$def    comma           ','
$def    colon           ':'
$def    semicol         ';'
$def    equal           '='
$def    less            '<'
$def    more            '>'
$def    at              '@'
$def    lqbrack         '['
$def    rqbrack         ']'
$def    lcbrack         '{'
$def    rcbrack         '}'
$def    space           ' '
$def    tab             "$ht"
$def    linefeed        "$lf"       fail-build  fail-install
$def    backspace       "$bs"
$def    formfeed        "$ff"
$def    carriageret     "$cr"
$def    quadrigraph0    '@&t@'      fail-build
$def    quadrigraph1    '@<:@'
$def    quadrigraph2    '@:>@'
$def    quadrigraph3    '@S|@'
$def    quadrigraph4    '@%:@'
$def    a_b             'a b'
$def    a__b            'a  b'
$def    a_lf_b          "a${lf}b"   fail-build  fail-install
$def    dotdotdot       '...'
$def    dosdrive        'a:'
$def    miscglob1       '?[a-z]*'
$def    miscglob2       '.*?[0-9]'

unset def

# --------------- #
#  Test data end  #
# =============== #


if test x"$instspc_action" = x"generate-makefile"; then
  # We must generate a makefile fragment on stdout.  It must refer
  # to all tests at once, hence the loop below.
  echo '## Generated by instspc-tests.sh.  DO NOT EDIT!'
  echo 'instspc_tests ='
  echo 'instspc_xfail_tests ='
  for test_name in $instspc_names_list; do
    echo "instspc_tests += build-$test_name.instspc"
    echo "instspc_tests += install-$test_name.instspc"
  done
  for test_name in $instspc_xfail_builds_list; do
    echo "instspc_xfail_tests += build-$test_name.instspc"
  done
  for test_name in $instspc_xfail_installs_list; do
    echo "instspc_xfail_tests += install-$test_name.instspc"
  done
  exit 0
fi

# We'll need the full setup provided by `tests/defs'.  Temporarily disable
# the errexit flag, since the setup code might not be prepared to deal
# with it.  Also pre-set `$me' for `tests/defs', so that different calls
# to `instspc-tests.sh' won't try to use the same temporary directory.
if test x"$instspc_action" = x"generate-data"; then
  me=instspc-data
else
  me=$instspc_action-$instspc_test_name
fi
set +e
. ./defs || Exit 99
set -e

# The directory set up by the `generate-data' action should contain all
# the files we need.  So remove the other files created by ./defs.  And
# check we really are in a temporary `*.dir' directory in the build tree,
# since the last thing we want is to remove some random user files!
test -f ../defs-static && test -f ../defs || Exit 99
case `pwd` in *.dir);; *) Exit 99;; esac
rm -f *

if test x"$instspc_action" = x"generate-data"; then
  # We must *not* remove the test directory, since its contents must be
  # used by following dependent tests.
  keep_testdirs=yes
  create_input_data
  Exit 0
fi

###  If we are still here, we have to run a test ...

eval "instspc_test_string=\${instspc__$instspc_test_name}" || Exit 99
if test x"$instspc_test_string" = x; then
  echo "$me: invalid test name: '$instspc_test_name'" >&2
  Exit 99
fi

test -f ../instspc-data.dir/success || {
  echo "$me: setup by instspc-data.test failed" >&2
  Exit 99
}

# Skip if this system doesn't support these characters in file names.
mkdir "./$instspc_test_string" || Exit 77

case $instspc_action in
  test-build)
    dest=`pwd`/_dest
    relbuilddir=../..
    cd "./$instspc_test_string"
    ;;
  test-install)
    dest=`pwd`/$instspc_test_string
    relbuilddir=..
    ;;
  *)
    echo "$me: internal error: invalid action '$instspc_action'"
    Exit 99
    ;;
esac

$relbuilddir/instspc-data.dir/configure \
  --prefix "/$instspc_test_string-prefix"
$MAKE
# Some make implementations eliminate leading and trailing whitespace
# from macros passed on the command line, and some eliminate leading
# whitespace from macros set from environment variables, so prepend
# './' and use the latter here.
# Tru64 sh -e needs '|| Exit' in order to work correctly.
DESTDIR="$dest" file="./$instspc_test_string" $MAKE -e test-install-sep \
  || Exit 1

:
