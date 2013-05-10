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

## ----------------------------------- ##
##  The automake and aclocal scripts.  ##
## ----------------------------------- ##

bin_SCRIPTS = %D%/automake %D%/aclocal
CLEANFILES += $(bin_SCRIPTS)

# Used by maintainer checks and such.
automake_in = $(srcdir)/%D%/automake.in
aclocal_in  = $(srcdir)/%D%/aclocal.in
automake_script = %D%/automake
aclocal_script  = %D%/aclocal

AUTOMAKESOURCES = $(automake_in) $(aclocal_in)
TAGS_FILES += $(AUTOMAKESOURCES)
EXTRA_DIST += $(AUTOMAKESOURCES)

# Make versioned links.  We only run the transform on the root name;
# then we make a versioned link with the transformed base name.  This
# seemed like the most reasonable approach.
install-exec-hook:
	@$(POST_INSTALL)
	@for p in $(bin_SCRIPTS); do \
	  f=`echo $$p | sed -e 's,.*/,,' -e '$(transform)'`; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
	  echo " $(LN) '$(DESTDIR)$(bindir)/$$f' '$(DESTDIR)$(bindir)/$$fv'"; \
	  $(LN) "$(DESTDIR)$(bindir)/$$f" "$(DESTDIR)$(bindir)/$$fv"; \
	done

uninstall-hook:
	@for p in $(bin_SCRIPTS); do \
	  f=`echo $$p | sed -e 's,.*/,,' -e '$(transform)'`; \
	  fv="$$f-$(APIVERSION)"; \
	  rm -f "$(DESTDIR)$(bindir)/$$fv"; \
	done

# These files depend on Makefile so they are rebuilt if $(VERSION),
# $(datadir) or other do_subst'd variables change.
%D%/automake %D%/aclocal: %: %.in Makefile %D%/gen-perl-protos
	$(AM_V_GEN)rm -f $@ $@-t $@-t2 \
## Common substitutions.
	  && $(do_subst)  \
## Auto-compute prototypes of perl subroutines.
	  && $(PERL) -w $(srcdir)/%D%/gen-perl-protos $@-t > $@-t2 \
	  && mv -f $@-t2 $@-t \
## We can't use '$(generated_file_finalize)' here, because currently
## Automake contains occurrences of unexpanded @substitutions@ in
## comments, and that is perfectly legit.
	  && chmod a+x,a-w $@-t && mv -f $@-t $@
EXTRA_DIST += %D%/gen-perl-protos

# vim: ft=automake noet
