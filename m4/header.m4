# Like AC_CONFIG_HEADER, but automatically create stamp file.

AC_DEFUN(AM_CONFIG_HEADER,
[AC_PREREQ([2.11.2])
AC_CONFIG_HEADER($1)
dnl When config.status generates a header, we must update the stamp-h file.
dnl This file resides in the same directory as the config header
dnl that is generated.  We must strip everything past the first ":",
dnl and everything past the last "/".
changequote(<<,>>)
AC_OUTPUT_COMMANDS(<<test -z "<<$>>CONFIG_HEADER" || echo timestamp > patsubst($1, <<^\([^:]*/\)?.*>>, <<\1>>)>>)
changequote([,])])
