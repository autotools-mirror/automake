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

# serial 5

# When config.status generates a header, we must update the stamp-h file.
# This file resides in the same directory as the config header
# that is generated.  We must strip everything past the first ":",
# and everything past the last "/".

# The stamp files are numbered to have different names.
# We could number them on a directory basis, but that's additional
# complications, let's have a unique counter.
m4_define([_AM_Config_Header_Index], [0])


# _AM_CONFIG_HEADER(HEADER[:SOURCES], COMMANDS, INIT-COMMANDS)
# ------------------------------------------------------------
AC_DEFUN([_AM_CONFIG_HEADER],
[m4_pushdef([_AM_Dest], patsubst([$1], [:.*]))
m4_define([_AM_Config_Header_Index], m4_incr(_AM_Config_Header_Index))
# Add the stamp file to the list of files AC keeps track of,
# along with our hook
AC_CONFIG_HEADERS([$1],
                  [# update the timestamp
echo timestamp >"AS_ESCAPE(_AM_DIRNAME(]_AM_Dest[))/stamp-h]_AM_Config_Header_Index["
$2],
                  [$3])
m4_popdef([_AM_Dest])
])# # _AM_CONFIG_HEADER


# AM_CONFIG_HEADER(HEADER[:SOURCES]..., COMMANDS, INIT-COMMANDS)
# --------------------------------------------------------------
AC_DEFUN([AM_CONFIG_HEADER],
[AC_FOREACH([_AM_File], [$1], [_AM_CONFIG_HEADER(_AM_File, [$2], [$3])])
]) # AM_CONFIG_HEADER


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
]) # _AM_DIRNAME
