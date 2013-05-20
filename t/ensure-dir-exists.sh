#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
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

# Test Automake-provided internal macro 'am.cmd.ensure-dir-exists'.

am_create_testdir=empty
. test-init.sh

# Filter out Automake comments.
grep -v '^##' "$am_amdir"/header-vars.mk > defn.mk \
  || fatal_ "fetching makefile fragment headers-vars.am"

cat > Makefile << 'END'
include ./defn.mk

files = x/1 x/2 x/3

all: $(files)
.PHONY: all

sanity-check:
	$(warning $(call am.cmd.ensure-dir-exists,x))
	$(if $(filter $(call am.cmd.ensure-dir-exists,x),:MKDIR_P:),, \
             $(error am.cmd.ensure-dir-exists does not contain $$(MKDIR_P)))
.PHONY: sanity-check

$(files):
	$(call am.cmd.ensure-dir-exists,x)
	echo dummy > $@
END

# Sanity check.
$MAKE sanity-check MKDIR_P=:MKDIR_P:

# Basic usage.
$MAKE MKDIR_P='mkdir -p'
test -f x/1
test -f x/2
test -f x/3

# Mkdir is not called uselessly.
rm -rf x
mkdir x
$MAKE MKDIR_P=false

# Mkdir is  not called too many times.
rm -rf x
$MAKE MKDIR_P=mkdir
test -f x/1
test -f x/2
test -f x/3

:
