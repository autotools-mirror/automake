# Check to make sure that the build environment is sane.    -*- Autoconf -*-

# Copyright (C) 1996-2023 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# _AM_SLEEP_FRACTIONAL_SECONDS
# ----------------------------
AC_DEFUN([_AM_SLEEP_FRACTIONAL_SECONDS], [dnl
AC_CACHE_CHECK([whether sleep supports fractional seconds], am_cv_sleep_fractional_seconds, [dnl
AS_IF([sleep 0.001 2>/dev/null], [am_cv_sleep_fractional_seconds=true], [am_cv_sleep_fractional_seconds=false])
])])

# _AM_FILESYSTEM_TIMESTAMP_RESOLUTION
# -----------------------------------
# Determine the filesystem timestamp resolution.  Modern systems are nanosecond
# capable, but historical systems could be millisecond, second, or even 2-second
# resolution.
AC_DEFUN([_AM_FILESYSTEM_TIMESTAMP_RESOLUTION], [dnl
AC_REQUIRE([_AM_SLEEP_FRACTIONAL_SECONDS])
AC_CACHE_CHECK([the filesystem timestamp resolution], am_cv_filesystem_timestamp_resolution, [dnl
# Use names that lexically sort older-first when the timestamps are equal.
rm -f conftest.file.a conftest.file.b
: > conftest.file.a
AS_IF([$am_cv_sleep_fractional_seconds], [dnl
  am_try_sleep=0.1 am_try_loops=20
], [dnl
  am_try_sleep=1   am_try_loops=2
])
am_try=0
while :; do
  AS_VAR_ARITH([am_try], [$am_try + 1])
  echo "timestamp $am_try" > conftest.file.b
  set X `ls -t conftest.file.a conftest.file.b`
  if test "$[2]" = conftest.file.b || test $am_try -eq $am_try_loops; then
    break
  fi
  sleep $am_try_sleep
done
rm -f conftest.file.a conftest.file.b
am_cv_filesystem_timestamp_resolution=$am_try
AS_IF([$am_cv_sleep_fractional_seconds], [dnl
  AS_VAR_ARITH([am_cv_filesystem_timestamp_resolution], [$am_try / 10])
  AS_VAR_ARITH([am_fraction], [$am_try % 10])
  AS_VAR_APPEND([am_cv_filesystem_timestamp_resolution], [.$am_fraction])
])
])])

# AM_SANITY_CHECK
# ---------------
AC_DEFUN([AM_SANITY_CHECK],
[AC_REQUIRE([_AM_FILESYSTEM_TIMESTAMP_RESOLUTION])
rm -f conftest.file
AC_CACHE_CHECK([whether build environment is sane], am_cv_build_env_is_sane, [dnl
# Reject unsafe characters in $srcdir or the absolute working directory
# name.  Accept space and tab only in the latter.
am_lf='
'
case `pwd` in
  *[[\\\"\#\$\&\'\`$am_lf]]*)
    AC_MSG_ERROR([unsafe absolute working directory name]);;
esac
case $srcdir in
  *[[\\\"\#\$\&\'\`$am_lf\ \	]]*)
    AC_MSG_ERROR([unsafe srcdir value: '$srcdir']);;
esac

# Do 'set' in a subshell so we don't clobber the current shell's
# arguments.  Must try -L first in case configure is actually a
# symlink; some systems play weird games with the mod time of symlinks
# (eg FreeBSD returns the mod time of the symlink's containing
# directory).
if (
   am_has_slept=no
   for am_try in 1 2; do
     echo "timestamp, slept: $am_has_slept" > conftest.file
     set X `ls -Lt "$srcdir/configure" conftest.file 2> /dev/null`
     if test "$[*]" = "X"; then
	# -L didn't work.
	set X `ls -t "$srcdir/configure" conftest.file`
     fi
     if test "$[*]" != "X $srcdir/configure conftest.file" \
	&& test "$[*]" != "X conftest.file $srcdir/configure"; then

	# If neither matched, then we have a broken ls.  This can happen
	# if, for instance, CONFIG_SHELL is bash and it inherits a
	# broken ls alias from the environment.  This has actually
	# happened.  Such a system could not be considered "sane".
	AC_MSG_ERROR([ls -t appears to fail.  Make sure there is not a broken
  alias in your environment])
     fi
     if test "$[2]" = conftest.file || test $am_try -eq 2; then
       break
     fi
     # Just in case.
     sleep $am_cv_filesystem_timestamp_resolution
     am_has_slept=yes
   done
   test "$[2]" = conftest.file
   )
then
  am_cv_build_env_is_sane=yes
else
   AC_MSG_ERROR([newly created file is older than distributed files!
Check your system clock])
fi
])
# If we didn't sleep, we still need to ensure time stamps of config.status and
# generated files are strictly newer.
am_sleep_pid=
if ! test -e conftest.file || grep 'slept: no' conftest.file >/dev/null 2>&1; then
  ( sleep $am_cv_filesystem_timestamp_resolution ) &
  am_sleep_pid=$!
fi
AC_CONFIG_COMMANDS_PRE(
  [AC_MSG_CHECKING([that generated files are newer than configure])
   if test -n "$am_sleep_pid"; then
     # Hide warnings about reused PIDs.
     wait $am_sleep_pid 2>/dev/null
   fi
   AC_MSG_RESULT([done])])
rm -f conftest.file
])
