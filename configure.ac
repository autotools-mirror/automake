# Process this file with autoconf to produce a configure script.

# Copyright (C) 1995-2012 Free Software Foundation, Inc.
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

AC_PREREQ([2.68])
AC_INIT([GNU Automake], [1.11a], [bug-automake@gnu.org])

AC_CONFIG_SRCDIR([automake.in])
AC_CONFIG_AUX_DIR([lib])

AM_SILENT_RULES([yes])

AC_CANONICAL_HOST
AC_CANONICAL_BUILD

# Save the AUTOCONF setting before AM_INIT_AUTOMAKE overrides it; this
# way we can run Autoconf tests from configure (or from the test
# suite) without being bothered by 'missing'.  Likewise for autom4te,
# autoreconf, autoheader, and autoupdate.
AC_SUBST([am_AUTOCONF], ["${AUTOCONF-autoconf}"])
AC_SUBST([am_AUTOM4TE], ["${AUTOM4TE-autom4te}"])
AC_SUBST([am_AUTORECONF], ["${AUTORECONF-autoreconf}"])
AC_SUBST([am_AUTOHEADER], ["${AUTOHEADER-autoheader}"])
AC_SUBST([am_AUTOUPDATE], ["${AUTOUPDATE-autoupdate}"])

dnl We call AC_PROG_CC in an unusual way, and only for use in our
dnl testsuite, so also use 'no-dependencies' and 'no-define' among
dnl the automake options to avoid bloating and potential problems.
AM_INIT_AUTOMAKE([1.10a dist-xz filename-length-max=99 color-tests
		  parallel-tests silent-rules no-define no-dependencies])

# The API version is the base version.  We must guarantee
# compatibility for all releases with the same API version.
# Our current rule is that:
# * All releases, including the prereleases, in an X.Y series
#   are compatible.  So 1.5.1c is compatible with 1.5.
# * Prereleases on the trunk are all incompatible -- 1.5b and 1.5c
#   aren't the same.
APIVERSION=`echo "$VERSION" | sed -e 's/^\([[0-9]]*\.[[0-9]]*[[a-z]]*\).*$/\1/'`
AC_SUBST([APIVERSION])

AC_SUBST([pkgvdatadir], ["\${datadir}/$PACKAGE-$APIVERSION"])
AC_SUBST([scriptdir], ["\${pkgvdatadir}"])
AC_SUBST([amdir], ["\${pkgvdatadir}/am"])
AC_SUBST([automake_acdir], ["\${datadir}/aclocal-$APIVERSION"])
AC_SUBST([system_acdir], ["\${datadir}/aclocal"])

# $AUTOMAKE and $ACLOCAL are always run after a "cd $top_srcdir",
# hence '.' is really what we want for perllibdir, libdir, and acdir.
ACLOCAL="perllibdir=\"`pwd`/lib$PATH_SEPARATOR./lib\" \"`pwd`/aclocal\" --acdir=m4 -I m4"
AUTOMAKE="perllibdir=\"`pwd`/lib$PATH_SEPARATOR./lib\" \"`pwd`/automake\" --libdir=lib"

AC_PATH_PROG([PERL], [perl])
if test -z "$PERL"; then
   AC_MSG_ERROR([perl not found])
fi
# Save details about the selected perl interpreter in config.log.
AM_RUN_LOG([$PERL --version])
$PERL -e 'require 5.006;' || {
   AC_MSG_ERROR(
[perl 5.6 or better is required; perl 5.8.2 or better
is recommended.  If you have several perl versions
installed, select the one Automake should use using
  ./configure PERL=/path/to/perl])
}

# We require ithreads support, and version 5.7.2 for CLONE.
AC_CACHE_CHECK([whether $PERL supports ithreads], [am_cv_prog_PERL_ithreads],
[if $PERL -e '
    require 5.007_002;
    use Config;
    if ($Config{useithreads})
      {
	require threads;
	import threads;
	require Thread::Queue;
	import Thread::Queue;
	exit 0;
      }
    exit 1;' >&AS_MESSAGE_LOG_FD 2>&1
then
  am_cv_prog_PERL_ithreads=yes
else
  am_cv_prog_PERL_ithreads=no
fi])
if test $am_cv_prog_PERL_ithreads = yes; then
  PERL_THREADS=1;
