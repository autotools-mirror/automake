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

# Check that python support can work well with virtualenvs.
# This test also works as a mild stress-test on the python support.

required='cc python virtualenv'
. ./defs || Exit 1

# In case the user's config.site defines pythondir or pyexecdir.
CONFIG_SITE=/dev/null; export CONFIG_SITE

# Skip the test if a proper virtualenv cannot be created.
virtualenv --verbose virtenv && test -f virtenv/bin/activate \
  || skip_ "coulnd't create python virtual environment"

# Activate the virtualenv.
. ./virtenv/bin/activate
# Sanity check.
if test -z "$VIRTUAL_ENV"; then
  framework_failure_ "can't activate python virtual environment"
fi

cwd=`pwd`
py_version=`python -c 'import sys; print("%u.%u" % tuple(sys.version_info[:2]))'`
py_site=$VIRTUAL_ENV/lib/python$py_version/site-packages

# We need control over the package name.
cat > configure.ac << END
AC_INIT([am_virtenv], [1.0])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
AC_SUBST([MY_VIRTENV], ['$cwd/virtenv'])
AC_PROG_CC
AM_PROG_AR
AC_PROG_RANLIB
AM_PATH_PYTHON
AC_OUTPUT
END

cat > Makefile.am << 'END'
python_PYTHON = am_foo.py
pkgpython_PYTHON = __init__.py
pyexec_LIBRARIES = libquux.a
libquux_a_SOURCES = foo.c
pkgpyexec_LIBRARIES = libzardoz.a
libzardoz_a_SOURCES = foo.c

py_site = $(MY_VIRTENV)/lib/python$(PYTHON_VERSION)/site-packages

.PYTHON: debug test-run test-install test-uninstall
debug:
	@echo PYTHON: $(PYTHON)
	@echo PYTHON_VERSION: $(PYTHON_VERSION)
	@echo prefix: $(prefix)
	@echo pythondir: $(pythondir)
	@echo pkgpythondir: $(pkgpythondir)
	@echo pyexecdir: $(pyexecdir)
	@echo pkgpyexecdir: $(pkgpyexecdir)
test-run:
	## In a virtualenv, the default python must be the custom
	## virtualenv python.
	@: \
	  && py1=`python -c 'import sys; print(sys.executable)'` \
	  && py2=`$(PYTHON) -c 'import sys; print(sys.executable)'` \
	  && echo "py1: $$py1" \
	  && echo "py2: $$py2" \
	  && test -n "$$py1" \
	  && test -n "$$py2" \
	  && test x"$$py1" = x"$$py2"
	## Check that modules installed in the virtualenv are readily
	## available.
	python -c 'from am_foo import foo_func; assert (foo_func () == 12345)'
	python -c 'from am_virtenv import old_am; assert (old_am () == "AutoMake")'
test-install:
	test -f $(py_site)/am_foo.py
	test -f $(py_site)/am_foo.pyc
	test -f $(py_site)/am_foo.pyo
	test -f $(py_site)/am_virtenv/__init__.py
	test -f $(py_site)/am_virtenv/__init__.pyc
	test -f $(py_site)/am_virtenv/__init__.pyo
	test -f $(py_site)/libquux.a
	test -f $(py_site)/am_virtenv/libzardoz.a
test-uninstall:
	test ! -f $(py_site)/am_foo.py
	test ! -f $(py_site)/am_foo.pyc
	test ! -f $(py_site)/am_foo.pyo
	test ! -f $(py_site)/am_virtenv/__init__.py
	test ! -f $(py_site)/am_virtenv/__init__.pyc
	test ! -f $(py_site)/am_virtenv/__init__.pyo
	test ! -f $(py_site)/libquux.a
	test ! -f $(py_site)/am_virtenv/libzardoz.a
all-local: debug
END

cat > am_foo.py << 'END'
def foo_func ():
    return 12345
END

cat > __init__.py << 'END'
def old_am ():
    return 'AutoMake'
END

cat > foo.c << 'END'
int foo (void)
{
  return 0;
}
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE --add-missing

# Try a VPATH build.
mkdir build
cd build
../configure --prefix="$VIRTUAL_ENV"
$MAKE install
$MAKE test-install
$MAKE test-run
$MAKE uninstall
$MAKE test-uninstall
cd ..

# Try an in-tree build.
./configure --prefix="$VIRTUAL_ENV"
$MAKE install
$MAKE test-install
$MAKE test-run
$MAKE uninstall
$MAKE test-uninstall

$MAKE distclean

# Overriding pythondir and pyexecdir with cache variables should work.
./configure am_cv_python_pythondir="$py_site" \
            am_cv_python_pyexecdir="$py_site"
$MAKE install
$MAKE test-install
$MAKE test-run
$MAKE uninstall
$MAKE test-uninstall

$MAKE distclean

# Overriding pythondir and pyexecdir at make time should be enough.
./configure --prefix="$cwd/bad-prefix"
pythondir=$py_site pyexecdir=$py_site
export pythondir pyexecdir
$MAKE -e install
test ! -d bad-prefix
$MAKE -e test-install
$MAKE test-run
$MAKE -e uninstall
$MAKE -e test-uninstall
unset pythondir pyexecdir

# Also check that the distribution is self-contained, for completeness.
$MAKE distcheck

# Finally, check that if we disable the virtualenv, we shouldn't be
# able to access to the installed modules anymore.
cd build
$MAKE install
python -c 'import am_foo; print(am_foo.__file__)'
python -c 'import am_virtenv; print(am_virtenv.__file__)'
deactivate "nondestructive"
python -c 'import am_foo' && Exit 1
python -c 'import am_virtenv' && Exit 1

:
