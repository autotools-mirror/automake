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

## -------------------------------------------------------------------- ##
##  Auxiliary scripts and files for use with "automake --add-missing".  ##
## -------------------------------------------------------------------- ##

dist_pkgvdata_DATA = \
  %D%/COPYING \
  %D%/INSTALL \
  %D%/texinfo.tex

# These must all be executable when installed.  However, if we use
# _SCRIPTS, then the program transform will be applied, which is not
# what we want.  So we make them executable by hand.
dist_script_DATA = \
  %D%/config.guess \
  %D%/config.sub \
  %D%/install-sh \
  %D%/mdate-sh \
  %D%/missing \
  %D%/ylwrap \
  %D%/depcomp \
  %D%/compile \
  %D%/py-compile \
  %D%/ar-lib \
  %D%/test-driver \
  %D%/tap-driver.sh \
  %D%/tap-driver.pl

install-data-hook:
	@$(POST_INSTALL)
	chmod +x $(patsubst %D%/%,'$(DESTDIR)$(scriptdir)/%',$(dist_script_DATA))

installcheck-local: installcheck-executable-scripts
installcheck-executable-scripts:
	@st=0; \
	 for f in $(patsubst %D%/%,'$(scriptdir)/%',$(dist_script_DATA)); do \
	   test -x $$f || { echo "$@: $$f: not executable" >&2; st=1; }; \
	 done; \
	 exit $$st;

# vim: ft=automake noet
