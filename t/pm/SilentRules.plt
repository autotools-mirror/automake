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

use Automake::SilentRules;
use Test::Simple tests => 3;

ok (verbose_flag 'FOO' eq '$(AM_V_FOO)', 'verbose_flag');
ok (verbose_nodep_flag 'FOO' eq '$(AM_V_FOO@am__nodep@)', 'verbose_nodep_flag');
ok (silent_flag eq '$(AM_V_at)', 'silent_flag');
