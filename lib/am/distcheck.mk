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


# ---------------------------------------- #
#  Building various distribution flavors.  #
# ---------------------------------------- #

# ----------------------------------------------------------------------
# FIXME: how and where are these old comments still relevant?
# ----------------------------------------------------------------------
# Note that we don't use GNU tar's '-z' option.  One reason (but
# not the only reason) is that some versions of tar (e.g., OSF1)
# interpret '-z' differently.
#
# The -o option of GNU tar used to exclude empty directories.  This
# behavior was fixed in tar 1.12 (released on 1997-04-25).  But older
# versions of tar are still used (for instance NetBSD 1.6.1 ships
# with tar 1.11.2).  We do not do anything specific w.r.t. this
# incompatibility since packages where empty directories need to be
# present in the archive are really unusual.
# ----------------------------------------------------------------------

# TODO: this definition-oriented interface is almost god enough to offer
# as a public API allowing the user to define and use new archive formats.
# However, we must think carefully about possible problems before setting
# the API in stone.  So, for the moment, we keep this internal and
# private; there will be time to make it public, once (and if) there's
# any request from the user base.

am.dist.all-formats =

am.dist.all-formats += gzip
am.dist.ext.gzip = tar.gz
am.dist.compress-cmd.gzip = GZIP=$(GZIP_ENV) gzip -c
am.dist.uncompress-cmd.gzip = GZIP=$(GZIP_ENV) gzip -dc

am.dist.all-formats += bzip2
am.dist.ext.bzip2 = tar.bz2
am.dist.compress-cmd.bzip2 = BZIP2=$${BZIP2--9} bzip2 -c
am.dist.uncompress-cmd.bzip2 = bzip2 -dc

am.dist.all-formats += lzip
am.dist.ext.lzip = tar.lz
am.dist.compress-cmd.lzip = lzip -c $${LZIP_OPT--9}
am.dist.uncompress-cmd.lzip = lzip -dc

am.dist.all-formats += xz
am.dist.ext.xz = tar.xz
am.dist.compress-cmd.xz = XZ_OPT=$${XZ_OPT--e} xz -c
am.dist.uncompress-cmd.xz = xz -dc

am.dist.all-formats += zip
am.dist.ext.zip = zip
am.dist.create-cmd.zip = \
  rm -f $(distdir).zip && zip -rq $(distdir).zip $(distdir)
am.dist.extract-cmd.zip = \
  unzip $(distdir).zip

am.dist.all-targets = $(patsubst %,dist-%,$(am.dist.all-formats))

define am.dist.create-archive-for-format.aux
$(or $(am.dist.create-cmd.$1), \
  tardir=$(distdir) && $(am__tar) \
    | $(am.dist.compress-cmd.$1) >$(distdir).$(am.dist.ext.$1))
endef
am.dist.create-archive-for-format = $(call $0.aux,$(strip $1))

define am.dist.extract-archive-for-format.aux
$(or $(am.dist.extract-cmd.$1), \
  $(am.dist.uncompress-cmd.$1) $(distdir).$(am.dist.ext.$1) \
    | $(am__untar))
endef
am.dist.extract-archive-for-format = $(call $0.aux,$(strip $1))

# The use of this option to pass arguments to the 'gzip' invocation is
# not only documented in the manual and useful for better compatibility
# with mainline Automake, but also actively employed by some important
# makefile fragments (e.g., Gnulib's 'top/maint.mk', at least up to
# commit v0.0-7569-gec58403).  So keep it.
GZIP_ENV = --best

am.dist.default-targets = \
  $(foreach x,$(am.dist.formats),dist-$x)
am.dist.default-archives = \
  $(foreach x,$(am.dist.formats),$(distdir).$(am.dist.ext.$x))

.PHONY: $(am.dist.all-targets)
$(am.dist.all-targets): dist-%: distdir
	$(call am.dist.create-archive-for-format,$*)
	$(am.dist.post-remove-distdir)


# -------------------------------------------------- #
#  Building all the requested distribution flavors.  #
# -------------------------------------------------- #

ifdef
AM_RECURSIVE_TARGETS += dist dist-all
endif

.PHONY: dist dist-all
dist dist-all:
	$(MAKE) $(am.dist.default-targets) am.dist.post-remove-distdir='@:'
	$(am.dist.post-remove-distdir)


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
	$(call am.dist.extract-archive-for-format, \
	  $(firstword $(am.dist.formats)))
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
	  && rm -f $(am.dist.default-archives) \
	  && $(MAKE) distcleancheck
	$(am.dist.post-remove-distdir)
	@(echo "$(distdir) archives ready for distribution: "; \
	  list='$(am.dist.default-archives)'; \
	  for i in $$list; do echo $$i; done; \
	 ) | sed -e 1h -e 1s/./=/g -e 1p -e 1x -e '$$p' -e '$$x'

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