else
  PERL_THREADS=0;
fi
AC_SUBST([PERL_THREADS])

# The test suite will skip some tests if tex is absent.
AC_CHECK_PROG([TEX], [tex], [tex])
# Save details about the selected TeX program in config.log.
# Redirect input from /dev/null, as TeX might otherwise hang waiting
# for input from the terminal.
AM_RUN_LOG([$TEX --version </dev/null])

# The test suite will skip some tests if no lex or yacc program is
# available.
# We don't use AC_PROG_LEX nor AC_PROG_YACC here because:
#  1. we don't want flex (resp. bison) to be preferred to system lex
#     (resp. system yacc);
#  2. we don't want $LEX (resp. $YACC) to be defined to ':' (resp. 'yacc')
#     by default;
#  3. we prefer not to have the variables YFLAGS, LEX_OUTPUT_ROOT and
#     LEXLIB to be calculated and/or AC_SUBST'd;
#  4. we prefer that the YACC and LEX variables are not reported in the
#     configure help screen.
AC_CHECK_PROGS([YACC], [yacc byacc 'bison -y'], [false])
AC_CHECK_PROGS([LEX], [lex flex], [false])

# Generate man pages.
AM_MISSING_PROG([HELP2MAN], [help2man])

# Test for Autoconf.  We run Autoconf in a subdirectory to ease
# deletion of any files created (such as those added to
# autom4te.cache).  We used to perform only the last of the three
# following tests, but some users were unable to figure out that their
# installation was broken since --version appeared to work.

required_autoconf_version=2.62
AC_CACHE_CHECK([whether autoconf is installed], [am_cv_autoconf_installed],
[if AM_RUN_LOG([$am_AUTOCONF --version]);
then
  am_cv_autoconf_installed=yes
else
  am_cv_autoconf_installed=no
fi])
if test "$am_cv_autoconf_installed" = no; then
  AC_MSG_ERROR([Autoconf $required_autoconf_version or better is required.
    Please make sure it is installed and in your PATH.])
fi

AC_CACHE_CHECK([whether autoconf works], [am_cv_autoconf_works],
[mkdir conftest
echo 'AC''_INIT' > conftest/conftest.ac
if AM_RUN_LOG([cd conftest && $am_AUTOCONF -o /dev/null conftest.ac]);
then
  am_cv_autoconf_works=yes
else
  am_cv_autoconf_works=no
fi
rm -rf conftest])
if test "$am_cv_autoconf_works" = no; then
  AC_MSG_ERROR([The installed version of autoconf does not work.
    Please check config.log for error messages before this one.])
fi

AC_CACHE_CHECK([whether autoconf is recent enough], [am_cv_autoconf_version],
[mkdir conftest
dnl Creative quoting required to avoid spurious expansion of AC_PREREQ macro
echo 'AC'"_PREREQ([[$required_autoconf_version]])" > conftest/conftest.ac
if AM_RUN_LOG([cd conftest && $am_AUTOCONF -o /dev/null conftest.ac]);
then
  am_cv_autoconf_version=yes
else
  am_cv_autoconf_version=no
fi
rm -rf conftest])
if test "$am_cv_autoconf_version" = no; then
  AC_MSG_ERROR([Autoconf $required_autoconf_version or better is required.])
fi

# Test for ln.  We need use it to install the versioned binaries.
AC_MSG_CHECKING([whether ln works])
AC_CACHE_VAL([am_cv_prog_ln], [
rm -f conftest conftest.file
: >conftest.file
if ln conftest.file conftest 2>/dev/null; then
  am_cv_prog_ln=ln
else
  am_cv_prog_ln='cp -p'
fi
rm -f conftest conftest.file])
AC_SUBST([LN], [$am_cv_prog_ln])
result=no
test "x$am_cv_prog_ln" = xln && result=yes
AC_MSG_RESULT([$result])

