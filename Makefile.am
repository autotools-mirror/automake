SCRIPTS = automake

amdatadir = $(datadir)/automake
am_DATA = clean-kr.am clean.am compile-kr.am compile-vars.am compile.am \
dist-subd-top.am dist-subd-vars.am dist-subd.am dist-vars.am dist.am \
footer.am header-vars.am header.am libprograms.am libraries-vars.am \
libraries.am library.am mans-vars.am mans.am program.am programs.am \
remake-hdr.am remake-subd.am remake.am subdirs.am texinfos-vars.am \
texinfos.am

DIST_OTHER = ChangeLog README TODO $(am_DATA) \
automake.in configure.in configure

install:: $(am_DATA)
	$(srcdir)/mkinstalldirs $(amdatadir)
	for i in $(am_DATA); do			\
	  $(INSTALL_DATA) $(srcdir)/$$i $(amdatadir)/$$i; \
	done
