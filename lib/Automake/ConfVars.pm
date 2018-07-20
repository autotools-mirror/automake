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
use Automake::VarDef;
use Automake::Variable;
use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw (%configure_vars %ignored_configure_vars $output_vars
    &define_standard_variables);

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

  my @paragraphs = make_paragraphs ($filename);

  my ($comments, undef, $rules) =
      file_contents_internal (1, $filename, new Automake::Location,
                              \@paragraphs);
  foreach my $var (sort keys %configure_vars)
    {
      _define_configure_variable ($var);
    }

  $output_vars .= $comments . $rules;
}

1;
