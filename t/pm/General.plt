# -*- mode:perl -*-
# Copyright (C) 2018 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use Automake::General;
use Test::Simple tests => 2;

# Check 'none'.
my $none_positive = none { $_[0] < 0 } (1, 7, 3, 8, 9);
ok ($none_positive != 0, 'Test none on positive values');

my $none_gt_8 = none { $_[0] >= 8 } (1, 7, 3, 8, 9);
ok ($none_gt_8 == 0, 'Test none on values > 8');
