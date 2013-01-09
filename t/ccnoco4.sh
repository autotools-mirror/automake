#! /bin/sh
# Copyright (C) 2001-2013 Free Software Foundation, Inc.
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

# Check that Automake doesn't pass "-c -o" to  losing compiler when
# the 'subdir-objects' is used but sources are only present in the
# top-level directory.  Reported by Nick Bowler in the discussion on
# automake bug#13378:
# <http://debbugs.gnu.org/cgi/bugreport.cgi?bug=13378#35>
# <http://debbugs.gnu.org/cgi/bugreport.cgi?bug=13378#44>

required=gcc
. test-init.sh

# We deliberately do not call AM_PROG_CC_C_O here.
cat >> configure.ac << 'END'
AC_PROG_CC
$CC --version; $CC -v; # For debugging.
AC_OUTPUT
END

cat > Makefile.am << 'END'
AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = foo bar
bar_SOURCES = foo.c
END

echo 'int main (void) { return 0; }' > foo.c

cat > Mycomp << END
#!/bin/sh

case " \$* " in
 *\ -c*\ -o* | *\ -o*\ -c*)
    exit 1
    ;;
esac

# Use '$CC', not 'gcc', to honour the compiler chosen
# by the testsuite setup.
exec $CC "\$@"
END

chmod +x Mycomp

# Make sure the compiler doesn't understand '-c -o'.
CC=$(pwd)/Mycomp
export CC

$ACLOCAL
$AUTOCONF
$AUTOMAKE --copy --add-missing

./configure
$MAKE
$MAKE distcheck

:
