# AM_MAKE_INCLUDE()
# -----------------
# Check to see how make treats includes.
AC_DEFUN([AM_MAKE_INCLUDE],
[am_make=${MAKE-make}
# BSD make uses .include
cat > confinc << 'END'
doit:
	@echo done
END
# If we don't find an include directive, just comment out the code.
AC_MSG_CHECKING([for style of include used by $am_make])
_am_include='#'
for am_inc in include .include; do
   echo "$am_inc confinc" > confmf
   if test "`$am_make -f confmf 2> /dev/null`" = "done"; then
      _am_include=$am_inc
      break
   fi
done
AC_SUBST(_am_include)
AC_MSG_RESULT($_am_include)
rm -f confinc confmf
])
