## Process this file with automake to create Makefile.in

AUTOMAKE_OPTIONS = gnits

## FIXME Ulrich has suggested implementing this in Automake.
## Perhaps he is right.
TESTS = mdate.test vtexi.test acoutput.test instexec.test checkall.test \
acoutnoq.test acouttbs.test libobj.test

DIST_OTHER = $(TESTS)

check-local:
	@failed=0; all=0; \
	srcdir=$(srcdir); export srcdir; \
	for tst in $(TESTS); do \
	  all=`expr $$all + 1`; \
## FIXME use $(SHELL) here?  That is what Ulrich suggests.  Maybe
## a new macro, $(TEST_SHELL), a la $(CONFIG_SHELL)?
## For now we just execute the file directly; this allows test files
## which are compiled -- a possibly useful feature.
	  if test -f $$tst; then dir=.; \
	  else dir="$(srcdir)"; fi; \
	  $$dir/$$tst || { \
	    failed=`expr $$failed + 1`; \
	    echo "FAIL: $$tst"; \
	  } \
	done; \
	if test "$$failed" -eq 0; then \
	  echo "All $$all tests passed"; \
	else \
	  echo "$$failed of $$all tests failed"; \
	fi
