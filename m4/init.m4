# Do all the work for Automake.  This macro actually does too much --
# some checks are only needed if your package does certain things.
# But this isn't really a big deal.

# serial 1

dnl Usage:
dnl AM_INIT_AUTOMAKE(package,version)

AC_DEFUN(AM_INIT_AUTOMAKE,
[AC_REQUIRE([AM_PROG_INSTALL])
PACKAGE=[$1]
AC_SUBST(PACKAGE)
AC_DEFINE_UNQUOTED(PACKAGE, "$PACKAGE")
VERSION=[$2]
AC_SUBST(VERSION)
AC_DEFINE_UNQUOTED(VERSION, "$VERSION")
AM_SANITY_CHECK
AC_ARG_PROGRAM
AC_CHECK_PROG(ACLOCAL, aclocal, aclocal, \$(SHELL) missing aclocal)
AC_CHECK_PROG(AUTOCONF, autoconf, autoconf, \$(SHELL) missing autoconf)
AC_CHECK_PROG(AUTOMAKE, automake, automake, \$(SHELL) missing automake)
AC_CHECK_PROG(AUTOHEADER, autoheader, autoheader, \$(SHELL) missing autoheader)
AM_CHECK_PROG(MAKEINFO, makeinfo, makeinfo, \$(SHELL) ../missing makeinfo)
AC_PROG_MAKE_SET])
