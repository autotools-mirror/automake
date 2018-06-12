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

package Automake::File;

use 5.006;
use strict;

use Exporter;
use Automake::ChannelDefs;
use Automake::Channels;
use Automake::Condition qw (TRUE FALSE);
use Automake::CondStack;
use Automake::Config;
use Automake::Global;
use Automake::Location;
use Automake::Rule;
use Automake::RuleDef;
use Automake::Utils;
use Automake::VarDef;
use Automake::Variable;

use vars qw (@ISA @EXPORT);

@ISA = qw (Exporter);
@EXPORT = qw (file_contents_internal file_contents);

# ($COMMENT, $VARIABLES, $RULES)
# file_contents_internal ($IS_AM, $FILE, $WHERE, [%TRANSFORM])
# ------------------------------------------------------------
# Return contents of a file from $libdir/am, automatically skipping
# macros or rules which are already known. $IS_AM iff the caller is
# reading an Automake file (as opposed to the user's Makefile.am).
sub file_contents_internal
{
    my ($is_am, $file, $where, %transform) = @_;

    $where->set ($file);

    my $result_vars = '';
    my $result_rules = '';
    my $comment = '';
    my $spacing = '';

    # The following flags are used to track rules spanning across
    # multiple paragraphs.
    my $is_rule = 0;		# 1 if we are processing a rule.
    my $discard_rule = 0;	# 1 if the current rule should not be output.

    # We save the conditional stack on entry, and then check to make
    # sure it is the same on exit.  This lets us conditionally include
    # other files.
    my @saved_cond_stack = @cond_stack;
    my $cond = new Automake::Condition (@cond_stack);

    foreach (make_paragraphs ($file, %transform))
    {
	# FIXME: no line number available.
	$where->set ($file);

	# Sanity checks.
	error $where, "blank line following trailing backslash:\n$_"
	  if /\\$/;
	error $where, "comment following trailing backslash:\n$_"
	  if /\\#/;

	if (/^$/)
	{
	    $is_rule = 0;
	    # Stick empty line before the incoming macro or rule.
	    $spacing = "\n";
	}
	elsif (/$COMMENT_PATTERN/mso)
	{
	    $is_rule = 0;
	    # Stick comments before the incoming macro or rule.
	    $comment = "$_\n";
	}

	# Handle inclusion of other files.
	elsif (/$INCLUDE_PATTERN/o)
	{
	    if ($cond != FALSE)
	      {
		my $file = ($is_am ? "$libdir/am/" : '') . $1;
		$where->push_context ("'$file' included from here");
		# N-ary '.=' fails.
		my ($com, $vars, $rules)
		  = file_contents_internal ($is_am, $file, $where, %transform);
		$where->pop_context;
		$comment .= $com;
		$result_vars .= $vars;
		$result_rules .= $rules;
	      }
	}

	# Handling the conditionals.
	elsif (/$IF_PATTERN/o)
	  {
	    $cond = cond_stack_if ($1, $2, $file);
	  }
	elsif (/$ELSE_PATTERN/o)
	  {
	    $cond = cond_stack_else ($1, $2, $file);
	  }
	elsif (/$ENDIF_PATTERN/o)
	  {
	    $cond = cond_stack_endif ($1, $2, $file);
	  }

	# Handling rules.
	elsif (/$RULE_PATTERN/mso)
	{
	  $is_rule = 1;
	  $discard_rule = 0;
	  # Separate relationship from optional actions: the first
	  # `new-line tab" not preceded by backslash (continuation
	  # line).
	  my $paragraph = $_;
	  /^(.*?)(?:(?<!\\)\n(\t.*))?$/s;
	  my ($relationship, $actions) = ($1, $2 || '');

	  # Separate targets from dependencies: the first colon.
	  $relationship =~ /^([^:]+\S+) *: *(.*)$/som;
	  my ($targets, $dependencies) = ($1, $2);
	  # Remove the escaped new lines.
	  # I don't know why, but I have to use a tmp $flat_deps.
	  my $flat_deps = flatten ($dependencies);
	  my @deps = split (' ', $flat_deps);

	  foreach (split (' ', $targets))
	    {
	      # FIXME: 1. We are not robust to people defining several targets
	      # at once, only some of them being in %dependencies.  The
	      # actions from the targets in %dependencies are usually generated
	      # from the content of %actions, but if some targets in $targets
	      # are not in %dependencies the ELSE branch will output
	      # a rule for all $targets (i.e. the targets which are both
	      # in %dependencies and $targets will have two rules).

	      # FIXME: 2. The logic here is not able to output a
	      # multi-paragraph rule several time (e.g. for each condition
	      # it is defined for) because it only knows the first paragraph.

	      # FIXME: 3. We are not robust to people defining a subset
	      # of a previously defined "multiple-target" rule.  E.g.
	      # 'foo:' after 'foo bar:'.

	      # Output only if not in FALSE.
	      if (defined $dependencies{$_} && $cond != FALSE)
		{
		  depend ($_, @deps);
		  register_action ($_, $actions);
		}
	      else
		{
		  # Free-lance dependency.  Output the rule for all the
		  # targets instead of one by one.
		  my @undefined_conds =
		    Automake::Rule::define ($targets, $file,
					    $is_am ? RULE_AUTOMAKE : RULE_USER,
					    $cond, $where);
		  for my $undefined_cond (@undefined_conds)
		    {
		      my $condparagraph = $paragraph;
		      $condparagraph =~ s/^/$undefined_cond->subst_string/gme;
		      $result_rules .= "$spacing$comment$condparagraph\n";
		    }
		  if (scalar @undefined_conds == 0)
		    {
		      # Remember to discard next paragraphs
		      # if they belong to this rule.
		      # (but see also FIXME: #2 above.)
		      $discard_rule = 1;
		    }
		  $comment = $spacing = '';
		  last;
		}
	    }
	}

	elsif (/$ASSIGNMENT_PATTERN/mso)
	{
	    my ($var, $type, $val) = ($1, $2, $3);
	    error $where, "variable '$var' with trailing backslash"
	      if /\\$/;

	    $is_rule = 0;

	    Automake::Variable::define ($var,
					$is_am ? VAR_AUTOMAKE : VAR_MAKEFILE,
					$type, $cond, $val, $comment, $where,
					VAR_ASIS)
	      if $cond != FALSE;

	    $comment = $spacing = '';
	}
	else
	{
	    # This isn't an error; it is probably some tokens which
	    # configure is supposed to replace, such as '@SET-MAKE@',
	    # or some part of a rule cut by an if/endif.
	    if (! $cond->false && ! ($is_rule && $discard_rule))
	      {
		s/^/$cond->subst_string/gme;
		$result_rules .= "$spacing$comment$_\n";
	      }
	    $comment = $spacing = '';
	}
    }

    error ($where, @cond_stack ?
	   "unterminated conditionals: @cond_stack" :
	   "too many conditionals closed in include file")
      if "@saved_cond_stack" ne "@cond_stack";

    return ($comment, $result_vars, $result_rules);
}


# $CONTENTS
# file_contents ($BASENAME, $WHERE, [%TRANSFORM])
# -----------------------------------------------
# Return contents of a file from $libdir/am, automatically skipping
# macros or rules which are already known.
sub file_contents
{
    my ($basename, $where, %transform) = @_;
    my ($comments, $variables, $rules) =
      file_contents_internal (1, "$libdir/am/$basename.am", $where,
			      %transform);
    return "$comments$variables$rules";
}

1;
