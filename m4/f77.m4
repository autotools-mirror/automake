dnl ########################### -*- Mode: M4 -*- ##############################
dnl am_f77.m4 -- Determine the linker flags (e.g. `-L' and `-l') for
dnl               the Fortran 77 intrinsic and run-time libraries that
dnl               are required to successfully link a Fortran 77 program
dnl               or shared library.
dnl 
dnl Copyright (C) 1998 Matthew D. Langston <langston@SLAC.Stanford.EDU>
dnl
dnl This file is free software; you can redistribute it and/or modify it
dnl under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 2 of the License, or
dnl (at your option) any later version.
dnl
dnl This file is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with this file; if not, write to:
dnl
dnl   Free Software Foundation, Inc.
dnl   Suite 330
dnl   59 Temple Place
dnl   Boston, MA 02111-1307, USA.
dnl ###########################################################################


dnl Determine the linker flags (e.g. `-L' and `-l') for the Fortran 77
dnl intrinsic and run-time libraries that are required to successfully
dnl link a Fortran 77 program or shared library.  The output variable
dnl FLIBS is set to these flags.
dnl 
dnl This macro is intended to be used in those situations when it is
dnl necessary to mix, e.g. C++ and Fortran 77 source code into a single
dnl program or shared library.
dnl 
dnl For example, if object files from a C++ and Fortran 77 compiler must
dnl be linked together, then the C++ compiler/linker must be used for
dnl linking (since special C++-ish things need to happen at link time
dnl like calling global constructors, instantiating templates, enabling
dnl exception support, etc.).
dnl 
dnl However, the Fortran 77 intrinsic and run-time libraries must be
dnl linked in as well, but the C++ compiler/linker doesn't know how to
dnl add these Fortran libraries.  Hence, the macro
dnl `AM_F77_LIBRARY_LDFLAGS' was created to determine these Fortran 77
dnl libraries.
dnl
dnl Nearly all of this macro came from the `OCTAVE_FLIBS' macro in
dnl `octave-2.0.13/aclocal.m4', and full credit should go to John
dnl W. Eaton for writing this extremely useful macro.  Thank you John.
dnl
dnl AM_F77_LIBRARY_LDFLAGS()
AC_DEFUN([AM_F77_LIBRARY_LDFLAGS],
[AC_MSG_CHECKING([for Fortran libraries])
AC_REQUIRE([AC_PROG_FC])
AC_REQUIRE([AC_CANONICAL_HOST])
AC_CACHE_VAL(am_cv_flibs,
[changequote(, )dnl
dnl Write a minimal program and compile it with -v.  I don't know what
dnl to do if your compiler doesn't have -v...
echo "      END" > conftest.f
foutput=`${FC} -v -o conftest conftest.f 2>&1`
dnl
dnl The easiest thing to do for xlf output is to replace all the commas
dnl with spaces.  Try to only do that if the output is really from xlf,
dnl since doing that causes problems on other systems.
dnl
xlf_p=`echo $foutput | grep xlfentry`
if test -n "$xlf_p"; then
  foutput=`echo $foutput | sed 's/,/ /g'`
fi
dnl
ld_run_path=`echo $foutput | \
  sed -n -e 's/^.*LD_RUN_PATH *= *\([^ ]*\).*/\1/p'`
dnl
dnl We are only supposed to find this on Solaris systems...
dnl Uh, the run path should be absolute, shouldn't it?
dnl
case "$ld_run_path" in
  /*)
    if test "$ac_cv_prog_gcc" = yes; then
      ld_run_path="-Xlinker -R -Xlinker $ld_run_path"
    else
      ld_run_path="-R $ld_run_path"
    fi
  ;;
  *)
    ld_run_path=
  ;;
esac
dnl
flibs=
lflags=
dnl
dnl If want_arg is set, we know we want the arg to be added to the list,
dnl so we don't have to examine it.
dnl
want_arg=
dnl
for arg in $foutput; do
  old_want_arg=$want_arg
  want_arg=
dnl
dnl None of the options that take arguments expect the argument to
dnl start with a -, so pretend we didn't see anything special.
dnl
  if test -n "$old_want_arg"; then
    case "$arg" in
      -*)
        old_want_arg=
      ;;
    esac
  fi
  case "$old_want_arg" in
    '')
      case $arg in
        /*.a)
          exists=false
          for f in $lflags; do
            if test x$arg = x$f; then
              exists=true
            fi
          done
          if $exists; then
            arg=
          else
            lflags="$lflags $arg"
          fi
        ;;
        -bI:*)
          exists=false
          for f in $lflags; do
            if test x$arg = x$f; then
              exists=true
            fi
          done
          if $exists; then
            arg=
          else
            if test "$ac_cv_prog_gcc" = yes; then
              lflags="$lflags -Xlinker $arg"
            else
              lflags="$lflags $arg"
            fi
          fi
        ;;
        -lang* | -lcrt0.o | -lc | -lgcc)
          arg=
        ;;
        -[lLR])
          want_arg=$arg
          arg=
        ;;
        -[lLR]*)
          exists=false
          for f in $lflags; do
            if test x$arg = x$f; then
              exists=true
            fi
          done
          if $exists; then
            arg=
          else
            case "$arg" in
              -lkernel32)
                case "$canonical_host_type" in
                  *-*-cygwin32)
                    arg=
                  ;;
                  *)
                    lflags="$lflags $arg"
                  ;;
                esac
              ;;
              -lm)
              ;;
              *)
                lflags="$lflags $arg"
              ;;
            esac
          fi
        ;;
        -u)
          want_arg=$arg
          arg=
        ;;
        -Y)
          want_arg=$arg
          arg=
        ;;
        *)
          arg=
        ;;
      esac
    ;;
    -[lLR])
      arg="$old_want_arg $arg"
    ;;
    -u)
      arg="-u $arg"
    ;;
    -Y)
dnl
dnl Should probably try to ensure unique directory options here too.
dnl This probably only applies to Solaris systems, and then will only
dnl work with gcc...
dnl
      arg=`echo $arg | sed -e 's%^P,%%'`
      SAVE_IFS=$IFS
      IFS=:
      list=
      for elt in $arg; do
        list="$list -L$elt"
      done
      IFS=$SAVE_IFS
      arg="$list"
    ;;
  esac
dnl
  if test -n "$arg"; then
    flibs="$flibs $arg"
  fi
done
if test -n "$ld_run_path"; then
  flibs_result="$ld_run_path $flibs"
else
  flibs_result="$flibs"
fi
changequote([, ])dnl
am_cv_flibs="$flibs_result"])
FLIBS="$am_cv_flibs"
AC_SUBST(FLIBS)dnl
AC_MSG_RESULT([$FLIBS])])
