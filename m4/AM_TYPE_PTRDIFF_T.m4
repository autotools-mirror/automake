# From Ulrich Drepper.

AC_DEFUN(AM_TYPE_PTRDIFF_T,
  [AC_CACHE_CHECK([for ptrdiff_t], ac_cv_type_ptrdiff_t,
     [AC_TRY_COMPILE([#include <stddef.h>], [ptrdiff_t p],
		     ac_cv_type_ptrdiff_t=yes, ac_cv_type_ptrdiff_t=no)])
   if test $ac_cv_type_ptrdiff_t = yes; then
     AC_DEFINE(HAVE_PTRDIFF_T)
   fi
])
