dnl Generate code to set up dependency tracking.
dnl This macro should only be invoked once -- use via AC_REQUIRE.
dnl Usage:
dnl AM_OUTPUT_DEPENDENCY_COMMANDS

dnl
dnl This code is only required when automatic dependency tracking
dnl is enabled.  FIXME.  This creates each `.P' file that we will
dnl need in order to bootstrap the dependency handling code.
AC_DEFUN(AM_OUTPUT_DEPENDENCY_COMMANDS,[
AC_OUTPUT_COMMANDS([
find . -name Makefile -print | while read mf; do
  # Extract the definition of DEP_FILES from the Makefile without
  # running `make'.
  DEPDIR=`sed -n -e '/^DEPDIR = / s///p' $mf`
  # We invoke sed twice because it is the simplest approach to
  # changing $(DEPDIR) to its actual value in the expansion.
  deps="`sed -n -e '
    /^DEP_FILES = .*\\\\$/ {
      s/^DEP_FILES = //
      :loop
	s/\\\\$//
	p
	n
	/\\\\$/ b loop
      p
    }
    /^DEP_FILES = / s/^DEP_FILES = //p' $mf | \
       sed -e 's/\$(DEPDIR)/'"$DEPDIR"'/g'`"
  # If we found a definition, proceed to create all the files.
  if test -n "$deps"; then
    dirpart="`echo $mf | sed -e 's|/[^/]*$||'`"
    test -d "$dirpart/$DEPDIR" || mkdir "$dirpart/$DEPDIR"
    case "$deps" in
    *'$U'*) # When using ansi2knr, U may be empty or an underscore; expand it
	U=`sed -n -e '/^U = / s///p' $mf`
	deps=`echo "$deps" | sed 's/\$U/'"$U"'/g'`
	;;
    esac	
    for file in $deps; do
      if test ! -f "$dirpart/$file"; then
	echo "creating $dirpart/$file"
	echo '# dummy' > "$dirpart/$file"
      fi
    done
  fi
done])])
