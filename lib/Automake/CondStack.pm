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

package Automake::CondStack;

use 5.006;
use strict;

use Exporter;
use Automake::Condition qw (TRUE FALSE);
use Automake::Global;
use Automake::Channels;
use Automake::ChannelDefs;

use vars qw (@ISA @EXPORT);

@ISA = qw (Exporter);
@EXPORT = qw (@cond_stack &cond_stack_if &cond_stack_else &cond_stack_endif);


# This is the conditional stack, updated on if/else/endif, and
# used to build Condition objects.
our @cond_stack;

my %_am_macro_for_cond =
  (
   AMDEP => "one of the compiler tests\n"
   . "    AC_PROG_CC, AC_PROG_CXX, AC_PROG_OBJC, AC_PROG_OBJCXX,\n"
   . "    AM_PROG_AS, AM_PROG_GCJ, AM_PROG_UPC",
   am__fastdepCC => 'AC_PROG_CC',
   am__fastdepCCAS => 'AM_PROG_AS',
   am__fastdepCXX => 'AC_PROG_CXX',
   am__fastdepGCJ => 'AM_PROG_GCJ',
   am__fastdepOBJC => 'AC_PROG_OBJC',
   am__fastdepOBJCXX => 'AC_PROG_OBJCXX',
   am__fastdepUPC => 'AM_PROG_UPC'
  );


# $STRING
# _make_conditional_string ($NEGATE, $COND)
# ----------------------------------------
sub _make_conditional_string
{
  my ($negate, $cond) = @_;
  $cond = "${cond}_TRUE"
    unless $cond =~ /^TRUE|FALSE$/;
  $cond = Automake::Condition::conditional_negate ($cond)
    if $negate;
  return $cond;
}


# $COND
# cond_stack_if ($NEGATE, $COND, $WHERE)
# --------------------------------------
sub cond_stack_if
{
  my ($negate, $cond, $where) = @_;

  if (! $configure_cond{$cond} && $cond !~ /^TRUE|FALSE$/)
    {
      my $text = "$cond does not appear in AM_CONDITIONAL";
      my $scope = US_LOCAL;
      if (exists $_am_macro_for_cond{$cond})
	{
	  my $mac = $_am_macro_for_cond{$cond};
	  $text .= "\n  The usual way to define '$cond' is to add ";
	  $text .= ($mac =~ / /) ? $mac : "'$mac'";
	  $text .= "\n  to '$configure_ac' and run 'aclocal' and 'autoconf' again";
	  # These warnings appear in Automake files (depend2.am),
	  # so there is no need to display them more than once:
	  $scope = US_GLOBAL;
	}
      error $where, $text, uniq_scope => $scope;
    }

  push (@cond_stack, _make_conditional_string ($negate, $cond));

  return new Automake::Condition (@cond_stack);
}


# $COND
# cond_stack_else ($NEGATE, $COND, $WHERE)
# ----------------------------------------
sub cond_stack_else
{
  my ($negate, $cond, $where) = @_;

  if (! @cond_stack)
    {
      error $where, "else without if";
      return FALSE;
    }

  $cond_stack[$#cond_stack] =
    Automake::Condition::conditional_negate ($cond_stack[$#cond_stack]);

  # If $COND is given, check against it.
  if (defined $cond)
    {
      $cond = _make_conditional_string ($negate, $cond);

      error ($where, "else reminder ($negate$cond) incompatible with "
	     . "current conditional: $cond_stack[$#cond_stack]")
	if $cond_stack[$#cond_stack] ne $cond;
    }

  return new Automake::Condition (@cond_stack);
}


# $COND
# cond_stack_endif ($NEGATE, $COND, $WHERE)
# -----------------------------------------
sub cond_stack_endif
{
  my ($negate, $cond, $where) = @_;
  my $old_cond;

  if (! @cond_stack)
    {
      error $where, "endif without if";
      return TRUE;
    }

  # If $COND is given, check against it.
  if (defined $cond)
    {
      $cond = _make_conditional_string ($negate, $cond);

      error ($where, "endif reminder ($negate$cond) incompatible with "
	     . "current conditional: $cond_stack[$#cond_stack]")
	if $cond_stack[$#cond_stack] ne $cond;
    }

  pop @cond_stack;

  return new Automake::Condition (@cond_stack);
}

1;
