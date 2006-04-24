##                                                          -*- Autoconf -*-
# Copyright (C) 2003, 2004, 2005, 2006  Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# AM_PROG_MKDIR_P
# ---------------
# Check whether `mkdir -p' is supported, fallback to mkinstalldirs otherwise.
#
# Automake 1.8 used `mkdir -m 0755 -p --' to ensure that directories
# created by `make install' are always world readable, even if the
# installer happens to have an overly restrictive umask (e.g. 077).
# This was a mistake.  There are at least two reasons why we must not
# use `-m 0755':
#   - it causes special bits like SGID to be ignored,
#   - it may be too restrictive (some setups expect 775 directories).
#
# Do not use -m 0755 and let people choose whatever they expect by
# setting umask.
#
# We cannot accept any implementation of `mkdir' that recognizes `-p'.
# Some implementations (such as Solaris 8's) are not thread-safe: if a
# parallel make tries to run `mkdir -p a/b' and `mkdir -p a/c'
# concurrently, both version can detect that a/ is missing, but only
# one can create it and the other will error out.  Consequently we
# restrict ourselves to GNU mkdir (using the --version option ensures
# this.)
AC_DEFUN([AM_PROG_MKDIR_P],
[if mkdir -p --version . >/dev/null 2>&1 && test ! -d ./--version; then
  # We used to define $(mkdir_p) as `mkdir -p .', in order to
  # allow $(mkdir_p) to be used without argument.  As in
  #   $(mkdir_p) $(somedir)
  # where $(somedir) is conditionally defined.  However we don't do
  # that anymore.
  #  1. before we restricted the check to GNU mkdir, `mkdir -p .' was
  #     reported to fail in read-only directories.  The system where this
  #     happened has been forgotten.
  #  2. in practice we call $(mkdir_p) on directories such as
  #       $(mkdir_p) "$(DESTDIR)$(somedir)"
  #     and we don't want to create $(DESTDIR) if $(somedir) is empty.
  #     To support the latter case, we have to write
  #       test -z "$(somedir)" || $(mkdir_p) "$(DESTDIR)$(somedir)"
  #     so $(mkdir_p) always has an argument.
  #     We will have better chances of detecting a missing test if
  #     $(mkdir_p) complains about missing arguments.
  #  3. $(mkdir_p) is named after `mkdir -p' and we don't expect this
  #     to accept no argument.
  #  4. having something like `mkdir .' in the output is unsightly.
  mkdir_p='mkdir -p'
else
  # On NextStep and OpenStep, the `mkdir' command does not
  # recognize any option.  It will interpret all options as
  # directories to create.
  for d in ./-p ./--version;
  do
    test -d $d && rmdir $d
  done
  # $(mkinstalldirs) is defined by Automake if mkinstalldirs exists.
  if test -f "$ac_aux_dir/mkinstalldirs"; then
    mkdir_p='$(mkinstalldirs)'
  else
    mkdir_p='$(install_sh) -d'
  fi
fi
AC_SUBST([mkdir_p])])
