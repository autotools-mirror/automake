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
