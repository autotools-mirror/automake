bin_SCRIPTS = automake
TEXINFOS = automake.texi
# SUBDIRS = intl po
# CONFIG_HEADER = config.h

pkgdata_DATA = clean-kr.am clean.am compile-kr.am compile-vars.am \
compile.am data.am depend.am dist-subd-top.am \
dist-subd.am dist-vars.am dist.am footer.am header-vars.am \
kr-vars.am libprograms.am libraries-vars.am \
libraries.am library.am mans-vars.am \
program.am programs.am remake-hdr.am \
remake-subd.am remake.am scripts.am subdirs.am tags.am tags-subd.am \
tags-clean.am \
texi-clean.am texi-version.am texinfos-vars.am texinfos.am \
libraries-clean.am scripts-clean.am programs-clean.am data-clean.am

DIST_OTHER = automake.in

# The following requires a fixed version of the Emacs 19.30 etags.
ETAGS_ARGS = automake.in --lang=none \
 --regex='/^@node[ \t]+\([^,]+\)/\1/' automake.texi

# The simplest form of checking.
check-local: automake
	@PERL@ -c -w automake

automake: automake.in
	CONFIG_FILES=$@ CONFIG_HEADERS= ./config.status

