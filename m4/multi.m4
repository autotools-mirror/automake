dnl Add --enable-multilib to configure.
dnl Usage: AM_ENABLE_MULTILIB([makefile, [rel-to-top-srcdir]])

AC_DEFUN([AM_ENABLE_MULTILIB], [
dnl Default to --enable-multilib
AC_ARG_ENABLE(multilib,
[  --enable-multilib         build many library versions (default)],
[case "${enableval}" in
  yes) multilib=yes ;;
  no)  multilib=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for multilib option) ;;
 esac], [multilib=yes]

dnl We may get other options which we are undocumented:
dnl --with-target-subdir, --with-multisrctop, --with-multisubdir

if test "[$]{srcdir}" = "."; then
  if test "[$]{with_target_subdir}" != "."; then
    multi_basedir="[$]{srcdir}/[$]{with_multisrctop}../ifelse([$2],,,[$2])"
  else
    multi_basedir="[$]{srcdir}/[$]{with_multisrctop}ifelse([$2],,,[$2])"
  fi
else
  multi_basedir="[$]{srcdir}/ifelse([$2],,,[$2])"
fi
AC_SUBST(multi_basedir)

AC_OUTPUT_COMMANDS([
if test -n "$CONFIG_FILES"; then
   ac_file=ifelse([$1],,Makefile,[$1]) . ..ifelse([$2],,,/[$2])/config-ml.in
fi], [
srcdir="$srcdir"
host="$host"
target="$target"
with_multisubdir="$with_multisubdir"
with_multisrctop="$with_multisrctop"
with_target_subdir="$with_target_subdir"
ac_configure_args="${multilib_arg} ${ac_configure_args}"
multi_basedir="$multi_basedir"
CONFIG_SHELL=${CONFIG_SHELL-/bin/sh}
CC="$CC"]))dnl
