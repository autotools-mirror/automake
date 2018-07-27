# -*- mode: Perl -*-
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

use Automake::File;
use Automake::Global;
use Automake::Utils;
use Automake::XFile;
use Test::Simple tests => 1;

my %transform = (
  'DEFAULT_INCLUDES' => 'FOO',
  'MOSTLYRMS' => 'BAR',
  'DISTRMS' => 'BAZ');

# For this test we use $libdir/am/compile.am but it doesn't matter which file
# we use really.
my $file = 'DEFAULT_INCLUDES = %DEFAULT_INCLUDES%

mostlyclean-am: mostlyclean-compile
mostlyclean-compile:
	-rm -f *.$(OBJEXT)
?MOSTLYRMS?%MOSTLYRMS%

distclean-am: distclean-compile
distclean-compile:
	-rm -f *.tab.c
?DISTRMS?%DISTRMS%

.PHONY: mostlyclean-compile distclean-compile
';

my $expected_res =
'DEFAULT_INCLUDES = FOO  mostlyclean-am: mostlyclean-compile mostlyclean-compile:
	-rm -f *.$(OBJEXT) BAR  distclean-am: distclean-compile distclean-compile:
	-rm -f *.tab.c BAZ  .PHONY: mostlyclean-compile distclean-compile';

# The following may seem a bit familiar as it resembles the preprocess_file
# subroutine from $libdir/Automake/File.pm but since we use a string instead
# of a filename, we cannot use this function (which also would have side
# effects we don't really want)
my $fh = new Automake::XFile;
$fh->open (\$file, "<");

my $saved_dollar_slash = $/;
undef $/;
$_ = $fh->getline;
$/ = $saved_dollar_slash;
$fh->close;
# Remove ##-comments
s/(?:$IGNORE_PATTERN|(?<=\n\n)\n+)//gom;
# Substitute Automake template tokens.
s/(?: % \?? [\w\-]+ %
    | \? !? [\w\-]+ \?
    )/transform($&, %transform)/gex;
# transform() may have added some ##%-comments to strip.
# (we use '##%' instead of '##' so we can distinguish ##%##%##% from
# ####### and do not remove the latter.)
s/^[ \t]*(?:##%)+.*\n//gm;

my @paragraphs = make_paragraphs ($_);
print "$expected_res\n";
print "@paragraphs\n";
ok ("@paragraphs" eq "$expected_res", "make_paragraphs");
