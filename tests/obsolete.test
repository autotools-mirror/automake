#! /bin/sh
# Copyright (C) 1996-2012 Free Software Foundation, Inc.
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

# Test to make sure obsolete macros can be autoupdated.

# We need the following indirection in case someone exported e.g.
# AUTOUPDATE='autoupdate --verbose'.
set x ${AUTOUPDATE-autoupdate}
required=$2
. ./defs || Exit 1

cat > configure.ac << 'END'
AC_INIT
END

$PERL -ne '/AU_DEFUN\(\[(\w+)\]/ && print "$1\n"' \
  "$am_automake_acdir/obsolete.m4" > obs
cat obs >> configure.ac
$PERL -ne 'chomp; print "grep $_ output || Exit 1\n"; ' obs > obs.1
$PERL -ne 'chomp; print "grep $_ configure.ac && Exit 1\n"; ' obs > obs.2
echo : >> obs.1 # Since it will be sourced, it must end with a success.
echo : >> obs.2 # Likewise.

cat configure.ac # For debugging.
cat obs.1        # Likewise.
cat obs.2        # Likewise.

# Sanity check.  Make sure we have added something to configure.ac.
test `wc -l <configure.ac` -gt 1

$ACLOCAL

# Expect Autoconf to complain about each of the macros in obs.
$AUTOCONF -Wobsolete >output 2>&1 || { cat output; Exit 1; }
cat output
. ./obs.1
# Make sure Autoupdate remove each of these macros.
$AUTOUPDATE
. ./obs.2

# Autoconf should be able to grok the updated configure.ac.
$AUTOCONF

:
