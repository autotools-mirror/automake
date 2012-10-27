#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Make sure we allow the use to whitelist false positives in our
# detection of variable typos.  Inspired by the GNU coreutils (8.17)
# build system.

required=cc
. test-init.sh

edit ()
{
  file=$1; shift
  "$@" <$file >t && mv -f t $file || fatal_ "editing $file"
}

cat >> configure.ac << 'END'
AC_PROG_CC
AM_PROG_AR
AC_PROG_RANLIB
AC_SUBST([LIBSELINUX], ["$l_selinux"])
AC_OUTPUT
END

l_selinux=; export l_selinux=

cat > Makefile.am <<'END'
bin_PROGRAMS = cp mv rm
noinst_LIBRARIES = libremove.a libcopy.a
remove_LDADD = libremove.a
copy_LDADD = libcopy.a
copy_LDADD += @LIBSELINUX@
cp_LDADD = $(copy_LDADD)
rm_LDADD = $(remove_LDADD)
mv_LDADD = $(copy_LDADD) $(remove_LDADD)
AM_VARTYPOS_WHITELIST = copy_LDADD remove_LDADD
EXTRA_DIST = libcopy.h libremove.h
END

echo 'extern void cu_copy (void);' > libcopy.h
echo 'extern void cu_remove (void);' > libremove.h

cat > libcopy.c << 'END'
#include "libcopy.h"
void cu_copy (void) { return; }
END

cat > libremove.c << 'END'
#include "libremove.h"
void cu_remove (void) { return; }
END

cat > cp.c <<'END'
#include "libcopy.h"
int main (void)
{
  cu_copy ();
  return 0;
}
END

cat > rm.c <<'END'
#include "libremove.h"
int main (void)
{
  cu_remove ();
  return 0;
}
END

cat > mv.c <<'END'
#include "libremove.h"
#include "libcopy.h"
int main (void)
{
  cu_copy ();
  cu_remove ();
  return 0;
}
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

./configure
$MAKE

# Sanity check the distribution.
$MAKE distcheck

# If we remove the whitelisting, failure ensues.
sed '/^AM_VARTYPOS_WHITELIST *=/d' <Makefile.am >t && mv -f t Makefile.am \
  || fatal_ "editing Makefile.am"
$MAKE 2>stderr && { cat stderr; exit 1; }
cat stderr >&2
grep "'copy_LDADD' is defined but no program" stderr
grep "'remove_LDADD' is defined but no program" stderr

$MAKE AM_VARTYPOS_WHITELIST=remove_LDADD AM_FORCE_SANITY_CHECK=yes \
  2>stderr && { cat stderr; exit 1; }
cat stderr >&2
grep "'copy_LDADD' is defined but no program" stderr
grep "remove_LDADD" stderr && exit 1

:
