# AM_PROG_MKDIR_P
# ---------------
# Check whether `mkdir -p' is supported, fallback to mkinstalldirs otherwise.

# Copyright (C) 2003 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

AC_DEFUN([AM_PROG_MKDIR_P],
[AC_REQUIRE([AM_AUX_DIR_EXPAND])dnl
if mkdir -m 0755 -p -- . 2>/dev/null; then
  mkdir_p='mkdir -m 0755 -p --'
else
  # On NextStep and OpenStep, the `mkdir' command does not
  # recognize any option.  It will interpret all options as
  # directories to create, and then abort because `.' already
  # exists.
  for d in ./-m ./0755 ./-p ./--;
  do
    test -d $d && rmdir $d
  done
  # $(mkinstalldirs) is defined by Automake if mkinstalldirs exists.
  if test -f "$am_aux_dir/mkinstalldirs"; then
    mkdir_p='$(mkinstalldirs) -m 0755'
  else
    mkdir_p='$(install_sh) -m 0755 -d'
  fi
fi
AC_SUBST([mkdir_p])])
