dnl aclocal.m4 generated automatically by aclocal 1.1b

# Do all the work for Automake.  This macro actually does too much --
# some checks are only needed if your package does certain things.
# But this isn't really a big deal.

dnl Usage:
dnl AM_INIT_AUTOMAKE(package,version)

AC_DEFUN(AM_INIT_AUTOMAKE,
[AC_REQUIRE([AM_PROG_INSTALL])
PACKAGE=[$1]
AC_SUBST(PACKAGE)
VERSION=[$2]
AC_SUBST(VERSION)
AC_ARG_PROGRAM
AC_PROG_MAKE_SET])

## --------------------------------------------------------- ##
## Use AC_PROG_INSTALL, supplementing it with INSTALL_SCRIPT ##
## substitution.                                             ##
## From Franc,ois Pinard                                     ##
## --------------------------------------------------------- ##

AC_DEFUN(AM_PROG_INSTALL,
[AC_REQUIRE([AC_PROG_INSTALL])
test -z "$INSTALL_SCRIPT" && INSTALL_SCRIPT='${INSTALL} -m 755'
AC_SUBST(INSTALL_SCRIPT)dnl
])

