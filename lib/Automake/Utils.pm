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
use Exporter;
use Automake::Global;
use Automake::Location;
use Automake::Options;
use Automake::XFile;
use Automake::ChannelDefs;
use Automake::Variable;
use Automake::Rule;

use vars qw (@ISA @EXPORT);

@ISA = qw (Exporter);
@EXPORT = qw (var_SUFFIXES_trigger locate_aux_dir subst
	      make_paragraphs flatten);

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


1;
