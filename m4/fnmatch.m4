## --------------------------- ##
## Check for a working fnmatch ##
## --------------------------- ##

# serial 1

# @defmac AC_FUNC_FNMATCH
# @maindex FUNC_FNMATCH
# @ovindex LIBOBJS
# If the @code{fnmatch} function is not available, or does not work
# correctly (like the one on SunOS 5.4), add @samp{fnmatch.o} to output
# variable @code{LIBOBJS}.
# @end defmac

AC_DEFUN(AM_FUNC_FNMATCH,
[AC_MSG_CHECKING(for working fnmatch)
AC_CACHE_VAL(am_cv_func_fnmatch,
# Some versions of Solaris or SCO have broken fnmatch() functions!
# So we run a test program.  If we're cross-compiling, take no chance.
AC_TRY_RUN([main() { exit (fnmatch ("a*", "abc", 0) != 0); }],
am_cv_func_fnmatch=yes, am_cv_func_fnmatch=no, am_cv_func_fnmatch=no))
test $am_cv_func_fnmatch = yes || LIBOBJS="$LIBOBJS fnmatch.o"
AC_MSG_RESULT($am_cv_func_fnmatch)
])
