## ------------------------
## Emacs LISP file handling
## From Ulrich Drepper
## ------------------------

# serial 1

AC_DEFUN(AM_PATH_LISPDIR,
 [# If set to t, that means we are running in a shell under Emacs.
  # If you have an Emacs named "t", then use the full path.
  test "$EMACS" = t && EMACS=
  AC_PATH_PROG(EMACS, emacs xemacs, no)
  if test $EMACS != "no"; then
    AC_MSG_CHECKING([where .elc files should go])
    dnl Set default value
    LISPDIR="\$(datadir)/emacs/site-lisp"
    if test "x$prefix" = "xNONE"; then
      if test -d $ac_default_prefix/share/emacs/site-lisp; then
	LISPDIR="\$(prefix)/share/emacs/site-lisp"
      else
	if test -d $ac_default_prefix/lib/emacs/site-lisp; then
	  LISPDIR="\$(prefix)/lib/emacs/site-lisp"
	fi
      fi
    else
      if test -d $prefix/share/emacs/site-lisp; then
	LISPDIR="\$(prefix)/share/emacs/site-lisp"
      else
	if test -d $prefix/lib/emacs/site-lisp; then
	  LISPDIR="\$(prefix)/lib/emacs/site-lisp"
	fi
      fi
    fi
    AC_MSG_RESULT($LISPDIR)
    ELCFILES="\$(ELCFILES)"
  fi
  AC_SUBST(LISPDIR)
  AC_SUBST(ELCFILES)])
