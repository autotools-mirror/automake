## Included by top-level Makefile for Automake.

## Copyright (C) 1995-2013 Free Software Foundation, Inc.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## --------------------- ##
##  Makefile fragments.  ##
## --------------------- ##

amdir = @amdir@

dist_am_DATA = \
  %D%/am-dir.mk \
  %D%/common-targets.mk \
  %D%/color-tests.mk \
  %D%/serial-tests.mk \
  %D%/parallel-tests.mk \
  %D%/check-typos.mk \
  %D%/clean.mk \
  %D%/header-vars.mk \
  %D%/tags.mk \
  %D%/dejagnu.mk \
  %D%/distcheck.mk \
  %D%/distdir.mk \
  %D%/subdirs.mk \
  %D%/texibuild.mk \
  %D%/texinfos.mk \
  %D%/compile.am \
  %D%/configure.am \
  %D%/data.am \
  %D%/depend2.am \
  %D%/footer.am \
  %D%/header.am \
  %D%/java.am \
  %D%/lang-compile.am \
  %D%/lex.am \
  %D%/library.am \
  %D%/libs.am \
  %D%/lisp.am \
  %D%/ltlib.am \
  %D%/ltlibrary.am \
  %D%/mans-vars.am \
  %D%/mans.am \
  %D%/program.am \
  %D%/progs.am \
  %D%/python.am \
  %D%/remake-hdr.am \
  %D%/scripts.am \
  %D%/texi-vers.am \
  %D%/texi-spec.am \
  %D%/vala.am \
  %D%/yacc.am

# vim: ft=automake noet
