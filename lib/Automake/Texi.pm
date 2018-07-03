# Copyright (C) 2018  Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Automake::Texi;

use 5.006;
use strict;

use Automake::ChannelDefs;
use Automake::Channels;
use Automake::Condition qw (TRUE FALSE);
use Automake::Errors;
use Automake::File;
use Automake::Global;
use Automake::Location;
use Automake::Options;
use Automake::Requires;
use Automake::SilentRules;
use Automake::Utils;
use Automake::Variable;
use Automake::Wrap qw (makefile_wrap);
use Automake::XFile;
use Exporter 'import';
use File::Basename;

use vars qw (@EXPORT);

@EXPORT = qw (scan_texinfo_file output_texinfo_build_rules
    handle_texinfo_helper handle_texinfo);


# ($OUTFILE, $VFILE)
# scan_texinfo_file ($FILENAME)
# -----------------------------
# $OUTFILE     - name of the info file produced by $FILENAME.
# $VFILE       - name of the version.texi file used (undef if none).
sub scan_texinfo_file
{
  my ($filename) = @_;

  my $texi = new Automake::XFile "< $filename";
  verb "reading $filename";

  my ($outfile, $vfile);
  while ($_ = $texi->getline)
    {
      if (/^\@setfilename +(\S+)/)
	{
	  # Honor only the first @setfilename.  (It's possible to have
	  # more occurrences later if the manual shows examples of how
	  # to use @setfilename...)
	  next if $outfile;

	  $outfile = $1;
	  if (index ($outfile, '.') < 0)
	    {
	      msg 'obsolete', "$filename:$.",
	          "use of suffix-less info files is discouraged"
	    }
	  elsif ($outfile !~ /\.info$/)
	    {
	      error ("$filename:$.",
		     "output '$outfile' has unrecognized extension");
	      return;
	    }
	}
      # A "version.texi" file is actually any file whose name matches
      # "vers*.texi".
      elsif (/^\@include\s+(vers[^.]*\.texi)\s*$/)
	{
	  $vfile = $1;
	}
    }

  if (! $outfile)
    {
      err_am "'$filename' missing \@setfilename";
      return;
    }

  return ($outfile, $vfile);
}


# ($DIRSTAMP, @CLEAN_FILES)
# output_texinfo_build_rules ($SOURCE, $DEST, $INSRC, @DEPENDENCIES)
# ------------------------------------------------------------------
# SOURCE - the source Texinfo file
# DEST - the destination Info file
# INSRC - whether DEST should be built in the source tree
# DEPENDENCIES - known dependencies
sub output_texinfo_build_rules
{
  my ($source, $dest, $insrc, @deps) = @_;

  # Split 'a.texi' into 'a' and '.texi'.
  my ($spfx, $ssfx) = ($source =~ /^(.*?)(\.[^.]*)?$/);
  my ($dpfx, $dsfx) = ($dest =~ /^(.*?)(\.[^.]*)?$/);

  $ssfx ||= "";
  $dsfx ||= "";

  # We can output two kinds of rules: the "generic" rules use Make
  # suffix rules and are appropriate when $source and $dest do not lie
  # in a sub-directory; the "specific" rules are needed in the other
  # case.
  #
  # The former are output only once (this is not really apparent here,
  # but just remember that some logic deeper in Automake will not
  # output the same rule twice); while the later need to be output for
  # each Texinfo source.
  my $generic;
  my $makeinfoflags;
  my $sdir = dirname $source;
  if ($sdir eq '.' && dirname ($dest) eq '.')
    {
      $generic = 1;
      $makeinfoflags = '-I $(srcdir)';
    }
  else
    {
      $generic = 0;
      $makeinfoflags = "-I $sdir -I \$(srcdir)/$sdir";
    }

  # A directory can contain two kinds of info files: some built in the
  # source tree, and some built in the build tree.  The rules are
  # different in each case.  However we cannot output two different
  # set of generic rules.  Because in-source builds are more usual, we
  # use generic rules in this case and fall back to "specific" rules
  # for build-dir builds.  (It should not be a problem to invert this
  # if needed.)
  $generic = 0 unless $insrc;

  # We cannot use a suffix rule to build info files with an empty
  # extension.  Otherwise we would output a single suffix inference
  # rule, with separate dependencies, as in
  #
  #    .texi:
  #             $(MAKEINFO) ...
  #    foo.info: foo.texi
  #
  # which confuse Solaris make.  (See the Autoconf manual for
  # details.)  Therefore we use a specific rule in this case.  This
  # applies to info files only (dvi and pdf files always have an
  # extension).
  my $generic_info = ($generic && $dsfx) ? 1 : 0;

  # If the resulting file lies in a subdirectory,
  # make sure this directory will exist.
  my $dirstamp = require_build_directory_maybe ($dest);

  my $dipfx = ($insrc ? '$(srcdir)/' : '') . $dpfx;

  $output_rules .= file_contents ('texibuild',
				  new Automake::Location,
                                  AM_V_MAKEINFO    => verbose_flag('MAKEINFO'),
                                  AM_V_TEXI2DVI    => verbose_flag('TEXI2DVI'),
                                  AM_V_TEXI2PDF    => verbose_flag('TEXI2PDF'),
				  DEPS             => "@deps",
				  DEST_PREFIX      => $dpfx,
				  DEST_INFO_PREFIX => $dipfx,
				  DEST_SUFFIX      => $dsfx,
				  DIRSTAMP         => $dirstamp,
				  GENERIC          => $generic,
				  GENERIC_INFO     => $generic_info,
				  INSRC		   => $insrc,
				  MAKEINFOFLAGS    => $makeinfoflags,
                                  SILENT           => silent_flag(),
				  SOURCE           => ($generic
						       ? '$<' : $source),
				  SOURCE_INFO      => ($generic_info
						       ? '$<' : $source),
				  SOURCE_REAL      => $source,
				  SOURCE_SUFFIX    => $ssfx,
                                  TEXIQUIET        => verbose_flag('texinfo'),
                                  TEXIDEVNULL      => verbose_flag('texidevnull'),
				  );
  return ($dirstamp, "$dpfx.dvi", "$dpfx.pdf", "$dpfx.ps", "$dpfx.html");
}


# ($MOSTLYCLEAN, $TEXICLEAN, $MAINTCLEAN)
# handle_texinfo_helper ($info_texinfos)
# --------------------------------------
# Handle all Texinfo source; helper for 'handle_texinfo'.
sub handle_texinfo_helper
{
  my ($info_texinfos) = @_;
  my (@infobase, @info_deps_list, @texi_deps);
  my %versions;
  my $done = 0;
  my (@mostly_cleans, @texi_cleans, @maint_cleans) = ('', '', '');

  # Build a regex matching user-cleaned files.
  my $d = var 'DISTCLEANFILES';
  my $c = var 'CLEANFILES';
  my @f = ();
  push @f, $d->value_as_list_recursive (inner_expand => 1) if $d;
  push @f, $c->value_as_list_recursive (inner_expand => 1) if $c;
  @f = map { s|[^A-Za-z_0-9*\[\]\-]|\\$&|g; s|\*|[^/]*|g; $_; } @f;
  my $user_cleaned_files = '^(?:' . join ('|', @f) . ')$';

  foreach my $texi
      ($info_texinfos->value_as_list_recursive (inner_expand => 1))
    {
      my $infobase = $texi;
      if ($infobase =~ s/\.texi$//)
        {
          1; # Nothing more to do.
        }
      elsif ($infobase =~ s/\.(txi|texinfo)$//)
        {
	  msg_var 'obsolete', $info_texinfos,
	          "suffix '.$1' for Texinfo files is discouraged;" .
                  " use '.texi' instead";
        }
      else
	{
	  # FIXME: report line number.
	  err_am "texinfo file '$texi' has unrecognized extension";
	  next;
	}

      push @infobase, $infobase;

      # If 'version.texi' is referenced by input file, then include
      # automatic versioning capability.
      my ($out_file, $vtexi) =
	scan_texinfo_file ("$relative_dir/$texi")
	or next;
      # Directory of auxiliary files and build by-products used by texi2dvi
      # and texi2pdf.
      push @mostly_cleans, "$infobase.t2d";
      push @mostly_cleans, "$infobase.t2p";

      # If the Texinfo source is in a subdirectory, create the
      # resulting info in this subdirectory.  If it is in the current
      # directory, try hard to not prefix "./" because it breaks the
      # generic rules.
      my $outdir = dirname ($texi) . '/';
      $outdir = "" if $outdir eq './';
      $out_file =  $outdir . $out_file;

      # Until Automake 1.6.3, .info files were built in the
      # source tree.  This was an obstacle to the support of
      # non-distributed .info files, and non-distributed .texi
      # files.
      #
      # * Non-distributed .texi files is important in some packages
      #   where .texi files are built at make time, probably using
      #   other binaries built in the package itself, maybe using
      #   tools or information found on the build host.  Because
      #   these files are not distributed they are always rebuilt
      #   at make time; they should therefore not lie in the source
      #   directory.  One plan was to support this using
      #   nodist_info_TEXINFOS or something similar.  (Doing this
      #   requires some sanity checks.  For instance Automake should
      #   not allow:
      #      dist_info_TEXINFOS = foo.texi
      #      nodist_foo_TEXINFOS = included.texi
      #   because a distributed file should never depend on a
      #   non-distributed file.)
      #
      # * If .texi files are not distributed, then .info files should
      #   not be distributed either.  There are also cases where one
      #   wants to distribute .texi files, but does not want to
      #   distribute the .info files.  For instance the Texinfo package
      #   distributes the tool used to build these files; it would
      #   be a waste of space to distribute them.  It's not clear
      #   which syntax we should use to indicate that .info files should
      #   not be distributed.  Akim Demaille suggested that eventually
      #   we switch to a new syntax:
      #   |  Maybe we should take some inspiration from what's already
      #   |  done in the rest of Automake.  Maybe there is too much
      #   |  syntactic sugar here, and you want
      #   |     nodist_INFO = bar.info
      #   |     dist_bar_info_SOURCES = bar.texi
      #   |     bar_texi_DEPENDENCIES = foo.texi
      #   |  with a bit of magic to have bar.info represent the whole
      #   |  bar*info set.  That's a lot more verbose that the current
      #   |  situation, but it is # not new, hence the user has less
      #   |  to learn.
      #	  |
      #   |  But there is still too much room for meaningless specs:
      #   |     nodist_INFO = bar.info
      #   |     dist_bar_info_SOURCES = bar.texi
      #   |     dist_PS = bar.ps something-written-by-hand.ps
      #   |     nodist_bar_ps_SOURCES = bar.texi
      #   |     bar_texi_DEPENDENCIES = foo.texi
      #   |  here bar.texi is dist_ in line 2, and nodist_ in 4.
      #
      # Back to the point, it should be clear that in order to support
      # non-distributed .info files, we need to build them in the
      # build tree, not in the source tree (non-distributed .texi
      # files are less of a problem, because we do not output build
      # rules for them).  In Automake 1.7 .info build rules have been
      # largely cleaned up so that .info files get always build in the
      # build tree, even when distributed.  The idea was that
      #   (1) if during a VPATH build the .info file was found to be
      #       absent or out-of-date (in the source tree or in the
      #       build tree), Make would rebuild it in the build tree.
      #       If an up-to-date source-tree of the .info file existed,
      #       make would not rebuild it in the build tree.
      #   (2) having two copies of .info files, one in the source tree
      #       and one (newer) in the build tree is not a problem
      #       because 'make dist' always pick files in the build tree
      #       first.
      # However it turned out the be a bad idea for several reasons:
      #   * Tru64, OpenBSD, and FreeBSD (not NetBSD) Make do not behave
      #     like GNU Make on point (1) above.  These implementations
      #     of Make would always rebuild .info files in the build
      #     tree, even if such files were up to date in the source
      #     tree.  Consequently, it was impossible to perform a VPATH
      #     build of a package containing Texinfo files using these
      #     Make implementations.
      #     (Refer to the Autoconf Manual, section "Limitation of
      #     Make", paragraph "VPATH", item "target lookup", for
      #     an account of the differences between these
      #     implementations.)
      #   * The GNU Coding Standards require these files to be built
      #     in the source-tree (when they are distributed, that is).
      #   * Keeping a fresher copy of distributed files in the
      #     build tree can be annoying during development because
      #     - if the files is kept under CVS, you really want it
      #       to be updated in the source tree
      #     - it is confusing that 'make distclean' does not erase
      #       all files in the build tree.
      #
      # Consequently, starting with Automake 1.8, .info files are
      # built in the source tree again.  Because we still plan to
      # support non-distributed .info files at some point, we
      # have a single variable ($INSRC) that controls whether
      # the current .info file must be built in the source tree
      # or in the build tree.  Actually this variable is switched
      # off in two cases:
      #  (1) For '.info' files that appear to be cleaned; this is for
      #      backward compatibility with package such as Texinfo,
      #      which do things like
      #        info_TEXINFOS = texinfo.txi info-stnd.texi info.texi
      #        DISTCLEANFILES = texinfo texinfo-* info*.info*
      #        # Do not create info files for distribution.
      #        dist-info:
      #      in order not to distribute .info files.
      #  (2) When the undocumented option 'info-in-builddir' is given.
      #      This is done to allow the developers of GCC, GDB, GNU
      #      binutils and the GNU bfd library to force the '.info' files
      #      to be generated in the builddir rather than the srcdir, as
      #      was once done when the (now removed) 'cygnus' option was
      #      given.  See automake bug#11034 for more discussion.
      my $insrc = 1;
      my $soutdir = '$(srcdir)/' . $outdir;

      if (option 'info-in-builddir')
        {
          $insrc = 0;
        }
      elsif ($out_file =~ $user_cleaned_files)
        {
          $insrc = 0;
          msg 'obsolete', "$am_file.am", <<EOF;
Oops!
    It appears this file (or files included by it) are triggering
    an undocumented, soon-to-be-removed automake hack.
    Future automake versions will no longer place in the builddir
    (rather than in the srcdir) the generated '.info' files that
    appear to be cleaned, by e.g. being listed in CLEANFILES or
    DISTCLEANFILES.
    If you want your '.info' files to be placed in the builddir
    rather than in the srcdir, you have to use the shiny new
    'info-in-builddir' automake option.
EOF
        }

      $outdir = $soutdir if $insrc;

      # If user specified file_TEXINFOS, then use that as explicit
      # dependency list.
      @texi_deps = ();
      push (@texi_deps, "${soutdir}${vtexi}") if $vtexi;

      my $canonical = canonicalize ($infobase);
      if (var ($canonical . "_TEXINFOS"))
	{
	  push (@texi_deps, '$(' . $canonical . '_TEXINFOS)');
	  push_dist_common ('$(' . $canonical . '_TEXINFOS)');
	}

      my ($dirstamp, @cfiles) =
	output_texinfo_build_rules ($texi, $out_file, $insrc, @texi_deps);
      push (@texi_cleans, @cfiles);

      push (@info_deps_list, $out_file);

      # If a vers*.texi file is needed, emit the rule.
      if ($vtexi)
	{
	  err_am ("'$vtexi', included in '$texi', "
		  . "also included in '$versions{$vtexi}'")
	    if defined $versions{$vtexi};
	  $versions{$vtexi} = $texi;

	  # We number the stamp-vti files.  This is doable since the
	  # actual names don't matter much.  We only number starting
	  # with the second one, so that the common case looks nice.
	  my $vti = ($done ? $done : 'vti');
	  ++$done;

	  # This is ugly, but it is our historical practice.
	  if ($config_aux_dir_set_in_configure_ac)
	    {
	      require_conf_file_with_macro (TRUE, 'info_TEXINFOS', FOREIGN,
					    'mdate-sh');
	    }
	  else
	    {
	      require_file_with_macro (TRUE, 'info_TEXINFOS',
				       FOREIGN, 'mdate-sh');
	    }

	  my $conf_dir;
	  if ($config_aux_dir_set_in_configure_ac)
	    {
	      $conf_dir = "$am_config_aux_dir/";
	    }
	  else
	    {
	      $conf_dir = '$(srcdir)/';
	    }
	  $output_rules .= file_contents ('texi-vers',
					  new Automake::Location,
					  TEXI     => $texi,
					  VTI      => $vti,
					  STAMPVTI => "${soutdir}stamp-$vti",
					  VTEXI    => "$soutdir$vtexi",
					  MDDIR    => $conf_dir,
					  DIRSTAMP => $dirstamp);
	}
    }

  # Handle location of texinfo.tex.
  my $need_texi_file = 0;
  my $texinfodir;
  if (var ('TEXINFO_TEX'))
    {
      # The user defined TEXINFO_TEX so assume he knows what he is
      # doing.
      $texinfodir = ('$(srcdir)/'
		     . dirname (variable_value ('TEXINFO_TEX')));
    }
  elsif ($config_aux_dir_set_in_configure_ac)
    {
      $texinfodir = $am_config_aux_dir;
      define_variable ('TEXINFO_TEX', "$texinfodir/texinfo.tex", INTERNAL);
      $need_texi_file = 2; # so that we require_conf_file later
    }
  else
    {
      $texinfodir = '$(srcdir)';
      $need_texi_file = 1;
    }
  define_variable ('am__TEXINFO_TEX_DIR', $texinfodir, INTERNAL);

  push (@dist_targets, 'dist-info');

  if (! option 'no-installinfo')
    {
      # Make sure documentation is made and installed first.  Use
      # $(INFO_DEPS), not 'info', because otherwise recursive makes
      # get run twice during "make all".
      unshift (@all, '$(INFO_DEPS)');
    }

  define_files_variable ("DVIS", @infobase, 'dvi', INTERNAL);
  define_files_variable ("PDFS", @infobase, 'pdf', INTERNAL);
  define_files_variable ("PSS", @infobase, 'ps', INTERNAL);
  define_files_variable ("HTMLS", @infobase, 'html', INTERNAL);

  # This next isn't strictly needed now -- the places that look here
  # could easily be changed to look in info_TEXINFOS.  But this is
  # probably better, in case noinst_TEXINFOS is ever supported.
  define_variable ("TEXINFOS", variable_value ('info_TEXINFOS'), INTERNAL);

  # Do some error checking.  Note that this file is not required
  # when in Cygnus mode; instead we defined TEXINFO_TEX explicitly
  # up above.
  if ($need_texi_file && ! option 'no-texinfo.tex')
    {
      if ($need_texi_file > 1)
	{
	  require_conf_file_with_macro (TRUE, 'info_TEXINFOS', FOREIGN,
					'texinfo.tex');
	}
      else
	{
	  require_file_with_macro (TRUE, 'info_TEXINFOS', FOREIGN,
				   'texinfo.tex');
	}
    }

  return (makefile_wrap ("", "\t  ", @mostly_cleans),
	  makefile_wrap ("", "\t  ", @texi_cleans),
	  makefile_wrap ("", "\t  ", @maint_cleans));
}


sub handle_texinfo
{
  reject_var 'TEXINFOS', "'TEXINFOS' is an anachronism; use 'info_TEXINFOS'";
  # FIXME: I think this is an obsolete future feature name.
  reject_var 'html_TEXINFOS', "HTML generation not yet supported";

  my $info_texinfos = var ('info_TEXINFOS');
  my ($mostlyclean, $clean, $maintclean) = ('', '', '');
  if ($info_texinfos)
    {
      define_verbose_texinfo;
      ($mostlyclean, $clean, $maintclean) = handle_texinfo_helper ($info_texinfos);
      chomp $mostlyclean;
      chomp $clean;
      chomp $maintclean;
    }

  $output_rules .=  file_contents ('texinfos',
				   new Automake::Location,
                                   AM_V_DVIPS    => verbose_flag('DVIPS'),
				   MOSTLYCLEAN   => $mostlyclean,
				   TEXICLEAN     => $clean,
				   MAINTCLEAN    => $maintclean,
				   'LOCAL-TEXIS' => !!$info_texinfos,
                                   TEXIQUIET     => verbose_flag('texinfo'));
}

1;
