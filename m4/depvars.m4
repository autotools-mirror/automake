dnl Set some convenience variables used by dependency tracking.
dnl These variables have the same (complicated) values for every
dnl way gcc can be invoked.  So we just define them once, here.
dnl You should only AC_REQUIRE this macro.

dnl The variables defined at the end are:
dnl  depsedmagic - sed magic to use as the post-compilation phase
dnl                This one is not gcc-specific.
dnl  depgccflag = flag to pass to gcc 
dnl  depstdprecomp - standard precompilation magic

AC_DEFUN(AM_DEP_SET_VARS,[
dnl This next piece of magic avoids the `deleted header file' problem.
dnl The problem is that when a header file which appears in a .P file
dnl is deleted, the dependency causes make to die (because there is
dnl typically no way to rebuild the header).  We avoid this by adding
dnl dummy dependencies for each header file.  Too bad gcc doesn't do
dnl this for us directly.
dnl Some versions of gcc put a space before the `:'.  On the theory
dnl that the space means something, we add a space to the output as
dnl well.
dnl We remove # comments because that lets this same piece of magic
dnl work with SGI compilers.
dnl This is extremely ugly.  We have to have it all on one line
dnl because AC_SUBST can't handle multi-line substitutions.  We build
dnl the value up in pieces to make it a bit clearer.

dnl Change the target if required, and remove hash comments.
changequote(<<,>>)
val="sed -e \"s/^\\([^:]*\\)\\.o[ 	]*:/\$\$suffix :/\" -e 's/\\#.*\$\$//' < .deps/\$\$pp > .deps/\$\$p;"
changequote([,])

dnl Remove newlines and trailing backslashes, and generate a new
dnl dummy target for each header mentioned.
val="$val tr ' ' '\\012' < .deps/\$\$pp | sed -e 's/^\\\\\$\$//' -e '/^\$\$/ d' -e '/:\$\$/ d' -e 's/\$\$/ :/' >> .deps/\$\$p;"

dnl Remove the temp file and exit with a good status.
depsedmagic="$val rm -f .deps/\$\$pp; :"

dnl There are various ways to get dependency output from gcc.  Here's
dnl why we pick this rather obscure method:
dnl - Don't want to use -MD because we'd like the dependencies to end
dnl   up in a subdir.  Having to rename by hand is ugly.
dnl   (We might end up doing this anyway to support other compilers.)
dnl - The DEPENDENCIES_OUTPUT environment variable makes gcc act like
dnl   -MM, not -M (despite what the docs say).
dnl - Using -M directly means running the compiler twice (even worse
dnl   than renaming).
depgccflag='-Wp,-MD,.deps/$$pp'

dnl We use this same precompilation boilerplate to make the user's job
dnl easy -- he only has to set the `file' variable in the shell
dnl before invoking the compilation rules.  Again, we build it up in
dnl pieces for clarity.

dnl Compute the default suffix.
val="test -z \"\$\$suffix\" && suffix='\\1.o';"

dnl First compute P as root part of file (no directory or extension).
changequote(<<,>>)
val="$val p=\"\`echo \$\$file | sed -e 's|^.*/||' -e 's|\\.[^.]*\$\$||'\`\";"
changequote([,])

dnl Now use P to compute PP (name of a temp file), and then finally the
dnl real value of P (which is the resulting dependency file name).
val="$val pp=\"\$\$p.pp\"; p=\"\$\$p.P\";"

depstdprecomp="$val"
])
