#! /bin/sh
# Copyright (C) 1996-2013 Free Software Foundation, Inc.
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

# Test to ensure that a ".info~" or ".info.bak" file doesn't end up
# in the distribution or the installation.  Bug report from Greg McGary.
# Also make sure that "split" info files (today no longer supported,
# see automake bug#13351) are not distributed nor installed.  See
# automake bug#12320.

. test-init.sh

cat >> configure.ac << 'END'
AC_OUTPUT
END

cat > Makefile.am << 'END'
info_TEXINFOS = textutils.texi subdir/main.texi

test-dist: distdir
	test -f $(distdir)/textutils.info
	test -f $(distdir)/subdir/main.info
	@echo am.dist.all-files = $(am.dist.all-files)
	@case '$(am.dist.all-files)' in \
           *'~'*|*'.bak'*|*'.info-'*|*.i[0-9]*) exit 1;; \
          *) exit 0;; \
        esac
	@st=0; \
	 find $(distdir) | grep '~' && st=1; \
	 find $(distdir) | grep '\.bak' && st=1; \
	 find $(distdir) | grep '\.info-' && st=1; \
	 find $(distdir) | grep '\.i[0-9]' && st=1; \
	 exit $$st

test-inst: install
	test -f '$(infodir)/textutils.info'
	test -f '$(infodir)/main.info'
	@st=0; \
	 find '$(prefix)' | grep '~' && st=1; \
	 find '$(prefix)' | grep '\.bak' && st=1; \
	 find '$(prefix)' | grep '\.info-' && st=1; \
	 find '$(prefix)' | grep '\.i[0-9]' && st=1; \
	 exit $$st

PHONY: test-dist test-inst
END

: > texinfo.tex
mkdir subdir
echo '@setfilename textutils.info' > textutils.texi
echo '@setfilename main.info' > subdir/main.texi

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure --prefix="$(pwd)/_inst"
info_suffixes='info info-0 info-1 info-2 i00 i01 i23 info.bak info~'
for suf in $info_suffixes; do
  for base in textutils subdir/main; do
    : > $base.$suf
  done
done
ls -l . subdir # For debugging.
$MAKE test-dist
$MAKE test-inst
$MAKE maintainer-clean

for suf in $info_suffixes; do
  for base in textutils subdir/main; do
    if test "$suf" = info; then
      test ! -e $base.$suf
    else
      test -f $base.$suf
    fi
  done
done

:
