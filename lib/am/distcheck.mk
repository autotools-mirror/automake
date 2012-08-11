## automake - create Makefile.in from Makefile.am
## Copyright (C) 2001-2012 Free Software Foundation, Inc.

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

# ---------------------------- #
#  Checking the distribution.  #
# ---------------------------- #

ifdef SUBDIRS
AM_RECURSIVE_TARGETS += distcheck
endif

# This target untars the dist file and tries a VPATH configuration.  Then
# it guarantees that the distribution is self-contained by making another
# tarfile.
.PHONY: distcheck
distcheck: dist
	case '$(DIST_ARCHIVES)' in \
	*.tar.gz*) \
	  GZIP=$(GZIP_ENV) gzip -dc $(distdir).tar.gz | $(am__untar) ;;\
	*.tar.bz2*) \
	  bzip2 -dc $(distdir).tar.bz2 | $(am__untar) ;;\
	*.tar.lz*) \
	  lzip -dc $(distdir).tar.lz | $(am__untar) ;;\
	*.tar.xz*) \
	  xz -dc $(distdir).tar.xz | $(am__untar) ;;\
	*.zip*) \
	  unzip $(distdir).zip ;;\
	esac
## Make the new source tree read-only.  Distributions ought to work in
## this case.  However, make the top-level directory writable so we
## can make our new subdirs.
	chmod -R a-w $(distdir)
	chmod u+w $(distdir)
	mkdir $(distdir)/_build $(distdir)/_inst
## Undo the write access.
	chmod a-w $(distdir)
## With GNU make, the following command will be executed even with "make -n",
## due to the presence of '$(MAKE)'.  That is normally all well (and '$(MAKE)'
## is necessary for things like parallel distcheck), but here we don't want
## execution.  To avoid MAKEFLAGS parsing hassles, use a witness file that a
## non-'-n' run would have just created.
	test -d $(distdir)/_build || exit 0; \
## Compute the absolute path of '_inst'.  Strip any leading DOS drive
## to allow DESTDIR installations.  Otherwise "$(DESTDIR)$(prefix)" would
## expand to "c:/temp/am-dc-5668/c:/src/package/package-1.0/_inst".
	dc_install_base=`cd $(distdir)/_inst && pwd | sed -e 's,^[^:\\/]:[\\/],/,'` \
## We will attempt a DESTDIR install in $dc_destdir.  We don't
## create this directory under $dc_install_base, because it would
## create very long directory names.
	  && dc_destdir="$${TMPDIR-/tmp}/am-dc-$$$$/" \
	  $(if $(am.dist.handle-distcheck-hook),&& $(MAKE) distcheck-hook) \
	  && cd $(distdir)/_build \
	  && ../configure --srcdir=.. --prefix="$$dc_install_base" \
	    $(if $(am.dist.handle-gettext),--with-included-gettext) \
## Additional flags for configure.  Keep this last in the configure
## invocation so the developer and user can override previous options,
## and let the user's flags take precedence over the developer's ones.
	    $(AM_DISTCHECK_CONFIGURE_FLAGS) \
	    $(DISTCHECK_CONFIGURE_FLAGS) \
	  && $(MAKE) \
	  && $(MAKE) dvi \
	  && $(MAKE) check \
	  && $(MAKE) install \
	  && $(MAKE) installcheck \
	  && $(MAKE) uninstall \
	  && $(MAKE) distuninstallcheck_dir="$$dc_install_base" \
	        distuninstallcheck \
## Make sure the package has proper DESTDIR support (we could not test this
## in the previous install/installcheck/uninstall test, because it's reasonable
## for installcheck to fail in a DESTDIR install).
## We make the '$dc_install_base' read-only because this is where files
## with missing DESTDIR support are likely to be installed.
	  && chmod -R a-w "$$dc_install_base" \
## The logic here is quite convoluted because we must clean $dc_destdir
## whatever happens (it won't be erased by the next run of distcheck like
## $(distdir) is).
	  && ({ \
## Build the directory, so we can cd into it even if "make install"
## didn't create it.  Use mkdir, not $(MKDIR_P) because we want to
## fail if the directory already exists (PR/413).
	       (cd ../.. && umask 077 && mkdir "$$dc_destdir") \
	       && $(MAKE) DESTDIR="$$dc_destdir" install \
	       && $(MAKE) DESTDIR="$$dc_destdir" uninstall \
	       && $(MAKE) DESTDIR="$$dc_destdir" \
	            distuninstallcheck_dir="$$dc_destdir" distuninstallcheck; \
	      } || { rm -rf "$$dc_destdir"; exit 1; }) \
	  && rm -rf "$$dc_destdir" \
	  && $(MAKE) dist \
## Make sure to remove the dists we created in the test build directory.
	  && rm -rf $(DIST_ARCHIVES) \
	  && $(MAKE) distcleancheck
	$(am__post_remove_distdir)
	@(echo "$(distdir) archives ready for distribution: "; \
	  list='$(DIST_ARCHIVES)'; for i in $$list; do echo $$i; done) | \
	  sed -e 1h -e 1s/./=/g -e 1p -e 1x -e '$$p' -e '$$x'

# Define distuninstallcheck_listfiles and distuninstallcheck separately
# from distcheck, so that they can be overridden by the user.
.PHONY: distuninstallcheck
distuninstallcheck_listfiles = find . -type f -print
# The 'dir' file (created by install-info) might still exist after
# uninstall, so we must be prepared to account for it.  The following
# check is not 100% strict, but is definitely good enough, and even
# accounts for overridden $(infodir).
am__distuninstallcheck_listfiles = $(distuninstallcheck_listfiles) \
  | sed 's|^\./|$(prefix)/|' | grep -v '$(infodir)/dir$$'
distuninstallcheck:
	@test -n '$(distuninstallcheck_dir)' || { \
	  echo 'ERROR: trying to run $@ with an empty' \
	       '$$(distuninstallcheck_dir)' >&2; \
	  exit 1; \
	}; \
	cd '$(distuninstallcheck_dir)' || { \
	  echo 'ERROR: cannot chdir into $(distuninstallcheck_dir)' >&2; \
	  exit 1; \
	}; \
	test `$(am__distuninstallcheck_listfiles) | wc -l` -eq 0 \
	   || { echo "ERROR: files left after uninstall:" ; \
	        if test -n "$(DESTDIR)"; then \
	          echo "  (check DESTDIR support)"; \
	        fi ; \
	        $(distuninstallcheck_listfiles) ; \
	        exit 1; } >&2

# Define '$(distcleancheck_listfiles)' and 'distcleancheck' separately
# from distcheck, so that they can be overridden by the user.
ifeq ($(call am.vars.is-undef,distcleancheck_listfiles),yes)
  distcleancheck_listfiles := find . -type f -print
endif
.PHONY: distcleancheck
distcleancheck: distclean
	@if test '$(srcdir)' = . ; then \
	  echo "ERROR: distcleancheck can only run from a VPATH build" ; \
	  exit 1 ; \
	fi
	@test `$(distcleancheck_listfiles) | wc -l` -eq 0 \
	  || { echo "ERROR: files left in build directory after distclean:" ; \
	       $(distcleancheck_listfiles) ; \
	       exit 1; } >&2
