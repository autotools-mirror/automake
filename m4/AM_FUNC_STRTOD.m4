dnl From Jim Meyering.

# serial 1

# @defmac AC_FUNC_STRTOD
# @maindex FUNC_STRTOD
# @ovindex LIBOBJS
# If the @code{strtod} function is not available, or does not work
# correctly (like the one on SunOS 5.4), add @samp{strtod.o} to output
# variable @code{LIBOBJS}.
# @end defmac

AC_DEFUN(AM_FUNC_STRTOD,
[AC_CACHE_CHECK(for working strtod, am_cv_func_strtod,
[AC_TRY_RUN([
double strtod ();
int
main()
{
  {
    /* Some versions of Linux strtod mis-parse strings with leading '+'.  */
    char *string = " +69";
    char *term;
    double value;
    value = strtod (string, &term);
    if (value != 69 || term != (string + 4))
      exit (1);
  }

  {
    /* Under Solaris 2.4, strtod returns the wrong value for the
       terminating character under some conditions.  */
    char *string = "NaN";
    char *term;
    strtod (string, &term);
    if (term != string && *(term - 1) == 0)
      exit (1);
  }
  exit (0);
}
], am_cv_func_strtod=yes, am_cv_func_strtod=no, am_cv_func_strtod=no)])
test $am_cv_func_strtod = no && LIBOBJS="$LIBOBJS strtod.o"
AC_SUBST(LIBOBJS)dnl
if test $am_cv_func_strtod = no; then
  AC_CHECK_FUNCS(pow)
  if test $am_cv_func_pow = no; then
    AC_CHECK_LIB(m, pow)
  fi
fi
])
