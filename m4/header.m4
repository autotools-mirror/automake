# Like AC_CONFIG_HEADER, but automatically create stamp file. -*- Autoconf -*-

# Copyright 1996, 1997, 2000, 2001 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

AC_PREREQ([2.52])

# serial 6

# When config.status generates a header, we must update the stamp-h file.
# This file resides in the same directory as the config header
# that is generated.  We must strip everything past the first ":",
# and everything past the last "/".

# _AM_DIRNAME(PATH)
# -----------------
# Like AS_DIRNAME, only do it during macro expansion
AC_DEFUN([_AM_DIRNAME],
       [m4_if(regexp([$1], [^.*[^/]//*[^/][^/]*/*$]), -1,
	      m4_if(regexp([$1], [^//\([^/]\|$\)]), -1,
		    m4_if(regexp([$1], [^/.*]), -1,
			  [.],
			  patsubst([$1], [^\(/\).*], [\1])),
		    patsubst([$1], [^\(//\)\([^/].*\|$\)], [\1])),
	      patsubst([$1], [^\(.*[^/]\)//*[^/][^/]*/*$], [\1]))[]dnl
])# _AM_DIRNAME


# The stamp files are numbered to have different names.
# We could number them on a directory basis, but that's additional
# complications, let's have a unique counter.
m4_define([_AM_STAMP_Count], [0])


# _AM_STAMP(HEADER)
# -----------------
# The name of the stamp file for HEADER.
AC_DEFUN([_AM_STAMP],
[m4_define([_AM_STAMP_Count], m4_incr(_AM_STAMP_Count))dnl
AS_ESCAPE(_AM_DIRNAME(patsubst([$1],
                               [:.*])))/stamp-h[]_AM_STAMP_Count])


# _AM_CONFIG_HEADER(HEADER[:SOURCES], COMMANDS, INIT-COMMANDS)
# ------------------------------------------------------------
# We used to try to get a real timestamp in stamp-h.  But the fear is that
# that will cause unnecessary cvs conflicts.
AC_DEFUN([_AM_CONFIG_HEADER],
[# Add the stamp file to the list of files AC keeps track of,
# along with our hook.
_AM_AC_CONFIG_HEADERS([$1],
                  [# update the timestamp
echo 'timestamp for $1' >"_AM_STAMP([$1])"
$2],
                  [$3])
])# _AM_CONFIG_HEADER


# _AM_CONFIG_HEADERS(HEADER[:SOURCES]..., COMMANDS, INIT-COMMANDS)
# ----------------------------------------------------------------
AC_DEFUN([_AM_CONFIG_HEADERS],
[AC_FOREACH([_AM_File], [$1], [_AM_CONFIG_HEADER(_AM_File, [$2], [$3])])
])# _AM_CONFIG_HEADERS

# This is a false definition of AM_CONFIG_HEADER that will be
# overridden by the real definition when _AM_CONFIG_HEADER_INSINUATE
# is called (i.e. during AM_INIT_AUTOMAKE).
AC_DEFUN([AM_CONFIG_HEADER],
[m4_fatal([AM_CONFIG_HEADER called before AM_INIT_AUTOMAKE])])

# _AM_CONFIG_HEADER_INSINUATE
# ---------------------------
# Replace AC_CONFIG_HEADERS with our AM_CONFIG_HEADER.
# We don't care about AC_CONFIG_HEADER (without S): it's an obsolete
# Autoconf macro which will simply call AC_CONFIG_HEADERS (with S).
AC_DEFUN([_AM_CONFIG_HEADER_INSINUATE], [
dnl Since the substitution is only effective after AM_INIT_AUTOMAKE,
dnl make sure AC_CONFIG_HEADERS is not called before.
AC_BEFORE([AM_INIT_AUTOMAKE], [AC_CONFIG_HEADERS])dnl
dnl Save the previous AC_CONFIG_HEADERS definition
dnl (Beware: this must be m4_copy, not m4_rename, because we will
dnl lose the --trace bit of AC_CONFIG_HEADERS if we undefine it.)
m4_copy([AC_CONFIG_HEADERS], [_AM_AC_CONFIG_HEADERS])dnl
dnl Override AC_CONFIG_HEADERS with ours.
AC_DEFUN([AC_CONFIG_HEADERS], [_AM_CONFIG_HEADERS($][@)])dnl
dnl Define AM_CONFIG_HEADERS (obsolete) in terms of AC_CONFIG_HEADERS.
dnl This way autoheader will `see' the calls to AM_CONFIG_HEADER.
AC_DEFUN([AM_CONFIG_HEADER], [AC_CONFIG_HEADERS($][@)])dnl
])
