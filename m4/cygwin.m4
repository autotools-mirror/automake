# Check to see if we're running under Cygwin32, without using
# AC_CANONICAL_*.  If so, set output variable EXEEXT to ".exe".
# Otherwise set it to "".

dnl AM_CYGWIN32()
dnl You might think we can do this by checking for a cygwin32-specific
dnl cpp define.  We can't, because cross-compilers that target
dnl cygwin32 don't use the .exe suffix.  I don't know why.
AC_DEFUN(AM_CYGWIN32,
[AC_CACHE_CHECK(for Cygwin32 environment, am_cv_cygwin32,
[cat > conftest.$ac_ext << 'EOF'
int main () {
/* Nothing.  */
return 0; }
EOF
if AC_TRY_EVAL(ac_link) && test -s conftest.exe; then
   am_cv_cygwin32=yes
else
   am_cv_cygwin32=no
fi
rm -f conftest*])
EXEEXT=
test "$am_cv_cygwin32" = yes && EXEEXT=.exe
AC_SUBST(EXEEXT)])
