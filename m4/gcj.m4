dnl Check for Java compiler.
dnl For now we only handle the GNU compiler.

AC_DEFUN(AC_PROG_GCJ,[
AC_CHECK_PROG(GCJ, gcj)
test -z "$GCJ" && AC_MSG_ERROR([no acceptable gcj found in \$PATH])
if test "x${GCJFLAGS+set}" = xset; then
   GCJFLAGS="-g -O2"
fi
AC_SUBST(GCJFLAGS)
])
