#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# A line starting with '!' used in our internal .am fragments is
# passed verbatim to the output Makefile, and in the right place
# too.  Yes, this test is hacky ... as is the behaviour it tests
# after all ;-)

. test-init.sh

echo AC_OUTPUT >> configure.ac

long1=long
long2="$long1 $long1"
long4="$long2 $long2"
long8="$long4 $long4"
long16="$long8 $long8"
long32="$long16 $long16"
long64="$long32 $long32"
long128="$long64 $long64"
long256="$long128 $long128"
long512="$long256 $long265"

# Sanity check.
case $long512 in
  *' long long '*) ;;
  *) fatal_ 'defining $long512' ;;
esac

mkdir am
cp "$am_amdir"/*.am ./am
cp "$am_amdir"/*.mk ./am

echo pkgdata_DATA = configure.ac > Makefile.am

# The '.am' file are read-only when this test is run under
# "make distcheck", so we need to unlink any of them we want
# to overwrite.
rm -f am/data.am
cat > am/data.am << 'END'
include 0.am
include 1.am
include 2.am
include 3.am
END

echo "!x = $long256" > am/0.am

cat >> am/1.am << 'END'
!## unmodified
!xyz = \
rule:
	@echo Go Custom Rule
!!unmodified!
.PHONY: test-xyz
test-xyz:
	test '$(xyz)' = '!unmodified!'
END

cat > am/2.am << 'END'
!badrule1: ; @echo "'$@' unexpectedly won over 'all'!"; exit 1
!badrule2:
!	@echo "'$@' unexpectedly won over 'all'!"; exit 1
all-local: verbatim-rule
	test -f $<.ok
!verbatim-rule:
!ifeq (ok,ok)
!	@echo $@ run correctly
!	: > $@.ok
!else
!	echo $@ failure; exit 1
!endif
# We want this deliberately after verbatim-rule.
x = ok
END

cat > am/3.am << 'END'
x1 := 1
x2 := 2

foo = .

!ifndef FOO
!foo += $(x1)
!else
!foo += $(x2)
!endif

!ifeq ($(BAR),1)
!bar = aaa
!else
!ifeq "$(BAR)" "2"
!bar = lol
!else
!bar = default
!endif # this comment should be comment ignored
!endif

check-var:
	test '$($(var))' = '$(val)'
END

# Avoid interferences from the environment.
FOO= BAR=; unset FOO BAR

$ACLOCAL
$AUTOMAKE --libdir=.

grep '^!' Makefile.in | grep -v '^!unmodified!$' && exit 1

# Use perl, to avoid possible issues with regex length in vendor greps.
$PERL -e "
  while (<>) { exit (0) if (/^x = $long256$/); }
  exit (1);
" Makefile.in

grep '^!unmodified!$' Makefile.in
test $(grep -c '^!unmodified!$' Makefile.in) -eq 1
grep '^## unmodified$' Makefile.in
grep '^xyz = \\$' Makefile.in

$EGREP 'foo|bar' Makefile.in # For debugging.
test $(grep -c '^foo +=' Makefile.in) -eq 2
test $(grep -c '^bar ='  Makefile.in) -eq 3

$AUTOCONF
./configure

# The created makefile is not broken.
$MAKE -n

$MAKE rule
test ! -f verbatim-rule.ok
$MAKE
test -f verbatim-rule.ok
$MAKE | grep 'Custom Rule' && exit 1
$MAKE test-xyz

$MAKE check-var var=foo val='. 1'
$MAKE check-var var=foo val='. 1' FOO=''
$MAKE check-var var=foo val='. 2' FOO=yes
$MAKE check-var var=foo val='. 2' FOO=' who cares!'

$MAKE check-var var=bar val=default
$MAKE check-var var=bar val=aaa     BAR=1
$MAKE check-var var=bar val=lol     BAR=2
$MAKE check-var var=bar val=default BAR=3

:
