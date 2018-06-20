package Automake::Requires;

use Automake::ChannelDefs;
use Automake::Channels;
use Automake::Condition qw (TRUE FALSE);
use Automake::Config;
use Automake::FileUtils;
use Automake::Global;
use Automake::Location;
use Automake::Options;
use Automake::Rule;
use Automake::Utils;
use Automake::Variable;
use File::Basename;

use Exporter;

use vars '@ISA', '@EXPORT';

@ISA = qw (Exporter);

@EXPORT = qw (push_required_file required_file_check_or_copy
    require_file_internal require_file require_file_with_macro
    require_libsource_with_macro queue_required_file_check_or_copy
    require_queued_file_check_or_copy require_conf_file
    require_conf_file_with_macro require_build_directory
    require_build_directory_maybe);

# push_required_file ($DIR, $FILE, $FULLFILE)
# -------------------------------------------
# Push the given file onto DIST_COMMON.
sub push_required_file
{
  my ($dir, $file, $fullfile) = @_;

  # If the file to be distributed is in the same directory of the
  # currently processed Makefile.am, then we want to distribute it
  # from this same Makefile.am.
  if ($dir eq $relative_dir)
    {
      push_dist_common ($file);
    }
  # This is needed to allow a construct in a non-top-level Makefile.am
  # to require a file in the build-aux directory (see at least the test
  # script 'test-driver-is-distributed.sh').  This is related to the
  # automake bug#9546.  Note that the use of $config_aux_dir instead
  # of $am_config_aux_dir here is deliberate and necessary.
  elsif ($dir eq $config_aux_dir)
    {
      push_dist_common ("$am_config_aux_dir/$file");
    }
  # FIXME: another spacial case, for AC_LIBOBJ/AC_LIBSOURCE support.
  # We probably need some refactoring of this function and its callers,
  # to have a more explicit and systematic handling of all the special
  # cases; but, since there are only two of them, this is low-priority
  # ATM.
  elsif ($config_libobj_dir && $dir eq $config_libobj_dir)
    {
      # Avoid unsightly '/.'s.
      my $am_config_libobj_dir =
        '$(top_srcdir)' .
        ($config_libobj_dir eq '.' ? "" : "/$config_libobj_dir");
      $am_config_libobj_dir =~ s|/*$||;
      push_dist_common ("$am_config_libobj_dir/$file");
    }
  elsif ($relative_dir eq '.' && ! is_make_dir ($dir))
    {
      # If we are doing the topmost directory, and the file is in a
      # subdir which does not have a Makefile, then we distribute it
      # here.

      # If a required file is above the source tree, it is important
      # to prefix it with '$(srcdir)' so that no VPATH search is
      # performed.  Otherwise problems occur with Make implementations
      # that rewrite and simplify rules whose dependencies are found in a
      # VPATH location.  Here is an example with OSF1/Tru64 Make.
      #
      #   % cat Makefile
      #   VPATH = sub
      #   distdir: ../a
      #	          echo ../a
      #   % ls
      #   Makefile a
      #   % make
      #   echo a
      #   a
      #
      # Dependency '../a' was found in 'sub/../a', but this make
      # implementation simplified it as 'a'.  (Note that the sub/
      # directory does not even exist.)
      #
      # This kind of VPATH rewriting seems hard to cancel.  The
      # distdir.am hack against VPATH rewriting works only when no
      # simplification is done, i.e., for dependencies which are in
      # subdirectories, not in enclosing directories.  Hence, in
      # the latter case we use a full path to make sure no VPATH
      # search occurs.
      $fullfile = '$(srcdir)/' . $fullfile
	if $dir =~ m,^\.\.(?:$|/),;

      push_dist_common ($fullfile);
    }
  else
    {
      prog_error "a Makefile in relative directory $relative_dir " .
                 "can't add files in directory $dir to DIST_COMMON";
    }
}


# If a file name appears as a key in this hash, then it has already
# been checked for.  This allows us not to report the same error more
# than once.
my %required_file_not_found = ();

# required_file_check_or_copy ($WHERE, $DIRECTORY, $FILE)
# -------------------------------------------------------
# Verify that the file must exist in $DIRECTORY, or install it.
sub required_file_check_or_copy
{
  my ($where, $dir, $file) = @_;

  my $fullfile = "$dir/$file";
  my $found_it = 0;
  my $dangling_sym = 0;

  if (-l $fullfile && ! -f $fullfile)
    {
      $dangling_sym = 1;
    }
  elsif (dir_has_case_matching_file ($dir, $file))
    {
      $found_it = 1;
    }

  # '--force-missing' only has an effect if '--add-missing' is
  # specified.
  return
    if $found_it && (! $add_missing || ! $force_missing);

  # If we've already looked for it, we're done.  You might wonder why we
  # don't do this before searching for the file.  If we do that, then
  # something like AC_OUTPUT([subdir/foo foo]) will fail to put 'foo.in'
  # into $(DIST_COMMON).
  if (! $found_it)
    {
      return if defined $required_file_not_found{$fullfile};
      $required_file_not_found{$fullfile} = 1;
    }
  if ($dangling_sym && $add_missing)
    {
      unlink ($fullfile);
    }

  my $trailer = '';
  my $trailer2 = '';
  my $suppress = 0;

  # Only install missing files according to our desired
  # strictness level.
  my $message = "required file '$fullfile' not found";
  if ($add_missing)
    {
      if (-f "$libdir/$file")
        {
          $suppress = 1;

          # Install the missing file.  Symlink if we
          # can, copy if we must.  Note: delete the file
          # first, in case it is a dangling symlink.
          $message = "installing '$fullfile'";

          # The license file should not be volatile.
          if ($file eq "COPYING")
            {
              $message .= " using GNU General Public License v3 file";
              $trailer2 = "\n    Consider adding the COPYING file"
                        . " to the version control system"
                        . "\n    for your code, to avoid questions"
                        . " about which license your project uses";
            }

          # Windows Perl will hang if we try to delete a
          # file that doesn't exist.
          unlink ($fullfile) if -f $fullfile;
          if ($symlink_exists && ! $copy_missing)
            {
              if (! symlink ("$libdir/$file", $fullfile)
                  || ! -e $fullfile)
                {
                  $suppress = 0;
                  $trailer = "; error while making link: $!";
                }
            }
          elsif (system ('cp', "$libdir/$file", $fullfile))
            {
              $suppress = 0;
              $trailer = "\n    error while copying";
            }
          set_dir_cache_file ($dir, $file);
        }
    }
  else
    {
      $trailer = "\n  'automake --add-missing' can install '$file'"
        if -f "$libdir/$file";
    }

  # If --force-missing was specified, and we have
  # actually found the file, then do nothing.
  return
    if $found_it && $force_missing;

  # If we couldn't install the file, but it is a target in
  # the Makefile, don't print anything.  This allows files
  # like README, AUTHORS, or THANKS to be generated.
  return
    if !$suppress && rule $file;

  msg ($suppress ? 'note' : 'error', $where, "$message$trailer$trailer2");
}


# require_file_internal ($WHERE, $MYSTRICT, $DIRECTORY, $QUEUE, @FILES)
# ---------------------------------------------------------------------
# Verify that the file must exist in $DIRECTORY, or install it.
# $MYSTRICT is the strictness level at which this file becomes required.
# Worker threads may queue up the action to be serialized by the master,
# if $QUEUE is true
sub require_file_internal
{
  my ($where, $mystrict, $dir, $queue, @files) = @_;

  return
    unless $strictness >= $mystrict;

  foreach my $file (@files)
    {
      push_required_file ($dir, $file, "$dir/$file");
      if ($queue)
        {
          queue_required_file_check_or_copy ($required_conf_file_queue,
                                             QUEUE_CONF_FILE, $relative_dir,
                                             $where, $mystrict, @files);
        }
      else
        {
          required_file_check_or_copy ($where, $dir, $file);
        }
    }
}

# require_file ($WHERE, $MYSTRICT, @FILES)
# ----------------------------------------
sub require_file
{
    my ($where, $mystrict, @files) = @_;
    require_file_internal ($where, $mystrict, $relative_dir, 0, @files);
}

# require_file_with_macro ($COND, $MACRO, $MYSTRICT, @FILES)
# ----------------------------------------------------------
sub require_file_with_macro
{
    my ($cond, $macro, $mystrict, @files) = @_;
    $macro = rvar ($macro) unless ref $macro;
    require_file ($macro->rdef ($cond)->location, $mystrict, @files);
}

# require_libsource_with_macro ($COND, $MACRO, $MYSTRICT, @FILES)
# ---------------------------------------------------------------
# Require an AC_LIBSOURCEd file.  If AC_CONFIG_LIBOBJ_DIR was called, it
# must be in that directory.  Otherwise expect it in the current directory.
sub require_libsource_with_macro
{
    my ($cond, $macro, $mystrict, @files) = @_;
    $macro = rvar ($macro) unless ref $macro;
    if ($config_libobj_dir)
      {
	require_file_internal ($macro->rdef ($cond)->location, $mystrict,
			       $config_libobj_dir, 0, @files);
      }
    else
      {
	require_file ($macro->rdef ($cond)->location, $mystrict, @files);
      }
}

# queue_required_file_check_or_copy ($QUEUE, $KEY, $DIR, $WHERE,
#                                    $MYSTRICT, @FILES)
# --------------------------------------------------------------
sub queue_required_file_check_or_copy
{
    my ($queue, $key, $dir, $where, $mystrict, @files) = @_;
    my @serial_loc;
    if (ref $where)
      {
        @serial_loc = (QUEUE_LOCATION, $where->serialize ());
      }
    else
      {
        @serial_loc = (QUEUE_STRING, $where);
      }
    $queue->enqueue ($key, $dir, @serial_loc, $mystrict, 0 + @files, @files);
}

# require_queued_file_check_or_copy ($QUEUE)
# ------------------------------------------
sub require_queued_file_check_or_copy
{
    my ($queue) = @_;
    my $where;
    my $dir = $queue->dequeue ();
    my $loc_key = $queue->dequeue ();
    if ($loc_key eq QUEUE_LOCATION)
      {
	$where = Automake::Location::deserialize ($queue);
      }
    elsif ($loc_key eq QUEUE_STRING)
      {
	$where = $queue->dequeue ();
      }
    else
      {
	prog_error "unexpected key $loc_key";
      }
    my $mystrict = $queue->dequeue ();
    my $nfiles = $queue->dequeue ();
    my @files;
    push @files, $queue->dequeue ()
      foreach (1 .. $nfiles);
    return
      unless $strictness >= $mystrict;
    foreach my $file (@files)
      {
        required_file_check_or_copy ($where, $config_aux_dir, $file);
      }
}

# require_conf_file ($WHERE, $MYSTRICT, @FILES)
# ---------------------------------------------
# Looks in configuration path, as specified by AC_CONFIG_AUX_DIR.
sub require_conf_file
{
    my ($where, $mystrict, @files) = @_;
    my $queue = defined $required_conf_file_queue ? 1 : 0;
    require_file_internal ($where, $mystrict, $config_aux_dir,
                           $queue, @files);
}


# require_conf_file_with_macro ($COND, $MACRO, $MYSTRICT, @FILES)
# ---------------------------------------------------------------
sub require_conf_file_with_macro
{
    my ($cond, $macro, $mystrict, @files) = @_;
    require_conf_file (rvar ($macro)->rdef ($cond)->location,
		       $mystrict, @files);
}

################################################################

# require_build_directory ($DIRECTORY)
# ------------------------------------
# Emit rules to create $DIRECTORY if needed, and return
# the file that any target requiring this directory should be made
# dependent upon.
# We don't want to emit the rule twice, and want to reuse it
# for directories with equivalent names (e.g., 'foo/bar' and './foo//bar').
sub require_build_directory
{
  my $directory = shift;

  return $directory_map{$directory} if exists $directory_map{$directory};

  my $cdir = File::Spec->canonpath ($directory);

  if (exists $directory_map{$cdir})
    {
      my $stamp = $directory_map{$cdir};
      $directory_map{$directory} = $stamp;
      return $stamp;
    }

  my $dirstamp = "$cdir/\$(am__dirstamp)";

  $directory_map{$directory} = $dirstamp;
  $directory_map{$cdir} = $dirstamp;

  # Set a variable for the dirstamp basename.
  define_pretty_variable ('am__dirstamp', TRUE, INTERNAL,
			  '$(am__leading_dot)dirstamp');

  # Directory must be removed by 'make distclean'.
  $clean_files{$dirstamp} = DIST_CLEAN;

  $output_rules .= ("$dirstamp:\n"
		    . "\t\@\$(MKDIR_P) $directory\n"
		    . "\t\@: > $dirstamp\n");

  return $dirstamp;
}

# require_build_directory_maybe ($FILE)
# -------------------------------------
# If $FILE lies in a subdirectory, emit a rule to create this
# directory and return the file that $FILE should be made
# dependent upon.  Otherwise, just return the empty string.
sub require_build_directory_maybe
{
    my $file = shift;
    my $directory = dirname ($file);

    if ($directory ne '.')
      {
	return require_build_directory ($directory);
      }
    else
      {
	return '';
      }
}

1;
