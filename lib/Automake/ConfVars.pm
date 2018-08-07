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

package Automake::ConfVars;

use 5.006;
use strict;

use Automake::ChannelDefs;
use Automake::Channels;
use Automake::Condition qw (TRUE FALSE);
use Automake::Config;
use Automake::File;
use Automake::Global;
use Automake::Location;
use Automake::Utils;
use Automake::Options;
use Automake::VarDef;
use Automake::Variable;
use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw (%configure_vars %ignored_configure_vars $output_vars
    &define_standard_variables &am_install_var);

# Hash table of discovered configure substitutions.  Keys are names,
# values are 'FILE:LINE' strings which are used by error message
# generation.
our %configure_vars = ();

# Ignored configure substitutions (i.e., variables not to be output in
# Makefile.in)
our %ignored_configure_vars = ();

# This variable is used when generating each Makefile.in. It holds the
# Makefile.in vars until the file is ready to be printed
our $output_vars;

sub _define_configure_variable ($)
{
  my ($var) = @_;
  # Some variables we do not want to output.  For instance it
  # would be a bad idea to output `U = @U@` when `@U@` can be
  # substituted as `\`.
  my $pretty = exists $ignored_configure_vars{$var} ? VAR_SILENT : VAR_ASIS;
  Automake::Variable::define ($var, VAR_CONFIGURE, '', TRUE, subst ($var),
	  '', $configure_vars{$var}, $pretty);
}


# A helper for read_main_am_file which initializes configure variables
# and variables from header-vars.am.
sub define_standard_variables ()
{
  my $saved_output_vars = $output_vars;
  my $filename = "$libdir/am/header-vars.am";

  my $preprocessed_file = preprocess_file ($filename);
  my @paragraphs = make_paragraphs ($preprocessed_file);

  my ($comments, undef, $rules) =
      file_contents_internal (1, $filename, new Automake::Location,
                              \@paragraphs);
  foreach my $var (sort keys %configure_vars)
    {
      _define_configure_variable ($var);
    }

  $output_vars .= $comments . $rules;
}


# am_install_var (-OPTION..., file, HOW, where...)>
# --------------------------------------------------
# Handle 'where_HOW' variable magic.  Does all lookups, generates
# install code, and possibly generates code to define the primary
# variable.  The first argument is the name of the .am file to munge,
# the second argument is the primary variable (e.g. HEADERS), and all
# subsequent arguments are possible installation locations.
#
# Returns list of [$location, $value] pairs, where
# $value's are the values in all where_HOW variable, and $location
# there associated location (the place here their parent variables were
# defined).
sub am_install_var
{
  my (@args) = @_;

  my $do_require = 1;
  my $can_dist = 0;
  my $default_dist = 0;
  while (@args)
    {
      if ($args[0] eq '-noextra')
	{
	  $do_require = 0;
	}
      elsif ($args[0] eq '-candist')
	{
	  $can_dist = 1;
	}
      elsif ($args[0] eq '-defaultdist')
	{
	  $default_dist = 1;
	  $can_dist = 1;
	}
      elsif ($args[0] !~ /^-/)
	{
	  last;
	}
      shift (@args);
    }

  my ($file, $primary, @prefix) = @args;

  # Now that configure substitutions are allowed in where_HOW
  # variables, it is an error to actually define the primary.  We
  # allow 'JAVA', as it is customarily used to mean the Java
  # interpreter.  This is but one of several Java hacks.  Similarly,
  # 'PYTHON' is customarily used to mean the Python interpreter.
  reject_var $primary, "'$primary' is an anachronism"
    unless $primary eq 'JAVA' || $primary eq 'PYTHON';

  # Get the prefixes which are valid and actually used.
  @prefix = am_primary_prefixes ($primary, $can_dist, @prefix);

  # If a primary includes a configure substitution, then the EXTRA_
  # form is required.  Otherwise we can't properly do our job.
  my $require_extra;

  my @used = ();
  my @result = ();

  foreach my $X (@prefix)
    {
      my $nodir_name = $X;
      my $one_name = $X . '_' . $primary;
      my $one_var = var $one_name;

      my $strip_subdir = 1;
      # If subdir prefix should be preserved, do so.
      if ($nodir_name =~ /^nobase_/)
	{
	  $strip_subdir = 0;
	  $nodir_name =~ s/^nobase_//;
	}

      # If files should be distributed, do so.
      my $dist_p = 0;
      if ($can_dist)
	{
	  $dist_p = (($default_dist && $nodir_name !~ /^nodist_/)
		     || (! $default_dist && $nodir_name =~ /^dist_/));
	  $nodir_name =~ s/^(dist|nodist)_//;
	}


      # Use the location of the currently processed variable.
      # We are not processing a particular condition, so pick the first
      # available.
      my $tmpcond = $one_var->conditions->one_cond;
      my $where = $one_var->rdef ($tmpcond)->location->clone;

      # Append actual contents of where_PRIMARY variable to
      # @result, skipping @substitutions@.
      foreach my $locvals ($one_var->value_as_list_recursive (location => 1))
	{
	  my ($loc, $value) = @$locvals;
	  # Skip configure substitutions.
	  if ($value =~ /^\@.*\@$/)
	    {
	      if ($nodir_name eq 'EXTRA')
		{
		  error ($where,
			 "'$one_name' contains configure substitution, "
			 . "but shouldn't");
		}
	      # Check here to make sure variables defined in
	      # configure.ac do not imply that EXTRA_PRIMARY
	      # must be defined.
	      elsif (! defined $configure_vars{$one_name})
		{
		  $require_extra = $one_name
		    if $do_require;
		}
	    }
	  else
	    {
	      # Strip any $(EXEEXT) suffix the user might have added,
              # or this will confuse handle_source_transform() and
              # check_canonical_spelling().
	      # We'll add $(EXEEXT) back later anyway.
	      # Do it here rather than in handle_programs so the
              # uniquifying at the end of this function works.
	      ${$locvals}[1] =~ s/\$\(EXEEXT\)$//
	        if $primary eq 'PROGRAMS';

	      push (@result, $locvals);
	    }
	}
      # A blatant hack: we rewrite each _PROGRAMS primary to include
      # EXEEXT.
      append_exeext { 1 } $one_name
	if $primary eq 'PROGRAMS';
      # "EXTRA" shouldn't be used when generating clean targets,
      # all, or install targets.  We used to warn if EXTRA_FOO was
      # defined uselessly, but this was annoying.
      next
	if $nodir_name eq 'EXTRA';

      if ($nodir_name eq 'check')
	{
	  push (@check, '$(' . $one_name . ')');
	}
      else
	{
	  push (@used, '$(' . $one_name . ')');
	}

      # Is this to be installed?
      my $install_p = $nodir_name ne 'noinst' && $nodir_name ne 'check';

      # If so, with install-exec? (or install-data?).
      my $exec_p = ($nodir_name =~ /$EXEC_DIR_PATTERN/o);

      my $check_options_p = $install_p && !! option 'std-options';

      # Use the location of the currently processed variable as context.
      $where->push_context ("while processing '$one_name'");

      # The variable containing all files to distribute.
      my $distvar = "\$($one_name)";
      $distvar = shadow_unconditionally ($one_name, $where)
	if ($dist_p && $one_var->has_conditional_contents);

      # Singular form of $PRIMARY.
      (my $one_primary = $primary) =~ s/S$//;
      $output_rules .= file_contents ($file, $where,
                                      PRIMARY     => $primary,
                                      ONE_PRIMARY => $one_primary,
                                      DIR         => $X,
                                      NDIR        => $nodir_name,
                                      BASE        => $strip_subdir,
                                      EXEC        => $exec_p,
                                      INSTALL     => $install_p,
                                      DIST        => $dist_p,
                                      DISTVAR     => $distvar,
                                      'CK-OPTS'   => $check_options_p);
    }

  # The JAVA variable is used as the name of the Java interpreter.
  # The PYTHON variable is used as the name of the Python interpreter.
  if (@used && $primary ne 'JAVA' && $primary ne 'PYTHON')
    {
      # Define it.
      define_pretty_variable ($primary, TRUE, INTERNAL, @used);
      $output_vars .= "\n";
    }

  err_var ($require_extra,
	   "'$require_extra' contains configure substitution,\n"
	   . "but 'EXTRA_$primary' not defined")
    if ($require_extra && ! var ('EXTRA_' . $primary));

  # Push here because PRIMARY might be configure time determined.
  push (@all, '$(' . $primary . ')')
    if @used && $primary ne 'JAVA' && $primary ne 'PYTHON';

  # Make the result unique.  This lets the user use conditionals in
  # a natural way, but still lets us program lazily -- we don't have
  # to worry about handling a particular object more than once.
  # We will keep only one location per object.
  my %result = ();
  for my $pair (@result)
    {
      my ($loc, $val) = @$pair;
      $result{$val} = $loc;
    }
  my @l = sort keys %result;
  return map { [$result{$_}->clone, $_] } @l;
}

1;
