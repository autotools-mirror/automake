## --------------------------------------------------------- ##
## Configure the libtool script for this package             ##
## From Gord Matzigkeit                                      ##
## --------------------------------------------------------- ##

# serial 1

AC_DEFUN(AM_PROG_LIBTOOL,
[AC_REQUIRE([AC_CANONICAL_HOST])
AC_REQUIRE([AC_PROG_CC])
AC_REQUIRE([AC_PROG_RANLIB])

AC_MSG_CHECKING([libtool object types])

# Default to static linking.
AC_ARG_ENABLE(linktype,
[  --enable-linktype=TYPE  link programs against TYPE libraries [default=static]],
[libtool_linktype="$enableval"],
libtool_linktype=static)

AC_ARG_ENABLE(profile,
[  --enable-profile        build profiled libraries [default=no]],
libtool_enable_profile="$enableval",
libtool_enable_profile=no)

AC_ARG_ENABLE(shared,
[  --enable-shared         build shared libraries [default=no]],
libtool_enable_shared="$enableval",
libtool_enable_shared=no)

AC_ARG_ENABLE(static,
[  --enable-static         build static libraries [default=yes]],
libtool_enable_static="$enableval",
libtool_enable_static=yes)

libtool_objtypes=
case "$libtool_linktype" in
  profile) libtool_objtypes=doP ;;
  shared) libtool_objtypes=dos ;;
  static) libtool_objtypes=do ;;
  *) AC_MSG_ERROR([invalid option to --enable-linktype]) ;;
esac

case "$libtool_enable_profile" in
  yes) test "$libtool_linktype" != "profile" &&
         libtool_objtypes="$libtool_objtypes:doP" ;;
  no) ;;
  *) AC_MSG_ERROR([invalid option to --enable-profile]) ;;
esac
case "$libtool_enable_shared" in
  yes) test "$libtool_linktype" != "shared" &&
         libtool_objtypes="$libtool_objtypes:dos" ;; # Yuck! It spells "DOS"!
  no) ;;
  *) AC_MSG_ERROR([invalid option to --enable-shared]) ;;
esac
case "$libtool_enable_static" in
  yes) test "$libtool_linktype" != "static" &&
         libtool_objtypes="$libtool_objtypes:do" ;;
  no) ;;
  *) AC_MSG_ERROR([invalid option to --enable-static]) ;;
esac

test -n "$OBJTYPES" || OBJTYPES="$libtool_objtypes"

AC_MSG_RESULT([$OBJTYPES])

# Propagate silent flags
am_prog_libtool_flags=
test "$silent" = yes && am_prog_libtool_flags="--silent"

# Get the real value of libdir:
am_prog_libtool_libdir=`eval echo $libdir`
case "$am_prog_libtool_libdir" in
  NONE/lib)
  if test "$exec_prefix" = "NONE"; then
    if test "$prefix" = NONE; then
      am_prog_libtool_libdir="$ac_default_prefix/lib"
    else
      am_prog_libtool_libdir="$prefix/lib"
    fi
  else
    am_prog_libtool_libdir="$exec_prefix/lib"
  fi ;;
esac
      
# Actually configure libtool.
# Holy mackerel, what a command line!
CC="$CC" LD="$LD" RANLIB="$RANLIB" OBJTYPES="$OBJTYPES" \
$srcdir/libtool --host="$host" --libdir="$am_prog_libtool_libdir" --no-validate-host \
--with-gcc="$am_cv_prog_gcc" $am_prog_libtool_flags \
configure || AC_MSG_ERROR([libtool configure failed])
])
