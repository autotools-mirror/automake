dnl See how the compiler implements dependency checking.
dnl Usage:
dnl AM_DEPENDENCIES(NAME)
dnl NAME is "CC", "CXX" or "OBJC".

dnl We try a few techniques and use that to set a single cache variable.

AC_DEFUN(AM_DEPENDENCIES,[
AC_REQUIRE([AM_SET_DEPDIR])
AC_REQUIRE([AM_OUTPUT_DEPENDENCY_COMMANDS])
ifelse([$1],CC,[
AC_REQUIRE([AC_PROG_CC])
AC_REQUIRE([AC_PROG_CPP])
depcc="$CC"
depcpp="$CPP"
depgcc="$GCC"],[$1],CXX,[
AC_REQUIRE([AC_PROG_CXX])
AC_REQUIRE([AC_PROG_CXXCPP])
depcc="$CXX"
depcpp="$CXXCPP"
depgcc="$GXX"],[$1],OBJC,[
am_cv_OBJC_dependencies_compiler_type=gcc],[
AC_REQUIRE([AC_PROG_][$1])
depcc="$[$1]"
depcpp=""
depgcc="no"])
AC_MSG_CHECKING([dependency style of $depcc])
AC_CACHE_VAL(am_cv_[$1]_dependencies_compiler_type,[
am_cv_[$1]_dependencies_compiler_type=none
if test "$depgcc" = yes; then
   am_cv_[$1]_dependencies_compiler_type=gcc
else
   echo '#include "conftest.h"' > conftest.c
   echo > conftest.h

   dnl SGI compiler has its own method for side-effect dependency
   dnl tracking.
   if test "$am_cv_[$1]_dependencies_compiler_type" = none; then
      rm -f conftest.P
      if $depcc -c -MDupdate conftest.P conftest.c && test -f conftest.P; then
	 am_cv_[$1]_dependencies_compiler_type=sgi
      fi
   fi

   if test "$am_cv_[$1]_dependencies_compiler_type" = none; then
      if test -n "`$depcc -M conftest.c`"; then
	 am_cv_[$1]_dependencies_compiler_type=dashmstdout
      fi
   fi

   dnl As a last resort, see if we can run CPP and extract line
   dnl information from the output.
   dnl FIXME

   rm -f conftest.*
fi
])
AC_MSG_RESULT($am_cv_[$1]_dependencies_compiler_type)
[$1]DEPMODE="depmode=$am_cv_[$1]_dependencies_compiler_type"
AC_SUBST([$1]DEPMODE)
])

dnl Choose a directory name for dependency files.
dnl This macro is AC_REQUIREd in AM_DEPENDENCIES

AC_DEFUN(AM_SET_DEPDIR,[
if test -d .deps || mkdir .deps 2> /dev/null || test -d .deps; then
  DEPDIR=.deps
else
  DEPDIR=_deps
fi
AC_SUBST(DEPDIR)
])
