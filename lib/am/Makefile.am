# SUBDIRS = intl po

SCRIPTS = automake
DISTCLEANFILES = automake

TEXINFOS = automake.texi version.texi

PACKAGEDATA = clean-kr.am clean.am compile-kr.am compile-vars.am \
compile.am data.am depend.am dist-subd-top.am dist-subd-vars.am \
dist-subd.am dist-vars.am dist.am footer.am header-vars.am header.am \
libscripts.am libprograms.am libraries-vars.am libraries.am library.am \
mans-vars.am mans.am packagedata.am program.am programs.am remake-hdr.am \
remake-subd.am remake.am scripts.am subdirs.am tags.am tags-subd.am \
texinfos-vars.am texinfos.am hack-make.sed nl-remove.sed

DIST_OTHER = automake.in stamp-vti gettext-sh $(am_DATA)
DIST_SUBDIRS = RCS samples

automake: automake.in
	CONFIG_FILES=$@ CONFIG_HEADERS= ./config.status

version.texi: stamp-vti
stamp-vti: automake.texi configure.in
	echo "@set UPDATED `date -r $(srcdir)/automake.texi '+%B %Y'`" \
		> version.tmp
	echo "@set VERSION $(VERSION)" >> version.tmp
	if cmp -s version.tmp $(srcdir)/version.texi; then rm version.tmp; \
	else mv version.tmp $(srcdir)/version.texi; fi
	touch $(srcdir)/stamp-vti
