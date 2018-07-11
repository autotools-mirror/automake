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

my @test_vars = qw (FOO BAR BAZ TEST);


sub test_verbose_flag
{
  my @res = map { verbose_flag $_ } @test_vars;
  print "Test verbose_flag:\n";
  print "Variable names: @test_vars\n";
  print "Result: @res\n\n";
  for my $i (0 .. $#res)
    {
      return 1
          unless $res[$i] eq '$(AM_V_' . $test_vars[$i] . ')';
    }
  return 0;
}


sub test_verbose_nodep_flag
{
  my @res = map { verbose_nodep_flag $_ } @test_vars;
  print "Test verbose_nodep_flag:\n";
  print "Variable names: @test_vars\n";
  print "Result: @res\n\n";
  for my $i (0 .. $#res)
    {
      return 1
          unless $res[$i] eq '$(AM_V_' . $test_vars[$i] . '@am__nodep@)';
    }
  return 0;
}


sub test_silent_flag
{
  return 1 
      unless silent_flag eq '$(AM_V_at)';
  print "silent_flag: OK\n\n";
  return 0;
}


exit (test_verbose_flag | test_verbose_nodep_flag | test_silent_flag);
