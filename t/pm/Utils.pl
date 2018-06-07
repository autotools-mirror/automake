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
use Automake::Utils;

sub check_subst
{
  my @inputs = qw (AC_FOO AC_BAR AC_BAZ);
  my @expected_outputs = map {
    (my $exp = $_) =~ s/(.*)/\@$1\@/;
    $exp;
  } @inputs;

  for my $i (0 .. $#inputs)
    {
      return 1 if (subst $inputs[$i]) ne $expected_outputs[$i];
    }
  return 0;
}

exit check_subst;
