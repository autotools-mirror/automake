SCRIPTS = automake
DISTCLEANFILES = automake

TEXINFOS = automake.texi version.texi

amdatadir = $(datadir)/automake
am_DATA = clean-kr.am clean.am compile-kr.am compile-vars.am compile.am \
dist-subd-top.am dist-subd-vars.am dist-subd.am dist-vars.am dist.am \
footer.am header-vars.am header.am libprograms.am libraries-vars.am \
libraries.am library.am mans-vars.am mans.am program.am programs.am \
remake-hdr.am remake-subd.am remake.am subdirs.am tags.am tags-subd.am \
texinfos-vars.am texinfos.am hack-make.sed nl-remove.sed

DIST_OTHER = automake.in stamp-vti $(am_DATA)
DIST_SUBDIRS = RCS samples

install:: $(am_DATA)
	$(srcdir)/mkinstalldirs $(amdatadir)
	for i in $(am_DATA); do			\
	  $(INSTALL_DATA) $(srcdir)/$$i $(amdatadir)/$$i; \
	done

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
