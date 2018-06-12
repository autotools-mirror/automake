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

use Automake::CondStack;
use Automake::Condition qw (TRUE FALSE);
use Automake::Location;

# The different test cases.  What happens with IF alone?
my @tests = (['IF', 'ELSE', 'ENDIF'],
	     ['ELSE', 'ENDIF'],
	     ['IF', 'ENDIF'],
	     ['ENDIF'],
	     ['IF', 'ELSE', 'IF', 'ELSE', 'ENDIF']);

my @exp_res = (0, 1, 0, 1, 0);

my $where = new Automake::Location "/dev/null:0";

sub test_cond_stack ()
{
  my @real_res = ();
  for (@tests)
    {
      # Reset conditional stack for each test case
      @cond_stack = ();
      my $res = 0;
      my $else_called = 0;
      for my $test (@$_)
        {
	  if ($test eq 'IF')
	    {
	      cond_stack_if (undef, 'FALSE', $where);
	    }
	  if ($test eq 'ELSE')
            {
              $else_called = 1;
	      if (cond_stack_else ('!', 'FALSE', $where) == FALSE)
		{
		  $res = 1;
		  last;
		}
	    }
	  if ($test eq 'ENDIF')
            {
              my $cond = ($else_called ? TRUE : FALSE);
	      if (cond_stack_else (undef, undef, $where) == $cond)
                {
		  $res = 1;
		  last;
		}
	    }
        }
      push @real_res, $res;
    }
  print "@real_res\n";
  print "@exp_res\n";
  for my $i (0 .. $#exp_res)
    {
      return 1 if $real_res[$i] ne $exp_res[$i];
    }
  return 0;
}

exit (test_cond_stack);
