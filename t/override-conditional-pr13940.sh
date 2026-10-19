#! /bin/sh
# Copyright (C) 2013-2026 Free Software Foundation, Inc.
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

# Repeated target declarations may add prerequisites in overlapping
# conditions, in either order (bug#13940).

. test-init.sh

cat >> configure.ac << 'END'
AM_CONDITIONAL([FOO], [test "$foo" = yes])
AM_CONDITIONAL([BAR], [test "$bar" = yes])
AC_OUTPUT
END

cat > Makefile.am << 'END'
if FOO
all-local: conditional
forward: conditional
.PHONY: conditional
if BAR
nested: both
endif
endif
all-local: always forward reverse nested overlap
forward: always
reverse: always
nested: always
overlap: always
.PHONY: always forward reverse nested overlap both
if FOO
reverse: conditional
overlap: conditional
endif
if BAR
overlap: other
endif
always conditional both other:
	@echo $@ >> seen
END

$ACLOCAL
$AUTOMAKE -a -Werror
$AUTOCONF

for foo in yes no; do
  for bar in yes no; do
    ./configure foo=$foo bar=$bar
    rm -f seen
    $MAKE all
    echo always > expected
    if test "$foo" = yes; then
      echo conditional >> expected
      if test "$bar" = yes; then
        echo both >> expected
      fi
    fi
    if test "$bar" = yes; then
      echo other >> expected
    fi
    sort seen > seen.sorted
    sort expected > expected.sorted
    diff expected.sorted seen.sorted
  done
done

# Adding prerequisites before or after a recipe is also legitimate.
cat > Makefile.am << 'END'
if FOO
first: conditional
last:
	@echo last >> seen
endif
first:
	@echo first >> seen
last: always
all-local: first last
always conditional:
	@echo $@ >> seen
.PHONY: first last always conditional
END

$AUTOMAKE -Werror
for foo in yes no; do
  ./configure foo=$foo bar=no
  rm -f seen
  $MAKE all
  echo always > expected
  echo first >> expected
  if test "$foo" = yes; then
    echo conditional >> expected
    echo last >> expected
  fi
  sort seen > seen.sorted
  sort expected > expected.sorted
  diff expected.sorted seen.sorted
done

# Only actual recipes conflict.  A semicolon in a comment, an escaped
# filename, or a variable reference must not turn prerequisites into one.
cat > Makefile.am << 'END'
if FOO
comment: dep # ; not a recipe
escaped: dep\;name
reference: $(subst ;,x,dep)
short: $;
continued: \
  dep
endif
comment: ; :
escaped: ; :
reference: ; :
short: ; :
continued: ; :
END
$AUTOMAKE -Werror -Wno-portability

# Diagnose real conditional recipe overrides in either declaration order.
# Include empty inline recipes and recipes on continued dependency lines.
for style in tab inline empty continued included; do
  case $style in
    tab) printf 'clash:\n\t:\n\t:\n' > recipe ;;
    inline) echo 'clash: ; :' > recipe ;;
    empty) echo 'clash: ;' > recipe ;;
    continued) printf 'clash: \\\n; :\n' > recipe ;;
    included)
      printf 'clash:\ninclude commands.am\n' > recipe
      printf '\t:\n' > commands.am
      ;;
  esac
  for order in before after; do
    echo 'clash: ; :' > unconditional
    {
      if test "$order" = before; then
        cat unconditional
      fi
      echo 'if FOO'
      cat recipe
      echo endif
      if test "$order" = after; then
        cat unconditional
      fi
    } > Makefile.am
    AUTOMAKE_fails
    test $(grep -c 'clash was already defined in condition' stderr) -eq 1
    grep "'clash' previously defined here" stderr
  done
done

# Separate conditional pieces of the same recipe are not overrides.
cat > Makefile.am << 'END'
whole:
	:
if FOO
	:
endif
	:
END
$AUTOMAKE -Werror

:
