## Process this file with automake to create Makefile.in

## Makefile for Automake.

# Copyright (C) 1995-2013 Free Software Foundation, Inc.

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

## Might be updated later.
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =
TAGS_FILES =
dist_noinst_DATA =
nodist_noinst_DATA =
dist_noinst_SCRIPTS =
nodist_noinst_SCRIPTS =

## ------------ ##
##  Top level.  ##
## ------------ ##

# Distribution formats.
AM_DIST_FORMATS = gzip xz

EXTRA_DIST += \
  bootstrap.sh \
  GNUmakefile \
  HACKING \
  NG-NEWS \
  PLANS \
  $(gitlog_to_changelog_fixes)

# We want a handful of substitutions to be fully-expanded by make;
# then use config.status to substitute the remainder where a single
# expansion is sufficient.  We use a funny notation here to avoid
# configure substitutions in our text.
do_subst = sed $(strip \
  $(foreach x, data am bin doc pkgvdata script automake_ac system_ac, \
              -e 's,@$(x)dir@,$($(x)dir),g')) \
  -e "s,[@]configure_input@,Generated from $(<F) do not edit by hand.,g" \
  <"$<" | $(SHELL) ./config.status --file=- >"$@-t"

# Generated  files shouldn't contain unexpanded '@substitutions@', and
# should be made read-only, to prevent them from being edited by mistake
# instead of the file the are generated from.
generated_file_finalize = $(AM_V_at) \
  if LC_ALL=C grep '@[a-zA-Z0-9_][a-zA-Z0-9_]*@' $@-t; then \
    echo "$@ contains unexpanded substitution (see lines above)"; \
    exit 1; \
  fi; \
  chmod a-w $@-t && mv -f $@-t $@

# For some tests or targets, we need to have the just-build automake and
# aclocal scripts avaiable on PATH.
extend_PATH = \
  { PATH='$(abs_builddir)/t/wrap'$(PATH_SEPARATOR)$$PATH && export PATH; }

# The master location for INSTALL is lib/INSTALL.
# This is where "make fetch" will install new versions.
# Make sure we also update this copy.
INSTALL: lib/INSTALL
	$(AM_V_GEN)cp $(srcdir)/lib/INSTALL $@

# We don't use the default name for the autom4te cache directory,
# so we need this.
maintainer-clean-local:
	rm -rf .autom4te.cache

# So that automake won't complain about the missing ChangeLog.
# The real rule for ChangeLog generation is now in maintainer/maint.mk
# (as it is maintainer-specific).
ChangeLog:

# Third-party, obsolescent or experimental stuff.
EXTRA_DIST += \
  contrib/check-html.am \
  contrib/README

# Older files, kept mostly for historical interest.
EXTRA_DIST += \
  $(addprefix old/ChangeLog., 96 98 00 01 02 03 04 09 11) \
  old/ChangeLog-tests old/TODO

# Maintainer-specific files and scripts.
EXTRA_DIST += \
  maintainer/am-ft \
  maintainer/am-xft \
  maintainer/rename-tests \
  maintainer/maint.mk \
  maintainer/syntax-checks.mk

# Most work delegated to sub-dir makefile fragments.
include $(srcdir)/bin/Makefile.inc
include $(srcdir)/doc/Makefile.inc
include $(srcdir)/lib/Makefile.inc
include $(srcdir)/lib/Automake/Makefile.inc
include $(srcdir)/lib/am/Makefile.inc
include $(srcdir)/m4/Makefile.inc
include $(srcdir)/t/Makefile.inc

# vim: ft=automake noet
