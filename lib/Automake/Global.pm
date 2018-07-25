# Copyright (C) 2018  Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Automake::Global;

use 5.006;
use strict;

use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw ($IGNORE_PATTERN $WHITE_PATTERN $COMMENT_PATTERN $RULE_PATTERN
    $ASSIGNMENT_PATTERN $GNITS_VERSION_PATTERN $IF_PATTERN $ELSE_PATTERN
    $ENDIF_PATTERN $PATH_PATTERN $INCLUDE_PATTERN $EXEC_DIR_PATTERN
    @libtool_files @libtool_sometimes @common_files @common_sometimes
    %standard_prefix $force_generation $symlink_exists $add_missing
    $copy_missing $force_missing %libsources @config_headers @config_links
    @input_files %output_files @configure_input_files @other_input_files
    %ac_config_files_location %ac_config_files_condition $config_libobj_dir
    $seen_gettext $seen_gettext_external $seen_gettext_intl
    @extra_recursive_targets %libtool_tags $libtool_new_api $package_version
    $seen_ar %required_aux_file $seen_init_automake $seen_automake_version
    %configure_cond %extension_map @configure_dist_common %languages
    %link_languages %sourceflags %required_targets $am_file $configure_ac
    $ac_gettext_location $package_version_location $required_conf_file_queue
    $output_deps_greatest_timestamp $output_all $output_header $output_rules
    $output_trailer @include_stack @all @check @check_tests %clean_files
    %compile_clean_files %libtool_clean_directories @sources @dist_sources
    %object_map %object_compilation_map %directory_map %dep_files
    @dist_targets @proglist @liblist @ltliblist @dup_shortnames
    %known_programs %known_libraries %extension_seen %language_scratch
    %lang_specific_files @dist_common $handle_dist_run %linkers_used
    $need_link $must_handle_compiled_objects AC_CANONICAL_BUILD
    AC_CANONICAL_HOST AC_CANONICAL_TARGET MOSTLY_CLEAN CLEAN DIST_CLEAN
    MAINTAINER_CLEAN LANG_IGNORE LANG_PROCESS LANG_SUBDIR COMPILE_LIBTOOL
    COMPILE_ORDINARY QUEUE_MESSAGE QUEUE_CONF_FILE QUEUE_LOCATION
    QUEUE_STRING);

## ----------- ##
## Constants.  ##
## ----------- ##

# Some regular expressions.  One reason to put them here is that it
# makes indentation work better in Emacs.

# Writing singled-quoted-$-terminated regexes is a pain because
# perl-mode thinks of $' as the ${'} variable (instead of a $ followed
# by a closing quote.  Letting perl-mode think the quote is not closed
# leads to all sort of misindentations.  On the other hand, defining
# regexes as double-quoted strings is far less readable.  So usually
# we will write:
#
#  $REGEX = '^regex_value' . "\$";

our $IGNORE_PATTERN = '^\s*##([^#\n].*)?\n';
our $WHITE_PATTERN = '^\s*' . "\$";
our $COMMENT_PATTERN = '^#';
our $TARGET_PATTERN='[$a-zA-Z0-9_.@%][-.a-zA-Z0-9_(){}/$+@%]*';
# A rule has three parts: a list of targets, a list of dependencies,
# and optionally actions.
our $RULE_PATTERN =
  "^($TARGET_PATTERN(?:(?:\\\\\n|\\s)+$TARGET_PATTERN)*) *:([^=].*|)\$";

# Only recognize leading spaces, not leading tabs.  If we recognize
# leading tabs here then we need to make the reader smarter, because
# otherwise it will think rules like 'foo=bar; \' are errors.
our $ASSIGNMENT_PATTERN = '^ *([^ \t=:+]*)\s*([:+]?)=\s*(.*)' . "\$";
# This pattern recognizes a Gnits version id and sets $1 if the
# release is an alpha release.  We also allow a suffix which can be
# used to extend the version number with a "fork" identifier.
our $GNITS_VERSION_PATTERN = '\d+\.\d+([a-z]|\.\d+)?(-[A-Za-z0-9]+)?';

our $IF_PATTERN = '^if\s+(!?)\s*([A-Za-z][A-Za-z0-9_]*)\s*(?:#.*)?' . "\$";
our $ELSE_PATTERN =
  '^else(?:\s+(!?)\s*([A-Za-z][A-Za-z0-9_]*))?\s*(?:#.*)?' . "\$";
our $ENDIF_PATTERN =
  '^endif(?:\s+(!?)\s*([A-Za-z][A-Za-z0-9_]*))?\s*(?:#.*)?' . "\$";
our $PATH_PATTERN = '(\w|[+/.-])+';
# This will pass through anything not of the prescribed form.
our $INCLUDE_PATTERN = ('^include\s+'
		       . '((\$\(top_srcdir\)/' . $PATH_PATTERN . ')'
		       . '|(\$\(srcdir\)/' . $PATH_PATTERN . ')'
		       . '|([^/\$]' . $PATH_PATTERN . '))\s*(#.*)?' . "\$");

# Directories installed during 'install-exec' phase.
our $EXEC_DIR_PATTERN =
  '^(?:bin|sbin|libexec|sysconf|localstate|lib|pkglib|.*exec.*)' . "\$";

# Values for AC_CANONICAL_*
use constant AC_CANONICAL_BUILD  => 1;
use constant AC_CANONICAL_HOST   => 2;
use constant AC_CANONICAL_TARGET => 3;

# Values indicating when something should be cleaned.
use constant MOSTLY_CLEAN     => 0;
use constant CLEAN            => 1;
use constant DIST_CLEAN       => 2;
use constant MAINTAINER_CLEAN => 3;

# Libtool files.
our @libtool_files = qw(ltmain.sh config.guess config.sub);
# ltconfig appears here for compatibility with old versions of libtool.
our @libtool_sometimes = qw(ltconfig ltcf-c.sh ltcf-cxx.sh ltcf-gcj.sh);

# Commonly found files we look for and automatically include in
# DISTFILES.
our @common_files =
    (qw(ABOUT-GNU ABOUT-NLS AUTHORS BACKLOG COPYING COPYING.DOC COPYING.LIB
	COPYING.LESSER ChangeLog INSTALL NEWS README THANKS TODO
	ar-lib compile config.guess config.rpath
	config.sub depcomp install-sh libversion.in mdate-sh
	missing mkinstalldirs py-compile texinfo.tex ylwrap),
     @libtool_files, @libtool_sometimes);

# Commonly used files we auto-include, but only sometimes.  This list
# is used for the --help output only.
our @common_sometimes =
  qw(aclocal.m4 acconfig.h config.h.top config.h.bot configure
     configure.ac configure.in stamp-vti);

# Standard directories from the GNU Coding Standards, and additional
# pkg* directories from Automake.  Stored in a hash for fast member check.
our %standard_prefix =
    map { $_ => 1 } (qw(bin data dataroot doc dvi exec html include info
			lib libexec lisp locale localstate man man1 man2
			man3 man4 man5 man6 man7 man8 man9 oldinclude pdf
			pkgdata pkginclude pkglib pkglibexec ps sbin
			sharedstate sysconf));

# These constants are returned by the lang_*_rewrite functions.
# LANG_SUBDIR means that the resulting object file should be in a
# subdir if the source file is.  In this case the file name cannot
# have '..' components.
use constant LANG_IGNORE  => 0;
use constant LANG_PROCESS => 1;
use constant LANG_SUBDIR  => 2;

# These are used when keeping track of whether an object can be built
# by two different paths.
use constant COMPILE_LIBTOOL  => 1;
use constant COMPILE_ORDINARY => 2;

# Serialization keys for message queues.
use constant QUEUE_MESSAGE   => "msg";
use constant QUEUE_CONF_FILE => "conf file";
use constant QUEUE_LOCATION  => "location";
use constant QUEUE_STRING    => "string";

