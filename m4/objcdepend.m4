dnl Dependency tracking checks for Objective C.
dnl AM_OJBC_DEPENDENCIES

dnl Since only gcc can handle Objective C, we skip the checks.

AC_DEFUN(AM_OBJC_DEPENDENCIES,[
AC_REQUIRE([AM_OUTPUT_DEPENDENCY_COMMANDS])
AC_REQUIRE([AM_DEP_SET_VARS])
DEP_OBJCFLAG="$depgccflag"
DEP_OBJCPRECOMP="$depstdprecomp"
DEP_OBJCPOSTCOMP="$depsedmagic"
AC_SUBST(DEP_OBJCFLAG)
AC_SUBST(DEP_OBJCPRECOMP)
AC_SUBST(DEP_OBJCPOSTCOMP)])
