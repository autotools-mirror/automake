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

# FIXME: This is a temporary package.  The functions it holds should be moved
# elsewhere
package Automake::TmpModule;

use 5.006;
use strict;

use Automake::ChannelDefs;
use Automake::Condition qw /TRUE FALSE/;
use Automake::ConfVars;
use Automake::File;
use Automake::General;
use Automake::Global;
use Automake::Location;
use Automake::Options;
use Automake::Utils;
use Automake::VarDef;
use Automake::Variable;
use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw (append_exeext am_install_var am_primary_prefixes
    shadow_unconditionally);


# append_exeext { PREDICATE } $MACRO
# ----------------------------------
# Append $(EXEEXT) to each filename in $F appearing in the Makefile
# variable $MACRO if &PREDICATE($F) is true.  @substitutions@ are
# ignored.
#
# This is typically used on all filenames of *_PROGRAMS, and filenames
# of TESTS that are programs.
sub append_exeext (&$)
{
  my ($pred, $macro) = @_;

  transform_variable_recursively
    ($macro, $macro, 'am__EXEEXT', 0, INTERNAL,
     sub {
       my ($subvar, $val, $cond, $full_cond) = @_;
       # Append $(EXEEXT) unless the user did it already, or it's a
       # @substitution@.
       $val .= '$(EXEEXT)'
	 if $val !~ /(?:\$\(EXEEXT\)$|^[@]\w+[@]$)/ && &$pred ($val);
       return $val;
     });
}


# shadow_unconditionally ($varname, $where)
# -----------------------------------------
# Return a $(variable) that contains all possible values
# $varname can take.
# If the VAR wasn't defined conditionally, return $(VAR).
# Otherwise we create an am__VAR_DIST variable which contains
# all possible values, and return $(am__VAR_DIST).
sub shadow_unconditionally
{
  my ($varname, $where) = @_;
  my $var = var $varname;
  if ($var->has_conditional_contents)
    {
      $varname = "am__${varname}_DIST";
      my @files = uniq ($var->value_as_list_recursive);
      define_pretty_variable ($varname, TRUE, $where, @files);
    }
  return "\$($varname)"
}


# am_install_var (-OPTION..., file, HOW, where...)
# ------------------------------------------------
#
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
#
# FIXME: this should be rewritten to be cleaner.  It should be broken
# up into multiple functions.
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


# @PREFIX
# am_primary_prefixes ($PRIMARY, $CAN_DIST, @PREFIXES)
# ----------------------------------------------------
# Find all variable prefixes that are used for install directories.  A
# prefix 'zar' qualifies iff:
#
# * 'zardir' is a variable.
# * 'zar_PRIMARY' is a variable.
#
# As a side effect, it looks for misspellings.  It is an error to have
# a variable ending in a "reserved" suffix whose prefix is unknown, e.g.
# "bni_PROGRAMS".  However, unusual prefixes are allowed if a variable
# of the same name (with "dir" appended) exists.  For instance, if the
# variable "zardir" is defined, then "zar_PROGRAMS" becomes valid.
# This is to provide a little extra flexibility in those cases which
# need it.
sub am_primary_prefixes
{
  my ($primary, $can_dist, @prefixes) = @_;

  local $_;
  my %valid = map { $_ => 0 } @prefixes;
  $valid{'EXTRA'} = 0;
  foreach my $var (variables $primary)
    {
      # Automake is allowed to define variables that look like primaries
      # but which aren't.  E.g. INSTALL_sh_DATA.
      # Autoconf can also define variables like INSTALL_DATA, so
      # ignore all configure variables (at least those which are not
      # redefined in Makefile.am).
      # FIXME: We should make sure that these variables are not
      # conditionally defined (or else adjust the condition below).
      my $def = $var->def (TRUE);
      next if $def && $def->owner != VAR_MAKEFILE;

      my $varname = $var->name;

      if ($varname =~ /^(nobase_)?(dist_|nodist_)?(.*)_[[:alnum:]]+$/)
	{
	  my ($base, $dist, $X) = ($1 || '', $2 || '', $3 || '');
	  if ($dist ne '' && ! $can_dist)
	    {
	      err_var ($var,
		       "invalid variable '$varname': 'dist' is forbidden");
	    }
	  # Standard directories must be explicitly allowed.
	  elsif (! defined $valid{$X} && exists $standard_prefix{$X})
	    {
	      err_var ($var,
		       "'${X}dir' is not a legitimate directory " .
		       "for '$primary'");
	    }
	  # A not explicitly valid directory is allowed if Xdir is defined.
	  elsif (! defined $valid{$X} &&
		 $var->requires_variables ("'$varname' is used", "${X}dir"))
	    {
	      # Nothing to do.  Any error message has been output
	      # by $var->requires_variables.
	    }
	  else
	    {
	      # Ensure all extended prefixes are actually used.
 $valid{"$base$dist$X"} = 1;
	    }
	}
      else
	{
	  prog_error "unexpected variable name: $varname";
	}
    }

  # Return only those which are actually defined.
  return sort grep { var ($_ . '_' . $primary) } keys %valid;
}


1;
