# Copyright (C) 2001, 2002  Free Software Foundation, Inc.
#
# This file is part of GNU Automake.
#
# GNU Automake is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# GNU Automake is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with autoconf; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

use Automake::Conditional qw/TRUE FALSE/;
use Automake::ConditionalSet;

sub test_basics ()
{
  my $cond = new Automake::Conditional "COND1_TRUE", "COND2_FALSE";
  my $other = new Automake::Conditional "COND3_FALSE";
  my $set1 = new Automake::ConditionalSet $cond, $other;
  my $set2 = new Automake::ConditionalSet $other, $cond;
  return 1 unless $set1 == $set2;
  return 1 if $set1->false;
  return 1 if $set1->true;
  return 1 unless (new Automake::ConditionalSet)->false;
  return 1 if (new Automake::ConditionalSet)->true;
}

sub build_set (@)
{
  my @conds = @_;
  my @set = ();
  for my $cond (@conds)
    {
      push @set, new Automake::Conditional @$cond;
    }
  return new Automake::ConditionalSet @set;
}

sub test_permutations ()
{
  my @tests = ([[["FALSE"]],
	        [["TRUE"]]],

	       [[["TRUE"]],
	        [["TRUE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["COND3_FALSE", "COND2_TRUE"]],
		[["COND1_FALSE","COND2_FALSE","COND3_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE","COND3_FALSE"],
		 ["COND1_FALSE","COND2_TRUE", "COND3_FALSE"],
		 ["COND1_TRUE", "COND2_TRUE", "COND3_FALSE"],
		 ["COND1_FALSE","COND2_FALSE","COND3_TRUE"],
		 ["COND1_TRUE", "COND2_FALSE","COND3_TRUE"],
		 ["COND1_FALSE","COND2_TRUE", "COND3_TRUE"],
		 ["COND1_TRUE", "COND2_TRUE", "COND3_TRUE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["TRUE"]],
		[["COND1_TRUE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["FALSE"]],
		[["COND1_TRUE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE"]]],

	       [[["COND1_TRUE"],
		 ["COND2_FALSE"]],
		[["COND1_TRUE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE"]]]
	       );

  for my $t (@tests)
    {
      my $set = build_set @{$t->[0]};
      my $res = build_set @{$t->[1]};
      my $per = $set->permutations;
      if ($per != $res)
	{
	  print $per->string . ' != ' . $res->string . "\n";
	  return 1;
	}
    }
  return 0;
}

sub test_invert ()
{
  my @tests = ([[["FALSE"]],
	        [["TRUE"]]],

	       [[["TRUE"]],
	        [["FALSE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["COND3_FALSE", "COND2_TRUE"]],
		[["COND1_FALSE","COND2_FALSE","COND3_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE","COND3_FALSE"],
		 ["COND1_FALSE","COND2_FALSE","COND3_TRUE"],
		 ["COND1_TRUE", "COND2_FALSE","COND3_TRUE"],
		 ["COND1_FALSE","COND2_TRUE", "COND3_TRUE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["TRUE"]],
		[["FALSE"]]],

	       [[["COND1_TRUE", "COND2_TRUE"],
		 ["FALSE"]],
		[["COND1_FALSE", "COND2_TRUE"],
		 ["COND1_FALSE", "COND2_FALSE"],
		 ["COND1_TRUE", "COND2_FALSE"]]],

	       [[["COND1_TRUE"],
		 ["COND2_FALSE"]],
		[["COND1_FALSE", "COND2_TRUE"]]]
	       );

  for my $t (@tests)
    {
      my $set = build_set @{$t->[0]};
      my $res = build_set @{$t->[1]};
      my $inv = $set->invert;
      if ($inv != $res)
	{
	  print $inv->string . ' != ' . $res->string . "\n";
	  return 1;
	}
    }
  return 0;
}

exit (test_basics || test_permutations || test_invert);

### Setup "GNU" style for perl-mode and cperl-mode.
## Local Variables:
## perl-indent-level: 2
## perl-continued-statement-offset: 2
## perl-continued-brace-offset: 0
## perl-brace-offset: 0
## perl-brace-imaginary-offset: 0
## perl-label-offset: -2
## cperl-indent-level: 2
## cperl-brace-offset: 0
## cperl-continued-brace-offset: 0
## cperl-label-offset: -2
## cperl-extra-newline-before-brace: t
## cperl-merge-trailing-else: nil
## cperl-continued-statement-offset: 2
## End:
