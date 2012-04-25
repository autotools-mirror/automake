# -*- shell-script -*-
#
# Copyright (C) 2011-2012 Free Software Foundation, Inc.
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Helper functions used by "plain" tests of the Automake testsuite
# (i.e., tests that don't use any test protocol).

# Print warnings (e.g., about skipped and failed tests) to this file
# number.  Override by putting, say:
#   AM_TESTS_ENVIRONMENT = stderr_fileno_=9; export stderr_fileno_;
#   AM_TESTS_FD_REDIRECT = 9>&2
# in your Makefile.am.
# This is useful when using automake's parallel tests mode, to print the
# reason for skip/failure to console, rather than to the *.log files.
: ${stderr_fileno_=2}

# Copied from Gnulib's 'tests/init.sh'.
warn_ () { echo "$@" 1>&$stderr_fileno_; }
fail_ () { warn_ "$me: failed test: $@"; Exit 1; }
skip_ () { warn_ "$me: skipped test: $@"; Exit 77; }
fatal_ () { warn_ "$me: hard error: $@"; Exit 99; }
framework_failure_ () { warn_ "$me: set-up failure: $@"; Exit 99; }

# For compatibility with TAP functions.
skip_all_ () { skip_ "$@"; }

:
