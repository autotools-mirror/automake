# -*- mode:perl -*-
# Copyright (C) 2002-2018 Free Software Foundation, Inc.
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

use Automake::Version;
use Test::Simple tests => 34;

sub test_version_compare
{
  my ($left, $right, $result) = @_;
  my @leftver = Automake::Version::split ($left);
  my @rightver = Automake::Version::split ($right);
  if ($#leftver == -1)
  {
    print "can't grok \"$left\"\n";
    return 1;
  }
  if ($#rightver == -1)
  {
    print "can't grok \"$right\"\n";
    return 1;
  }
  my $res = Automake::Version::compare (@leftver, @rightver);
  if ($res != $result)
  {
    print "compare (\"$left\", \"$right\") = $res! (not $result?)\n";
    return 1;
  }

  my $check_expected = ($result == 0 || $result == 1) ? 0 : 1;
  # Exception for 'foo' fork.
  $check_expected = 1
    if ($right =~ /foo/ && !($left =~ /foo/));

  my $check = Automake::Version::check ($left, $right);
  if ($check != $check_expected)
    {
      print "check (\"$left\", \"$right\") = $check! (not $check_expected?)\n";
      return 1;
    }
  return 0;
}

sub test_bad_versions
{
  my ($ver) = @_;
  my @version = Automake::Version::split ($ver);
  if ($#version != -1)
    {
      print "shouldn't grok \"$ver\"\n";
      return 1;
    }
  return 0;
}

sub test_bad_declarations
{
  eval { Automake::Version::check ('', '1.2.3') };

  warn $@ if $@;
  $failed = 1 unless $@;

  $@ = '';

  eval { Automake::Version::check ('1.2.3', '') };

  warn $@ if $@;
  return 1 unless $@;
  return 0;
}

ok (test_version_compare ('2.0', '1.0', 1) == 0, 'Test comparing versions basics 2');
ok (test_version_compare ('1.2', '1.2', 0) == 0, 'Test comparing versions basics 3');
ok (test_version_compare ('1.1', '1.2', -1) == 0, 'Test comparing versions basics 4');
ok (test_version_compare ('1.2', '1.1', 1) == 0, 'Test comparing versions basics 5');

ok (test_version_compare ('1.4', '1.4g', -1) == 0, 'Test comparing versions with alphas 1');
ok (test_version_compare ('1.4g', '1.5', -1) == 0, 'Test comparing versions with alphas 2');
ok (test_version_compare ('1.4g', '1.4', 1) == 0, 'Test comparing versions with alphas 3');
ok (test_version_compare ('1.5', '1.4g', 1) == 0, 'Test comparing versions with alphas 4');
ok (test_version_compare ('1.4a', '1.4g', -1) == 0, 'Test comparing versions with alphas 5');
ok (test_version_compare ('1.5a', '1.3g', 1) == 0, 'Test comparing versions with alphas 6');
ok (test_version_compare ('1.6a', '1.6a', 0) == 0, 'Test comparing versions with alphas 7');

ok (test_version_compare ('1.5.1', '1.5', 1) == 0, 'Test comparing versions micros 1');
ok (test_version_compare ('1.5.0', '1.5', 0) == 0, 'Test comparing versions micros 2');
ok (test_version_compare ('1.5.4', '1.6.1', -1) == 0, 'Test comparing versions micros 3');

ok (test_version_compare ('1.5a', '1.5.1', 1) == 0, 'Test comparing versions micros and alphas 1');
ok (test_version_compare ('1.5a', '1.5.1a', 1) == 0, 'Test comparing versions micros and alphas 2');
ok (test_version_compare ('1.5a', '1.5.1f', 1) == 0, 'Test comparing versions micros and alphas 3');
ok (test_version_compare ('1.5', '1.5.1a', -1) == 0, 'Test comparing versions micros and alphas 4');
ok (test_version_compare ('1.5.1a', '1.5.1f', -1) == 0, 'Test comparing versions micros and alphas 5');
ok (test_version_compare ('1.5.1f', '1.5.1a', 1) == 0, 'Test comparing versions micros and alphas 6');
ok (test_version_compare ('1.5.1f', '1.5.1f', 0) == 0, 'Test comparing versions micros and alphas 7');

ok (test_version_compare ('1.6-p5a', '1.6.5a', 0) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6', '1.6-p5a', -1) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6-p4b', '1.6-p5a', -1) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6-p4b', '1.6-foo', 1) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6-p4b', '1.6a-foo', -1) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6-p5', '1.6.5', 0) == 0, 'Test comparing versions special exceptions 1');
ok (test_version_compare ('1.6a-foo', '1.6a-foo', 0) == 0, 'Test comparing versions special exceptions 1');

ok (test_bad_versions ('') == 0, 'Test bad version numbers empty str');
ok (test_bad_versions ('a') == 0, 'Test bad version numbers only alpha');
ok (test_bad_versions ('1') == 0, 'Test bad version numbers only major');
ok (test_bad_versions ('1a') == 0, 'Test bad version numbers only major with alpha');
ok (test_bad_versions ('1.2.3.4') == 0, 'Test bad version numbers to many minor versions');
ok (test_bad_versions ('-1.2') == 0, 'Test bad version numbers negative');