# The amount we should wait after modifying files depends on the platform.
# On Windows '95, '98 and ME, files modifications have 2-seconds
# granularity and can be up to 3 seconds in the future w.r.t. the
# system clock.  When it is important to ensure one file is older
# than another we wait at least 5 seconds between creations.
case $build in
  *-pc-msdosdjgpp) MODIFICATION_DELAY=5;;
  *)               MODIFICATION_DELAY=2;;
esac
AC_SUBST([MODIFICATION_DELAY])

# Test for things needed by the test suite.
AC_PROG_EGREP
AC_PROG_FGREP

AC_CACHE_CHECK([whether $SHELL has working 'set -e' with exit trap],
[am_cv_sh_errexit_works],
[if $SHELL -ec "trap 'exit \$?' 0; (exit 77); exit 77"; test $? = 77
then
  am_cv_sh_errexit_works=yes
else
  am_cv_sh_errexit_works=no
fi
])
if test $am_cv_sh_errexit_works = no; then
  AC_MSG_WARN(["${MAKE-make} check" will leave leftover directories tests/*.dir])
  AC_MSG_WARN([you can clean them up manually using "${MAKE-make} clean" or])
  AC_MSG_WARN(["cd tests && ${MAKE-make} clean-local-check'])
fi
AC_SUBST([sh_errexit_works], [$am_cv_sh_errexit_works])


###########################################################################

# Look for C, C++ and fortran compilers to be used in the testsuite.

dnl We don't want to abort our configuration script if no C compiler is
dnl available, as such a compiler is only required to run part of the
dnl testsuite, not to build or install Automake.  Ditto for C++, Fortran
dnl and Fortran 77 compilers.  Unfortunately, autoconf does not offer an
dnl easy way to obtain this behaviour, so we'll need a few hacks.

dnl We want the body of this macro to expand as a single shell statement,
dnl thus we wrap it into { ... } brackets.
AC_DEFUN([_AM_WRAP_MSG_ERROR], [ {
  AC_MSG_WARN([$1])
  am__failed=yes
  break
} ])

AC_DEFUN([_AM_COMPILER_CAN_FAIL], [
  m4_pushdef([AC_MSG_FAILURE], m4_defn([_AM_WRAP_MSG_ERROR]))
  m4_pushdef([AC_MSG_ERROR],   m4_defn([_AM_WRAP_MSG_ERROR]))
  am__failed=no
  while :; do
     $1
     break
  done
  AS_IF([test $am__failed = yes], [$2])
  # We have to clear these cache variables, so that future checks on
  # compilers for different languages won't be confused.
  unset ac_cv_objext ac_cv_exeext
  # We also need to meddle with the autoconf internals to ensure that
  # checks to find object and executable extensions will be run anew.
  # FIXME: In the long run, the better thing to do would be to fix
  # FIXME: autoconf instead ...
  m4_undefine([m4_provide(_AC_COMPILER_OBJEXT)])
  m4_undefine([m4_provide(_AC_COMPILER_EXEEXT)])
  m4_popdef([AC_MSG_FAILURE])
  m4_popdef([AC_MSG_ERROR])
])

AC_DEFUN([_AM_SKIP_COMP_TESTS],
  [AC_MSG_NOTICE([tests requiring the $1 compiler will be skipped])])

# Prefer generic compilers to GNU ones when possible.  This will ensure
# more testsuite coverage "in the wild".
# Note that we don't look for the MSVC C/C++ compiler here.  This is
# deliberate; for more discussion and rationale, see:
# <http://lists.gnu.org/archive/html/automake-patches/2012-01/msg00130.html>

AC_MSG_NOTICE([will now look for generic compilers])

# C compiler.
_AM_COMPILER_CAN_FAIL(dnl
  [AC_PROG_CC([cc gcc])],
  [CC=false; _AM_SKIP_COMP_TESTS([C])])

AS_IF([test x"$GCC" = x"yes"], [am_CC_is_GNU=yes], [am_CC_is_GNU=no])

# The list of C++ compilers here has been copied, pasted and edited
# from 'lib/autoconf/c.m4:AC_PROG_CXX' in the Autoconf distribution.
# Keep it in sync, or better again, find out a way to avoid this code
# duplication.
_AM_COMPILER_CAN_FAIL([AC_PROG_CXX(dnl
  [aCC CC FCC KCC RCC xlC_r xlC c++ cxx cc++ gpp g++])],
  [CXX=false; _AM_SKIP_COMP_TESTS([C++])])

AS_IF([test x"$GXX" = x"yes"], [am_CXX_is_GNU=yes], [am_CXX_is_GNU=no])

# The lists of Fortran compilers here has been copied, pasted and edited
# from file 'lib/autoconf/fortran.m4' in the Autoconf distribution.
# Keep it in sync, or better again, find out a way to avoid this code
# duplication.

_AM_COMPILER_CAN_FAIL([AC_PROG_FC(dnl
  [xlf95 f95 fort ifort ifc efc pgfortran pgf95 lf95 ftn nagfor] dnl
  [xlf90 f90 pgf90 pghpf epcf90 g95 gfortran])],
  [FC=false; _AM_SKIP_COMP_TESTS([Fortran])])

# FIXME this won't work as expected until we can assume autoconf 2.69 :-(
AS_IF([test x"$GFC" = x"yes"], [am_FC_is_GNU=yes], [am_FC_is_GNU=no])

_AM_COMPILER_CAN_FAIL([AC_PROG_F77(dnl
  [xlf f77 frt pgf77 cf77 fort77 fl32 af77 g77 gfortran])],
  [F77=false; _AM_SKIP_COMP_TESTS([Fortran 77])])

AS_IF([test x"$G77" = x"yes"], [am_F77_is_GNU=yes], [am_F77_is_GNU=no])

# Some tests will need the GNU compilers.  Searching for them here would
# be overkill, since our testsuite already handles their search and setup
# pretty well.  But in case the compilers already found are the GNU ones,
# we want to use them in the testsuite where GNU compilers are required.
# Also, in case the compilers detected above (at configure time) are not
# the GNU ones, we cannot use the values of CFLAGS, CXXFLAGS, FCFLAGS and
# FFLAGS detected for them with the GNU compilers too, since it's likely
# they won't be compatible.  So we allow the user to define variants of
# these variables for the GNU compilers separately.

AC_MSG_NOTICE([will now look for GNU compilers])

# GNU C compiler.
AC_ARG_VAR([GNU_CC],     [GNU C compiler])
AC_ARG_VAR([GNU_CFLAGS], [GNU C compiler flags])
if test $am_CC_is_GNU = yes; then
  AC_MSG_NOTICE([$CC is already a GNU C compiler])
  GNU_CC=$CC GNU_CFLAGS=${GNU_CFLAGS-$CFLAGS}
else
  AC_CHECK_TOOLS([GNU_CC], [gcc], [false])
fi
AS_IF([AM_RUN_LOG([$GNU_CC --version && $GNU_CC -v])], [],
      [AC_MSG_WARN([botched installation for GNU C compiler])
       _AM_SKIP_COMP_TESTS([GNU C])])

# GNU C++ compiler.
AC_ARG_VAR([GNU_CXX],      [GNU C++ compiler])
AC_ARG_VAR([GNU_CXXFLAGS], [GNU C++ compiler flags])
if test $am_CXX_is_GNU = yes; then
  AC_MSG_NOTICE([$CXX is already a GNU C++ compiler])
  GNU_CXX=$CXX
  GNU_CXXFLAGS=${GNU_CXXFLAGS-$CXXFLAGS}
else
  AC_CHECK_TOOLS([GNU_CXX], [g++ gpp], [false])
fi
AS_IF([AM_RUN_LOG([$GNU_CXX --version && $GNU_CXX -v])], [],
      [AC_MSG_WARN([botched installation for GNU C++ compiler])
       _AM_SKIP_COMP_TESTS([GNU C++])])

# GNU Fortran compiler.
AC_ARG_VAR([GNU_FC],      [GNU Fortran compiler])
AC_ARG_VAR([GNU_FCFLAGS], [GNU Fortran compiler flags])
if test $am_FC_is_GNU = yes; then
  AC_MSG_NOTICE([$FC is already a GNU Fortran compiler])
  GNU_FC=$FC
  GNU_FCFLAGS=${GNU_FCFLAGS-$FCFLAGS}
else
  AC_CHECK_TOOLS([GNU_FC], [gfortran], [false])
fi
AS_IF([AM_RUN_LOG([$GNU_FC --version && $GNU_FC -v])], [],
      [AC_MSG_WARN([botched installation for GNU Fortran compiler])
       _AM_SKIP_COMP_TESTS([GNU Fortran])])

# GNU Fortran 77 compiler.
AC_ARG_VAR([GNU_F77],    [GNU Fortran 77 compiler])
AC_ARG_VAR([GNU_FFLAGS], [GNU Fortran 77 compiler flags])
if test $am_F77_is_GNU = yes; then
  AC_MSG_NOTICE([$F77 is already a GNU Fortran 77 compiler])
  GNU_F77=$F77
  GNU_FFLAGS=${GNU_FFLAGS-$FFLAGS}
else
  AC_CHECK_TOOLS([GNU_F77], [g77 gfortran], [false])
fi
AS_IF([AM_RUN_LOG([$GNU_F77 --version && $GNU_F77 -v])], [],
      [AC_MSG_WARN([botched installation for GNU Fortran 77 compiler])
      _AM_SKIP_COMP_TESTS([GNU Fortran 77])])

# GNU Java compiler.
AC_ARG_VAR([GNU_GCJ], [GNU Java compiler])
AC_ARG_VAR([GNU_GCJFLAGS], [GNU Java compiler flags])
AC_CHECK_TOOLS([GNU_GCJ], [gcj], [false])
AS_IF([AM_RUN_LOG([$GNU_GCJ --version && $GNU_GCJ -v])], [],
      [AC_MSG_WARN([botched installation for GNU Java compiler])
      _AM_SKIP_COMP_TESTS([GNU Java])])

# If we have been able to find at least a working compiler above, we
# know what the object and executable extensions for this platform are.
OBJEXT=${ac_cv_objext-UNKNOWN}
EXEEXT=${ac_cv_exeext-UNKNOWN}
AC_SUBST([OBJEXT])
AC_SUBST([EXEEXT])

###########################################################################

AC_CONFIG_FILES([
  Makefile
  contrib/Makefile
  doc/Makefile
  lib/Makefile
  m4/Makefile
  tests/Makefile
])
AC_CONFIG_LINKS([GNUmakefile:GNUmakefile])
AC_CONFIG_LINKS([tests/defs:tests/defs])
AC_CONFIG_FILES([tests/wrap/aclocal-${APIVERSION}:tests/wrap/aclocal.in],
                [chmod +x tests/wrap/aclocal-${APIVERSION}],
	        [APIVERSION=$APIVERSION])
AC_CONFIG_FILES([tests/wrap/automake-${APIVERSION}:tests/wrap/automake.in],
                [chmod +x tests/wrap/automake-${APIVERSION}],
	        [APIVERSION=$APIVERSION])

AC_OUTPUT

# Inform the user if this version of automake is a beta release or
# a development snapshot.
# According to HACKING, the version of a development snapshot should
# end with an "odd" letter (a, c, ...), the version of a test release
# should end wit an "even" letter (b, d, ...).

am_stable_version_rx='[[1-9]\.[0-9]+(\.[0-9]+)?]'
am_beta_version_rx="[$am_stable_version_rx[bdfhjlnprtvxz]]"

am_release_type=`AS_ECHO(["$PACKAGE_VERSION"]) | LC_ALL=C awk ["
  /^$am_stable_version_rx$/ { print \"stable\"; exit(0); }
  /^$am_beta_version_rx$/ { print \"beta version\"; exit(0); }
  { print \"development snapshot\"; }"]`

test "$am_release_type" = stable || cat <<EOF

WARNING: You are about to use a $am_release_type of automake.
WARNING: It might easily suffer from new bugs or regressions.
WARNING: You are strongly advised not to use it in production code.

Please report bugs, problems and feedback to <AC_PACKAGE_BUGREPORT>.
EOF

AS_EXIT([0])
