# Copyright (C) 2018  Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Automake::Utils;

use 5.006;
use strict;
use Exporter;
use Automake::Rule;
use Automake::Global;

use vars qw (@ISA @EXPORT);

@ISA = qw (Exporter);
@EXPORT = qw (&var_SUFFIXES_trigger &locate_aux_dir);

# var_SUFFIXES_trigger ($TYPE, $VALUE)
# ------------------------------------
# This is called by Automake::Variable::define() when SUFFIXES
# is defined ($TYPE eq '') or appended ($TYPE eq '+').
# The work here needs to be performed as a side-effect of the
# macro_define() call because SUFFIXES definitions impact
# on $KNOWN_EXTENSIONS_PATTERN which is used used when parsing
# the input am file.
sub var_SUFFIXES_trigger
{
    my ($type, $value) = @_;
    accept_extensions (split (' ', $value));
}

# Find the aux dir.  This should match the algorithm used by
# ./configure. (See the Autoconf documentation for for
# AC_CONFIG_AUX_DIR.)
sub locate_aux_dir
{
  if (! $config_aux_dir_set_in_configure_ac)
    {
      # The default auxiliary directory is the first
      # of ., .., or ../.. that contains install-sh.
      # Assume . if install-sh doesn't exist yet.
      for my $dir (qw (. .. ../..))
	{
	  if (-f "$dir/install-sh")
	    {
	      $config_aux_dir = $dir;
	      last;
	    }
	}
      $config_aux_dir = '.' unless $config_aux_dir;
    }
  # Avoid unsightly '/.'s.
  $am_config_aux_dir =
    '$(top_srcdir)' . ($config_aux_dir eq '.' ? "" : "/$config_aux_dir");
  $am_config_aux_dir =~ s,/*$,,;
}

1;
