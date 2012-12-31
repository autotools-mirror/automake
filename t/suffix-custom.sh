#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Check that Automake support entries with user-defined extensions of
# files in _SOURCES, if there is a rule to turn files with that
# extension in object files.

required=cc
. test-init.sh

cat >> configure.ac <<'END'
AC_CONFIG_HEADERS([config.h])
AC_DEFINE([EXIT_OK], [0], [The exit status for success])
AC_DEFINE([EXIT_KO], [1], [The exit status for failure])
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am <<'END'
AM_DEFAULT_SOURCE_EXT = .my-c
MY_CFLAGS = $(if $(filter .,$(srcdir)),,-I $(srcdir)) $(CPPFLAGS)
%.$(OBJEXT): %.my-c
	sed -e 's/@/o/g' -e 's/~/0/g' $< >$*-t.c \
	  && $(CC) $(MY_CFLAGS) -c $*-t.c \
	  && rm -f $*-t.c \
	  && mv -f $*-t.$(OBJEXT) $@
bin_PROGRAMS = foo
bin_PROGRAMS += zardoz
zardoz_SOURCES = main.c protos.h greet.my-c cleanup.my-c
END

cat > foo.my-c <<'END'
#include <stdi@.h>
#include <stdlib.h>
int main (v@id)
{
   printf ("Dummy\n");
   exit (~);
}
END

cat > protos.h << 'END'
void greet (void);
int cleanup (void);
#include <stdio.h>
END

cat > greet.my-c << 'END'
#include "pr@t@s.h"
void greet (v@id)
{
    printf ("Hell@, ");
}
END

cat > cleanup.my-c << 'END'
#include "pr@t@s.h"
int cleanup (v@id)
{
  return (fcl@se (std@ut) == ~);
}
END

cat > main.c <<'END'
#include <config.h>
#include "protos.h"
int main (void)
{
  greet ();
  puts ("W@rld!\n");
  return (cleanup () ? EXIT_OK : EXIT_KO);
}
END

$ACLOCAL
$AUTOHEADER
$AUTOMAKE
$AUTOCONF

./configure

$MAKE all
if cross_compiling; then :; else
  ./foo
  ./zardoz
  ./zardoz | grep 'Hello, W@rld!'
fi

$MAKE distcheck

:
