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

# A line starting with '!' is passed verbatim to the output Makefile,
# and in the right place too.

. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_CONFIG_FILES([Makefile2 Makefile3])
AC_OUTPUT
END

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

cat > Makefile.am << END
!x = $long256
!!unmodified!
!## unmodified
! foo = \
rule:
END

cat > Makefile2.am << 'END'
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

cat > Makefile3.am << 'END'
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
$AUTOMAKE

grep '^!' Makefile.in | grep -v '^!unmodified!$' && Exit 1
grep '^!' Makefile[23].in && Exit 1

# Use perl, to avoid possible issues with regex length in vendor greps.
$PERL -e "
  while (<>) { exit 0 if (/^x = $long256$/); }
  exit 1;
" Makefile.in

grep '^!unmodified!$' Makefile.in
grep '^## unmodified$' Makefile.in
# FIXME: automake is not yet smart enough to handle line continuation
# FIXME: on the last line of a '!' series correctly.
#grep '^ foo = \\$' Makefile.in

$EGREP 'foo|bar' Makefile3.in # For debugging.
test `grep -c '^foo +=' Makefile3.in` -eq 2
test `grep -c '^bar =' Makefile3.in` -eq 3

$AUTOCONF
./configure

# FIXME: automake is not yet smart enough to handle line continuation
# FIXME: on the last line of a '!' series correctly.
#grep '^ foo = \\$' Makefile.in
#$MAKE rule

$MAKE -f Makefile2
test -f verbatim-rule.ok

$MAKE -f Makefile3 check-var var=foo val='. 1'
$MAKE -f Makefile3 check-var var=foo val='. 1' FOO=''
$MAKE -f Makefile3 check-var var=foo val='. 2' FOO=yes
$MAKE -f Makefile3 check-var var=foo val='. 2' FOO=' who cares!'

$MAKE -f Makefile3 check-var var=bar val=default
$MAKE -f Makefile3 check-var var=bar val=aaa     BAR=1
$MAKE -f Makefile3 check-var var=bar val=lol     BAR=2
$MAKE -f Makefile3 check-var var=bar val=default BAR=3

:
