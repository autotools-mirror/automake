# Like AC_PROG_CC_C_O, but changed for automake.

AC_DEFUN([AM_PROG_CC_C_O],[
AC_REQUIRE([AC_PROG_CC_C_O])
# FIXME: we rely on the cache variable name because
# there is no other way.
set dummy $CC; ac_cc="`echo [$]2 |
changequote(, )dnl
		       sed -e 's/[^a-zA-Z0-9_]/_/g' -e 's/^[0-9]/_/'`"
changequote([, ])dnl
if eval "test \"`echo '$ac_cv_prog_cc_'${ac_cc}_c_o`\" != yes"; then
   # Losing compiler, so override with the script.
   CC="\$(top_srcdir)/compile $CC"
fi
])
