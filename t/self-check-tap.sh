#! /bin/sh
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

# Sanity check for the automake testsuite.
# Make sure that '$am_test_protocol' gets automatically defined by
# 'test-defs.sh', but can be overridden by the individual tests.

. test-defs.sh

set -ex

$AM_TEST_RUNNER_SHELL -c \
  ". test-defs.sh && test \$am_test_protocol = tap" foo.tap

for name in foo.test tap tap.test foo-tap; do
  $AM_TEST_RUNNER_SHELL -c \
    ". test-defs.sh && test \$am_test_protocol = none" $name
done

$AM_TEST_RUNNER_SHELL -c "
  am_test_protocol=none
  . test-defs.sh
  test \$am_test_protocol = none
" foo.tap

$AM_TEST_RUNNER_SHELL -c "
  am_test_protocol=tap
  . test-defs.sh
  test \$am_test_protocol = tap
" foo.test

:
