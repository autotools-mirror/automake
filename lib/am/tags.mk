## automake - create Makefile.in from Makefile.am
## Copyright (C) 1994-2012 Free Software Foundation, Inc.

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

# Every Makefile must define some sort of TAGS rule.  Otherwise, it
# would be possible for a top-level "make TAGS" to fail because some
# subdirectory failed.  Ditto for ctags and cscope.
.PHONY: tags TAGS ctags CTAGS cscope cscopelist

am.tags.files = \
  $(call am.memoize,am.tags.files,$(strip \
    $(HEADERS) $(SOURCES) $(TAGS_FILES) $(LISP) $(am.config-hdr.local.in)))

# Let's see if we have to actually deal with tags creation.
ifneq ($(or $(am.tags.files),$(ETAGS_ARGS),$(SUBDIRS)),)

# ---------------------------------- #
#  Tags-related internal variables.  #
# ---------------------------------- #

# Use $(sort) rather than $(am.util.uniq) here, because the former is
# faster on long lists, and we don't care about the order of the list
# anyway.
am.tags.files.unique = \
 $(call am.memoize,am.tags.files.unique,$(sort \
   $(foreach f,$(am.tags.files),$(call am.vpath.rewrite,$f))))

# Option to include other TAGS files in an etags-generated file.
# Exuberant Ctags wants '--etags-include', GNU Etags wants '--include'.
am.tags.include-option = \
 $(call am.memoize,am.tags.include-option,$(strip $(shell \
   if { $(ETAGS) --etags-include --version; } >/dev/null 2>&1; then \
     printf '%s\n' --etags-include; \
   else \
     printf '%s\n' --include; \
   fi)))

# TAGS files in $(SUBDIRS) entries (if any) that must be included in
# the top-level TAGS file.
am.tags.subfiles = \
  $(call am.memoize,am.tags.subfiles,$(strip \
    $(foreach d,$(filter-out .,$(SUBDIRS)),$(wildcard $d/TAGS))))


# ---------------------------------- #
#  ID database (from GNU id-utils).  #
# ---------------------------------- #

ID: $(am.tags.files)
	mkid -fID $(am.tags.files.unique)
am.clean.dist.f += ID


# -------------------------------- #
#  GNU Etags and Exuberant ctags.  #
# -------------------------------- #

CTAGS = ctags
ETAGS = etags

ifdef SUBDIRS
AM_RECURSIVE_TARGETS += TAGS CTAGS
RECURSIVE_TARGETS += tags-recursive ctags-recursive
ctags: ctags-recursive
tags: tags-recursive
else
tags: tags-am
ctags: ctags-am
endif

TAGS: tags
CTAGS: ctags
.PHONY: TAGS tags CTAGS ctags

tags-am: $(TAGS_DEPENDENCIES) $(am.tags.files)
ifneq ($(or $(ETAGS_ARGS),$(am.tags.subfiles),$(am.tags.files.unique)),)
	$(ETAGS) \
	  $(ETAGSFLAGS) $(AM_ETAGSFLAGS) $(ETAGS_ARGS) \
	  $(foreach f,$(am.tags.subfiles),'$(am.tags.include-option)=$(CURDIR)/$f') \
	  $(am.tags.files.unique)
endif

ctags-am: $(TAGS_DEPENDENCIES) $(am.tags.files)
ifneq ($(or $(CTAGS_ARGS),$(am.tags.files.unique)),)
	$(CTAGS) \
	  $(CTAGSFLAGS) $(AM_CTAGSFLAGS) $(CTAGS_ARGS) \
	  $(am.tags.files.unique)
endif

am.clean.dist.f += TAGS tags


# -------------------- #
#  GNU "Global tags".  #
# -------------------- #

.PHONY: GTAGS
GTAGS:
	cd $(top_srcdir) && gtags -i $(GTAGS_ARGS) '$(abs_top_builddir)'
am.clean.dist.f += GTAGS GRTAGS GSYMS


# --------- #
#  Cscope.  #
# --------- #

ifdef am.conf.is-topdir
CSCOPE = cscope
.PHONY: cscope clean-cscope
AM_RECURSIVE_TARGETS += cscope
cscope: cscope.files
	test ! -s cscope.files \
	  || $(CSCOPE) -b -q $(AM_CSCOPEFLAGS) $(CSCOPEFLAGS) -i cscope.files $(CSCOPE_ARGS)
clean-cscope:
	rm -f cscope.files
cscope.files: clean-cscope cscopelist
am.clean.dist.f += cscope.out cscope.in.out cscope.po.out cscope.files
endif

ifdef SUBDIRS
RECURSIVE_TARGETS += cscopelist-recursive
cscopelist: cscopelist-recursive
else
cscopelist: cscopelist-am
endif

cscopelist-am: $(am.tags.files)
	list='$(am.tags.files)'; \
	case "$(srcdir)" in \
	  [\\/]* | ?:[\\/]*) sdir="$(srcdir)" ;; \
	  *) sdir=$(subdir)/$(srcdir) ;; \
	esac; \
	for i in $$list; do \
	  if test -f "$$i"; then \
	    echo "$(subdir)/$$i"; \
	  else \
	    echo "$$sdir/$$i"; \
	  fi; \
	done >> $(top_builddir)/cscope.files

endif # Dealing with tags.
