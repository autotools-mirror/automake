## Process this file with automake to create Makefile.in

## Makefile for Automake lib.

# Copyright (C) 2001-2012 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

EXTRA_DIST = gnupload gitlog-to-changelog update-copyright

## -------------------------------------------------------------------- ##
##  Auxiliary scripts and files for use with "automake --add-missing".  ##
## -------------------------------------------------------------------- ##

dist_pkgvdata_DATA = COPYING INSTALL texinfo.tex ansi2knr.c ansi2knr.1 \
  config-ml.in

## These must all be executable when installed.  However, if we use
## _SCRIPTS, then the program transform will be applied, which is not
## what we want.  So we make them executable by hand.
scriptdir = $(pkgvdatadir)
dist_script_DATA = config.guess config.sub install-sh mdate-sh missing \
  mkinstalldirs elisp-comp ylwrap acinstall depcomp compile py-compile \
  symlink-tree ar-lib

install-data-hook:
	@$(POST_INSTALL)
	@for prog in $(dist_script_DATA); do \
	  echo " chmod +x $(DESTDIR)$(scriptdir)/$$prog"; \
	  chmod +x $(DESTDIR)$(scriptdir)/$$prog; \
	done

## `test -x' is not portable.  So we use Perl instead.  If Perl
## doesn't exist, then this test is meaningless anyway.
installcheck-local:
	for file in $(dist_script_DATA); do \
	  $(PERL) -e "exit ! -x '$(pkgvdatadir)/$$file';" || exit 1; \
	done

## ---------------------------------------------------- ##
##  Private perl modules used by automake and aclocal.  ##
## ---------------------------------------------------- ##

perllibdir = $(pkgvdatadir)/Automake
dist_perllib_DATA = \
  Automake/ChannelDefs.pm \
  Automake/Channels.pm \
  Automake/Condition.pm \
  Automake/Configure_ac.pm \
  Automake/DisjConditions.pm \
  Automake/FileUtils.pm \
  Automake/General.pm \
  Automake/Getopt.pm \
  Automake/Item.pm \
  Automake/ItemDef.pm \
  Automake/Location.pm \
  Automake/Options.pm \
  Automake/Rule.pm \
  Automake/RuleDef.pm \
  Automake/Struct.pm \
  Automake/Variable.pm \
  Automake/VarDef.pm \
  Automake/Version.pm \
  Automake/XFile.pm \
  Automake/Wrap.pm

nodist_perllib_DATA = Automake/Config.pm
CLEANFILES = $(nodist_perllib_DATA)

## We can't use configure to do the substitution here; we must do it
## by hand.  We use a funny notation here to avoid configure
## substitutions in our text.
do_subst = in=`echo $@ | sed 's/\.[^.]*$$//'`; sed \
  -e 's,[@]APIVERSION[@],$(APIVERSION),g' \
  -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
  -e 's,[@]PACKAGE_BUGREPORT[@],$(PACKAGE_BUGREPORT),g' \
  -e 's,[@]PERL[@],$(PERL),g' \
  -e 's,[@]PERL_THREADS[@],$(PERL_THREADS),g' \
  -e 's,[@]SHELL[@],$(SHELL),g' \
  -e 's,[@]VERSION[@],$(VERSION),g' \
  -e "s,[@]configure_input[@],Generated from $$in.in; do not edit by hand.,g" \
  -e 's,[@]datadir[@],$(datadir),g'

## This file depends on Makefile so it is rebuilt if $(VERSION),
## $(datadir) or other do_subst'ituted variables change.
## Use chmod a-w to prevent people from editing the wrong file by accident.
Automake/Config.pm: Automake/Config.in Makefile
	$(AM_V_at)rm -f $@ $@-t
	$(AM_V_at)test -d Automake || mkdir Automake
	$(AM_V_GEN)$(do_subst) $(srcdir)/Automake/Config.in >$@-t
	$(AM_V_at)chmod a-w $@-t && mv -f $@-t $@
EXTRA_DIST += Automake/Config.in

## --------------------- ##
##  Makefile fragments.  ##
## --------------------- ##

amdir = $(pkgvdatadir)/am

dist_am_DATA = \
  am/ansi2knr.am \
  am/check.am \
  am/check-html.am \
  am/check2.am \
  am/clean-hdr.am \
  am/clean.am \
  am/compile.am \
  am/configure.am \
  am/data.am \
  am/dejagnu.am \
  am/depend.am \
  am/depend2.am \
  am/distdir.am \
  am/footer.am \
  am/header-vars.am \
  am/header.am \
  am/install.am \
  am/inst-vars.am \
  am/java.am \
  am/lang-compile.am \
  am/lex.am \
  am/library.am \
  am/libs.am \
  am/libtool.am \
  am/lisp.am \
  am/ltlib.am \
  am/ltlibrary.am \
  am/mans-vars.am \
  am/mans.am \
  am/multilib.am \
  am/program.am \
  am/progs.am \
  am/python.am \
  am/remake-hdr.am \
  am/scripts.am \
  am/subdirs.am \
  am/tags.am \
  am/texi-vers.am \
  am/texibuild.am \
  am/texinfos.am \
  am/vala.am \
  am/yacc.am
