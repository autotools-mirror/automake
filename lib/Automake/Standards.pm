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

package Automake::Standards;

use Automake::Channels;
use Automake::Global;
use Automake::Options;
use Automake::Requires;
use Automake::Utils;
use Exporter 'import';

use vars qw (@EXPORT);

@EXPORT = qw (check_gnu_standards check_gnits_standards);


# Do any extra checking for GNU standards.
sub check_gnu_standards ()
{
  if ($relative_dir eq '.')
    {
      # In top level (or only) directory.
      require_file ("$am_file.am", GNU,
		    qw/INSTALL NEWS README AUTHORS ChangeLog/);

      # Accept one of these three licenses; default to COPYING.
      # Make sure we do not overwrite an existing license.
      my $license;
      foreach (qw /COPYING COPYING.LIB COPYING.LESSER/)
	{
	  if (-f $_)
	    {
	      $license = $_;
	      last;
	    }
	}
      require_file ("$am_file.am", GNU, 'COPYING')
	unless $license;
    }

  for my $opt ('no-installman', 'no-installinfo')
    {
      msg ('error-gnu', option $opt,
	   "option '$opt' disallowed by GNU standards")
	if option $opt;
    }
}


# Do any extra checking for GNITS standards.
sub check_gnits_standards ()
{
  if ($relative_dir eq '.')
    {
      # In top level (or only) directory.
      require_file ("$am_file.am", GNITS, 'THANKS');
    }
}


1;
