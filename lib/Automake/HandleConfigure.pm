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

package Automake::HandleConfigure;

use 5.006;
use strict;

use Automake::Channels;
use Automake::ChannelDefs;
use Automake::Condition qw (TRUE FALSE);
use Automake::CondStack;
use Automake::Config;
use Automake::ConfVars;
use Automake::Errors;
use Automake::File;
use Automake::FileUtils;
use Automake::Global;
use Automake::Requires;
use Automake::Location;
use Automake::Options;
use Automake::RuleDef;
use Automake::SilentRules;
use Automake::Utils;
use Automake::Variable;
use Automake::XFile;
use Exporter 'import';
use File::Basename;

use vars qw (@EXPORT);

@EXPORT = qw ($configure_deps_greatest_timestamp &handle_configure
    &split_config_file_spec &scan_autoconf_config_files &scan_autoconf_files
    &scan_aclocal_m4);

# Helper functions for handling configure files inside Automake

# Greatest timestamp of configure's dependencies.
our $configure_deps_greatest_timestamp = 0;

# Files included by $configure_ac.
my @configure_deps = ();

my %make_list;


# ($REGEN, @DEPENDENCIES)
# scan_aclocal_m4
# ---------------
# If aclocal.m4 creation is automated, return the list of its dependencies.
sub scan_aclocal_m4 ()
{
  my $regen_aclocal = 0;

  set_seen 'CONFIG_STATUS_DEPENDENCIES';
  set_seen 'CONFIGURE_DEPENDENCIES';

  if (-f 'aclocal.m4')
    {
      define_variable ("ACLOCAL_M4", '$(top_srcdir)/aclocal.m4', INTERNAL);

      my $aclocal = new Automake::XFile "< aclocal.m4";
      my $line = $aclocal->getline;
      $regen_aclocal = $line =~ 'generated automatically by aclocal';
    }

  my @ac_deps = ();

  if (set_seen ('ACLOCAL_M4_SOURCES'))
    {
      push (@ac_deps, '$(ACLOCAL_M4_SOURCES)');
      msg_var ('obsolete', 'ACLOCAL_M4_SOURCES',
	       "'ACLOCAL_M4_SOURCES' is obsolete.\n"
	       . "It should be safe to simply remove it");
    }

  # Note that it might be possible that aclocal.m4 doesn't exist but
  # should be auto-generated.  This case probably isn't very
  # important.

  return ($regen_aclocal, @ac_deps);
}


# handle_configure ($MAKEFILE_AM, $MAKEFILE_IN, $MAKEFILE, @INPUTS)
# -----------------------------------------------------------------
# Handle remaking and configure stuff.
# We need the name of the input file, to do proper remaking rules.
sub handle_configure
{
  my ($makefile_am, $makefile_in, $makefile, @inputs) = @_;

  prog_error 'empty @inputs'
    unless @inputs;

  my ($rel_makefile_am, $rel_makefile_in) = prepend_srcdir ($makefile_am,
							    $makefile_in);
  my $rel_makefile = basename $makefile;

  my $colon_infile = ':' . join (':', @inputs);
  $colon_infile = '' if $colon_infile eq ":$makefile.in";
  my @rewritten = rewrite_inputs_into_dependencies ($makefile, @inputs);
  my ($regen_aclocal_m4, @aclocal_m4_deps) = scan_aclocal_m4;
  define_pretty_variable ('am__aclocal_m4_deps', TRUE, INTERNAL,
			  @configure_deps, @aclocal_m4_deps,
			  '$(top_srcdir)/' . $configure_ac);
  my @configuredeps = ('$(am__aclocal_m4_deps)', '$(CONFIGURE_DEPENDENCIES)');
  push @configuredeps, '$(ACLOCAL_M4)' if -f 'aclocal.m4';
  define_pretty_variable ('am__configure_deps', TRUE, INTERNAL,
			  @configuredeps);

  my $automake_options = '--' . $strictness_name .
			 (global_option 'no-dependencies' ? ' --ignore-deps' : '');

  $output_rules .= file_contents
    ('configure',
     new Automake::Location,
     MAKEFILE              => $rel_makefile,
     'MAKEFILE-DEPS'       => "@rewritten",
     'CONFIG-MAKEFILE'     => ($relative_dir eq '.') ? '$@' : '$(subdir)/$@',
     'MAKEFILE-IN'         => $rel_makefile_in,
     'HAVE-MAKEFILE-IN-DEPS' => (@include_stack > 0),
     'MAKEFILE-IN-DEPS'    => "@include_stack",
     'MAKEFILE-AM'         => $rel_makefile_am,
     'AUTOMAKE-OPTIONS'    => $automake_options,
     'MAKEFILE-AM-SOURCES' => "$makefile$colon_infile",
     'REGEN-ACLOCAL-M4'    => $regen_aclocal_m4,
     VERBOSE               => verbose_flag ('GEN'));

  if ($relative_dir eq '.')
    {
      push_dist_common ('acconfig.h')
	if -f 'acconfig.h';
    }

  # If we have a configure header, require it.
  my $hdr_index = 0;
  my @distclean_config;
  foreach my $spec (@config_headers)
    {
      $hdr_index += 1;
      # $CONFIG_H_PATH: config.h from top level.
      my ($config_h_path, @ins) = split_config_file_spec ($spec);
      my $config_h_dir = dirname ($config_h_path);

      # If the header is in the current directory we want to build
      # the header here.  Otherwise, if we're at the topmost
      # directory and the header's directory doesn't have a
      # Makefile, then we also want to build the header.
      if ($relative_dir eq $config_h_dir
	  || ($relative_dir eq '.' && ! is_make_dir ($config_h_dir)))
	{
	  my ($cn_sans_dir, $stamp_dir);
	  if ($relative_dir eq $config_h_dir)
	    {
	      $cn_sans_dir = basename ($config_h_path);
	      $stamp_dir = '';
	    }
	  else
	    {
	      $cn_sans_dir = $config_h_path;
	      if ($config_h_dir eq '.')
		{
		  $stamp_dir = '';
		}
	      else
		{
		  $stamp_dir = $config_h_dir . '/';
		}
	    }

	  # This will also distribute all inputs.
	  @ins = rewrite_inputs_into_dependencies ($config_h_path, @ins);

	  # Cannot define rebuild rules for filenames with shell variables.
	  next if (substitute_ac_subst_variables $config_h_path) =~ /\$/;

	  # Header defined in this directory.
	  my @files;
	  if (-f $config_h_path . '.top')
	    {
	      push (@files, "$cn_sans_dir.top");
	    }
	  if (-f $config_h_path . '.bot')
	    {
	      push (@files, "$cn_sans_dir.bot");
	    }

	  push_dist_common (@files);

	  # For now, acconfig.h can only appear in the top srcdir.
	  if (-f 'acconfig.h')
	    {
	      push (@files, '$(top_srcdir)/acconfig.h');
	    }

	  my $stamp = "${stamp_dir}stamp-h${hdr_index}";
	  $output_rules .=
	    file_contents ('remake-hdr',
			   new Automake::Location,
			   FILES            => "@files",
			   'FIRST-HDR'      => ($hdr_index == 1),
			   CONFIG_H         => $cn_sans_dir,
			   CONFIG_HIN       => $ins[0],
			   CONFIG_H_DEPS    => "@ins",
			   CONFIG_H_PATH    => $config_h_path,
			   STAMP            => "$stamp");

	  push @distclean_config, $cn_sans_dir, $stamp;
	}
    }

  $output_rules .= file_contents ('clean-hdr',
				  new Automake::Location,
				  FILES => "@distclean_config")
    if @distclean_config;

  # Distribute and define mkinstalldirs only if it is already present
  # in the package, for backward compatibility (some people may still
  # use $(mkinstalldirs)).
  # TODO: start warning about this in Automake 1.14, and have
  # TODO: Automake 2.0 drop it (and the mkinstalldirs script
  # TODO: as well).
  my $mkidpath = "$config_aux_dir/mkinstalldirs";
  if (-f $mkidpath)
    {
      # Use require_file so that any existing script gets updated
      # by --force-missing.
      require_conf_file ($mkidpath, FOREIGN, 'mkinstalldirs');
      define_variable ('mkinstalldirs',
		       "\$(SHELL) $am_config_aux_dir/mkinstalldirs", INTERNAL);
    }
  else
    {
      # Use $(install_sh), not $(MKDIR_P) because the latter requires
      # at least one argument, and $(mkinstalldirs) used to work
      # even without arguments (e.g. $(mkinstalldirs) $(conditional_dir)).
      define_variable ('mkinstalldirs', '$(install_sh) -d', INTERNAL);
    }

  reject_var ('CONFIG_HEADER',
	      "'CONFIG_HEADER' is an anachronism; now determined "
	      . "automatically\nfrom '$configure_ac'");

  my @config_h;
  foreach my $spec (@config_headers)
    {
      my ($out, @ins) = split_config_file_spec ($spec);
      # Generate CONFIG_HEADER define.
      if ($relative_dir eq dirname ($out))
	{
	  push @config_h, basename ($out);
	}
      else
	{
	  push @config_h, "\$(top_builddir)/$out";
	}
    }
  define_variable ("CONFIG_HEADER", "@config_h", INTERNAL)
    if @config_h;

  # Now look for other files in this directory which must be remade
  # by config.status, and generate rules for them.
  my @actual_other_files = ();
  # These get cleaned only in a VPATH build.
  my @actual_other_vpath_files = ();
  foreach my $lfile (@other_input_files)
    {
      my $file;
      my @inputs;
      if ($lfile =~ /^([^:]*):(.*)$/)
	{
	  # This is the ":" syntax of AC_OUTPUT.
	  $file = $1;
	  @inputs = split (':', $2);
	}
      else
	{
	  # Normal usage.
	  $file = $lfile;
	  @inputs = $file . '.in';
	}

      # Automake files should not be stored in here, but in %MAKE_LIST.
      prog_error ("$lfile in \@other_input_files\n"
		  . "\@other_input_files = (@other_input_files)")
	if -f $file . '.am';

      my $local = basename ($file);

      # We skip files that aren't in this directory.  However, if
      # the file's directory does not have a Makefile, and we are
      # currently doing '.', then we create a rule to rebuild the
      # file in the subdir.
      my $fd = dirname ($file);
      if ($fd ne $relative_dir)
	{
	  if ($relative_dir eq '.' && ! is_make_dir ($fd))
	    {
	      $local = $file;
	    }
	  else
	    {
	      next;
	    }
	}

      my @rewritten_inputs = rewrite_inputs_into_dependencies ($file, @inputs);

      # Cannot output rules for shell variables.
      next if (substitute_ac_subst_variables $local) =~ /\$/;

      my $condstr = '';
      my $cond = $ac_config_files_condition{$lfile};
      if (defined $cond)
        {
	  $condstr = $cond->subst_string;
	  Automake::Rule::define ($local, $configure_ac, RULE_AUTOMAKE, $cond,
				  $ac_config_files_location{$file});
        }
      $output_rules .= ($condstr . $local . ': '
			. '$(top_builddir)/config.status '
			. "@rewritten_inputs\n"
			. $condstr . "\t"
			. 'cd $(top_builddir) && '
			. '$(SHELL) ./config.status '
			. ($relative_dir eq '.' ? '' : '$(subdir)/')
			. '$@'
			. "\n");
      push (@actual_other_files, $local);
    }

  # For links we should clean destinations and distribute sources.
  foreach my $spec (@config_links)
    {
      my ($link, $file) = split /:/, $spec;
      # Some people do AC_CONFIG_LINKS($computed).  We only handle
      # the DEST:SRC form.
      next unless $file;
      my $where = $ac_config_files_location{$link};

      # Skip destinations that contain shell variables.
      if ((substitute_ac_subst_variables $link) !~ /\$/)
	{
	  # We skip links that aren't in this directory.  However, if
	  # the link's directory does not have a Makefile, and we are
	  # currently doing '.', then we add the link to CONFIG_CLEAN_FILES
	  # in '.'s Makefile.in.
	  my $local = basename ($link);
	  my $fd = dirname ($link);
	  if ($fd ne $relative_dir)
	    {
	      if ($relative_dir eq '.' && ! is_make_dir ($fd))
		{
		  $local = $link;
		}
	      else
		{
		  $local = undef;
		}
	    }
	  if ($file ne $link)
	    {
	      push @actual_other_files, $local if $local;
	    }
	  else
	    {
	      push @actual_other_vpath_files, $local if $local;
	    }
	}

      # Do not process sources that contain shell variables.
      if ((substitute_ac_subst_variables $file) !~ /\$/)
	{
	  my $fd = dirname ($file);

	  # We distribute files that are in this directory.
	  # At the top-level ('.') we also distribute files whose
	  # directory does not have a Makefile.
	  if (($fd eq $relative_dir)
	      || ($relative_dir eq '.' && ! is_make_dir ($fd)))
	    {
	      # The following will distribute $file as a side-effect when
	      # it is appropriate (i.e., when $file is not already an output).
	      # We do not need the result, just the side-effect.
	      rewrite_inputs_into_dependencies ($link, $file);
	    }
	}
    }

  # These files get removed by "make distclean".
  define_pretty_variable ('CONFIG_CLEAN_FILES', TRUE, INTERNAL,
			  @actual_other_files);
  define_pretty_variable ('CONFIG_CLEAN_VPATH_FILES', TRUE, INTERNAL,
			  @actual_other_vpath_files);
}


# ($OUTPUT, @INPUTS)
# split_config_file_spec ($SPEC)
# ------------------------------
# Decode the Autoconf syntax for config files (files, headers, links
# etc.).
sub split_config_file_spec
{
  my ($spec) = @_;
  my ($output, @inputs) = split (/:/, $spec);

  push @inputs, "$output.in"
    unless @inputs;

  return ($output, @inputs);
}


# scan_autoconf_config_files ($WHERE, $CONFIG-FILES)
# --------------------------------------------------
# Study $CONFIG-FILES which is the first argument to AC_CONFIG_FILES
# (or AC_OUTPUT).
sub scan_autoconf_config_files
{
  my ($where, $config_files) = @_;

  # Look at potential Makefile.am's.
  foreach (split ' ', $config_files)
    {
      # Must skip empty string for Perl 4.
      next if $_ eq "\\" || $_ eq '';

      # Handle $local:$input syntax.
      my ($local, @rest) = split (/:/);
      @rest = ("$local.in",) unless @rest;
      # Keep in sync with test 'conffile-leading-dot.sh'.
      msg ('unsupported', $where,
           "omit leading './' from config file names such as '$local';"
           . "\nremake rules might be subtly broken otherwise")
        if ($local =~ /^\.\//);
      my $input = locate_am @rest;
      if ($input)
	{
	  # We have a file that automake should generate.
	  $make_list{$input} = join (':', ($local, @rest));
	}
      else
	{
	  # We have a file that automake should cause to be
	  # rebuilt, but shouldn't generate itself.
	  push (@other_input_files, $_);
	}
      $ac_config_files_location{$local} = $where;
      $ac_config_files_condition{$local} =
        new Automake::Condition (@cond_stack)
          if (@cond_stack);
    }
}


sub scan_autoconf_traces
{
  my ($filename, $traces) = @_;

  # Macros to trace, with their minimal number of arguments.
  #
  # IMPORTANT: If you add a macro here, you should also add this macro
  # =========  to Automake-preselection in autoconf/lib/autom4te.in.
  my %traced = (
		AC_CANONICAL_BUILD => 0,
		AC_CANONICAL_HOST => 0,
		AC_CANONICAL_TARGET => 0,
		AC_CONFIG_AUX_DIR => 1,
		AC_CONFIG_FILES => 1,
		AC_CONFIG_HEADERS => 1,
		AC_CONFIG_LIBOBJ_DIR => 1,
		AC_CONFIG_LINKS => 1,
		AC_FC_SRCEXT => 1,
		AC_INIT => 0,
		AC_LIBSOURCE => 1,
		AC_REQUIRE_AUX_FILE => 1,
		AC_SUBST_TRACE => 1,
		AM_AUTOMAKE_VERSION => 1,
                AM_PROG_MKDIR_P => 0,
		AM_CONDITIONAL => 2,
		AM_EXTRA_RECURSIVE_TARGETS => 1,
		AM_GNU_GETTEXT => 0,
		AM_GNU_GETTEXT_INTL_SUBDIR => 0,
		AM_INIT_AUTOMAKE => 0,
		AM_MAINTAINER_MODE => 0,
		AM_PROG_AR => 0,
		_AM_SUBST_NOTMAKE => 1,
		_AM_COND_IF => 1,
		_AM_COND_ELSE => 1,
		_AM_COND_ENDIF => 1,
		LT_SUPPORTED_TAG => 1,
		_LT_AC_TAGCONFIG => 0,
		m4_include => 1,
		m4_sinclude => 1,
		sinclude => 1,
	      );

  # Use a separator unlikely to be used, not ':', the default, which
  # has a precise meaning for AC_CONFIG_FILES and so on.
  $traces .= join (' ',
		   map { "--trace=$_" . ':\$f:\$l::\$d::\$n::\${::}%' }
		   (keys %traced));

  my $tracefh = new Automake::XFile ("$traces $filename |");
  verb "reading $traces";

  @cond_stack = ();
  my $where;

  while ($_ = $tracefh->getline)
    {
      chomp;
      my ($here, $depth, @args) = split (/::/);
      $where = new Automake::Location $here;
      my $macro = $args[0];

      prog_error ("unrequested trace '$macro'")
	unless exists $traced{$macro};

      # Skip and diagnose malformed calls.
      if ($#args < $traced{$macro})
	{
	  msg ('syntax', $where, "not enough arguments for $macro");
	  next;
	}

      # Alphabetical ordering please.
      if ($macro eq 'AC_CANONICAL_BUILD')
	{
	  if ($seen_canonical <= AC_CANONICAL_BUILD)
	    {
	      $seen_canonical = AC_CANONICAL_BUILD;
	    }
	}
      elsif ($macro eq 'AC_CANONICAL_HOST')
	{
	  if ($seen_canonical <= AC_CANONICAL_HOST)
	    {
	      $seen_canonical = AC_CANONICAL_HOST;
	    }
	}
      elsif ($macro eq 'AC_CANONICAL_TARGET')
	{
	  $seen_canonical = AC_CANONICAL_TARGET;
	}
      elsif ($macro eq 'AC_CONFIG_AUX_DIR')
	{
	  if ($seen_init_automake)
	    {
	      error ($where, "AC_CONFIG_AUX_DIR must be called before "
		     . "AM_INIT_AUTOMAKE ...", partial => 1);
	      error ($seen_init_automake, "... AM_INIT_AUTOMAKE called here");
	    }
	  $config_aux_dir = $args[1];
	  $config_aux_dir_set_in_configure_ac = 1;
	  check_directory ($config_aux_dir, $where);
	}
      elsif ($macro eq 'AC_CONFIG_FILES')
	{
	  # Look at potential Makefile.am's.
	  scan_autoconf_config_files ($where, $args[1]);
	}
      elsif ($macro eq 'AC_CONFIG_HEADERS')
	{
	  foreach my $spec (split (' ', $args[1]))
	    {
	      my ($dest, @src) = split (':', $spec);
	      $ac_config_files_location{$dest} = $where;
	      push @config_headers, $spec;
	    }
	}
      elsif ($macro eq 'AC_CONFIG_LIBOBJ_DIR')
	{
	  $config_libobj_dir = $args[1];
	  check_directory ($config_libobj_dir, $where);
	}
      elsif ($macro eq 'AC_CONFIG_LINKS')
	{
	  foreach my $spec (split (' ', $args[1]))
	    {
	      my ($dest, $src) = split (':', $spec);
	      $ac_config_files_location{$dest} = $where;
	      push @config_links, $spec;
	    }
	}
      elsif ($macro eq 'AC_FC_SRCEXT')
	{
	  my $suffix = $args[1];
	  # These flags are used as %SOURCEFLAG% in depend2.am,
	  # where the trailing space is important.
	  $sourceflags{'.' . $suffix} = '$(FCFLAGS_' . $suffix . ') '
	    if ($suffix eq 'f90' || $suffix eq 'f95' || $suffix eq 'f03' || $suffix eq 'f08');
	}
      elsif ($macro eq 'AC_INIT')
	{
	  if (defined $args[2])
	    {
	      $package_version = $args[2];
	      $package_version_location = $where;
	    }
	}
      elsif ($macro eq 'AC_LIBSOURCE')
	{
	  $libsources{$args[1]} = $here;
	}
      elsif ($macro eq 'AC_REQUIRE_AUX_FILE')
	{
	  # Only remember the first time a file is required.
	  $required_aux_file{$args[1]} = $where
	    unless exists $required_aux_file{$args[1]};
	}
      elsif ($macro eq 'AC_SUBST_TRACE')
	{
	  # Just check for alphanumeric in AC_SUBST_TRACE.  If you do
	  # AC_SUBST(5), then too bad.
	  $configure_vars{$args[1]} = $where
	    if $args[1] =~ /^\w+$/;
	}
      elsif ($macro eq 'AM_AUTOMAKE_VERSION')
	{
	  error ($where,
		 "version mismatch.  This is Automake $VERSION,\n" .
		 "but the definition used by this AM_INIT_AUTOMAKE\n" .
		 "comes from Automake $args[1].  You should recreate\n" .
		 "aclocal.m4 with aclocal and run automake again.\n",
		 # $? = 63 is used to indicate version mismatch to missing.
		 exit_code => 63)
	    if $VERSION ne $args[1];

	  $seen_automake_version = 1;
	}
      elsif ($macro eq 'AM_PROG_MKDIR_P')
	{
	  msg 'obsolete', $where, <<'EOF';
The 'AM_PROG_MKDIR_P' macro is deprecated, and its use is discouraged.
You should use the Autoconf-provided 'AC_PROG_MKDIR_P' macro instead,
and use '$(MKDIR_P)' instead of '$(mkdir_p)'in your Makefile.am files.
EOF
	}
      elsif ($macro eq 'AM_CONDITIONAL')
	{
	  $configure_cond{$args[1]} = $where;
	}
      elsif ($macro eq 'AM_EXTRA_RECURSIVE_TARGETS')
	{
          # Empty leading/trailing fields might be produced by split,
          # hence the grep is really needed.
          push @extra_recursive_targets,
               grep (/./, (split /\s+/, $args[1]));
	}
      elsif ($macro eq 'AM_GNU_GETTEXT')
	{
	  $seen_gettext = $where;
	  $ac_gettext_location = $where;
	  $seen_gettext_external = grep ($_ eq 'external', @args);
	}
      elsif ($macro eq 'AM_GNU_GETTEXT_INTL_SUBDIR')
	{
	  $seen_gettext_intl = $where;
	}
      elsif ($macro eq 'AM_INIT_AUTOMAKE')
	{
	  $seen_init_automake = $where;
	  if (defined $args[2])
	    {
              msg 'obsolete', $where, <<'EOF';
AM_INIT_AUTOMAKE: two- and three-arguments forms are deprecated.  For more info, see:
https://www.gnu.org/software/automake/manual/automake.html#Modernize-AM_005fINIT_005fAUTOMAKE-invocation
EOF
	      $package_version = $args[2];
	      $package_version_location = $where;
	    }
	  elsif (defined $args[1])
	    {
	      my @opts = split (' ', $args[1]);
	      @opts = map { { option => $_, where => $where } } @opts;
	      exit $exit_code unless process_global_option_list (@opts);
	    }
	}
      elsif ($macro eq 'AM_MAINTAINER_MODE')
	{
	  $seen_maint_mode = $where;
	}
      elsif ($macro eq 'AM_PROG_AR')
	{
	  $seen_ar = $where;
	}
      elsif ($macro eq '_AM_COND_IF')
        {
	  cond_stack_if ('', $args[1], $where);
	  error ($where, "missing m4 quoting, macro depth $depth")
	    if ($depth != 1);
	}
      elsif ($macro eq '_AM_COND_ELSE')
        {
	  cond_stack_else ('!', $args[1], $where);
	  error ($where, "missing m4 quoting, macro depth $depth")
	    if ($depth != 1);
	}
      elsif ($macro eq '_AM_COND_ENDIF')
        {
	  cond_stack_endif (undef, undef, $where);
	  error ($where, "missing m4 quoting, macro depth $depth")
	    if ($depth != 1);
	}
      elsif ($macro eq '_AM_SUBST_NOTMAKE')
	{
	  $ignored_configure_vars{$args[1]} = $where;
	}
      elsif ($macro eq 'm4_include'
	     || $macro eq 'm4_sinclude'
	     || $macro eq 'sinclude')
	{
	  # Skip missing 'sinclude'd files.
	  next if $macro ne 'm4_include' && ! -f $args[1];

	  # Some modified versions of Autoconf don't use
	  # frozen files.  Consequently it's possible that we see all
	  # m4_include's performed during Autoconf's startup.
	  # Obviously we don't want to distribute Autoconf's files
	  # so we skip absolute filenames here.
	  push @configure_deps, '$(top_srcdir)/' . $args[1]
	    unless $here =~ m,^(?:\w:)?[\\/],;
	  # Keep track of the greatest timestamp.
	  if (-e $args[1])
	    {
	      my $mtime = mtime $args[1];
	      $configure_deps_greatest_timestamp = $mtime
		if $mtime > $configure_deps_greatest_timestamp;
	    }
	}
      elsif ($macro eq 'LT_SUPPORTED_TAG')
	{
	  $libtool_tags{$args[1]} = 1;
	  $libtool_new_api = 1;
	}
      elsif ($macro eq '_LT_AC_TAGCONFIG')
	{
	  # _LT_AC_TAGCONFIG is an old macro present in Libtool 1.5.
	  # We use it to detect whether tags are supported.  Our
	  # preferred interface is LT_SUPPORTED_TAG, but it was
	  # introduced in Libtool 1.6.
	  if (0 == keys %libtool_tags)
	    {
	      # Hardcode the tags supported by Libtool 1.5.
	      %libtool_tags = (CC => 1, CXX => 1, GCJ => 1, F77 => 1);
	    }
	}
    }

  error ($where, "condition stack not properly closed")
    if (@cond_stack);

  $tracefh->close;
}


# Check whether we use 'configure.ac' or 'configure.in'.
# Scan it (and possibly 'aclocal.m4') for interesting things.
# We must scan aclocal.m4 because there might be AC_SUBSTs and such there.
sub scan_autoconf_files
{
  my ($traces) = @_;

  # Reinitialize libsources here.  This isn't really necessary,
  # since we currently assume there is only one configure.ac.  But
  # that won't always be the case.
  %libsources = ();

  # Keep track of the youngest configure dependency.
  $configure_deps_greatest_timestamp = mtime $configure_ac;
  if (-e 'aclocal.m4')
    {
      my $mtime = mtime 'aclocal.m4';
      $configure_deps_greatest_timestamp = $mtime
	if $mtime > $configure_deps_greatest_timestamp;
    }

  scan_autoconf_traces ($configure_ac, $traces);

  @configure_input_files = sort keys %make_list;
  # Set input and output files if not specified by user.
  if (! @input_files)
    {
      @input_files = @configure_input_files;
      %output_files = %make_list;
    }


  if (! $seen_init_automake)
    {
      err_ac ("no proper invocation of AM_INIT_AUTOMAKE was found.\nYou "
	      . "should verify that $configure_ac invokes AM_INIT_AUTOMAKE,"
	      . "\nthat aclocal.m4 is present in the top-level directory,\n"
	      . "and that aclocal.m4 was recently regenerated "
	      . "(using aclocal)");
    }
  else
    {
      if (! $seen_automake_version)
	{
	  if (-f 'aclocal.m4')
	    {
	      error ($seen_init_automake,
		     "your implementation of AM_INIT_AUTOMAKE comes from " .
		     "an\nold Automake version.  You should recreate " .
		     "aclocal.m4\nwith aclocal and run automake again",
		     # $? = 63 is used to indicate version mismatch to missing.
		     exit_code => 63);
	    }
	  else
	    {
	      error ($seen_init_automake,
		     "no proper implementation of AM_INIT_AUTOMAKE was " .
		     "found,\nprobably because aclocal.m4 is missing.\n" .
		     "You should run aclocal to create this file, then\n" .
		     "run automake again");
	    }
	}
    }

  locate_aux_dir ();

  # Look for some files we need.  Always check for these.  This
  # check must be done for every run, even those where we are only
  # looking at a subdir Makefile.  We must set relative_dir for
  # push_required_file to work.
  # Sort the files for stable verbose output.
  $relative_dir = '.';
  foreach my $file (sort keys %required_aux_file)
    {
      require_conf_file ($required_aux_file{$file}->get, FOREIGN, $file)
    }
  err_am "'install.sh' is an anachronism; use 'install-sh' instead"
    if -f $config_aux_dir . '/install.sh';

  # Preserve dist_common for later.
  @configure_dist_common = @dist_common;
}


1;
