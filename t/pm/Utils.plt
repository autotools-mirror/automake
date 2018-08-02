# -*- mode:perl -*-
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

use Automake::Utils;
use Test::Simple tests => 3;

ok (subst 'AC_FOO' eq '@AC_FOO@', 'subst');

##########################################

my $test_str = "\

  Aliquam posuere.  Nunc aliquet, augue nec adipiscing interdum, lacus tellus
malesuada massa, quis varius mi purus     non odio.  Pellentesque condimentum,

magna ut suscipit hendrerit, ipsum augue ornare nulla,  non luctus diam neque

sit amet urna.  Curabitur vulputate vestibulum lorem.  Fusce sagittis, libero
  non molestie mollis, magna orci ultrices dolor, at vulputate neque nulla
lacinia eros.
";

my $expected_res = "Aliquam posuere. Nunc aliquet, augue nec adipiscing " .
    "interdum, lacus tellus malesuada massa, quis varius mi purus non " .
    "odio. Pellentesque condimentum, magna ut suscipit hendrerit, ipsum " .
    "augue ornare nulla, non luctus diam neque sit amet urna. Curabitur " .
    "vulputate vestibulum lorem. Fusce sagittis, libero non molestie " .
    "mollis, magna orci ultrices dolor, at vulputate neque nulla lacinia " .
    "eros.";

ok ((flatten $test_str) eq $expected_res, 'flatten');

#####################################################

locate_aux_dir;
# The install-sh script is located in $(top_scrdir)/lib/
print "$am_config_aux_dir\n";
ok ($am_config_aux_dir eq '$(top_srcdir)', 'locate_aux_dir');
