# Hack data.am for PACKAGEDATA variable.
s/@SHORT@/p/g
s/@LONG@/$(PACKAGEDATA)/g
s,@DIR@,$(datadir)/$(PACKAGE),g
