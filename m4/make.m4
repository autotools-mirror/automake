# AM_MAKE_INCLUDE()
# -----------------
# Check to see how make treats includes.
AC_DEFUN([AM_MAKE_INCLUDE],
[am_make=${MAKE-make}
cat > confinc << 'END'
doit:
	@echo done
END
# If we don't find an include directive, just comment out the code.
AC_MSG_CHECKING([for style of include used by $am_make])
_am_include='#'
_am_quote=
_am_result=none
# First try GNU make style include.
echo "include confinc" > confmf
if test "`$am_make -s -f confmf 2> /dev/null`" = "done"; then
   _am_include=include
   _am_quote=
   _am_result=GNU
fi
# Now try BSD make style include.
if test "$_am_include" = "#"; then
   echo '.include "confinc"' > confmf
   if test "`$am_make -s -f confmf 2> /dev/null`" = "done"; then
      _am_include=.include
      _am_quote='"'
      _am_result=BSD
   fi
fi
AC_SUBST(_am_include)
AC_SUBST(_am_quote)
AC_MSG_RESULT($_am_result)
rm -f confinc confmf
])
