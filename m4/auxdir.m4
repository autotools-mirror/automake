# AM_AUX_DIR_EXPAND

# For projects using AC_CONFIG_AUX_DIR([foo]), Autoconf sets
# $ac_aux_dir to ${srcdir}/foo.  In other projects, it is set to `.'.
# Of course, Automake must honor this variable whenever it calls a tool
# from the auxiliary directory.  The problem is that $srcdir (and therefore
# $ac_aux_dir as well) can be either an absolute path or a path relative to
# $top_srcdir, depending on how configure is run.  This is pretty annoying,
# since it makes $ac_aux_dir quite unusable in subdirectories: in the top
# source directory, any form will work fine, but in subdirectories a relative
# path needs to be adjusted first.
# - calling $top_srcdir/$ac_aux_dir/missing would succeed if $ac_aux_dir was
#   relative, but fail if it was absolute.
# - conversly, calling $ac_aux_dir/missing would fail if $ac_aux_dir was
#   relative, and succeed on absolute paths.
#
# Consequently, we define and use $am_aux_dir, the "always absolute"
# version of $ac_aux_dir.

AC_DEFUN([AM_AUX_DIR_EXPAND], [
# expand $ac_aux_dir to an absolute path
am_aux_dir=`CDPATH=:; cd $ac_aux_dir && pwd`
])
