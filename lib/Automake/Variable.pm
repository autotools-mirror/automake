# Copyright (C) 2003  Free Software Foundation, Inc.

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

package Automake::Variable;
use strict;
use Carp;
use Automake::Channels;
use Automake::ChannelDefs;
use Automake::Configure_ac;
use Automake::VarDef;
use Automake::Condition qw (TRUE FALSE);
use Automake::DisjConditions;
use Automake::General 'uniq';
use Automake::Wrap 'makefile_wrap';

require Exporter;
use vars '@ISA', '@EXPORT', '@EXPORT_OK';
@ISA = qw/Exporter/;
@EXPORT = qw (err_var msg_var msg_cond_var reject_var
	      var rvar vardef rvardef
	      variables
	      scan_variable_expansions check_variable_expansions
	      condition_ambiguous_p
	      variable_delete
	      variable_dump variables_dump
	      set_seen
	      require_variables require_variables_for_variable
	      variable_value
	      output_variables
	      traverse_variable_recursively
	      transform_variable_recursively);

=head1 NAME

Automake::Variable - support for variable definitions

=head1 SYNOPSIS

  use Automake::Variable;
  use Automake::VarDef;

  # Defining a variable.
  Automake::Variable::define($varname, $owner, $type,
                             $cond, $value, $comment,
                             $where, $pretty)

  # Looking up a variable.
  my $var = var $varname;
  if ($var)
    {
      ...
    }

  # Looking up a variable that is assumed to exist.
  my $var = rvar $varname;

  # The list of conditions where $var has been defined.
  # ($var->conditions is an Automake::DisjConditions,
  # $var->conditions->conds is a list of Automake::Condition.)
  my @conds = $var->conditions->conds

  # Accessing to the definition in Condition $cond.
  # $def is an Automake::VarDef.
  my $def = $var->def ($cond);
  if ($def)
    {
      ...
    }

  # When the conditional definition is assumed to exist, use
  my $def = $var->rdef ($cond);


=head1 DESCRIPTION

This package provides support for Makefile variable definitions.

An C<Automake::Variable> is a variable name associated to possibly
many conditional definitions.  These definitions are instances
of C<Automake::VarDef>.

Therefore obtaining the value of a variable under a given
condition involves two lookups.  One to look up the variable,
and one to look up the conditional definition:

  my $var = var $name;
  if ($var)
    {
      my $def = $var->def ($cond);
      if ($def)
        {
          return $def->value;
        }
      ...
    }
  ...

When it is known that the variable and the definition
being looked up exist, the above can be simplified to

  return var ($name)->def ($cond)->value; # Do not write this.

but is better written

  return rvar ($name)->rdef ($cond)->value;

or even

  return rvardef ($name, $cond)->value;

The I<r> variants of the C<var>, C<def>, and C<vardef> methods add an
extra test to ensure that the lookup succeeded, and will diagnose
failures as internal errors (which a message which is much more
informative than Perl's warning about calling a method on a
non-object).

=cut

my $_VARIABLE_PATTERN = '^[.A-Za-z0-9_@]+' . "\$";

# The order in which variables should be output.  (May contain
# duplicates -- only the first occurence matters.)
my @_var_order;

# This keeps track of all variables defined by &_gen_varname.
# $_gen_varname{$base} is a hash for all variable defined with
# prefix `$base'.  Values stored this this hash are the variable names.
# Keys have the form "(COND1)VAL1(COND2)VAL2..." where VAL1 and VAL2
# are the values of the variable for condition COND1 and COND2.
my %_gen_varname = ();

# Declare the macros that define known variables, so we can
# hint the user if she try to use one of these variables.

# Macros accessible via aclocal.
my %_am_macro_for_var =
  (
   ANSI2KNR => 'AM_C_PROTOTYPES',
   CCAS => 'AM_PROG_AS',
   CCASFLAGS => 'AM_PROG_AS',
   EMACS => 'AM_PATH_LISPDIR',
   GCJ => 'AM_PROG_GCJ',
   LEX => 'AM_PROG_LEX',
   LIBTOOL => 'AC_PROG_LIBTOOL',
   lispdir => 'AM_PATH_LISPDIR',
   pkgpyexecdir => 'AM_PATH_PYTHON',
   pkgpythondir => 'AM_PATH_PYTHON',
   pyexecdir => 'AM_PATH_PYTHON',
   PYTHON => 'AM_PATH_PYTHON',
   pythondir => 'AM_PATH_PYTHON',
   U => 'AM_C_PROTOTYPES',
   );

# Macros shipped with Autoconf.
my %_ac_macro_for_var =
  (
   ALLOCA => 'AC_FUNC_ALLOCA',
   CC => 'AC_PROG_CC',
   CFLAGS => 'AC_PROG_CC',
   CXX => 'AC_PROG_CXX',
   CXXFLAGS => 'AC_PROG_CXX',
   F77 => 'AC_PROG_F77',
   F77FLAGS => 'AC_PROG_F77',
   RANLIB => 'AC_PROG_RANLIB',
   YACC => 'AC_PROG_YACC',
   );

# Variables that can be overriden without complaint from -Woverride
my %_silent_variable_override =
  (AR => 1,
   ARFLAGS => 1,
   DEJATOOL => 1,
   JAVAC => 1);

# This hash records helper variables used to implement conditional '+='.
# Keys have the form "VAR:CONDITIONS".  The value associated to a key is
# the named of the helper variable used to append to VAR in CONDITIONS.
my %_appendvar = ();


=head2 Error reporting functions

In these functions, C<$var> can be either a variable name, or
an instance of C<Automake::Variable>.

=over 4

=item C<err_var ($var, $message, [%options])>

Uncategorized errors about variables.

=cut

sub err_var ($$;%)
{
  msg_var ('error', @_);
}

=item C<msg_cond_var ($channel, $cond, $var, $message, [%options])>

Messages about conditional variable.

=cut

sub msg_cond_var ($$$$;%)
{
  my ($channel, $cond, $var, $msg, %opts) = @_;
  my $v = ref ($var) ? $var : rvar ($var);
  msg $channel, $v->rdef ($cond)->location, $msg, %opts;
}

=item C<msg_var ($channel, $var, $message, [%options])>

messages about variables.

=cut

sub msg_var ($$$;%)
{
  my ($channel, $var, $msg, %opts) = @_;
  my $v = ref ($var) ? $var : rvar ($var);
  # Don't know which condition is concerned.  Pick any.
  my $cond = $v->conditions->one_cond;
  msg_cond_var $channel, $cond, $v, $msg, %opts;
}

=item C<reject_var ($varname, $error_msg)>

Bail out with C<$ERROR_MSG> if a variable with name C<$VARNAME> has
been defined.

=cut

# $BOOL
# reject_var ($VARNAME, $ERROR_MSG)
# -----------------------------
sub reject_var ($$)
{
  my ($var, $msg) = @_;
  my $v = var ($var);
  if ($v)
    {
      err_var $v, $msg;
      return 1;
    }
  return 0;
}

=back

=head2 Administrative functions

=over 4

=item C<Automake::Variable::hook ($varname, $fun)>

Declare a function to be called whenever a variable
named C<$varname> is defined or redefined.

C<$fun> should take two arguments: C<$type> and C<$value>.
When type is C<''> or <':'>, C<$value> is the value being
assigned to C<$varname>.  When C<$type> is C<'+'>, C<$value>
is the value being appended to  C<$varname>.

=cut

use vars '%_hooks';
sub hook ($\&)
{
  my ($var, $fun) = @_;
  $_hooks{$var} = $fun;
}

=item C<variables>

Returns the list of all L<Automake::Variable> instances.  (I.e., all
variables defined so far.)

=cut

use vars '%_variable_dict';
sub variables ()
{
  return keys %_variable_dict;
}

=item C<Automake::Variable::reset>

The I<forget all> function.  Clears all know variables and reset some
other internal data.

=cut

sub reset ()
{
  %_variable_dict = ();
  %_appendvar = ();
  @_var_order = ();
  %_gen_varname = ();
}

=item C<var ($varname)>

Return the C<Automake::Variable> object for the variable
named C<$varname> if defined.   Return 0 otherwise.

=cut

sub var ($)
{
  my ($name) = @_;
  return $_variable_dict{$name} if exists $_variable_dict{$name};
  return 0;
}

=item C<vardef ($varname, $cond)>

Return the C<Automake::VarDef> object for the variable named
C<$varname> if defined in condition C<$cond>.  Return the empty list
if the condition or the variable does not exist.

=cut

sub vardef ($$)
{
  my ($name, $cond) = @_;
  my $var = var $name;
  return $var && $var->def ($cond);
}

# Create the variable if it does not exist.
# This is used only by other functions in this package.
sub _cvar ($)
{
  my ($name) = @_;
  my $v = var $name;
  return $v if $v;
  return _new Automake::Variable $name;
}

=item C<rvar ($varname)>

Return the C<Automake::Variable> object for the variable named
C<$varname>.  Abort with an internal error if the variable was not
defined.

The I<r> in front of C<var> stands for I<required>.  One
should call C<rvar> to assert the variable's existence.

=cut

sub rvar ($)
{
  my ($name) = @_;
  my $v = var $name;
  prog_error ("undefined variable $name\n" . &variables_dump)
    unless $v;
  return $v;
}

=item C<rvardef ($varname, $cond)>

Return the C<Automake::VarDef> object for the variable named
C<$varname> if defined in condition C<$cond>.  Abort with an internal
error if the variable or the variable does not exist.

=cut

sub rvardef ($$)
{
  my ($name, $cond) = @_;
  return rvar ($name)->rdef ($cond);
}

=back

=head2 Methods

Here are the methods of the C<Automake::Variable> instances.
Use the C<define> function, described latter, to create such objects.

=over 4

=cut

# Create Automake::Variable objects.  This is used
# only in this file.  Other users should use
# the "define" function.
sub _new ($$)
{
  my ($class, $name) = @_;
  my $self = {
    name => $name,
    defs => {},
    conds => {},
  };
  bless $self, $class;
  $_variable_dict{$name} = $self;
  return $self;
}

=item C<$var-E<gt>name>

Return the name of C<$var>.

=cut

sub name ($)
{
  my ($self) = @_;
  return $self->{'name'};
}

=item C<$var-E<gt>def ($cond)>

Return the C<Automake::VarDef> definition for this variable in
condition C<$cond>, if it exists.  Return 0 otherwise.

=cut

sub def ($$)
{
  my ($self, $cond) = @_;
  return $self->{'defs'}{$cond} if exists $self->{'defs'}{$cond};
  return 0;
}

=item C<$var-E<gt>rdef ($cond)>

Return the C<Automake::VarDef> definition for this variable in
condition C<$cond>.  Abort with an internal error if the variable was
not defined under this condition.

The I<r> in front of C<def> stands for I<required>.  One
should call C<rdef> to assert the conditional definition's existence.

=cut

sub rdef ($$)
{
  my ($self, $cond) = @_;
  my $d = $self->def ($cond);
  prog_error ("undefined condition `" . $cond->human . "' for `"
	      . $self->name . "'\n" . variable_dump ($self->name))
    unless $d;
  return $d;
}

# Add a new VarDef to an existing Variable.  This is a private
# function.  Our public interface is the `define' function.
sub _set ($$$)
{
  my ($self, $cond, $def) = @_;
  $self->{'defs'}{$cond} = $def;
  $self->{'conds'}{$cond} = $cond;
}

=item C<$var-E<gt>conditions>

Return an L<Automake::DisjConditions> describing the conditions that
that a variable is defined with, without recursing through the
conditions of any subvariables.

These are all the conditions for which is would be safe to call
C<rdef>.

=cut

sub conditions ($)
{
  my ($self) = @_;
  prog_error ("self is not a reference")
    unless ref $self;
  return new Automake::DisjConditions (values %{$self->{'conds'}});
}

# _check_ambiguous_condition ($SELF, $COND, $WHERE)
# -------------------------------------------------
# Check for an ambiguous conditional.  This is called when a variable
# is being defined conditionally.  If we already know about a
# definition that is true under the same conditions, then we have an
# ambiguity.
sub _check_ambiguous_condition ($$$)
{
  my ($self, $cond, $where) = @_;
  my $var = $self->name;
  my ($message, $ambig_cond) =
    condition_ambiguous_p ($var, $cond, $self->conditions);

  # We allow silent variables to be overridden silently.
  my $def = $self->def ($cond);
  if ($message && !($def && $def->pretty == VAR_SILENT))
    {
      msg 'syntax', $where, "$message ...", partial => 1;
      msg_var ('syntax', $var, "... `$var' previously defined here");
      verb (variable_dump ($var));
    }
}

=item C<@missing_conds = $var-E<gt>not_always_defined_in_cond ($cond)>

Check whether C<$var> is always defined for condition C<$cond>.
Return a list of conditions where the definition is missing.

For instance, given

  if COND1
    if COND2
      A = foo
      D = d1
    else
      A = bar
      D = d2
    endif
  else
    D = d3
  endif
  if COND3
    A = baz
    B = mumble
  endif
  C = mumble

we should have (we display result as conditional strings in this
illustration, but we really return DisjConditions objects):

  var ('A')->not_always_defined_in_cond ('COND1_TRUE COND2_TRUE')
    => ()
  var ('A')->not_always_defined_in_cond ('COND1_TRUE')
    => ()
  var ('A')->not_always_defined_in_cond ('TRUE')
    => ("COND1_FALSE COND3_FALSE")
  var ('B')->not_always_defined_in_cond ('COND1_TRUE')
    => ("COND1_TRUE COND3_FALSE")
  var ('C')->not_always_defined_in_cond ('COND1_TRUE')
    => ()
  var ('D')->not_always_defined_in_cond ('TRUE')
    => ()
  var ('Z')->not_always_defined_in_cond ('TRUE')
    => ("TRUE")

=cut

sub not_always_defined_in_cond ($$)
{
  my ($self, $cond) = @_;

  # Compute the subconditions where $var isn't defined.
  return
    $self->conditions
      ->sub_conditions ($cond)
	->invert
	  ->simplify
	    ->multiply ($cond);
}

=item C<$bool = $var-E<gt>check_defined_unconditionally ([$parent, $parent_cond])>

Warn if the variable is conditionally defined.  C<$parent> is the name
of the parent variable, and C<$parent_cond> the condition of the parent
definition.  These two variables are used to display diagnostics.

=cut

sub check_defined_unconditionally ($;$$)
{
  my ($self, $parent, $parent_cond) = @_;

  if (!$self->conditions->true)
    {
      if ($parent)
	{
	  msg_cond_var ('unsupported', $parent_cond, $parent,
			"automake does not support conditional definition of "
			. $self->name . " in $parent");
	}
      else
	{
	  msg_var ('unsupported', $self,
		   "automake does not support " . $self->name
		   . " being defined conditionally");
	}
    }
}

=item C<$str = $var-E<gt>output ([@conds])>

Format all the definitions of C<$var> if C<@cond> is not specified,
else only that corresponding to C<@cond>.

=cut

sub output ($@)
{
  my ($self, @conds) = @_;

  @conds = $self->conditions->conds
    unless @conds;

  my $res = '';
  my $name = $self->name;

  foreach my $cond (@conds)
    {
      my $def = $self->def ($cond);
      prog_error ("unknown condition `" . $cond->human . "' for `"
		  . $self->name . "'")
	unless $def;

      next
	if $def->pretty == VAR_SILENT;

      $res .= $def->comment;

      my $val = $def->value;
      my $equals = $def->type eq ':' ? ':=' : '=';
      my $str = $cond->subst_string;


      if ($def->pretty == VAR_ASIS)
	{
	  my $output_var = "$name $equals $val";
	  $output_var =~ s/^/$str/meg;
	  $res .= "$output_var\n";
	}
      elsif ($def->pretty == VAR_PRETTY)
	{
	  # Suppress escaped new lines.  &makefile_wrap will
	  # add them back, maybe at other places.
	  $val =~ s/\\$//mg;
	  $res .= makefile_wrap ("$str$name $equals", "$str\t",
				 split (' ' , $val));
	}
      else # ($def->pretty == VAR_SORTED)
	{
	  # Suppress escaped new lines.  &makefile_wrap will
	  # add them back, maybe at other places.
	  $val =~ s/\\$//mg;
	  $res .= makefile_wrap ("$str$name $equals", "$str\t",
				 sort (split (' ' , $val)));
	}
    }
  return $res;
}

=item C<@values = $var-E<gt>value_as_list ($cond, [$parent, $parent_cond])>

Get the value of C<$var> as a list, given a specified condition,
without recursing through any subvariables.

C<$cond> is the condition of interest.  C<$var> does not need
to be defined for condition C<$cond> exactly, but it needs
to be defined for at most one condition implied by C<$cond>.

C<$parent> and C<$parent_cond> designate the name and the condition
of the parent variable, i.e., the variable in which C<$var> is
being expanded.  These are used in diagnostics.

For example, if C<A> is defined as "C<foo $(B) bar>" in condition
C<TRUE>, calling C<rvar ('A')->value_as_list (TRUE)> will return
C<("foo", "$(B)", "bar")>.

=cut

sub value_as_list ($$;$$)
{
  my ($self, $cond, $parent, $parent_cond) = @_;
  my @result;

  # Get value for given condition
  my $onceflag;
  foreach my $vcond ($self->conditions->conds)
    {
      my $val = $self->rdef ($vcond)->value;

      if ($vcond->true_when ($cond))
	{
	  # If there is more than one definitions of $var matching
	  # $cond then we are in trouble: tell the user we need a
	  # paddle.  Continue by merging results from all conditions,
	  # although it doesn't make much sense.
	  $self->check_defined_unconditionally ($parent, $parent_cond)
	    if $onceflag;
	  $onceflag = 1;

	  # Strip backslashes
	  $val =~ s/\\(\n|$)/ /g;

	  foreach (split (' ', $val))
	    {
	      # If a comment seen, just leave.
	      last if /^#/;

	      push (@result, $_);
	    }
	}
    }
  return @result;
}

=item C<@values = $var-E<gt>value_as_list_recursive ($cond)>

Return the list of values of C<$var> and any subvariable in condition
C<$cond>.

=cut

sub value_as_list_recursive ($$)
{
  return &_value_as_list_recursive_worker (@_, 0);
}

=item C<@values = $var-E<gt>loc_and_value_as_list_recursive ($cond)>

Return the values of C<$var> and any subvariable in condition
C<$cond> as a list of C<[$location, @values]> pairs.

=cut

sub loc_and_value_as_list_recursive ($$)
{
  return &_value_as_list_recursive_worker (@_, 1);
}

# @VALUE
# &_value_as_list_recursive_worker ($VAR, $COND, $LOC_WANTED)
# -----------------------------------------------------------
# Return contents of VAR as a list, split on whitespace.  This will
# recursively follow $(...) and ${...} inclusions.  It preserves @...@
# substitutions.  If COND is 'all', then all values under all
# conditions should be returned; if COND is a particular condition
# then only the value for that condition should be returned;
# otherwise, warn if VAR is conditionally defined.  If $LOC_WANTED is set,
# return a list of [$location, $value] instead of a list of values.
sub _value_as_list_recursive_worker ($$$)
{
  my ($var, $cond_filter, $loc_wanted) = @_;

  return traverse_variable_recursively
    ($var,
     # Construct [$location, $value] pairs if requested.
     sub {
       my ($var, $val, $cond, $full_cond) = @_;
       return [$var->rdef ($cond)->location, $val] if $loc_wanted;
       return $val;
     },
     # Collect results.
     sub {
       my ($var, $parent_cond, @allresults) = @_;
       return map { my ($cond, @vals) = @$_; return @vals } @allresults;
     },
     $cond_filter);
}


=item C<$bool = $var-E<gt>has_conditional_contents>

Return 1 if C<$var> or one of its subvariable was conditionally
defined.  Return 0 otherwise.

=cut

sub has_conditional_contents ($)
{
  my ($self) = @_;

  # Traverse the variable recursively until we
  # find a variable defined conditionally.
  # Use `die' to abort the traversal, and pass it `$full_cond'
  # to we can find easily whether the `eval' block aborted
  # because we found a condition, or for some other error.
  eval
    {
      $self->traverse_variable_recursively
	(sub
	 {
	   my ($subvar, $val, $cond, $full_cond) = @_;
	   die $full_cond if ! $full_cond->true;
	   return ();
	 },
	 sub { return (); });
    };
  if ($@)
    {
      return 1 if ref ($@) && $@->isa ("Automake::Condition");
      # Propagate other errors.
      die;
    }
  return 0;
}


=back

=head2 Utility functions

=over 4

=item C<@list = scan_variable_expansions ($text)>

Return the list of variable names expanded in C<$text>.  Note that
unlike some other functions, C<$text> is not split on spaces before we
check for subvariables.

=cut

sub scan_variable_expansions ($)
{
  my ($text) = @_;
  my @result = ();

  # Strip comments.
  $text =~ s/#.*$//;

  # Record each use of ${stuff} or $(stuff) that do not follow a $.
  while ($text =~ /(?<!\$)\$(?:\{([^\}]*)\}|\(([^\)]*)\))/g)
    {
      my $var = $1 || $2;
      # The occurent may look like $(string1[:subst1=[subst2]]) but
      # we want only `string1'.
      $var =~ s/:[^:=]*=[^=]*$//;
      push @result, $var;
    }

  return @result;
}

=item C<check_variable_expansions ($text, $where)>

Check variable expansions in C<$text> and warn about any name that
does not conform to POSIX.  C<$where> is the location of C<$text>
for the error message.

=cut

sub check_variable_expansions ($$)
{
  my ($text, $where) = @_;
  # Catch expansion of variables whose name does not conform to POSIX.
  foreach my $var (scan_variable_expansions ($text))
    {
      if ($var !~ /$_VARIABLE_PATTERN/o)
	{
	  # If the variable name contains a space, it's likely
	  # to be a GNU make extension (such as $(addsuffix ...)).
	  # Mention this in the diagnostic.
	  my $gnuext = "";
	  $gnuext = "\n(probably a GNU make extension)" if $var =~ / /;
	  msg ('portability', $where,
	       "$var: non-POSIX variable name$gnuext");
	}
    }
}


=item C<($string, $ambig_cond) = condition_ambiguous_p ($what, $cond, $condset)>

Check for an ambiguous condition.  Return an error message and
the other condition involved if we have one, two empty strings otherwise.

C<$what> is the name of the thing being defined, to use in the error
message.  C<$cond> is the C<Condition> under which it is being
defined.  C<$condset> is the C<DisjConditions> under which it had
already been defined.

=cut

sub condition_ambiguous_p ($$$)
{
  my ($var, $cond, $condset) = @_;

  foreach my $vcond ($condset->conds)
    {
      # Note that these rules doesn't consider the following
      # example as ambiguous.
      #
      #   if COND1
      #     FOO = foo
      #   endif
      #   if COND2
      #     FOO = bar
      #   endif
      #
      # It's up to the user to not define COND1 and COND2
      # simultaneously.
      my $message;
      if ($vcond eq $cond)
	{
	  return ("$var multiply defined in condition " . $cond->human,
		  $vcond);
	}
      elsif ($vcond->true_when ($cond))
	{
	  return ("$var was already defined in condition " . $vcond->human
		  . ", which implies condition ". $cond->human, $vcond);
	}
      elsif ($cond->true_when ($vcond))
	{
	  return ("$var was already defined in condition "
		  . $vcond->human . ", which is implied by condition "
		  . $cond->human, $vcond);
	}
    }
  return ('', '');
}

=item C<Automake::Variable::define($varname, $owner, $type, $cond, $value, $comment, $where, $pretty)>

Define or append to a new variable.

C<$varname>: the name of the variable being defined.

C<$owner>: owner of the variable (one of C<VAR_MAKEFILE>,
C<VAR_CONFIGURE>, or C<VAR_AUTOMAKE>, defined by L<Automake::VarDef>).
Variables can be overriden, provided the new owner is not weaker
(C<VAR_AUTOMAKE> < C<VAR_CONFIGURE> < C<VAR_MAKEFILE>).

C<$type>: the type of the assignment (C<''> for C<FOO = bar>,
C<':'> for C<FOO := bar>, and C<'+'> for C<'FOO += bar'>).

C<$cond>: the C<Condition> in which C<$var> is being defined.

C<$value>: the value assigned to C<$var> in condition C<$cond>.

C<$comment>: any comment (C<'# bla.'>) associated with the assignment.
Comments from C<+=> assignments stack with comments from the last C<=>
assignment.

C<$where>: the C<Location> of the assignment.

C<$pretty>: whether C<$value> should be pretty printed (one of
C<VAR_ASIS>, C<VAR_PRETTY>, C<VAR_SILENT>, or C<VAR_SORTED>, defined
by by L<Automake::VarDef>).  C<$pretty> applies only to real
assignments.  I.e., it does not apply to a C<+=> assignment (except
when part of it is being done as a conditional C<=> assignment).

This function will all run any hook registered with the C<hook>
function.

=cut

sub define ($$$$$$$$)
{
  my ($var, $owner, $type, $cond, $value, $comment, $where, $pretty) = @_;

  prog_error "$cond is not a reference"
    unless ref $where;

  prog_error "$where is not a reference"
    unless ref $where;

  prog_error "pretty argument missing"
    unless defined $pretty && ($pretty == VAR_ASIS
			       || $pretty == VAR_PRETTY
			       || $pretty == VAR_SILENT
			       || $pretty == VAR_SORTED);

  # We will adjust the owner of this variable unless told otherwise.
  my $adjust_owner = 1;

  error $where, "bad characters in variable name `$var'"
    if $var !~ /$_VARIABLE_PATTERN/o;

  # NEWS-OS 4.2R complains if a Makefile variable begins with `_'.
  msg ('portability', $where,
       "$var: Make variable names starting with `_' are not portable")
    if $var =~ /^_/;

  # `:='-style assignments are not acknowledged by POSIX.  Moreover it
  # has multiple meanings.  In GNU make or BSD make it means "assign
  # with immediate expansion", while in OSF make it is used for
  # conditional assignments.
  msg ('portability', $where, "`:='-style assignments are not portable")
    if $type eq ':';

  check_variable_expansions ($value, $where);

  # If there's a comment, make sure it is \n-terminated.
  if ($comment)
    {
      chomp $comment;
      $comment .= "\n";
    }
  else
    {
      $comment = '';
    }

  my $self = _cvar $var;

  my $def = $self->def ($cond);
  my $new_var = $def ? 0 : 1;

  # An Automake variable must be consistently defined with the same
  # sign by Automake.
  error ($where, "$var was set with `". $def->type .
	 "=' and is now set with `$type='")
    if $owner == VAR_AUTOMAKE && ! $new_var && $def->type ne $type;


  # Differentiate assignment types.

  # 1. append (+=) to a variable defined for current condition
  if ($type eq '+' && ! $new_var)
    {
      $def->append ($value, $comment);
    }
  # 2. append (+=) to a variable defined for *another* condition
  elsif ($type eq '+' && ! $self->conditions->false)
    {
      # * Generally, $cond is not TRUE.  For instance:
      #     FOO = foo
      #     if COND
      #       FOO += bar
      #     endif
      #   In this case, we declare an helper variable conditionally,
      #   and append it to FOO:
      #     FOO = foo $(am__append_1)
      #     @COND_TRUE@am__append_1 = bar
      #   Of course if FOO is defined under several conditions, we add
      #   $(am__append_1) to each definitions.
      #
      # * If $cond is TRUE, we don't need the helper variable.  E.g., in
      #     if COND1
      #       FOO = foo1
      #     else
      #       FOO = foo2
      #     endif
      #     FOO += bar
      #   we can add bar directly to all definition of FOO, and output
      #     @COND_TRUE@FOO = foo1 bar
      #     @COND_FALSE@FOO = foo2 bar

      # Do we need an helper variable?
      if ($cond != TRUE)
        {
	    # Does the helper variable already exists?
	    my $key = "$var:" . $cond->string;
	    if (exists $_appendvar{$key})
	      {
		# Yes, let's simply append to it.
		$var = $_appendvar{$key};
		$owner = VAR_AUTOMAKE;
		$self = var ($var);
		$def = $self->rdef ($cond);
		$new_var = 0;
	      }
	    else
	      {
		# No, create it.
		my $num = 1 + keys (%_appendvar);
		my $hvar = "am__append_$num";
		$_appendvar{$key} = $hvar;
		&define ($hvar, VAR_AUTOMAKE, '+',
			 $cond, $value, $comment, $where, $pretty);
		# Now HVAR is to be added to VAR.
		$comment = '';
		$value = "\$($hvar)";
	      }
	}

      # Add VALUE to all definitions of SELF.
      foreach my $vcond ($self->conditions->conds)
        {
	  # We have a bit of error detection to do here.
	  # This:
	  #   if COND1
	  #     X = Y
	  #   endif
	  #   X += Z
	  # should be rejected because X is not defined for all conditions
	  # where `+=' applies.
	  my $undef_cond = $self->not_always_defined_in_cond ($cond);
	  if (! $undef_cond->false)
	    {
	      error ($where,
		     "Cannot apply `+=' because `$var' is not defined "
		     . "in\nthe following conditions:\n  "
		     . join ("\n  ", map { $_->human } $undef_cond->conds)
		     . "\nEither define `$var' in these conditions,"
		     . " or use\n`+=' in the same conditions as"
		     . " the definitions.");
	    }
	  else
	    {
	      &define ($var, $owner, '+', $vcond, $value, $comment,
		       $where, $pretty);
	    }
	}
      # Don't adjust the owner.  The above &define did it in the
      # right conditions.
      $adjust_owner = 0;
    }
  # 3. first assignment (=, :=, or +=)
  else
    {
      # If Automake tries to override a value specified by the user,
      # just don't let it do.
      if (! $new_var && $def->owner != VAR_AUTOMAKE
	  && $owner == VAR_AUTOMAKE)
	{
	  if (! exists $_silent_variable_override{$var})
	    {
	      my $condmsg = ($cond == TRUE
			     ? '' : (" in condition `" . $cond->human . "'"));
	      msg_cond_var ('override', $cond, $var,
			    "user variable `$var' defined here$condmsg...",
			    partial => 1);
	      msg ('override', $where,
		   "... overrides Automake variable `$var' defined here");
	    }
	  verb ("refusing to override the user definition of:\n"
		. variable_dump ($var)
		."with `" . $cond->human . "' => `$value'");
	}
      else
	{
	  # There must be no previous value unless the user is redefining
	  # an Automake variable or an AC_SUBST variable for an existing
	  # condition.
	  _check_ambiguous_condition ($self, $cond, $where)
	    unless (!$new_var
		    && (($def->owner == VAR_AUTOMAKE && $owner != VAR_AUTOMAKE)
			|| $def->owner == VAR_CONFIGURE));

	  # Never decrease an owner.
	  $owner = $def->owner
	    if ! $new_var && $owner < $def->owner;

	  # Assignments to a macro set its location.  We don't adjust
	  # locations for `+='.  Ideally I suppose we would associate
	  # line numbers with random bits of text.
	  $def = new Automake::VarDef ($var, $value, $comment, $where->clone,
				       $type, $owner, $pretty);
	  $self->_set ($cond, $def);
	  push @_var_order, $var;

	  # No need to adjust the owner later as we have overridden
	  # the definition.
	  $adjust_owner = 0;
	}
    }

  # The owner of a variable can only increase, because an Automake
  # variable can be given to the user, but not the converse.
  $def->set_owner ($owner, $where->clone)
    if $adjust_owner && $owner > $def->owner;

  # Call any defined hook.  This helps to update some internal state
  # *while* parsing the file.  For instance the handling of SUFFIXES
  # requires this (see var_SUFFIXES_trigger).
  &{$_hooks{$var}}($type, $value) if exists $_hooks{$var};
}

=item C<variable_delete ($varname, [@conds])>

Forget about C<$varname> under the conditions C<@conds>, or completely
if C<@conds> is empty.

=cut

sub variable_delete ($@)
{
  my ($var, @conds) = @_;

  if (!@conds)
    {
      delete $_variable_dict{$var};
    }
  else
    {
      for my $cond (@conds)
	{
	  delete $_variable_dict{$var}{'defs'}{$cond};
	}
    }
}

=item C<$str = variable_dump ($varname)>

Return a string describing all we know about C<$varname>.
For debugging.

=cut

# &variable_dump ($VAR)
# ---------------------
sub variable_dump ($)
{
  my ($var) = @_;
  my $text = '';

  my $v = var $var;

  if (!$v)
    {
      $text = "  $var does not exist\n";
    }
  else
    {
      $text .= "$var: \n  {\n";
      foreach my $vcond ($v->conditions->conds)
	{
	  $text .= "    " . $vcond->human . " => " . $v->rdef ($vcond)->dump;
	}
      $text .= "  }\n";
    }
  return $text;
}


=item C<$str = variables_dump ($varname)>

Return a string describing all we know about all variables.
For debugging.

=cut

sub variables_dump ()
{
  my ($var) = @_;

  my $text = "All variables:\n{\n";
  foreach my $var (sort (variables()))
    {
      $text .= variable_dump ($var);
    }
  $text .= "}\n";
  return $text;
}


=item C<$var = set_seen ($varname)>

=item C<$var = $var-E<gt>set_seen>

Mark all definitions of this variable as examined, if the variable
exists.  See L<Automake::VarDef::set_seen>.

Return the C<Variable> object if the variable exists, or 0
otherwise (i.e., as the C<var> function).

=cut

sub set_seen ($)
{
  my ($self) = @_;
  $self = ref $self ? $self : var $self;

  return 0 unless $self;

  for my $c ($self->conditions->conds)
    {
      $self->rdef ($c)->set_seen;
    }

  return $self;
}


=item C<$count = require_variables ($where, $reason, $cond, @variables)>

Make sure that each supplied variable is defined in C<$cond>.
Otherwise, issue a warning showing C<$reason> (C<$reason> should be
the reason why these variable are required, for instance C<'option foo
used'>).  If we know which macro can define this variable, hint the
user.  Return the number of undefined variables.

=cut

sub require_variables ($$$@)
{
  my ($where, $reason, $cond, @vars) = @_;
  my $res = 0;
  $reason .= ' but ' unless $reason eq '';

 VARIABLE:
  foreach my $var (@vars)
    {
      # Nothing to do if the variable exists.
      next VARIABLE
	if vardef ($var, $cond);

      my $text = "$reason`$var' is undefined\n";
      my $v = var $var;
      if ($v)
	{
	  my $undef_cond = $v->not_always_defined_in_cond ($cond);
	  next VARIABLE
	    if $undef_cond->false;
	  $text .= ("in the following conditions:\n  "
		    . join ("\n  ", map { $_->human } $undef_cond->conds));
	}

      ++$res;

      if (exists $_am_macro_for_var{$var})
	{
	  $text .= "\nThe usual way to define `$var' is to add "
	    . "`$_am_macro_for_var{$var}'\nto `$configure_ac' and "
	    . "run `aclocal' and `autoconf' again.";
	}
      elsif (exists $_ac_macro_for_var{$var})
	{
	  $text .= "\nThe usual way to define `$var' is to add "
	    . "`$_ac_macro_for_var{$var}'\nto `$configure_ac' and "
	    . "run `autoconf' again.";
	}

      error $where, $text, uniq_scope => US_GLOBAL;
    }
  return $res;
}

=item C<$count = require_variables_for_variable ($var, $reason, @variables)>

Same as C<require_variables>, but take a variable name as first argument.
C<@variables> should be defined in the same conditions as C<$var> is
defined.  C<$var> can be a variable name or an C<Automake::Variable>.

=cut

sub require_variables_for_variable ($$@)
{
  my ($var, $reason, @args) = @_;
  $var = rvar ($var) unless ref $var;
  for my $cond ($var->conditions->conds)
    {
      return require_variables ($var->rdef ($cond)->location, $reason,
				$cond, @args);
    }
}


=item C<variable_value ($var)>

Get the C<TRUE> value of a variable, warn if the variable is
conditionally defined.  C<$var> can be either a variable name
or a C<Automake::Variable> instance (this allows to calls sucha
as C<$var-E<gt>variable_value>).

=cut

sub variable_value ($)
{
    my ($var) = @_;
    my $v = ref ($var) ? $var : var ($var);
    return () unless $v;
    $v->check_defined_unconditionally;
    return $v->rdef (TRUE)->value;
}

=item C<$str = output_variables>

Format definitions for all variables.

=cut

sub output_variables ()
{
  my $res = '';
  # We output variables it in the same order in which they were
  # defined (skipping duplicates).
  my @vars = uniq @_var_order;

  # Output all the Automake variables.  If the user changed one,
  # then it is now marked as VAR_CONFIGURE or VAR_MAKEFILE.
  foreach my $var (@vars)
    {
      my $v = rvar $var;
      foreach my $cond ($v->conditions->conds)
	{
	  $res .= $v->output ($cond)
	    if $v->rdef ($cond)->owner == VAR_AUTOMAKE;
	}
    }

  # Now dump the user variables that were defined.
  foreach my $var (@vars)
    {
      my $v = rvar $var;
      foreach my $cond ($v->conditions->conds)
	{
	  $res .= $v->output ($cond)
	    if $v->rdef ($cond)->owner != VAR_AUTOMAKE;
	}
    }
  return $res;
}

=item C<traverse_variable_recursively ($var, &fun_item, &fun_collect, [$cond_filter])>

=item C<$var-E<gt>traverse_variable_recursively (&fun_item, &fun_collect, [$cond_filter])>

Split the value of the variable C<$var> on space, and traverse its
componants recursively.  (C<$var> may be a variable name in the first
syntax.  It must be an C<Automake::Variable> otherwise.)  If
C<$cond_filter> is an C<Automake::Condition>, process any conditions
which are true when C<$cond_filter> is true.  Otherwise, process all
conditions.

We distinguish to kinds of items in the content of C<$var>.
Terms that look like C<$(foo)> or C<${foo}> are subvariables
and cause recursion.  Other terms are assumed to be filenames.

Each time a filename is encountered, C<&fun_item> is called with the
following arguments:

  ($var,        -- the Automake::Variable we are currently
                   traversing
   $val,        -- the item (i.e., filename) to process
   $cond,       -- the Condition for the $var definition we are
                   examinating (ignoring the recursion context)
   $full_cond)  -- the full Condition, taking into account
                   conditions inherited from parent variables
                   during recursion

C<&fun_item> may return a list of items, they will be passed to
C<&fun_store> later on.  Define C<&fun_item> as C<undef> when it serve
no purpose, this will speed things up.

Once all items of a variable have been processed, the result (of the
calls to C<&fun_items>, or of recursive traversals of subvariables)
are passed to C<&fun_collect>.  C<&fun_collect> receives three
arguments:

  ($var,         -- the variable being traversed
   $parent_cond, -- the Condition inherited from parent
                    variables during recursion
   @condlist)    -- a list of [$cond, @results] pairs
                    where each $cond appear only once, and @result
                    are all the results for this condition.

Typically you should do C<$cond->merge ($parent_cond)> to recompute
the C<$full_cond> associated to C<@result>.  C<&fun_collect> may
return a list of items, that will be used as the result of
C<&traverse_variable_recursively> (the top-level, or it's recursive
calls).

=cut

# Contains a stack of `from' and `to' parts of variable
# substitutions currently in force.
my @_substfroms;
my @_substtos;
# This is used to keep track of which variable definitions we are
# scanning.
my %_vars_scanned = ();

sub traverse_variable_recursively ($&&;$)
{
  %_vars_scanned = ();
  @_substfroms = ();
  @_substtos = ();
  my ($var, $fun_item, $fun_collect, $cond_filter) = @_;
  return _traverse_variable_recursively_worker ($var, $var,
						$fun_item, $fun_collect,
						$cond_filter, TRUE)
}

# The guts of &traverse_variable_recursively.
sub _traverse_variable_recursively_worker ($$&&$$)
{
  my ($var, $parent, $fun_item, $fun_collect, $cond_filter, $parent_cond) = @_;

  # Don't recurse into undefined variables and mark
  # existing variable as examined.
  $var = set_seen $var;
  return ()
    unless $var;

  if (defined $_vars_scanned{$var})
    {
      err_var $var, "variable `" . $var->name() . "' recursively defined";
      return ();
    }
  $_vars_scanned{$var} = 1;

  my @allresults = ();
  my $cond_once = 0;
  foreach my $cond ($var->conditions->conds)
    {
      if (ref $cond_filter)
	{
	  # Ignore conditions that don't match $cond_filter.
	  next if ! $cond->true_when ($cond_filter);
	  # If we found out several definitions of $var
	  # match $cond_filter then we are in trouble.
	  # Tell the user we don't support this.
	  $var->check_defined_unconditionally ($parent, $parent_cond)
	    if $cond_once;
	  $cond_once = 1;
	}
      my @result = ();
      my $full_cond = $cond->merge ($parent_cond);
      foreach my $val ($var->value_as_list ($cond, $parent, $parent_cond))
	{
	  # If $val is a variable (i.e. ${foo} or $(bar), not a filename),
	  # handle the sub variable recursively.
	  # (Backslashes between bracklets, before `}' and `)' are required
	  # only of Emacs's indentation.)
	  if ($val =~ /^\$\{([^\}]*)\}$/ || $val =~ /^\$\(([^\)]*)\)$/)
	    {
	      my $subvar = $1;

	      # If the user uses a losing variable name, just ignore it.
	      # This isn't ideal, but people have requested it.
	      next if ($subvar =~ /\@.*\@/);


	      # See if the variable is actually a substitution reference
	      my ($from, $to);
	      my @temp_list;
              # This handles substitution references like ${foo:.a=.b}.
	      if ($subvar =~ /^([^:]*):([^=]*)=(.*)$/o)
		{
		  $subvar = $1;
		  $to = $3;
		  $from = quotemeta $2;
		}
	      push @_substfroms, $from;
	      push @_substtos, $to;

	      my @res =
		&_traverse_variable_recursively_worker ($subvar, $parent,
							$fun_item,
							$fun_collect,
							$cond_filter,
							$full_cond);
	      push (@result, @res);

	      pop @_substfroms;
	      pop @_substtos;
	    }
	    elsif ($fun_item) # $var is a filename we must process
	    {
	      my $substnum=$#_substfroms;
	      while ($substnum >= 0)
		{
		  $val =~ s/$_substfroms[$substnum]$/$_substtos[$substnum]/
		    if defined $_substfroms[$substnum];
		  $substnum -= 1;
		}

	      # Make sure you update the doc of &traverse_variable_recursively
	      # if you change the prototype of &fun_item.
	      my @transformed = &$fun_item ($var, $val, $cond, $full_cond);
	      push (@result, @transformed);
	    }
	}
      push (@allresults, [$cond, @result]) if @result;
    }

  # We only care about _recursive_ variable definitions.  The user
  # is free to use the same variable several times in the same definition.
  delete $_vars_scanned{$var};

  # Make sure you update the doc of &traverse_variable_recursively
  # if you change the prototype of &fun_collect.
  return &$fun_collect ($var, $parent_cond, @allresults);
}

# $VARNAME
# _gen_varname ($BASE, @DEFINITIONS)
# ---------------------------------
# Return a variable name starting with $BASE, that will be
# used to store definitions @DEFINITIONS.
# @DEFINITIONS is a list of pair [$COND, @OBJECTS].
#
# If we already have a $BASE-variable containing @DEFINITIONS, reuse it.
# This way, we avoid combinatorial explosion of the generated
# variables.  Especially, in a Makefile such as:
#
# | if FOO1
# | A1=1
# | endif
# |
# | if FOO2
# | A2=2
# | endif
# |
# | ...
# |
# | if FOON
# | AN=N
# | endif
# |
# | B=$(A1) $(A2) ... $(AN)
# |
# | c_SOURCES=$(B)
# | d_SOURCES=$(B)
#
# The generated c_OBJECTS and d_OBJECTS will share the same variable
# definitions.
#
# This setup can be the case of a testsuite containing lots (>100) of
# small C programs, all testing the same set of source files.
sub _gen_varname ($@)
{
  my $base = shift;
  my $key = '';
  foreach my $pair (@_)
    {
      my ($cond, @values) = @$pair;
      $key .= "($cond)@values";
    }

  return $_gen_varname{$base}{$key} if exists $_gen_varname{$base}{$key};

  my $num = 1 + keys (%{$_gen_varname{$base}});
  my $name = "${base}_${num}";
  $_gen_varname{$base}{$key} = $name;
  return $name;
}

=item C<$resvar = transform_variable_recursively ($var, $resvar, $base, $nodefine, $where, &fun_item)>

=item C<$resvar = $var-E<gt>transform_variable_recursively ($resvar, $base, $nodefine, $where, &fun_item)>

Traverse C<$var> recursively, and create a C<$resvar> variable in
which each filename in C<$var> have been transformed using
C<&fun_item>.  (C<$var> may be a variable name in the first syntax.
It must be an C<Automake::Variable> otherwise.)

Helper variables (corresponding to sub-variables of C<$var>) are
created as needed, using C<$base> as prefix.

Arguments are:
  $var       source variable to traverse
  $resvar    resulting variable to define
  $base      prefix to use when naming subvariables of $resvar
  $nodefine  if true, traverse $var but do not define any variable
             (this assumes &fun_item has some useful side-effect)
  $where     context into which variable definitions are done
  &fun_item  a transformation function -- see the documentation
             of &fun_item in traverse_variable_recursively.

This returns the string C<"\$($RESVAR)">.

=cut

sub transform_variable_recursively ($$$$$&)
{
  my ($var, $resvar, $base, $nodefine, $where, $fun_item) = @_;

  # Convert $var here, even though &traverse_variable_recursively
  # would do it, because we need to compare $var and $subvar below.
  $var = ref $var ? $var : rvar $var;

  my $res = &traverse_variable_recursively
    ($var,
     $fun_item,
     # The code that define the variable holding the result
     # of the recursive transformation of a subvariable.
     sub {
       my ($subvar, $parent_cond, @allresults) = @_;
       # Find a name for the variable, unless this is the top-variable
       # for which we want to use $resvar.
       my $varname =
	 ($var != $subvar) ? _gen_varname ($base, @allresults) : $resvar;
       # Define the variable if required.
       unless ($nodefine)
	 {
	   # If the new variable is the source variable, we assume
	   # we are trying to override a user variable.  Delete
	   # the old variable first.
	   variable_delete ($varname) if $varname eq $var->name;
	   # Define for all conditions.
	   foreach my $pair (@allresults)
	     {
	       my ($cond, @result) = @$pair;
	       define ($varname, VAR_AUTOMAKE, '', $cond, "@result",
		       '', $where, VAR_PRETTY)
		 unless vardef ($varname, $cond);
	       rvardef ($varname, $cond)->set_seen;
	     }
	 }
       return "\$($varname)";
     });
  return $res;
}


=back

=head1 SEE ALSO

L<Automake::VarDef>, L<Automake::Condition>,
L<Automake::DisjConditions>, L<Automake::Location>.

=cut

1;

### Setup "GNU" style for perl-mode and cperl-mode.
## Local Variables:
## perl-indent-level: 2
## perl-continued-statement-offset: 2
## perl-continued-brace-offset: 0
## perl-brace-offset: 0
## perl-brace-imaginary-offset: 0
## perl-label-offset: -2
## cperl-indent-level: 2
## cperl-brace-offset: 0
## cperl-continued-brace-offset: 0
## cperl-label-offset: -2
## cperl-extra-newline-before-brace: t
## cperl-merge-trailing-else: nil
## cperl-continued-statement-offset: 2
## End:
