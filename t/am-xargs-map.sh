#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
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

# Test Automake internal function 'am.xargs-map', in several usage
# scenarios.

am_create_testdir=empty
. ./defs || exit 1

# Filter out Automake comments.
grep -v '^##' "$am_amdir"/header-vars.am > defn.mk \
  || fatal_ "fetching makefile fragment headers-vars.am"

sed 's/^[0-9][0-9]*:://' > Makefile << 'END'
01::include ./defn.mk
02::
03::args1  := 0 1 2 3 4 5 6 7 8 9
04::args2  := $(args1) $(args1)
05::args4  := $(args2) $(args2)
06::args8  := $(args4) $(args4)
07::args16 := $(args8) $(args8)
08::
09::WARN := no
10::ifeq ($(WARN),yes)
11::  $(call am.xargs-map,warning,$(args16))
12::  $(call am.xargs-map,warning,$(args16) 0 1 2 3)
13::  $(call am.xargs-map,warning,x y z)
14::endif

args32 := $(args16) $(args16)
args64 := $(args32) $(args32)

bar = test '$1' = '$(args4)'$(am.chars.newline)
test-xargs-map:
	$(call am.xargs-map,bar,$(args16))

args = $(error 'args' should be overridden from the command line)
foo = @echo $1$(am.chars.newline)
echo-xargs-map:
	$(call am.xargs-map,foo,$(args))
END

args1="0 1 2 3 4 5 6 7 8 9"
args2="$args1 $args1"
args4="$args2 $args2"

$MAKE .am/nil WARN=yes 2>stderr || { cat stderr >&2; exit 1; }
cat stderr >&2
grep '^Makefile:' stderr # For debugging
test $(grep -c "^Makefile:11: $args4$" stderr) -eq 4
test $(grep -c "^Makefile:12: $args4$" stderr) -eq 4
test $(grep -c "^Makefile:12: 0 1 2 3$" stderr) -eq 1
test $(grep -c "^Makefile:13: x y z$" stderr) -eq 1
test $(grep -c "^Makefile:" stderr) -eq 10

$MAKE 'test-xargs-map'

check_echo ()
{
  cat > exp
  $MAKE --no-print-directory "echo-xargs-map" args="$1" >got \
    || { cat got >&2; exit 1; }
  cat exp && cat got && diff exp got || exit 1
}

echo "$args1" | check_echo '$(args1)'
echo "$args2" | check_echo '$(args2)'
echo "$args4" | check_echo '$(args4)'

check_echo '$(args8)'<<END
$args4
$args4
END

check_echo "$args4 $args4" <<END
$args4
$args4
END

check_echo "$args4 $args4 x" <<END
$args4
$args4
x
END

check_echo "$args4 01 02 03 04 05 06 07" <<END
$args4
01 02 03 04 05 06 07
END

check_echo '$(args32) 11 12 13 67' <<END
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
11 12 13 67
END

check_echo '$(args64)' <<END
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
$args4
END

:
