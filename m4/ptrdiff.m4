# AM_TYPE_PTRDIFF_T

# Copyright 1996, 1998, 2000, 2001 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# From Ulrich Drepper.

# serial 1

AC_DEFUN([AM_TYPE_PTRDIFF_T],
  [AC_CACHE_CHECK([for ptrdiff_t], am_cv_type_ptrdiff_t,
     [AC_TRY_COMPILE([#include <stddef.h>], [ptrdiff_t p],
		     am_cv_type_ptrdiff_t=yes, am_cv_type_ptrdiff_t=no)])
   if test $am_cv_type_ptrdiff_t = yes; then
     AC_DEFINE(HAVE_PTRDIFF_T,1,[Define if system has ptrdiff_t type])
   fi
])
