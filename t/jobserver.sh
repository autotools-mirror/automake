#! /bin/sh
# Copyright (C) 2026 Free Software Foundation, Inc.
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

# Compilers and linkers can inherit the pipe jobserver without running
# under make -n, -q, or -t (bug#45756).

required='cc GNUmake libtoolize'
. test-init.sh

cat >> configure.ac <<'END'
AC_PROG_CC
AM_PROG_AR
LT_INIT
AC_OUTPUT
END

cat > Makefile.am <<'END'
bin_PROGRAMS = foo bar
foo_SOURCES = foo.c
bar_SOURCES = foo.c
bar_CFLAGS = $(AM_CFLAGS)
noinst_LTLIBRARIES = libfoo.la
libfoo_la_SOURCES = foo.c
libfoo_la_CFLAGS = $(AM_CFLAGS)
END

echo 'int main (void) { return 0; }' > foo.c

# Check the descriptors themselves, independently of compiler LTO support.
cat > check-jobserver.c <<'END'
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
int main (void)
{
  const char *flags = getenv ("MAKEFLAGS");
  const char *p;
  int r, w;
  if (!flags) return 1;
  p = strstr (flags, "--jobserver-auth=");
  if (!p) p = strstr (flags, "--jobserver-fds=");
  if (!p || sscanf (strchr (p, '=') + 1, "%d,%d", &r, &w) != 2)
    return 1;
  return fcntl (r, F_GETFD) < 0 || fcntl (w, F_GETFD) < 0;
}
END
$CC -o check-jobserver check-jobserver.c

cat > cc-wrapper <<'END'
#!/bin/sh
./check-jobserver || exit 99
echo invoked >> compiler.log
exec "$@"
END

cat > lt-wrapper <<'END'
#!/bin/sh
./check-jobserver || exit 99
echo invoked >> libtool.log
exec "$@"
END

libtoolize
$ACLOCAL
$AUTOCONF
$AUTOMAKE -a

# GNU make 4.4 defaults to a FIFO, which does not need inherited fds.
# Force the pipe jobserver there; older versions already use pipes.
run_make -O -- --help
jobserver_style=
if grep 'jobserver-style' stdout; then
  jobserver_style=--jobserver-style=pipe
fi

for deps in none fast slow; do
  case $deps in
    none) ./configure --enable-jobserver --disable-dependency-tracking;;
    fast) ./configure --enable-jobserver --enable-dependency-tracking;;
    slow) ./configure --enable-jobserver --enable-dependency-tracking \
            am_cv_CC_dependencies_compiler_type=gcc;;
  esac
  for verbosity in 0 1; do
    rm -f compiler.log libtool.log
    run_make -M -j2 $jobserver_style V=$verbosity CC="$SHELL ./cc-wrapper $CC" \
      LIBTOOL="$SHELL ./lt-wrapper $SHELL ./libtool"
    test $(wc -l < compiler.log) -ge 5
    test $(wc -l < libtool.log) -eq 4
    run_make clean

    for mode in -n -q -t -kn -kq -kt; do
      rm -f compiler.log libtool.log
      run_make -M -e IGNORE -j2 $jobserver_style $mode V=$verbosity \
        CC="$SHELL ./cc-wrapper $CC" \
        LIBTOOL="$SHELL ./lt-wrapper $SHELL ./libtool"
      case $mode in
        *q) test "$am_make_rc" -eq 1;;
        *) test "$am_make_rc" -eq 0;;
      esac
      test ! -e libtool.log
      test ! -e compiler.log
      run_make clean
    done
  done
done

for option in '' --disable-jobserver; do
  ./configure $option
  # Default configuration leaves compiler recipes non-recursive.
  run_make -M -e FAIL -j2 $jobserver_style CC="$SHELL ./cc-wrapper $CC"
done

# Under .ONESHELL, only the first recipe line controls jobserver access.
# GNU make must recognize SHELL as a POSIX shell to remove internal
# recipe prefixes.  Preserve CONFIG_SHELL's checks (in particular those
# of shell-no-trail-bslash), but give it a recognized basename.
mkdir test-shell
cp "${CONFIG_SHELL:-$SHELL}" test-shell/sh
chmod +x test-shell/sh
cat >> Makefile.am <<'END'
.ONESHELL:
SHELL = $(abs_builddir)/test-shell/sh
END
$AUTOMAKE
./configure --enable-jobserver
run_make clean
run_make -M -j2 $jobserver_style CC="$SHELL ./cc-wrapper $CC" \
  LIBTOOL="$SHELL ./lt-wrapper $SHELL ./libtool"
run_make clean
for mode in -n -q -t; do
  rm -f compiler.log libtool.log
  run_make -M -e IGNORE -j2 $jobserver_style $mode \
    CC="$SHELL ./cc-wrapper $CC" \
    LIBTOOL="$SHELL ./lt-wrapper $SHELL ./libtool"
  case $mode in
    -q) test "$am_make_rc" -eq 1;;
    *) test "$am_make_rc" -eq 0;;
  esac
  test ! -e libtool.log
  test ! -e compiler.log
  run_make clean
done

./configure --enable-jobserver=invalid && exit 1

:
