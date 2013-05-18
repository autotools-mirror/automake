#!/usr/bin/env perl
# deltree: recursively removes file and directory,
# trying to handle permissions and other complications.

use strict;
use warnings FATAL => 'all';
use File::Path qw/rmtree/;

my $exit_status = 0;
local $SIG{__WARN__} = sub { warn "@_"; $exit_status = 1; };

foreach my $path (@ARGV) {
  local $@ = undef;
  rmtree ($path);
}

exit $exit_status;

# vim: ft=perl ts=4 sw=4 et
