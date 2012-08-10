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

# The $(host), $(build), $(target) variables, and their '*_alias'
# and 'am.conf.*-triplet' counterparts.

. ./defs || exit 1

: > config.guess
: > config.sub
: > Makefile.am

$ACLOCAL
$AUTOMAKE
grep "^am\.conf\.host-triplet = *$" Makefile.in
grep "^am\.conf\.build-triplet = *$" Makefile.in
grep "^am\.conf\.target-triplet = *$" Makefile.in

mv -f configure.ac configure.tmpl

for M in HOST BUILD TARGET; do
  m=$(echo $M | LC_ALL=C tr '[A-Z]' '[a-z]')
  (cat configure.tmpl && echo AC_CANONICAL_$M) > configure.ac
  rm -rf autom4te.cache
  $AUTOMAKE
  grep "^$m = @$m@$" Makefile.in
  grep "^${m}_alias = @${m}_alias@$" Makefile.in
  grep "^am\\.conf\\.${m}-triplet = \\\$(${m})$" Makefile.in
  case $m in
    build)
      grep '^am\.conf\.host-triplet = *$' Makefile.in
      grep '^am\.conf\.target-triplet = *$' Makefile.in
      ;;
    host)
      grep '^am\.conf\.build-triplet = $(build)$' Makefile.in
      grep '^am\.conf\.target-triplet = *$' Makefile.in
      ;;
    target)
      grep '^am\.conf\.build-triplet = $(build)$' Makefile.in
      grep '^am\.conf\.target-triplet = $(target)$' Makefile.in
      ;;
  esac
done

rm -rf autom4te.cache

cat configure.tmpl - >configure.ac <<'END'
AC_CANONICAL_HOST
AC_CANONICAL_BUILD
AC_CANONICAL_TARGET
END

$AUTOMAKE
for m in host build target; do
  grep "^$m = @$m@$" Makefile.in
  grep "^${m}_alias = @${m}_alias@$" Makefile.in
  grep "^am\.conf\.${m}-triplet = \$(${m})$" Makefile.in
done

:
