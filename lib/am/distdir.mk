## automake - create Makefile.in from Makefile.am
## Copyright (C) 2001-2013 Free Software Foundation, Inc.

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Files added by the automake script.
am.dist.common-files += $(am.dist.common-files.internal)

# Makefile fragments used internally by automake-generated Makefiles.
am.dist.mk-files = $(wildcard $(am.conf.aux-dir)/am-ng/*)

# Use 'sort', not 'am.util.uniq', for performance reasons.  Luckily, we
# don't care in which order the distributed files are.
am.dist.all-files = $(call am.memoize,am.dist.all-files,$(strip $(sort \
  $(am.dist.common-files) $(am.dist.sources) $(am.dist.mk-files) \
  $(TEXINFOS) $(EXTRA_DIST))))

# Try to avoid repeated slashes in the entries, to make the filtering
# in the 'am.dist.files-tmp2' definition below more reliable.
# This idiom should compress up to four consecutive '/' characters
# in each $(am.dist.all-files) entry.
am.dist.files-tmp1 = $(call am.memoize,am.dist.files-tmp1, \
  $(subst //,/,$(subst //,/,$(am.dist.all-files))))

# Files filtered out here require an ad-hoc "munging".
#
# 1. In the first $(patsubst), we strip leading $(srcdir) (which might
#    appears in EXTRA_DIST, especially if one want to use the $(wildcard)
#    built-in in there), so that in our 'distdir' recipe below we can loop
#    on the list of distributed files and copy them in the distribution
#    directory with a simple "cp $file $(distdir)/$file" -- which would
#    break if $file contained a leading $(srcdir) component.  However,
#    it should be noted that this filtering has the quite undesirable
#    side effect of triggering a VPATH search also for files specified
#    *explicitly* with a $(srcdir) prefix; but this limitation is also
#    present in mainline Automake, and concerns only such corner-case
#    situations that it's probably not worth worrying about.
#
# 2. In the second $(patsubst), we also rewrite $(top_srcdir) -- which
#    can sometimes appear in $(am.dist.common-files), and can be an
#    absolute path -- by $(top_builddir) (which is always relative).
#    If needed, $(srcdir) will be prepended later by our VPATH-aware
#    rules.  The same caveats reported above apply.
#
am.dist.files-tmp2 = $(call am.memoize,am.dist.files-tmp2, \
  $(filter-out $(srcdir)/% $(top_srcdir)/%, $(am.dist.files-tmp1)) \
  $(patsubst $(srcdir)/%, %, \
             $(filter $(srcdir)/%, $(am.dist.files-tmp1))) \
  $(patsubst $(top_srcdir)/%, $(top_builddir)/%, \
             $(filter $(top_srcdir)/%, $(am.dist.files-tmp1))))

# Strip extra whitespaces, for more safety.
am.dist.files-cooked = \
  $(call am.memoize,am.dist.files-cooked,$(strip $(am.dist.files-tmp2)))

# Given the pre-processing done above to the list of distributed files,
# this definition ensures that we won't try to create the wrong
# directories when $(top_srcdir) or $(srcdir) appears in some entry of
# the list of all distributed files.
# For example, with EXTRA_DIST containing "$(srcdir)/subdir/file", this
# will allow our rules to correctly create "$(distdir)/subdir", and not
# "$(distdir)/$(srcdir)/subdir" -- which, in a VPATH build where
# "$(subdir) = ..", would be the build directory!
am.dist.parent-dirs = \
  $(call am.memoize,am.dist.parent-dirs,$(strip $(sort \
    $(filter-out ., $(patsubst ./%,%,$(dir $(am.dist.files-cooked)))))))

# These two variables are used in the 'distdir' rule below to avoid
# potential problems with overly long command lines (the infamous
# "Argument list too long" error).
am.dist.xmkdir = \
  @$(MKDIR_P) $(patsubst %,"$(distdir)"/%,$1)$(am.chars.newline)
am.dist.write-filelist = \
  @lst='$1'; for x in $$lst; do echo $$x; done \
    >> $(am.dir)/$@-list$(am.chars.newline)

ifdef am.conf.is-topdir

# This is user-overridable.
ifeq ($(call am.vars.is-undef,distdir),yes)
distdir = $(PACKAGE)-$(VERSION)
endif

# This is not, but must be public to be avaialable in the "dist-hook"
# rules (this is also documented in the Automake manual).
top_distdir = $(distdir)

# A failed "make distcheck" might leave some parts of the $(distdir)
# readonly, so we need these hoops to ensure it is removed correctly.
# On MSYS (1.0.17, at least) it is not possible to remove a directory
# that is in use; so, if the first rm fails, we sleep some seconds and
# retry, to give pending processes some time to exit and "release" the
# directory before we remove it.  The value of "some seconds" is 5 for
# the moment, which is mostly an arbitrary value, but seems high enough
# in practice.  See automake bug#10470.
am.dist.remove-distdir = \
    find "$(distdir)" -type d ! -perm -200 -exec chmod u+w {} ';' \
      && rm -rf "$(distdir)" \
      || { sleep 5 && rm -rf "$(distdir)"; }

# Define this separately, so that if can be overridden by the recursive
# make invocation in 'dist-all'.  That is needed to support concurrent
# creation of different tarball formats.
am.dist.post-remove-distdir = \
  test ! -d "$(distdir)" || { $(am.dist.remove-distdir); }

endif # am.conf.is-topdir

ifdef DIST_SUBDIRS
# Computes a relative pathname RELDIR such that DIR1/RELDIR = DIR2.
# Input:
#   - dir1      relative pathname, relative to the current directory.
#   - dir2      relative pathname, relative to the current directory.
# Output:
#   - reldir    relative pathname of dir2, relative to dir1.
am.dist.relativize-path = \
  dir0=`pwd`; \
  sed_first='s,^\([^/]*\)/.*$$,\1,'; \
  sed_rest='s,^[^/]*/*,,'; \
  sed_last='s,^.*/\([^/]*\)$$,\1,'; \
  sed_butlast='s,/*[^/]*$$,,'; \
  while test -n "$$dir1"; do \
    first=`echo "$$dir1" | sed -e "$$sed_first"`; \
    if test "$$first" != "."; then \
      if test "$$first" = ".."; then \
        dir2=`echo "$$dir0" | sed -e "$$sed_last"`/"$$dir2"; \
        dir0=`echo "$$dir0" | sed -e "$$sed_butlast"`; \
      else \
        first2=`echo "$$dir2" | sed -e "$$sed_first"`; \
        if test "$$first2" = "$$first"; then \
          dir2=`echo "$$dir2" | sed -e "$$sed_rest"`; \
        else \
          dir2="../$$dir2"; \
        fi; \
        dir0="$$dir0"/"$$first"; \
      fi; \
    fi; \
    dir1=`echo "$$dir1" | sed -e "$$sed_rest"`; \
  done; \
  reldir="$$dir2"
endif # DIST_SUBDIRS

.PHONY: distdir
ifdef DIST_SUBDIRS
AM_RECURSIVE_TARGETS += distdir
endif

distdir: $(am.dist.all-files) | $(am.dir)
##
## For Gnits users, this is pretty handy.  Look at 15 lines
## in case some explanatory text is desirable.
##
ifdef am.conf.is-topdir
ifdef am.conf.check-news
	@case `sed 15q $(srcdir)/NEWS` in \
	  *'$(VERSION)'*) : ;; \
	  *) echo "NEWS not updated; not releasing" 1>&2; exit 1;; \
	esac
endif # am.conf.is-topdir
## Avoid this command if there is no directory to clean.
	$(if $(wildcard $(distdir)/),$(am.dist.remove-distdir))
	test -d "$(distdir)" || mkdir "$(distdir)"
endif # am.conf.check-news
## Make the subdirectories for the files, avoiding to exceed command
## line length limitations.
	$(call am.xargs-map,am.dist.xmkdir,$(am.dist.parent-dirs))
## Install the files and directories, applying a "VPATH rewrite"
## by hand where needed.
## To get the files in the distribution directory, use 'cp', not 'ln'.
## There are situations in which 'ln' can fail.  For instance a file to
## distribute could actually be a cross-filesystem symlink -- this can
## easily happen if "gettextize" was run on the distribution.
	@rm -f $(am.dir)/$@-list
	$(call am.xargs-map,am.dist.write-filelist, \
	       $(am.dist.files-cooked))
	@while read file; do \
## Always look for the file or directory to distribute in the build
## directory first, in VPATH spirit.
	  if test -f $$file || test -d $$file; then d=.; else d=$(srcdir); fi; \
	  if test -d $$d/$$file; then \
## Don't mention $$file in the destination argument, since this fails if
## the destination directory already exists.  Also, use '-R' and not '-r'.
## '-r' is almost always incorrect.
## If a directory exists both in '.' and $(srcdir), then we copy the
## files from $(srcdir) first and then install those from '.'.  This
## can help people who distribute directories made of source files
## *and* generated files.
	    dir=`echo "/$$file" | sed -e 's,/[^/]*$$,,'`; \
## If the destination directory already exists, it may contain read-only
## files, e.g., during "make distcheck".
	    if test -d "$(distdir)/$$file"; then \
	      find "$(distdir)/$$file" -type d ! -perm -700 -exec chmod u+rwx {} \;; \
	    fi; \
	    if test -d $(srcdir)/$$file && test $$d != $(srcdir); then \
	      cp -fpR $(srcdir)/$$file "$(distdir)$$dir" || exit 1; \
	      find "$(distdir)/$$file" -type d ! -perm -700 -exec chmod u+rwx {} \;; \
	    fi; \
	    cp -fpR $$d/$$file "$(distdir)$$dir" || exit 1; \
	  else \
## Test for file existence because sometimes a single auxiliary file
## is distributed from several Makefiles at once (see automake bug#9546
## and bug#9651, and the follow-up commits 'v1.11-1219-g326ecba',
## 'v1.11-1220-g851b1ae' and 'v1.11-1221-gdccae6a').  See also test
## 't/dist-repeated.sh'.
	    test -f "$(distdir)/$$file" \
	    || cp -p $$d/$$file "$(distdir)/$$file" \
	    || exit 1; \
	  fi; \
	done < $(am.dir)/$@-list
##
## Test for directory existence here because previous automake
## invocation might have created some directories.  Note that we
## explicitly set distdir for the subdir make; that lets us mix-n-match
## many automake-using packages into one large package, and have "dist"
## at the top level do the right thing.  If we're in the topmost
## directory, then we use 'distdir' instead of 'top_distdir'; this lets
## us work correctly with an enclosing package.
ifdef DIST_SUBDIRS
	@list='$(DIST_SUBDIRS)'; for subdir in $$list; do \
	  if test "$$subdir" = .; then :; else \
	    $(am.make.dry-run) \
	      || test -d "$(distdir)/$$subdir" \
	      || $(MKDIR_P) "$(distdir)/$$subdir" \
	      || exit 1; \
	    dir1=$$subdir; dir2="$(distdir)/$$subdir"; \
	    $(am.dist.relativize-path); \
	    new_distdir=$$reldir; \
	    dir1=$$subdir; dir2="$(top_distdir)"; \
	    $(am.dist.relativize-path); \
	    new_top_distdir=$$reldir; \
	    echo " $(MAKE) -C $$subdir distdir top_distdir=$$new_top_distdir distdir=$$new_distdir"; \
	    $(MAKE) -C $$subdir distdir \
	        top_distdir="$$new_top_distdir" \
	        distdir="$$new_distdir" \
## Disable am.dist.remove-distdir so that sub-packages do not clear a
## directory we have already cleared and might even have populated
## (e.g. shared AUX dir in the sub-package).
		am.dist.remove-distdir='' \
## Disable filename length check:
		am.dist.filename-filter='' \
## No need to fix modes more than once:
		am.dist.skip-mode-fix=yes \
	      || exit 1; \
	  fi; \
	done
endif # DIST_SUBDIRS
##
## We might have to perform some last second updates, such as updating
## info files.
## We must explicitly set distdir and top_distdir for these sub-makes.
##
ifdef am.dist.extra-targets
	$(MAKE) $(am.dist.extra-targets) $(if $(am.conf.is-topdir),, \
	  top_distdir="$(top_distdir)" distdir="$(distdir)")
endif
##
## This complex find command will try to avoid changing the modes of
## links into the source tree, in case they're hard-linked.
##
## Ignore return result from chmod, because it might give an error
## if we chmod a symlink.
##
## Another nastiness: if the file is unreadable by us, we make it
## readable regardless of the number of links to it.  This only
## happens in perverse cases.
##
## We use $(install_sh) because that is a known-portable way to modify
## the file in place in the source tree.
##
## If we are being invoked recursively, then there is no need to walk
## the whole subtree again.  This is a complexity reduction for a deep
## hierarchy of subpackages.
##
ifdef am.conf.is-topdir
ifndef am.dist.skip-mode-fix
	find "$(distdir)" \
	  -type d ! -perm -755 -exec chmod u+rwx,go+rx {} \; -o \
	  ! -type d ! -perm -444 -links 1 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -400 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -444 -exec $(install_sh) -c -m a+r {} {} \; \
	|| chmod -R a+r "$(distdir)"
endif # !am.dist.skip-mode-fix
ifdef am.dist.filename-filter
	@if find "$(distdir)" -type f -print \
	    | grep '^$(am.dist.filename-filter)' 1>&2; then \
	  echo '$@: error: the above filenames are too long' 1>&2; \
	  exit 1; \
	else :; fi
endif # am.dist.filename-filter
endif # am.conf.is-topdir
