dnl See how the compiler implements dependency checking.
dnl Usage:
dnl AM_DEPENDENCIES(NAME, PFX)
dnl NAME is either "CC" or "CXX".

dnl Conceptually dependency tracking has 3 parts:
dnl (1) a pre-compilation step
dnl (2) the compilation step (which we can affect only using a flag)
dnl (3) a post-compilation step (which is almost always the same sed
dnl     magic to work around the deleted header file problem)
dnl We try a few techniques and use that to set a single cache variable.
dnl Then we use the cache variable to set the actual variables we use.
dnl A fair amount of ugliness is required to share this code betewen
dnl C and C++.


AC_DEFUN(AM_DEPENDENCIES,[
AC_REQUIRE([AM_OUTPUT_DEPENDENCY_COMMANDS])
AC_REQUIRE([AM_DEP_SET_VARS])
ifelse([$1],CC,[
depcc="$CC"
depcpp="$CPP"
depgcc="$GCC"
depcompile=COMPILE],[
depcc="$CXX"
depcpp="$CXXCPP"
depgcc="$GXX"
depcompile=CXXCOMPILE])
AC_MSG_CHECKING([dependency style of $depcc])
AC_CACHE_VAL(am_cv_[$1]_dependencies_compiler_type,[
am_cv_[$1]_dependencies_compiler_type=none
if test "$depgcc" = yes; then
   am_cv_[$1]_dependencies_compiler_type=gcc
else
   echo '#include "confest.h"' > conftest.c
   echo > conftest.h

   dnl SGI compiler has its own method for side-effect dependency
   dnl tracking.
   if test "$am_cv_[$1]_dependencies_compiler_type" = none; then
      rm -f conftest.P
      if $depcc -c -MDupdate conftest.P && test -f conftest.P; then
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

DEP_[$1]FLAG=
DEP_[$1]PRECOMP=:
DEP_[$1]POSTCOMP=:

case "$am_cv_[$1]_dependencies_compiler_type" in
 gcc)
    depprecomp=none
    DEP_[$1]FLAG="$depgccflag"
    deppostcomp=sedmagic
    ;;

 sgi)
    depprecomp=none
    DEP_[$1]FLAG='-MDupdate .deps/$$pp'
    deppostcomp=sedmagic
    ;;

 dashmstdout)
    depprecomp=dashmstdout
    deppostcomp=sedmagic
    ;;

 cpp)
    depprecomp=cpp
    deppostcomp=none
    ;;

 none)
    depprecomp=none
    deppostcomp=none
    ;;
esac

case "$depprecomp" in
 none)
    ;;

 dashmstdout)
    DEP_[$1]PRECOMP="\$($depcompile) -M \$\$file > .deps/\$\$pp"
    ;;

 cpp)
    dnl We want a pre compilation step which runs CPP (but with all
    dnl the right options!  This is hard).  Then we want to run sed
    dnl on the output, extract `#line' or `# NNN' lines, and turn
    dnl that into correct dependencies.  We might as well do this
    dnl all in one step, so we have no post-compilation step here.
    FIXME
    ;;
esac

dnl We always prepend some boilerplate to the precompilation rule.
dnl This makes it very easy for the user to use this code -- he must
dnl only set the "file" variable.
DEP_[$1]PRECOMP="$depstdprecomp [$]DEP_[$1]PRECOMP"

case "$deppostcomp" in
 sedmagic)
    DEP_[$1]POSTCOMP="$depsedmagic"
    ;;

 none)
    ;;
esac

AC_SUBST(DEP_[$1]PRECOMP)
AC_SUBST(DEP_[$1]POSTCOMP)
AC_SUBST(DEP_[$1]FLAG)
])
