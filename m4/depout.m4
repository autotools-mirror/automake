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
  # Extract the definition of DEP_FILES from the Makefile withou
  # running `make'.
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
    /^DEP_FILES = / s/^DEP_FILES = //p' $mf`"
  # If we found a definition, proceed to create all the files.
  if test -n "$deps"; then
    dirpart="`echo $mf | sed -e 's|/.*$||'`"
    test -d "$dirpart/.deps" || mkdir "$dirpart/.deps"
    for file in $deps; do
      test -f "$dirpart/$file" || : > "$dirpart/$file"
    done
  fi
done])])
