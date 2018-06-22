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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Automake::LangHandling;

use Automake::Condition qw (TRUE FALSE);
use Automake::ChannelDefs;
use Automake::Global;
use Automake::Language;
use Automake::Location;
use Automake::Options;
use Automake::Requires;
use Automake::Rule;
use Automake::SilentRules;
use Automake::Utils;
use Automake::Variable;
use Automake::VarDef;
use Automake::Wrap qw (makefile_wrap);
use Exporter 'import';
use File::Basename;

use vars qw (@EXPORT);

@EXPORT = qw (check_user_variables lang_sub_obj lang_header_rewrite
	      lang_vala_rewrite lang_yacc_rewrite lang_yaccxx_rewrite
	      lang_lex_rewrite lang_lexxx_rewrite lang_java_rewrite
	      lang_vala_finish_target lang_vala_finish
	      lang_vala_target_hook lang_yacc_target_hook
	      lang_lex_target_hook yacc_lex_finish_helper
	      lang_yacc_finish lang_lex_finish resolve_linker
	      saw_extension register_language derive_suffix
	      pretty_print_rule);

# check_user_variables (@LIST)
# ----------------------------
# Make sure each variable VAR in @LIST does not exist, suggest using AM_VAR
# otherwise.
sub check_user_variables
{
  my @dont_override = @_;
  foreach my $flag (@dont_override)
    {
      my $var = var $flag;
      if ($var)
	{
	  for my $cond ($var->conditions->conds)
	    {
	      if ($var->rdef ($cond)->owner == VAR_MAKEFILE)
		{
		  msg_cond_var ('gnu', $cond, $flag,
				"'$flag' is a user variable, "
				. "you should not override it;\n"
				. "use 'AM_$flag' instead");
		}
	    }
	}
    }
}

################################################################
#
# Functions to handle files of each language.

# Each 'lang_X_rewrite($DIRECTORY, $BASE, $EXT)' function follows a
# simple formula: Return value is LANG_SUBDIR if the resulting object
# file should be in a subdir if the source file is, LANG_PROCESS if
# file is to be dealt with, LANG_IGNORE otherwise.

# Much of the actual processing is handled in
# handle_single_transform.  These functions exist so that
# auxiliary information can be recorded for a later cleanup pass.
# Note that the calls to these functions are computed, so don't bother
# searching for their precise names in the source.

# This is just a convenience function that can be used to determine
# when a subdir object should be used.
sub lang_sub_obj ()
{
    return option 'subdir-objects' ? LANG_SUBDIR : LANG_PROCESS;
}

# Rewrite a single header file.
sub lang_header_rewrite
{
    # Header files are simply ignored.
    return LANG_IGNORE;
}

# Rewrite a single Vala source file.
sub lang_vala_rewrite
{
    my ($directory, $base, $ext) = @_;

    (my $newext = $ext) =~ s/vala$/c/;
    return (LANG_SUBDIR, $newext);
}

# Rewrite a single yacc/yacc++ file.
sub lang_yacc_rewrite
{
    my ($directory, $base, $ext) = @_;

    my $r = lang_sub_obj;
    (my $newext = $ext) =~ tr/y/c/;
    return ($r, $newext);
}
sub lang_yaccxx_rewrite { lang_yacc_rewrite (@_); };

# Rewrite a single lex/lex++ file.
sub lang_lex_rewrite
{
    my ($directory, $base, $ext) = @_;

    my $r = lang_sub_obj;
    (my $newext = $ext) =~ tr/l/c/;
    return ($r, $newext);
}
sub lang_lexxx_rewrite { lang_lex_rewrite (@_); };

# Rewrite a single Java file.
sub lang_java_rewrite
{
    return LANG_SUBDIR;
}

# The lang_X_finish functions are called after all source file
# processing is done.  Each should handle defining rules for the
# language, etc.  A finish function is only called if a source file of
# the appropriate type has been seen.

sub lang_vala_finish_target
{
  my ($self, $name) = @_;

  my $derived = canonicalize ($name);
  my $var = var "${derived}_SOURCES";
  return unless $var;

  my @vala_sources = grep { /\.(vala|vapi)$/ } ($var->value_as_list_recursive);

  # For automake bug#11229.
  return unless @vala_sources;

  foreach my $vala_file (@vala_sources)
    {
      my $c_file = $vala_file;
      if ($c_file =~ s/(.*)\.vala$/$1.c/)
        {
          $c_file = "\$(srcdir)/$c_file";
          $output_rules .= "$c_file: \$(srcdir)/${derived}_vala.stamp\n"
            . "\t\@if test -f \$@; then :; else rm -f \$(srcdir)/${derived}_vala.stamp; fi\n"
            . "\t\@if test -f \$@; then :; else \\\n"
            . "\t  \$(MAKE) \$(AM_MAKEFLAGS) \$(srcdir)/${derived}_vala.stamp; \\\n"
            . "\tfi\n";
	  $clean_files{$c_file} = MAINTAINER_CLEAN;
        }
    }

  # Add rebuild rules for generated header and vapi files
  my $flags = var ($derived . '_VALAFLAGS');
  if ($flags)
    {
      my $lastflag = '';
      foreach my $flag ($flags->value_as_list_recursive)
	{
	  if (grep (/$lastflag/, ('-H', '-h', '--header', '--internal-header',
	                          '--vapi', '--internal-vapi', '--gir')))
	    {
	      my $headerfile = "\$(srcdir)/$flag";
	      $output_rules .= "$headerfile: \$(srcdir)/${derived}_vala.stamp\n"
		. "\t\@if test -f \$@; then :; else rm -f \$(srcdir)/${derived}_vala.stamp; fi\n"
		. "\t\@if test -f \$@; then :; else \\\n"
		. "\t  \$(MAKE) \$(AM_MAKEFLAGS) \$(srcdir)/${derived}_vala.stamp; \\\n"
		. "\tfi\n";

	      # valac is not used when building from dist tarballs
	      # distribute the generated files
	      push_dist_common ($headerfile);
	      $clean_files{$headerfile} = MAINTAINER_CLEAN;
	    }
	  $lastflag = $flag;
	}
    }

  my $compile = $self->compile;

  # Rewrite each occurrence of 'AM_VALAFLAGS' in the compile
  # rule into '${derived}_VALAFLAGS' if it exists.
  my $val = "${derived}_VALAFLAGS";
  $compile =~ s/\(AM_VALAFLAGS\)/\($val\)/
    if set_seen ($val);

  # VALAFLAGS is a user variable (per GNU Standards),
  # it should not be overridden in the Makefile...
  check_user_variables 'VALAFLAGS';

  my $dirname = dirname ($name);

  # Only generate C code, do not run C compiler
  $compile .= " -C";

  my $verbose = verbose_flag ('VALAC');
  my $silent = silent_flag ();
  my $stampfile = "\$(srcdir)/${derived}_vala.stamp";

  $output_rules .=
    "\$(srcdir)/${derived}_vala.stamp: @vala_sources\n".
# Since the C files generated from the vala sources depend on the
# ${derived}_vala.stamp file, we must ensure its timestamp is older than
# those of the C files generated by the valac invocation below (this is
# especially important on systems with sub-second timestamp resolution).
# Thus we need to create the stamp file *before* invoking valac, and to
# move it to its final location only after valac has been invoked.
    "\t${silent}rm -f \$\@ && echo stamp > \$\@-t\n".
    "\t${verbose}\$(am__cd) \$(srcdir) && $compile @vala_sources\n".
    "\t${silent}mv -f \$\@-t \$\@\n";

  push_dist_common ($stampfile);

  $clean_files{$stampfile} = MAINTAINER_CLEAN;
}

# Add output rules to invoke valac and create stamp file as a witness
# to handle multiple outputs. This function is called after all source
# file processing is done.
sub lang_vala_finish ()
{
  my ($self) = @_;

  foreach my $prog (keys %known_programs)
    {
      lang_vala_finish_target ($self, $prog);
    }

  while (my ($name) = each %known_libraries)
    {
      lang_vala_finish_target ($self, $name);
    }
}