## ---------------------------------- ##
## Variables related to the options.  ##
## ---------------------------------- ##

# TRUE if we should always generate Makefile.in.
our $force_generation = 1;

# From the Perl manual.
our $symlink_exists = (eval 'symlink ("", "");', $@ eq '');

# TRUE if missing standard files should be installed.
our $add_missing = 0;

# TRUE if we should copy missing files; otherwise symlink if possible.
our $copy_missing = 0;

# TRUE if we should always update files that we know about.
our $force_missing = 0;


## ---------------------------------------- ##
## Variables filled during files scanning.  ##
## ---------------------------------------- ##

# Name of the configure.ac file.
our $configure_ac;

# Files found by scanning configure.ac for LIBOBJS.
our %libsources = ();

# Names used in AC_CONFIG_HEADERS call.
our @config_headers = ();

# Names used in AC_CONFIG_LINKS call.
our @config_links = ();

# List of Makefile.am's to process, and their corresponding outputs.
our @input_files = ();
our %output_files = ();

# Complete list of Makefile.am's that exist.
our @configure_input_files = ();

# List of files in AC_CONFIG_FILES/AC_OUTPUT without Makefile.am's,
# and their outputs.
our @other_input_files = ();
# Where each AC_CONFIG_FILES/AC_OUTPUT/AC_CONFIG_LINK/AC_CONFIG_HEADERS
# appears.  The keys are the files created by these macros.
our %ac_config_files_location = ();
# The condition under which AC_CONFIG_FOOS appears.
our %ac_config_files_condition = ();

# Directory to search for AC_LIBSOURCE files, as set by AC_CONFIG_LIBOBJ_DIR
# in configure.ac.
our $config_libobj_dir = '';

# Whether AM_GNU_GETTEXT has been seen in configure.ac.
our $seen_gettext = 0;
# Whether AM_GNU_GETTEXT([external]) is used.
our $seen_gettext_external = 0;
# Where AM_GNU_GETTEXT appears.
our $ac_gettext_location;
# Whether AM_GNU_GETTEXT_INTL_SUBDIR has been seen.
our $seen_gettext_intl = 0;

# The arguments of the AM_EXTRA_RECURSIVE_TARGETS call (if any).
our @extra_recursive_targets = ();

# Lists of tags supported by Libtool.
our %libtool_tags = ();
# 1 if Libtool uses LT_SUPPORTED_TAG.  If it does, then it also
# uses AC_REQUIRE_AUX_FILE.
our $libtool_new_api = 0;

# Actual version we've seen.
our $package_version = '';

# Where version is defined.
our $package_version_location;

# TRUE if we've seen AM_PROG_AR
our $seen_ar = 0;

# Location of AC_REQUIRE_AUX_FILE calls, indexed by their argument.
our %required_aux_file = ();

# Where AM_INIT_AUTOMAKE is called.
our $seen_init_automake = 0;

# TRUE if we've seen AM_AUTOMAKE_VERSION.
our $seen_automake_version = 0;

# Hash table of AM_CONDITIONAL variables seen in configure.
our %configure_cond = ();

# This maps extensions onto language names.
our %extension_map = ();

# List of the DIST_COMMON files we discovered while reading
# configure.ac.
our @configure_dist_common = ();

# This maps languages names onto objects.
our %languages = ();
# Maps each linker variable onto a language object.
our %link_languages = ();

# maps extensions to needed source flags.
our %sourceflags = ();

# List of targets we must always output.
# FIXME: Complete, and remove falsely required targets.
our %required_targets =
  (
   'all'          => 1,
   'dvi'	  => 1,
   'pdf'	  => 1,
   'ps'		  => 1,
   'info'	  => 1,
   'install-info' => 1,
   'install'      => 1,
   'install-data' => 1,
   'install-exec' => 1,
   'uninstall'    => 1,

   # FIXME: Not required, temporary hacks.
   # Well, actually they are sort of required: the -recursive
   # targets will run them anyway...
   'html-am'         => 1,
   'dvi-am'          => 1,
   'pdf-am'          => 1,
   'ps-am'           => 1,
   'info-am'         => 1,
   'install-data-am' => 1,
   'install-exec-am' => 1,
   'install-html-am' => 1,
   'install-dvi-am'  => 1,
   'install-pdf-am'  => 1,
   'install-ps-am'   => 1,
   'install-info-am' => 1,
   'installcheck-am' => 1,
   'uninstall-am'    => 1,
   'tags-am'         => 1,
   'ctags-am'        => 1,
   'cscopelist-am'   => 1,
   'install-man'     => 1,
  );

# Queue to push require_conf_file requirements to.
our $required_conf_file_queue;

# The name of the Makefile currently being processed.
our $am_file = 'BUG';

################################################################

## ------------------------------------------ ##
## Variables reset by &initialize_per_input.  ##
## ------------------------------------------ ##

# Greatest timestamp of the output's dependencies (excluding
# configure's dependencies).
our $output_deps_greatest_timestamp;

# These variables are used when generating each Makefile.in.
# They hold the Makefile.in until it is ready to be printed.
our $output_all;
our $output_header;
our $output_rules;
our $output_trailer;

# This holds the set of included files.
our @include_stack;

# List of dependencies for the obvious targets.
our @all;
our @check;
our @check_tests;

# Keys in this hash table are files to delete.  The associated
# value tells when this should happen (MOSTLY_CLEAN, DIST_CLEAN, etc.)
our %clean_files;

# Keys in this hash table are object files or other files in
# subdirectories which need to be removed.  This only holds files
# which are created by compilations.  The value in the hash indicates
# when the file should be removed.
our %compile_clean_files;

# Keys in this hash table are directories where we expect to build a
# libtool object.  We use this information to decide what directories
# to delete.
our %libtool_clean_directories;

# Value of $(SOURCES), used by tags.am.
our @sources;
# Sources which go in the distribution.
our @dist_sources;

# This hash maps object file names onto their corresponding source
# file names.  This is used to ensure that each object is created
# by a single source file.
our %object_map;

# This hash maps object file names onto an integer value representing
# whether this object has been built via ordinary compilation or
# libtool compilation (the COMPILE_* constants).
our %object_compilation_map;


# This keeps track of the directories for which we've already
# created dirstamp code.  Keys are directories, values are stamp files.
# Several keys can share the same stamp files if they are equivalent
# (as are './/foo' and 'foo').
our %directory_map;

# All .P files.
our %dep_files;

# This is a list of all targets to run during "make dist".
our @dist_targets;

# List of all programs, libraries and ltlibraries as returned
# by am_install_var
our @proglist;
our @liblist;
our @ltliblist;
# Blacklist of targets (as canonical base name) for which object file names
# may not be automatically shortened
our @dup_shortnames;

# Keep track of all programs declared in this Makefile, without
# $(EXEEXT).  @substitutions@ are not listed.
our %known_programs;
our %known_libraries;

# This keeps track of which extensions we've seen (that we care
# about).
our %extension_seen;

# This is random scratch space for the language finish functions.
# Don't randomly overwrite it; examine other uses of keys first.
our %language_scratch;

# We keep track of which objects need special (per-executable)
# handling on a per-language basis.
our %lang_specific_files;

# List of distributed files to be put in DIST_COMMON.
our @dist_common;

# This is set when 'handle_dist' has finished.  Once this happens,
# we should no longer push on dist_common.
our $handle_dist_run;

# Used to store a set of linkers needed to generate the sources currently
# under consideration.
our %linkers_used;

# True if we need 'LINK' defined.  This is a hack.
our $need_link;

# Does the generated Makefile have to build some compiled object
# (for binary programs, or plain or libtool libraries)?
our $must_handle_compiled_objects;


1;
