dnl --------------------------------------------------------- ##
dnl Use AC_PROG_INSTALL, supplementing it with INSTALL_SCRIPT ##
dnl substitution.                                             ##
dnl --------------------------------------------------------- ##

AC_DEFUN(fp_PROG_INSTALL,
[AC_PROG_INSTALL
test -z "$INSTALL_SCRIPT" && INSTALL_SCRIPT='${INSTALL} -m 755'
AC_SUBST(INSTALL_SCRIPT)dnl
])
