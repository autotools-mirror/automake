# Figure out how to run the assembler.

# AM_PROG_AS
AC_DEFUN([AM_PROG_AS],
[# By default we simply use the C compiler to build assembly code.
AC_REQUIRE([AC_PROG_CC])
: ${AS='$(CC)'}
# Set ASFLAGS if not already set.
: ${ASFLAGS='$(CFLAGS)'}
AC_SUBST(AS)
AC_SUBST(ASFLAGS)])
