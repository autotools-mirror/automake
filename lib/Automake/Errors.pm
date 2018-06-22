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

package Automake::Errors;

use strict;
use 5.006;

use Automake::Channels;
use Automake::Global;
use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw (err_am err_ac);

=head1 NAME

Automake::Errors - Functions for printing error messages about am and ac
files

=head1 DESCRIPTION

This package provides two methods for printing errors about
C<Makefile.am> and C<configure.ac> files.

=head2 FUNCTIONS

=cut

# _msg_am ($CHANNEL, $MESSAGE, [%OPTIONS])
#---------------------------------------
# Messages about about the current Makefile.am.
sub _msg_am
{
  my ($channel, $msg, %opts) = @_;
  msg $channel, "${am_file}.am", $msg, %opts;
}

# _msg_ac ($CHANNEL, $MESSAGE, [%OPTIONS])
# ---------------------------------------
# Messages about about configure.ac.
sub _msg_ac
{
  my ($channel, $msg, %opts) = @_;
  msg $channel, $configure_ac, $msg, %opts;
}

=item C<err_am ($MESSAGE, [%OPTIONS])>

Uncategorized errors about the current Makefile.am.

=cut

sub err_am
{
  _msg_am ('error', @_);
}

=item C<err_ac ($MESSAGE, [%OPTIONS])>

Uncategorized errors about configure.ac.

=cut

sub err_ac
{
  _msg_ac ('error', @_);
}

=back

=head1 SEE ALSO

L<Automake::Channels>, L<Automake::ChannelDefs>

=cut

1;