# The built .c files should be cleaned only on maintainer-clean
# as the .c files are distributed. This function is called for each
# .vala source file.
sub lang_vala_target_hook
{
  my ($self, $aggregate, $output, $input, %transform) = @_;

  $clean_files{$output} = MAINTAINER_CLEAN;
}

# This is a yacc helper which is called whenever we have decided to
# compile a yacc file.
sub lang_yacc_target_hook
{
    my ($self, $aggregate, $output, $input, %transform) = @_;

    # If some relevant *YFLAGS variable contains the '-d' flag, we'll
    # have to to generate special code.
    my $yflags_contains_minus_d = 0;

    foreach my $pfx ("", "${aggregate}_")
      {
	my $yflagsvar = var ("${pfx}YFLAGS");
	next unless $yflagsvar;
	# We cannot work reliably with conditionally-defined YFLAGS.
	if ($yflagsvar->has_conditional_contents)
	  {
	    msg_var ('unsupported', $yflagsvar,
	             "'${pfx}YFLAGS' cannot have conditional contents");
	  }
	else
	  {
	    $yflags_contains_minus_d = 1
	      if grep (/^-d$/, $yflagsvar->value_as_list_recursive);
	  }
      }

    if ($yflags_contains_minus_d)
      {
	# Found a '-d' that applies to the compilation of this file.
	# Add a dependency for the generated header file, and arrange
	# for that file to be included in the distribution.

	# The extension of the output file (e.g., '.c' or '.cxx').
	# We'll need it to compute the name of the generated header file.
	(my $output_ext = basename ($output)) =~ s/.*(\.[^.]+)$/$1/;

	# We know that a yacc input should be turned into either a C or
	# C++ output file.  We depend on this fact (here and in yacc.am),
	# so check that it really holds.
	my $lang = $languages{$extension_map{$output_ext}};
	prog_error "invalid output name '$output' for yacc file '$input'"
	  if (!$lang || ($lang->name ne 'c' && $lang->name ne 'cxx'));

	(my $header_ext = $output_ext) =~ s/c/h/g;
        # Quote $output_ext in the regexp, so that dots in it are taken
        # as literal dots, not as metacharacters.
	(my $header = $output) =~ s/\Q$output_ext\E$/$header_ext/;

	foreach my $cond (Automake::Rule::define (${header}, 'internal',
						  RULE_AUTOMAKE, TRUE,
						  INTERNAL))
	  {
	    my $condstr = $cond->subst_string;
	    $output_rules .=
	      "$condstr${header}: $output\n"
	      # Recover from removal of $header
	      . "$condstr\t\@if test ! -f \$@; then rm -f $output; else :; fi\n"
	      . "$condstr\t\@if test ! -f \$@; then \$(MAKE) \$(AM_MAKEFLAGS) $output; else :; fi\n";
	  }
	# Distribute the generated file, unless its .y source was
	# listed in a nodist_ variable.  (handle_source_transform()
	# will set DIST_SOURCE.)
	push_dist_common ($header)
	  if $transform{'DIST_SOURCE'};

	# The GNU rules say that yacc/lex output files should be removed
	# by maintainer-clean.  However, if the files are not distributed,
	# then we want to remove them with "make clean"; otherwise,
	# "make distcheck" will fail.
	$clean_files{$header} = $transform{'DIST_SOURCE'} ? MAINTAINER_CLEAN : CLEAN;
      }
    # See the comment above for $HEADER.
    $clean_files{$output} = $transform{'DIST_SOURCE'} ? MAINTAINER_CLEAN : CLEAN;
}

# This is a lex helper which is called whenever we have decided to
# compile a lex file.
sub lang_lex_target_hook
{
    my ($self, $aggregate, $output, $input, %transform) = @_;
    # The GNU rules say that yacc/lex output files should be removed
    # by maintainer-clean.  However, if the files are not distributed,
    # then we want to remove them with "make clean"; otherwise,
    # "make distcheck" will fail.
    $clean_files{$output} = $transform{'DIST_SOURCE'} ? MAINTAINER_CLEAN : CLEAN;
}

# This is a helper for both lex and yacc.
sub yacc_lex_finish_helper ()
{
  return if defined $language_scratch{'lex-yacc-done'};
  $language_scratch{'lex-yacc-done'} = 1;

  # FIXME: for now, no line number.
  require_conf_file ($configure_ac, FOREIGN, 'ylwrap');
  define_variable ('YLWRAP', "$am_config_aux_dir/ylwrap", INTERNAL);
}

sub lang_yacc_finish ()
{
  return if defined $language_scratch{'yacc-done'};
  $language_scratch{'yacc-done'} = 1;

  reject_var 'YACCFLAGS', "'YACCFLAGS' obsolete; use 'YFLAGS' instead";

  yacc_lex_finish_helper;
}


sub lang_lex_finish ()
{
  return if defined $language_scratch{'lex-done'};
  $language_scratch{'lex-done'} = 1;

  yacc_lex_finish_helper;
}


# Given a hash table of linker names, pick the name that has the most
# precedence.  This is lame, but something has to have global
# knowledge in order to eliminate the conflict.  Add more linkers as
# required.
sub resolve_linker
{
    my (%linkers) = @_;

    foreach my $l (qw(GCJLINK OBJCXXLINK CXXLINK F77LINK FCLINK OBJCLINK UPCLINK))
    {
	return $l if defined $linkers{$l};
    }
    return 'LINK';
}

# Called to indicate that an extension was used.
sub saw_extension
{
    my ($ext) = @_;
    $extension_seen{$ext} = 1;
}

# register_language (%ATTRIBUTE)
# ------------------------------
# Register a single language.
# Each %ATTRIBUTE is of the form ATTRIBUTE => VALUE.
sub register_language
{
  my (%option) = @_;

  # Set the defaults.
  $option{'autodep'} = 'no'
    unless defined $option{'autodep'};
  $option{'linker'} = ''
    unless defined $option{'linker'};
  $option{'flags'} = []
    unless defined $option{'flags'};
  $option{'output_extensions'} = sub { return ( '.$(OBJEXT)', '.lo' ) }
    unless defined $option{'output_extensions'};
  $option{'nodist_specific'} = 0
    unless defined $option{'nodist_specific'};

  my $lang = new Automake::Language (%option);

  # Fill indexes.
  $extension_map{$_} = $lang->name foreach @{$lang->extensions};
  $languages{$lang->name} = $lang;
  my $link = $lang->linker;
  if ($link)
    {
      if (exists $link_languages{$link})
	{
	  prog_error ("'$link' has different definitions in "
		      . $lang->name . " and " . $link_languages{$link}->name)
	    if $lang->link ne $link_languages{$link}->link;
	}
      else
	{
	  $link_languages{$link} = $lang;
	}
    }

  # Update the pattern of known extensions.
  accept_extensions (@{$lang->extensions});

  # Update the suffix rules map.
  foreach my $suffix (@{$lang->extensions})
    {
      foreach my $dest ($lang->output_extensions->($suffix))
	{
	  register_suffix_rule (INTERNAL, $suffix, $dest);
	}
    }
}

# derive_suffix ($EXT, $OBJ)
# --------------------------
# This function is used to find a path from a user-specified suffix $EXT
# to $OBJ or to some other suffix we recognize internally, e.g. 'cc'.
sub derive_suffix
{
  my ($source_ext, $obj) = @_;

  while (!$extension_map{$source_ext} && $source_ext ne $obj)
    {
      my $new_source_ext = next_in_suffix_chain ($source_ext, $obj);
      last if not defined $new_source_ext;
      $source_ext = $new_source_ext;
    }

  return $source_ext;
}


# Pretty-print something and append to '$output_rules'.
sub pretty_print_rule
{
    $output_rules .= makefile_wrap (shift, shift, @_);
}

1;
