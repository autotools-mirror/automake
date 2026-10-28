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

# The tar-ustar and tar-pax checks must keep accepting non-GNU tars that
# understand --format=, such as bsdtar, while skipping BusyBox tar, which
# answers --version like GNU tar but lacks --format= (bug#81303).

. test-init.sh

real_tar=$(command -v tar) || skip_ "tar not found"
case $("$real_tar" --version 2>/dev/null) in
  *GNU*) ;;
  *) skip_ "the real tar is not GNU tar";;
esac

mkdir bsd busybox both
# A bsdtar look-alike: identifies itself differently, but supports --format=.
cat > bsd/tar <<END
#! /bin/sh
case \$1 in --version) echo 'bsdtar 3.7.4 - libarchive 3.7.4'; exit 0;; esac
exec '$real_tar' "\$@"
END
# A BusyBox look-alike: GNU-like --version, no --format=.
cat > busybox/tar <<END
#! /bin/sh
case \$1 in
  --version) echo 'tar (busybox) 1.38.0'; exit 0;;
  --format=*) echo "tar: unrecognized option '\$1'" >&2; exit 1;;
esac
exec '$real_tar' "\$@"
END
cp busybox/tar both/tar
cat > both/gtar <<END
#! /bin/sh
exec '$real_tar' "\$@"
END
chmod a+x bsd/tar busybox/tar both/tar both/gtar
for d in bsd busybox both; do
  eval "path_$d=\$(pwd)/$d\$PATH_SEPARATOR\$PATH"
done

cat > configure.ac <<END
AC_INIT([$me], [1.0])
AM_INIT_AUTOMAKE([tar-ustar])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
END
: > Makefile.am

$ACLOCAL
$AUTOCONF
$AUTOMAKE

check_tar ()
{
  PATH=$1 ./configure --cache-file=/dev/null
  grep '^am__tar =' Makefile
  grep "^am__tar = $2" Makefile
}

check_tar "$path_bsd" 'tar --format=ustar '
PATH=$path_bsd $MAKE distcheck
check_tar "$path_busybox" 'tar chf '
PATH=$path_busybox $MAKE distcheck
check_tar "$path_both" 'gtar --format=ustar '

sed 's/tar-ustar/tar-pax/' configure.ac > t
mv -f t configure.ac
$AUTOCONF --force
$AUTOMAKE

check_tar "$path_bsd" 'tar --format=posix '
check_tar "$path_both" 'gtar --format=posix '
PATH=$path_both $MAKE distcheck

:
