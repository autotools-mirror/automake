# Hack data.am for DATA variable.
s/@SHORT@/d/g
s/@LONG@/$(DATA)/g
s/@DIR@/$(datadir)/g
