# One issue with vendor `install' (even GNU) is that you can't
# specify the program used to strip binaries.  This is especially
# annoying in cross=compiling environments, where the build's strip
# is unlikely to handle the host's binaries.
# Fortunately install-sh will honor a STRIPPROG variable, so if we ever
# need to use a non standard strip, we just have to make sure we use
# install-sh with the STRIPPROG variable set.
AC_DEFUN([AM_PROG_INSTALL_STRIP],
[AC_REQUIRE([AM_MISSING_INSTALL_SH])
dnl Don't test for $cross_compiling = yes, it might be `maybe'...
# We'd like to do this but we can't because it will unconditionally
# require config.guess.  One way would be if autoconf had the capability
# to let us compile in this code only when config.guess was already
# a possibility.
#if test "$cross_compiling" != no; then
#  # since we are cross-compiling, we need to check for a suitable `strip'
#  AM_PROG_STRIP
#  if test -z "$STRIP"; then
#    AC_MSG_WARN([strip missing, install-strip will not strip binaries])
#  fi
#fi

# If $STRIP is defined (either by the user, or by AM_PROG_STRIP),
# instruct install-strip to use install-sh and the given $STRIP program.
# Otherwise, just use ${INSTALL}: the idea is to use the vendor install
# as much as possible, because it's faster.
if test -z "$STRIP"; then
  # The top level make will set INSTALL_PROGRAM=$(INSTALL_STRIP_PROGRAM)
  # and the double dolard below is there to make sure that ${INSTALL}
  # is substitued in the sub-makes, not at the top-level; this is
  # needed if ${INSTALL} is a relative path (ajusted in each subdirectory
  # by config.status).
  INSTALL_STRIP_PROGRAM='$${INSTALL} -s'
  INSTALL_STRIP_PROGRAM_ENV=''
else
  _am_dirpart="`echo $install_sh | sed -e 's,//*[[^/]]*$,,'`"
  INSTALL_STRIP_PROGRAM="\${SHELL} \`CDPATH=: && cd $_am_dirpart && pwd\`/install-sh -c -s"
  INSTALL_STRIP_PROGRAM_ENV="STRIPPROG='\$(STRIP)'"
fi
AC_SUBST([STRIP])
AC_SUBST([INSTALL_STRIP_PROGRAM])
AC_SUBST([INSTALL_STRIP_PROGRAM_ENV])])

#AC_DEFUN([AM_PROG_STRIP],
#[# Check for `strip', unless the installer
# has set the STRIP environment variable.
# Note: don't explicitly check for -z "$STRIP" here because
# that will cause problems if AC_CANONICAL_* is AC_REQUIREd after
# this macro, and anyway it doesn't have an effect anyway.
#AC_CHECK_TOOL([STRIP],[strip])
#])
