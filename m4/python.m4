## ------------------------
## Python file handling
## From Andrew Dalke
## ------------------------

# AM_PATH_PYTHON([package, module])
# 

# Adds support for distributing Python modules or the special form
# of a module called a `package.'  Modules of the first type are 
# files ending in `.py' with no '__init__.py' file.  This must be
# placed on the PYTHONPATH, and the default location is PYTHON_SITE,
# or $(prefix)/lib/python$(PYTHON_VERSION)/site-package
# 
# A package module is contained in its own directory.  This directory
# is named PACKAGE, which was the name given to automake.  The full
# directory path is PYTHON_SITE_PACKAGE or
#   $(prefix)/lib/python$(PYTHON_VERSION)/site-package/$(PACKAGE)
# where site-package is on the PYTHONPATH.  The `__init__.py' file is
# located in the directory, along with any other submodules which may
# be necessary.


AC_DEFUN([AM_PATH_PYTHON],
 [
  dnl Find a version of Python.  I could check for python versions 1.4
  dnl or earlier, but the default installation locations changed from
  dnl $prefix/lib/site-python in 1.4 to $prefix/lib/python1.5/site-packages
  dnl in 1.5, and I don't want to maintain that logic.

  AC_PATH_PROG(PYTHON, python python1.5)

  AC_MSG_CHECKING([local Python configuration])

  dnl Query Python for its version number.  Getting [:3] seems to be
  dnl the best way to do this; it's what "site.py" does in the standard
  dnl library.  Need to change quote character because of [:3]

  AC_SUBST(PYTHON_VERSION)
  changequote(<<, >>)dnl
  PYTHON_VERSION=`$PYTHON -c "import sys; print sys.version[:3]"`
  changequote([, ])dnl


  dnl Use the values of $prefix and $exec_prefix for the corresponding
  dnl values of PYTHON_PREFIX and PYTHON_EXEC_PREFIX.  These are made
  dnl distinct variables so they can be overridden if need be.  However,
  dnl general consensus is that you shouldn't need this ability.

  AC_SUBST(PYTHON_PREFIX)
  PYTHON_PREFIX='${prefix}'

  AC_SUBST(PYTHON_EXEC_PREFIX)
  PYTHON_EXEC_PREFIX='${exec_prefix}'

  dnl At times (like when building shared libraries) you may want
  dnl to know which OS platform Python thinks this is.

  AC_SUBST(PYTHON_PLATFORM)
  PYTHON_PLATFORM=`$PYTHON -c "import sys; print sys.platform"`


  dnl Set up 4 directories:

  dnl   pythondir -- location of the standard python libraries 
  dnl     Also lets automake think PYTHON means something.

  AC_SUBST(pythondir)
  pythondir=$PYTHON_PREFIX"/lib/python"$PYTHON_VERSION

  dnl   PYTHON_SITE -- the platform independent site-packages directory

  AC_SUBST(PYTHON_SITE)
  PYTHON_SITE=$pythondir/site-packages

  dnl   PYTHON_SITE_PACKAGE -- the $PACKAGE directory under PYTHON_SITE

  AC_SUBST(PYTHON_SITE_PACKAGE)
  PYTHON_SITE_PACKAGE=$pythondir/site-packages/$PACKAGE

  dnl   PYTHON_SITE_EXEC -- platform dependent site-packages dir (eg, for
  dnl        shared libraries)

  AC_SUBST(PYTHON_SITE_EXEC)
  PYTHON_SITE_EXEC=$PYTHON_EXEC_PREFIX"/lib/python"$PYTHON_VERSION/site-packages


  dnl Configure PYTHON_SITE_INSTALL so it points to either the module
  dnl directory or the package subdirectory, depending on the $1
  dnl parameter ("module" or "package").

  AC_SUBST(PYTHON_SITE_INSTALL)
  ifelse($1, module, [PYTHON_SITE_INSTALL=$PYTHON_SITE],
         $1, package, [PYTHON_SITE_INSTALL=$PYTHON_SITE_PACKAGE],
   [errprint([Unknown option `$1' used in call to AM_PATH_PYTHON.
Valid options are `module' or `package'
])m4exit(4)])


  dnl All done.

  AC_MSG_RESULT(looks good)
])
