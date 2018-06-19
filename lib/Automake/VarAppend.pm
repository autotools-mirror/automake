# Copyright (C) 2018  Free Software Foundation, Inc

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

package Automake::VarAppend;

use strict;
use 5.006;

use Automake::Channels;
use Automake::Condition qw (TRUE FALSE);
use Automake::Item;
use Automake::VarDef;
use Exporter;

use vars '@ISA', '@EXPORT';

@ISA = qw (Automake::Item Exporter);

@EXPORT = qw (append_var_cur_cond first_assign_var am_check_definitions);

=head1 NAME

Automake::VarAppend - Helper methods for appending to variables

=head1 DESCRIPTION

This package provides methods for appending values to variables.

It is used by the C<Automake::Variable> class in its C<define> function.

=head2 FUNCTIONS

=item C<append_var_cur_cond ($self, $var, $owner, $where, $def, $value,
$comment)>

Append $value to an existing $var defined for the current condition.

=cut

sub append_var_cur_cond ($$$$$$$)
{
  my ($self, $var, $owner, $where, $def, $value, $comment) = @_;
  $def->append ($value, $comment);
  $self->{'last-append'} = [];

  # Only increase owners.  A VAR_CONFIGURE variable augmented in a
  # Makefile.am becomes a VAR_MAKEFILE variable.
  $def->set_owner ($owner, $where->clone)
      if $owner > $def->owner;
}


=item C<first_assign_var ($sefl, $var, $cond, $owner, $where, $def, $value, $pretty, $comment, $new_var, $type)>

Method that assign a value to a variable for the first time or for total
redefinition of an Automake variable or an AC_SUBST variable for an existing
condition.

=cut

sub first_assign_var ($$$$$$$$$$$)
{
  my ($self, $var, $cond, $owner, $where, $def, $value, $pretty, $comment, $new_var, $type) = @_;

  # Never decrease an owner.
  $owner = $def->owner
    if ! $new_var && $owner < $def->owner;

  # Assignments to a macro set its location.  We don't adjust
  # locations for '+='.  Ideally I suppose we would associate
  # line numbers with random bits of text.
  $def = new Automake::VarDef ($var, $value, $comment, $where->clone,
			       $type, $owner, $pretty);
  $self->set ($cond, $def);
}


=item am_check_definitions ($var, $cond, $def, $type, $where)

Additional checks for Automake definitions

=cut

sub am_check_definitions ($$$$$)
{
  my ($var, $cond, $def, $type, $where) = @_;
  # An Automake variable must be consistently defined with the same
  # sign by Automake.
  if ($def->type ne $type && $def->owner == VAR_AUTOMAKE)
    {
      error ($def->location,
             "Automake variable '$var' was set with '"
             . $def->type . "=' here ...", partial => 1);
      error ($where, "... and is now set with '$type=' here.");
      prog_error ("Automake variable assignments should be consistently\n"
                  . "defined with the same sign");
    }
}


=back

=head1 SEE ALSO

L<Automake::VarDef>, L<Automake::Variable>,
L<Automake::Condition>, L<Automake::Item>,
L<Automake::Channels>.

=cut

1;
