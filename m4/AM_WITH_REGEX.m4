## --------------------------------- ##
## Check if --with-regex was given.  ##
## From Franc,ois Pinard             ##
## --------------------------------- ##

# The idea is to distribute rx.[hc] and regex.[hc] together, for
# a while.  The WITH_REGEX symbol (which should also be documented
# in acconfig.h) is used to decide which of regex.h or rx.h should
# be included in the application.  If `./configure --with-regex' is
# given, the package will use the older regex.  Else, a check is
# made to see if rx is already installed, as with newer Linux'es.
# If not found, the package will use the rx from the distribution.
# If found, the package will use the system's rx which, on Linux
# at least, will result in a smaller executable file.

AC_DEFUN(AM_WITH_REGEX,
[AC_MSG_CHECKING(which of rx or regex is wanted)
AC_ARG_WITH(regex,
[  --with-regex            use older regex in lieu of GNU rx for matching],
[if test "$withval" = yes; then
  ac_with_regex=1
  AC_MSG_RESULT(regex)
  AC_DEFINE(WITH_REGEX)
  LIBOBJS="$LIBOBJS regex.o"
fi])
if test -z "$ac_with_regex"; then
  AC_MSG_RESULT(rx)
  AC_CHECK_FUNC(re_rx_search, , [LIBOBJS="$LIBOBJS rx.o"])
fi
AC_SUBST(LIBOBJS)dnl
])
