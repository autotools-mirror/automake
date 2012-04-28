# Maintainer makefile for Automake.  Requires GNU make.

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

ifeq ($(wildcard Makefile),)
  ifeq ($(filter bootstrap,$(MAKECMDGOALS)),bootstrap)
    # Allow the user (or more likely the developer) to ask for a bootstrap
    # of the package; of course, this can happen before configure is run,
    # and in fact even before it is created.
  else
    # Else, If the user runs GNU make but has not yet run ./configure,
    # give them an helpful diagnostic instead of a cryptic error.
    $(warning There seems to be no Makefile in this directory.)
    $(warning You must run ./configure before running 'make'.)
    $(error Fatal Error)
  endif
else
  include ./Makefile
  include $(srcdir)/syntax-checks.mk
endif

# To allow bootstrapping also in an unconfigured tree.
srcdir ?= .
am__cd ?= CDPATH=. && unset CDPATH && cd
AM_DEFAULT_VERBOSITY ?= 0
V ?= $(AM_DEFAULT_VERBOSITY)

ifeq ($(V),0)
  AM_V_BOOTSTRAP = @echo "  BOOTSTRAP";
  AM_V_CONFIGURE = @echo "  CONFIGURE";
  AM_V_REMAKE    = @echo "  REMAKE";
else
  AM_V_BOOTSTRAP =
  AM_V_CONFIGURE =
  AM_V_REMAKE    =
endif

# Must be phony, not to be confused with the 'bootstrap' script.
.PHONY: bootstrap
bootstrap:
	$(AM_V_BOOTSTRAP)$(am__cd) $(srcdir) && ./bootstrap.sh
	$(AM_V_CONFIGURE)set -e; \
	am__bootstrap_configure () { \
	  $(srcdir)/configure $${1+"$$@"} $(BOOTSTRAP_CONFIGURE_FLAGS); \
	}; \
	if test -f $(srcdir)/config.status; then \
	  : config.status should return a string properly quoted for eval; \
	  old_configure_flags=`$(srcdir)/config.status --config`; \
	else \
	  old_configure_flags=""; \
	fi; \
	eval am__bootstrap_configure "$$old_configure_flags"
	# The "make check" below is to ensure all the testsuite-required
	# files are rebuilt.
	$(AM_V_REMAKE)$(MAKE) clean && $(MAKE) check TESTS=t/get-sysconf
