## --------------------------------------------------------- ##
## Fake the existence of programs that GNU maintainers use.  ##
## --------------------------------------------------------- ##
dnl AM_MISSING_PROG(NAME, PROGRAM)
AC_DEFUN(AM_MISSING_PROG, [
AC_REQUIRE([AM_MISSING_HAS_RUN])
$1=${$1-"${am_missing_run}$2"}
AC_SUBST($1)])

dnl AM_MISSING_HAS_RUN.
dnl Define MISSING if not defined so far and test if it supports --run.
dnl If it does, set am_missing_run to use it, otherwise, to nothing.
AC_DEFUN([AM_MISSING_HAS_RUN], [
test x"${MISSING+set}" = xset || \
  MISSING="\${SHELL} $ac_aux_dir/missing"
if ${SHELL-/bin/sh} -c "$MISSING --run :"; then
  am_missing_run="$MISSING --run "
else
  am_missing_run=
  AC_MSG_WARN([\`missing' script is too old or missing])
fi
])
