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

package Automake::Utils;

use 5.006;
use strict;

use Automake::Channels;
use Automake::ConfVars;
use Automake::Global;
use Automake::Location;
use Automake::Options;
use Automake::XFile;
use Automake::ChannelDefs;
use Automake::Variable 'var';
use Automake::Rule;
use Exporter 'import';
use File::Basename;

use vars qw (@EXPORT);

@EXPORT = qw ($config_aux_dir $am_config_aux_dir
    $config_aux_dir_set_in_configure_ac $seen_maint_mode $relative_dir
    $seen_canonical $am_file_cache &var_SUFFIXES_trigger &locate_aux_dir
    &subst &make_paragraphs &flatten &canonicalize &push_dist_common
    &is_make_dir &backname &get_number_of_threads &locate_am &prepend_srcdir
    &rewrite_inputs_into_dependencies &substitute_ac_subst_variables
    &check_directory);

# Directory to search for configure-required files.  This
# will be computed by locate_aux_dir() and can be set using
# AC_CONFIG_AUX_DIR in configure.ac.
# $CONFIG_AUX_DIR is the 'raw' directory, valid only in the source-tree.
our $config_aux_dir = '';

# $AM_CONFIG_AUX_DIR is prefixed with $(top_srcdir), so it can be used
# in Makefiles.
our $am_config_aux_dir;

our $config_aux_dir_set_in_configure_ac = 0;

# Where AM_MAINTAINER_MODE appears.
our $seen_maint_mode;

# Relative dir of the output makefile.
our $relative_dir;

# Most important AC_CANONICAL_* macro seen so far.
our $seen_canonical = 0;

# Cache each file processed by make_paragraphs.
# (This is different from %transformed_files because
# %transformed_files is reset for each file while %am_file_cache
# it global to the run.)
our %am_file_cache;


# var_SUFFIXES_trigger ($TYPE, $VALUE)
# ------------------------------------
# This is called by Automake::Variable::define() when SUFFIXES
# is defined ($TYPE eq '') or appended ($TYPE eq '+').
# The work here needs to be performed as a side-effect of the
# macro_define() call because SUFFIXES definitions impact
# on $KNOWN_EXTENSIONS_PATTERN which is used used when parsing
# the input am file.
sub var_SUFFIXES_trigger
{
    my ($type, $value) = @_;
    accept_extensions (split (' ', $value));
}


# Find the aux dir.  This should match the algorithm used by
# ./configure. (See the Autoconf documentation for for
# AC_CONFIG_AUX_DIR.)
sub locate_aux_dir
{
  if (! $config_aux_dir_set_in_configure_ac)
    {
      # The default auxiliary directory is the first
      # of ., .., or ../.. that contains install-sh.
      # Assume . if install-sh doesn't exist yet.
      for my $dir (qw (. .. ../..))
	{
	  if (-f "$dir/install-sh")
	    {
	      $config_aux_dir = $dir;
	      last;
	    }
	}
      $config_aux_dir = '.' unless $config_aux_dir;
    }
  # Avoid unsightly '/.'s.
  $am_config_aux_dir =
    '$(top_srcdir)' . ($config_aux_dir eq '.' ? "" : "/$config_aux_dir");
  $am_config_aux_dir =~ s,/*$,,;
}


# subst ($TEXT)
# -------------
# Return a configure-style substitution using the indicated text.
# We do this to avoid having the substitutions directly in automake.in;
# when we do that they are sometimes removed and this causes confusion
# and bugs.
sub subst ($)
{
    my ($text) = @_;
    return '@' . $text . '@';
}


# transform_token ($TOKEN, \%PAIRS, $KEY)
# ---------------------------------------
# Return the value associated to $KEY in %PAIRS, as used on $TOKEN
# (which should be ?KEY? or any of the special %% requests)..
sub transform_token ($\%$)
{
  my ($token, $transform, $key) = @_;
  my $res = $transform->{$key};
  prog_error "Unknown key '$key' in '$token'" unless defined $res;
  return $res;
}


# transform ($TOKEN, \%PAIRS)
# ---------------------------
# If ($TOKEN, $VAL) is in %PAIRS:
#   - replaces %KEY% with $VAL,
#   - enables/disables ?KEY? and ?!KEY?,
#   - replaces %?KEY% with TRUE or FALSE.
sub transform ($\%)
{
  my ($token, $transform) = @_;

  # %KEY%.
  # Must be before the following pattern to exclude the case
  # when there is neither IFTRUE nor IFFALSE.
  if ($token =~ /^%([\w\-]+)%$/)
    {
      return transform_token ($token, %$transform, $1);
    }
  # %?KEY%.
  elsif ($token =~ /^%\?([\w\-]+)%$/)
    {
      return transform_token ($token, %$transform, $1) ? 'TRUE' : 'FALSE';
    }
  # ?KEY? and ?!KEY?.
  elsif ($token =~ /^ \? (!?) ([\w\-]+) \? $/x)
    {
      my $neg = ($1 eq '!') ? 1 : 0;
      my $val = transform_token ($token, %$transform, $2);
      return (!!$val == $neg) ? '##%' : '';
    }
  else
    {
      prog_error "Unknown request format: $token";
    }
}


# $TEXT
# preprocess_file ($MAKEFILE, [%TRANSFORM])
# -----------------------------------------
# Load a $MAKEFILE, apply the %TRANSFORM, and return the result.
# No extra parsing or post-processing is done (i.e., recognition of
# rules declaration or of make variables definitions).
sub preprocess_file
{
  my ($file, %transform) = @_;

  # Complete %transform with global options.
  # Note that %transform goes last, so it overrides global options.
  %transform = ( 'MAINTAINER-MODE'
		 => $seen_maint_mode ? subst ('MAINTAINER_MODE_TRUE') : '',

		 'XZ'          => !! option 'dist-xz',
		 'LZIP'        => !! option 'dist-lzip',
		 'BZIP2'       => !! option 'dist-bzip2',
		 'COMPRESS'    => !! option 'dist-tarZ',
		 'GZIP'        =>  ! option 'no-dist-gzip',
		 'SHAR'        => !! option 'dist-shar',
		 'ZIP'         => !! option 'dist-zip',

		 'INSTALL-INFO' =>  ! option 'no-installinfo',
		 'INSTALL-MAN'  =>  ! option 'no-installman',
		 'CK-NEWS'      => !! option 'check-news',

		 'SUBDIRS'      => !! Automake::Variable::var ('SUBDIRS'),
		 'TOPDIR_P'     => $relative_dir eq '.',

		 'BUILD'    => ($seen_canonical >= AC_CANONICAL_BUILD),
		 'HOST'     => ($seen_canonical >= AC_CANONICAL_HOST),
		 'TARGET'   => ($seen_canonical >= AC_CANONICAL_TARGET),

		 'LIBTOOL'      => !! Automake::Variable::var ('LIBTOOL'),
		 'NONLIBTOOL'   => 1,
		%transform);

  if (! defined ($_ = $am_file_cache{$file}))
    {
      verb "reading $file";
      # Swallow the whole file.
      my $fc_file = new Automake::XFile "< $file";
      my $saved_dollar_slash = $/;
      undef $/;
      $_ = $fc_file->getline;
      $/ = $saved_dollar_slash;
      $fc_file->close;
      # Remove ##-comments.
      # Besides we don't need more than two consecutive new-lines.
      s/(?:$IGNORE_PATTERN|(?<=\n\n)\n+)//gom;
      # Remember the contents of the just-read file.
      $am_file_cache{$file} = $_;
    }

  # Substitute Automake template tokens.
  s/(?: % \?? [\w\-]+ %
      | \? !? [\w\-]+ \?
    )/transform($&, %transform)/gex;
  # transform() may have added some ##%-comments to strip.
  # (we use '##%' instead of '##' so we can distinguish ##%##%##% from
  # ####### and do not remove the latter.)
  s/^[ \t]*(?:##%)+.*\n//gm;

  return $_;
}


# @PARAGRAPHS
# make_paragraphs ($MAKEFILE, [%TRANSFORM])
# -----------------------------------------
# Load a $MAKEFILE, apply the %TRANSFORM, and return it as a list of
# paragraphs.
sub make_paragraphs
{
  my ($file, %transform) = @_;
  $transform{FIRST} = !$transformed_files{$file};
  $transformed_files{$file} = 1;

  my @lines = split /(?<!\\)\n/, preprocess_file ($file, %transform);
  my @res;

  while (defined ($_ = shift @lines))
    {
      my $paragraph = $_;
      # If we are a rule, eat as long as we start with a tab.
      if (/$RULE_PATTERN/smo)
	{
	  while (defined ($_ = shift @lines) && $_ =~ /^\t/)
	    {
	      $paragraph .= "\n$_";
	    }
	  unshift (@lines, $_);
	}

      # If we are a comments, eat as much comments as you can.
      elsif (/$COMMENT_PATTERN/smo)
	{
	  while (defined ($_ = shift @lines)
		 && $_ =~ /$COMMENT_PATTERN/smo)
	    {
	      $paragraph .= "\n$_";
	    }
	  unshift (@lines, $_);
	}

      push @res, $paragraph;
    }

  return @res;
}


# $STRING
# flatten ($ORIGINAL_STRING)
# --------------------------
sub flatten
{
  $_ = shift;

  s/\\\n//somg;
  s/\s+/ /g;
  s/^ //;
  s/ $//;

  return $_;
}


# Canonicalize the input parameter.
sub canonicalize
{
    my ($string) = @_;
    $string =~ tr/A-Za-z0-9_\@/_/c;
    return $string;
}


# Push a list of files onto '@dist_common'.
sub push_dist_common
{
  prog_error "push_dist_common run after handle_dist"
    if $handle_dist_run;
  push @dist_common, @_;
}

# Each key in this hash is the name of a directory holding a
# Makefile.in.  These variables are local to 'is_make_dir'.
my %make_dirs = ();
my $make_dirs_set = 0;

# is_make_dir ($DIRECTORY)
# ------------------------
sub is_make_dir
{
    my ($dir) = @_;
    if (! $make_dirs_set)
    {
	foreach my $iter (@configure_input_files)
	{
	    $make_dirs{dirname ($iter)} = 1;
	}
	# We also want to notice Makefile.in's.
	foreach my $iter (@other_input_files)
	{
	    if ($iter =~ /Makefile\.in$/)
	    {
		$make_dirs{dirname ($iter)} = 1;
	    }
	}
	$make_dirs_set = 1;
    }
    return defined $make_dirs{$dir};
}


# $BACKPATH
# backname ($RELDIR)
# -------------------
# If I "cd $RELDIR", then to come back, I should "cd $BACKPATH".
# For instance 'src/foo' => '../..'.
# Works with non strictly increasing paths, i.e., 'src/../lib' => '..'.
sub backname
{
    my ($file) = @_;
    my @res;
    foreach (split (/\//, $file))
    {
	next if $_ eq '.' || $_ eq '';
	if ($_ eq '..')
	{
	    pop @res
	      or prog_error ("trying to reverse path '$file' pointing outside tree");
	}
	else
	{
	    push (@res, '..');
	}
    }
    return join ('/', @res) || '.';
}


# Logic for deciding how many worker threads to use.
sub get_number_of_threads ()
{
  my $nthreads = $ENV{'AUTOMAKE_JOBS'} || 0;

  $nthreads = 0
    unless $nthreads =~ /^[0-9]+$/;

  # It doesn't make sense to use more threads than makefiles,
  my $max_threads = @input_files;

  if ($nthreads > $max_threads)
    {
      $nthreads = $max_threads;
    }
  return $nthreads;
}



# $input
# locate_am (@POSSIBLE_SOURCES)
# -----------------------------
# AC_CONFIG_FILES allow specifications such as Makefile:top.in:mid.in:bot.in
# This functions returns the first *.in file for which a *.am exists.
# It returns undef otherwise.
sub locate_am
{
  my (@rest) = @_;
  my $input;
  foreach my $file (@rest)
    {
      if (($file =~ /^(.*)\.in$/) && -f "$1.am")
	{
	  $input = $file;
	  last;
	}
    }
  return $input;
}


# @DEPENDENCIES
# prepend_srcdir (@INPUTS)
# ------------------------
# Prepend $(srcdir) or $(top_srcdir) to all @INPUTS.  The idea is that
# if an input file has a directory part the same as the current
# directory, then the directory part is simply replaced by $(srcdir).
# But if the directory part is different, then $(top_srcdir) is
# prepended.
sub prepend_srcdir
{
  my (@inputs) = @_;
  my @newinputs;

  foreach my $single (@inputs)
    {
      if (dirname ($single) eq $relative_dir)
	{
	  push (@newinputs, '$(srcdir)/' . basename ($single));
	}
      else
	{
	  push (@newinputs, '$(top_srcdir)/' . $single);
	}
    }
  return @newinputs;
}


# Helper function for 'substitute_ac_subst_variables'.
sub substitute_ac_subst_variables_worker
{
  my ($token) = @_;
  return "\@$token\@" if var $token;
  return "\${$token\}";
}


# substitute_ac_subst_variables ($TEXT)
# -------------------------------------
# Replace any occurrence of ${FOO} in $TEXT by @FOO@ if FOO is an AC_SUBST
# variable.
sub substitute_ac_subst_variables
{
  my ($text) = @_;
  $text =~ s/\$[{]([^ \t=:+{}]+)}/substitute_ac_subst_variables_worker ($1)/ge;
  return $text;
}


# @DEPENDENCIES
# rewrite_inputs_into_dependencies ($OUTPUT, @INPUTS)
# ---------------------------------------------------
# Compute a list of dependencies appropriate for the rebuild
# rule of
#   AC_CONFIG_FILES($OUTPUT:$INPUT[0]:$INPUTS[1]:...)
# Also distribute $INPUTs which are not built by another AC_CONFIG_FOOs.
sub rewrite_inputs_into_dependencies
{
  my ($file, @inputs) = @_;
  my @res = ();

  for my $i (@inputs)
    {
      # We cannot create dependencies on shell variables.
      next if (substitute_ac_subst_variables $i) =~ /\$/;

      if (exists $ac_config_files_location{$i} && $i ne $file)
	{
	  my $di = dirname $i;
	  if ($di eq $relative_dir)
	    {
	      $i = basename $i;
	    }
	  # In the top-level Makefile we do not use $(top_builddir), because
	  # we are already there, and since the targets are built without
	  # a $(top_builddir), it helps BSD Make to match them with
	  # dependencies.
	  elsif ($relative_dir ne '.')
	    {
	      $i = '$(top_builddir)/' . $i;
	    }
	}
      else
	{
	  msg ('error', $ac_config_files_location{$file},
	       "required file '$i' not found")
	    unless $i =~ /\$/ || exists $output_files{$i} || -f $i;
	  ($i) = prepend_srcdir ($i);
	  push_dist_common ($i);
	}
      push @res, $i;
    }
  return @res;
}


# check_directory ($NAME, $WHERE [, $RELATIVE_DIR = "."])
# -------------------------------------------------------
# Ensure $NAME is a directory (in $RELATIVE_DIR), and that it uses a sane
# name.  Use $WHERE as a location in the diagnostic, if any.
sub check_directory
{
  my ($dir, $where, $reldir) = @_;
  $reldir = '.' unless defined $reldir;

  error $where, "required directory $reldir/$dir does not exist"
    unless -d "$reldir/$dir";

  # If an 'obj/' directory exists, BSD make will enter it before
  # reading 'Makefile'.  Hence the 'Makefile' in the current directory
  # will not be read.
  #
  #  % cat Makefile
  #  all:
  #          echo Hello
  #  % cat obj/Makefile
  #  all:
  #          echo World
  #  % make      # GNU make
  #  echo Hello
  #  Hello
  #  % pmake     # BSD make
  #  echo World
  #  World
  msg ('portability', $where,
       "naming a subdirectory 'obj' causes troubles with BSD make")
    if $dir eq 'obj';

  # 'aux' is probably the most important of the following forbidden name,
  # since it's tempting to use it as an AC_CONFIG_AUX_DIR.
  msg ('portability', $where,
       "name '$dir' is reserved on W32 and DOS platforms")
    if grep (/^\Q$dir\E$/i, qw/aux lpt1 lpt2 lpt3 com1 com2 com3 com4 con prn/);
}


1;
