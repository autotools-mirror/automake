package Automake::ConditionalSet;

use Carp;
use strict;
use Automake::Conditional qw/TRUE FALSE/;

=head1 NAME

Automake::ConditionalSet - record a disjunction of conditions

=head1 SYNOPSIS

  use Automake::Conditional;
  use Automake::ConditionalSet;

  # Create a conditional to represent "COND1 and not COND2".
  my $cond = new Automake::Conditional "COND1_TRUE", "COND2_FALSE";
  # Create a conditional to represent "not COND3".
  my $other = new Automake::Conditional "COND3_FALSE";

  # Create a ConditionalSet to represent
  #   "(COND1 and not COND2) or (not COND3)"
  my $set = new Automake::ConditionalSet $cond, $other;

  # Return the list of Conditionals involved in $set.
  my @conds = $set->conds;

  # Return one of the Conditional involved in $set.
  my $cond = $set->one_cond;

  # Return true iff $set is always true (i.e. its subconditions
  # conver all cases).
  if ($set->true) { ... }

  # Return false iff $set is always false (i.e. is empty, or contains
  # only false conditions).
  if ($set->false) { ... }

  # Return a string representing the ConditionalSet.
  #   "COND1_TRUE COND2_FALSE | COND3_FALSE"
  my $str = $set->string;

  # Return a human readable string representing the ConditionalSet.
  #   "(COND1 and !COND2) or (!COND3)"
  my $str = $set->human;

  # Build a new ConditionalSet from the permuation of all
  # subconditions appearing in $set.
  my $perm = $set->permutations;

  # Invert a ConditionalSet, i.e., create a new ConditionalSet
  # that complements $set.
  my $inv = $set->invert;

=head1 DESCRIPTION

A C<ConditionalSet> is a disjunction of atomic conditions.  In
Automake they are used to represent the conditions into which Makefile
variables and Makefile rules are defined.

If the variable C<VAR> is defined as

  if COND1
    if COND2
      VAR = value1
    endif
  endif
  if !COND3
    if COND4
      VAR = value2
    endif
  endif

then it will be associated a C<ConditionalSet> created with
the following statement.

  new Automake::ConditionalSet
    (new Automake::Conditional ("COND1_TRUE", "COND2_TRUE"),
     new Automake::Conditional ("COND3_FALSE", "COND4_TRUE"));

As you can see, a C<ConditionalSet> is made from a list of
C<Conditional>s.  Since C<ConditionalSet> is a disjunction, and
C<Conditional> is a conjunction, the above can be read as
follows.

  (COND1 and COND2) or ((not COND3) and COND4)

Like C<Conditional> objects, a C<ConditionalSet> object is unisque
with respect to its conditions.  Two C<ConditionalSet> objects created
for the same set of conditions will have the same adress.  This makes
it easy to compare C<ConditionalSet>s: just compare the references.

=head2 Methods

=over 4

=item C<$set = new Automake::ConditionalSet [@conds]>

Create a C<ConditionalSet> object from the list of C<Conditional>
objects passed in arguments.

If the C<@conds> list is empty, the C<ConditionalSet> is assumed to be
false.

As explained previously, the reference (object) returned is unique
with respect to C<@conds>.  For this purpose, duplicate elements are
ignored.

=cut

# Keys in this hash are ConditionalSet strings. Values are the
# associated object ConditionalSet.  This is used by `new' to reuse
# ConditionalSet objects with identical conditions.
use vars '%_conditional_set_singletons';

sub new ($;@)
{
  my ($class, @conds) = @_;
  my $self = {
    hash => {},
  };
  bless $self, $class;

  for my $cond (@conds)
    {
      confess "`$cond' isn't a reference" unless ref $cond;
      confess "`$cond' isn't an Automake::Conditional"
	unless $cond->isa ("Automake::Conditional");

      # This is a disjunction of conditions, so we drop
      # false conditions.  We'll always treat an "empty"
      # ConditionalSet as false for this reason.
      next if $cond->false;

      # Store conditions as keys AND as values, because blessed
      # objects are converted to string when used as keys (so
      # at least we still have the value when we need to call
      # a method).
      $self->{'hash'}{$cond} = $cond;
    }

  my $key = $self->string;
  if (exists $_conditional_set_singletons{$key})
    {
      return $_conditional_set_singletons{$key};
    }
  $_conditional_set_singletons{$key} = $self;
  return $self;
}

=item C<@conds = $set-E<gt>conds>

Return the list of C<Conditional> objects involved in C<$set>.

=cut

sub conds ($ )
{
  my ($self) = @_;
  return @{$self->{'conds'}} if exists $self->{'conds'};
  my @conds = values %{$self->{'hash'}};
  @conds = sort { $a->string cmp $b->string } @conds;
  $self->{'conds'} = [@conds];
  return @conds;
}

=item C<$cond = $set-E<gt>one_cond>

Return one C<Conditional> object involved in C<$set>.

=cut

sub one_cond ($)
{
  my ($self) = @_;
  return (%{$self->{'hash'}},)[1];
}

=item C<$et = $set-E<gt>false>

Return 1 iff the C<ConditionalSet> object is always false (i.e., if it
is empty, or if it contains only false C<Conditional>s). Return 0
otherwise.

=cut

sub false ($ )
{
  my ($self) = @_;
  return 0 == keys %{$self->{'hash'}};
}

=item C<$et = $set-E<gt>true>

Return 1 iff the C<ConditionalSet> object is always true (i.e. covers all
conditions). Return 0 otherwise.

=cut

sub true ($ )
{
  my ($self) = @_;
  # We cache 'true' so that simplify() can use the value if it's available.
  return $self->{'true'} if defined $self->{'true'};
  my $res = $self->invert->false;
  $self->{'true'} = $res;
  return $res;
}

=item C<$str = $set-E<gt>string>

Build a string which denotes the C<ConditionalSet>.

=cut

sub string ($ )
{
  my ($self) = @_;

  return $self->{'string'} if defined $self->{'string'};

  my $res = '';
  if ($self->false)
    {
      $res = 'FALSE';
    }
  else
    {
      $res = join (' | ', map { $_->string } $self->conds);
    }

  $self->{'string'} = $res;
  return $res;
}

=item C<$cond-E<gt>human>

Build a human readable string which denotes the C<ConditionalSet>.

=cut

sub human ($ )
{
  my ($self) = @_;

  return $self->{'human'} if defined $self->{'human'};

  my $res = '';
  if ($self->false)
    {
      $res = 'FALSE';
    }
  else
    {
      my @c = $self->conds;
      if (1 == @c)
	{
	  $res = $self->human;
	}
      else
	{
	  $res = '(' . join (') or (', map { $_->human } $self->conds) . ')';
	}
    }
  $self->{'human'} = $res;
  return $res;
}


sub _permutations_worker (@)
{
  my @conds = @_;
  return () unless @conds;

  my $cond = shift @conds;

  # Ignore "TRUE" conditions, since they add nothing to permutations.
  return &_permutations_worker (@conds) if $cond eq "TRUE";

  (my $neg = $cond) =~ s/TRUE$/FALSE/;

  # Recurse.
  my @ret = ();
  foreach my $c (&_permutations_worker (@conds))
    {
      push (@ret, $c->merge_conds ($cond));
      push (@ret, $c->merge_conds ($neg));
    }
  if (! @ret)
    {
      push (@ret, new Automake::Conditional $cond);
      push (@ret, new Automake::Conditional $neg);
    }

  return @ret;
}

=item C<$perm = $set-E<gt>permutations>

Return a permutations of the subconditions involved in a C<ConditionalSet>.

For instance consider this initial C<ConditionalSet>.

  my $set = new Automake::ConditionalSet
    (new Automake::Conditional ("COND1_TRUE", "COND2_TRUE"),
     new Automake::Conditional ("COND3_FALSE", "COND2_TRUE"));

Calling C<$set-E<gt>permutations> will return the following Conditional set.

  new Automake::ConditionalSet
    (new Automake::Conditional ("COND1_TRUE", "COND2_TRUE", "COND3_TRUE"),
     new Automake::Conditional ("COND1_FALSE","COND2_TRUE", "COND3_TRUE"),
     new Automake::Conditional ("COND1_TRUE", "COND2_FALSE","COND3_TRUE"),
     new Automake::Conditional ("COND1_FALSE","COND2_FALSE","COND3_TRUE"),
     new Automake::Conditional ("COND1_TRUE", "COND2_TRUE", "COND3_FALSE"),
     new Automake::Conditional ("COND1_FALSE","COND2_TRUE", "COND3_FALSE"),
     new Automake::Conditional ("COND1_TRUE", "COND2_FALSE","COND3_FALSE"),
     new Automake::Conditional ("COND1_FALSE","COND2_FALSE","COND3_FALSE"));

=cut

sub permutations ($ )
{
  my ($self) = @_;

  return $self->{'permutations'} if defined $self->{'permutations'};

  my %atomic_conds = ();

  for my $conditional ($self->conds)
    {
      for my $cond ($conditional->conds)
	{
	  $cond =~ s/FALSE$/TRUE/;
	  $atomic_conds{$cond} = 1;
	}
    }

  my @res = _permutations_worker (keys %atomic_conds);
  # An empty permutation is TRUE, because we ignore TRUE conditions
  # in the recursions.
  @res = (TRUE) unless @res;
  my $res = new Automake::ConditionalSet @res;

  $self->{'permutations'} = $res;

  return $res;
}

=item C<$prod = $set1->multiply ($set2)>

Multiply two conditional sets.

  my $set1 = new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE"),
     new Automake::Conditional ("B_TRUE"));
  my $set2 = new Automake::ConditionalSet
    (new Automake::Conditional ("C_FALSE"),
     new Automake::Conditional ("D_FALSE"));

C<$set1-E<gt>multiply ($set2)> will return

  new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE", "C_FALSE"),
     new Automake::Conditional ("B_TRUE", "C_FALSE"),;
     new Automake::Conditional ("A_TRUE", "D_FALSE"),
     new Automake::Conditional ("B_TRUE", "D_FALSE"));

The argument can also be a C<Conditional>.

=cut

# Same as multiply() but take a list of Conditonal as second argument.
# We use this in invert().
sub _multiply ($@)
{
  my ($self, @set) = @_;
  my @res = ();
  foreach my $selfcond ($self->conds)
    {
      foreach my $setcond (@set)
	{
	  push @res, $selfcond->merge ($setcond);
	}
    }
  return new Automake::ConditionalSet @res;
}

sub multiply ($$)
{
  my ($self, $set) = @_;
  return $self->_multiply ($set) if $set->isa('Automake::Conditional');
  return $self->_multiply ($set->conds);
}

=item C<$inv = $set-E<gt>invert>

Invert a C<ConditionalSet>.  Return a C<ConditionalSet> which is true
when C<$set> is false, and vice-versa.

  my $set = new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE", "B_TRUE"),
     new Automake::Conditional ("A_FALSE", "B_FALSE"));

Calling C<$set-E<gt>invert> will return the following C<ConditionalSet>.

  new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE", "B_FALSE"),
     new Automake::Conditional ("A_FALSE", "B_TRUE"));

=cut

sub invert($ )
{
  my ($self) = @_;

  return $self->{'invert'} if defined $self->{'invert'};

  # The invert of an empty ConditionalSet is TRUE.
  my $res = new Automake::ConditionalSet TRUE;

  #   !((a.b)+(c.d)+(e.f))
  # = (!a+!b).(!c+!d).(!e+!f)
  # We develop this into a sum of product iteratively, starting from TRUE:
  # 1) TRUE
  # 2) TRUE.!a + TRUE.!b
  # 3) TRUE.!a.!c + TRUE.!b.!c + TRUE.!a.!d + TRUE.!b.!d
  # 4) TRUE.!a.!c.!e + TRUE.!b.!c.!e + TRUE.!a.!d.!e + TRUE.!b.!d.!e
  #    + TRUE.!a.!c.!f + TRUE.!b.!c.!f + TRUE.!a.!d.!f + TRUE.!b.!d.!f
  foreach my $cond ($self->conds)
    {
      $res = $res->_multiply ($cond->not);
    }

  # Cache result.
  $self->{'invert'} = $res;
  # It's tempting to also set $res->{'invert'} to $self, but that
  # is a bad idea as $self hasn't been normalized in any way.
  # (Different inputs can produce the same inverted set.)
  return $res;
}

=item C<$simp = $set->simplify>

Find prime implicants and return a simplified C<ConditionalSet>.

=cut

sub _simplify ($)		# Based on Quine-McCluskey's algorithm.
{
  my ($self) = @_;

  # If we know this ConditionalSet is always true, we have nothing to do.
  # Use the cached value if true if available.  Never call true()
  # as this would call invert() which can be slow.
  return new Automake::ConditionalSet TRUE
    if $self->{'hash'}{&TRUE} || $self->{'true'};

  my $nvars = 0;
  my %var_rank;
  my @rank_var;

  # Initialization.
  # Translate and-terms into bit string pairs: [$true, $false].
  #
  # Each variable is given a bit position in the strings.
  #
  # The first string in the pair tells wether a variable is
  # uncomplemented in the term.
  # The second string tells whether a variable is complemented.
  # If a variable does not appear in the term, then its
  # corresponding bit is unset in both strings.

  # Order the resulting bit string pairs by the number of
  # variables involved:
  #   @{$subcubes[2]} is the list of string pairs involving two variables.
  # (Level 0 is used for "TRUE".)
  my @subcubes;
  for my $and_conds ($self->conds)
    {
      my $true = 0;		# Bit string for uncomplemented variables.
      my $false = 0;		# Bit string for complemented variables.

      my @conds = $and_conds->conds;
      for my $cond (@conds)
	{
	  # Which variable is this condition about?
	  confess "can't parse `$cond'"
	    unless $cond =~ /^(.*_)(FALSE|TRUE)$/;

	  # Get the variabe's rank, or assign it a new one.
	  my $rank = $var_rank{$1};
	  if (! defined $rank)
	    {
	      $rank = $nvars++;

	      # FIXME: simplify() cannot work with more that 31 variables.
	      # We need a bitset implementation to allow more variables.
	      # For now we just return the input, as is, not simplified.
	      return $self if $rank >= 31;

	      $var_rank{$1} = $rank;
	      $rank_var[$rank] = $1;
	    }

	  # Fire the relevant bit in the strings.
	  if ($2 eq 'FALSE')
	    {
	      $false |= 1 << $rank;
	    }
	  else
	    {
	      $true |= 1 << $rank;
	    }
	}

      # Register this term.
      push @{$subcubes[1 + $#conds]}, [$true, $false];
    }

  # Real work.  Let's combine terms.

  # Process terms in diminishing size order.  Those
  # involving the maximum number of variables first.
  for (my $m = $#subcubes; $m > 0; --$m)
    {
      my $m_subcubes = $#{$subcubes[$m]};

      # Consider all terms with $m variables.
      for (my $j = 0; $j <= $m_subcubes; ++$j)
	{
	  my $tj = $subcubes[$m][$j];
	  my $jtrue = $tj->[0];
	  my $jfalse = $tj->[1];

	  # Compare them with all other terms with $m variables.
	COMBINATION:
	  for (my $k = $j + 1; $k <= $m_subcubes; ++$k)
	    {
	      my $tk = $subcubes[$m][$k];
	      my $ktrue = $tk->[0];
	      my $kfalse = $tk->[1];

	      # Two terms can combine if they differ only by one variable
	      # (i.e., a bit here), which is complemented in one term
	      # and uncomplemented in the other.
	      my $true  = $jtrue  ^ $ktrue;
	      my $false = $jfalse ^ $kfalse;
	      next COMBINATION if $true != $false;
	      # There should be exactly one bit set.
	      # (`$true & ($true - 1)' unsets the rightmost 1 bit in $true.)
	      next COMBINATION if $true == 0 || $true & ($true - 1);

	      # At this point we know we can combine the two terms.

	      # Mark these two terms as "combined", so they will be
	      # deleted after we have processed all other combinations.
	      $tj->[2] = 1;
	      $tk->[2] = 1;

	      # Actually combine the two terms.
	      my $ctrue  = $jtrue  & $ktrue;
	      my $cfalse = $jfalse & $kfalse;

	      # Don't add the combined term if it already exists.
	    DUP_SEARCH:
	      for my $c (@{$subcubes[$m - 1]})
		{
		  next DUP_SEARCH  if $ctrue  != $c->[0];
		  next COMBINATION if $cfalse == $c->[1];
		}
	      push @{$subcubes[$m - 1]}, [$ctrue, $cfalse];
	    }
	}

      # Delete all covered terms.
      for (my $j = 0; $j <= $m_subcubes; ++$j)
	{
	  delete $subcubes[$m][$j] if $subcubes[$m][$j][2];
	}
    }

  # Finally merge bit strings back into a Automake::ConditionalSet.

  # If level 0 has been filled, we've found `TRUE'.  No need to translate
  # anything.
  return new Automake::ConditionalSet TRUE if $#{$subcubes[0]} >= 0;

  # Otherwise, translate uncombined terms in other levels.

  my @or_conds = ();
  # Process terms in diminishing size order.  Those
  # involving the maximum number of variables first.
  for (my $m = 1; $m <= $#subcubes; ++$m)
    {
      my $m_subcubes = $#{$subcubes[$m]};
      # Consider all terms with $m variables.
      for (my $j = 0; $j <= $m_subcubes; ++$j)
	{
	  my $tj = $subcubes[$m][$j];
	  next unless $tj;	# Skip deleted terms.
	  my $jtrue  = $tj->[0];
	  my $jfalse = $tj->[1];

	  # Filter-out implied terms.
	  #
	  # An and-term at level N might cover and-terms at level M>N.
	  # We need to mark all these covered terms so that they are
	  # not output in the result formula.
	  #
	  # If $tj was generated by combining two terms at level N+1,
	  # there two terms are already marked.  However there might be
	  # implied terms deeper.
	  #
	  #    For instance consider this input: "A_TRUE | A_TRUE C_FALSE".
	  #
	  #    This can also occur with and-term generated by the
	  #    combining algorith.  E.g., consider
	  #    "A_TRUE B_TRUE" | "A_TRUE B_FALSE" | "A_TRUE C_FALSE D_FALSE"
	  #     - at level 3 we can't combine "A_TRUE C_FALSE D_FALSE"
	  #     - at level 2 we can combine "A_TRUE B_TRUE" | "A_TRUE B_FALSE"
	  #       into "A_TRUE
	  #     - at level 1 we an't combine "A_TRUE"
	  #    so without more simplification we would output
	  #    "A_TRUE | A_TRUE C_FALSE D_FALSE"
	  #
	  # So let's filter-out and-terms which are implied by other
	  # and-terms. An and-term $tk is implied by an and-term $tj if $k
	  # involves more variables than $tj (i.e., N>M) and if
	  # all variables occurring in $tk also occur in A in the
	  # same state (complemented or uncomplemented.)
	  for (my $n = $m + 1; $n <= $#subcubes; ++$n)
	    {
	      my $n_subcubes = $#{$subcubes[$n]};
	      for (my $k = 0; $k <= $n_subcubes; ++$k)
		{
		  my $tk = $subcubes[$n][$k];
		  next unless $tk; # Skip deleted terms.
		  my $ktrue = $tk->[0];
		  my $kfalse = $tk->[1];

		  next unless $ktrue == ($ktrue | $jtrue);
		  next unless $kfalse == ($kfalse | $jfalse);

		  delete $subcubes[$n][$k];
		}
	    }

	  # Translate $tj.
	  my @and_conds = ();
	  my $rank = 0;
	  while ($jtrue > 0)
	    {
	      if ($jtrue & 1)
		{
		  push @and_conds, $rank_var[$rank] . 'TRUE';
		}
	      $jtrue >>= 1;
	      ++$rank;
	    }
	  $rank = 0;
	  while ($jfalse > 0)
	    {
	      if ($jfalse & 1)
		{
		  push @and_conds, $rank_var[$rank] . 'FALSE';
		}
	      $jfalse >>= 1;
	      ++$rank;
	    }

	  push @or_conds, new Automake::Conditional @and_conds if @and_conds;
	}
    }

  return new Automake::ConditionalSet @or_conds;
}

sub simplify ($)
{
  my ($self) = @_;
  return $self->{'simplify'} if defined $self->{'simplify'};
  my $res = $self->_simplify ;
  $self->{'simplify'} = $res;
  return $res;
}

=item C<$self-E<gt>sub_conditions ($cond)>

Return the subconditions of C<$self> that contains C<$cond>, with
C<$cond> stripped.

For instance, consider:

  my $a = new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE", "B_TRUE"),
     new Automake::Conditional ("A_TRUE", "C_FALSE"),
     new Automake::Conditional ("A_TRUE", "B_FALSE", "C_TRUE"),
     new Automake::Conditional ("A_FALSE"));
  my $b = new Automake::ConditionalSet
    (new Automake::Conditional ("A_TRUE", "B_FALSE"));

Calling C<$a-E<gt>sub_conditions ($b)> will return the following
C<ConditionalSet>.

  new Automake::ConditionalSet
    (new Automake::Conditional ("C_FALSE"), # From A_TRUE C_FALSE
     new Automake::Conditional ("C_TRUE")); # From A_TRUE B_FALSE C_TRUE"

=cut

sub sub_conditions ($$)
{
  my ($self, $subcond) = @_;
  my @res;

  # Make $subcond blindingly apparent in the ConditionalSet.
  # For instance `$a->_multiply($b)' (from the POD example) is:
  #   new Automake::ConditionalSet
  # 	(new Automake::Conditional ("FALSE"),
  # 	 new Automake::Conditional ("A_TRUE", "B_FALSE", "C_FALSE"),
  # 	 new Automake::Conditional ("A_TRUE", "B_FALSE", "C_TRUE"),
  # 	 new Automake::Conditional ("FALSE"));
  my $prod = $self->_multiply ($subcond);

  # Now, strip $subcond from the non-false Conditionals.
  foreach my $c ($prod->conds)
    {
      if (! $c->false)
	{
	  my @rescond;
	  foreach my $cc ($c->conds)
	    {
	      push @rescond, $cc
		unless $subcond->has ($cc);
	    }
	  push @res, new Automake::Conditional @rescond;
	}
    }
  return new Automake::ConditionalSet @res;
}

=head1 SEE ALSO

L<Automake::Conditional>.

=head1 HISTORY

C<AM_CONDITIONAL>s and supporting code were added to Automake 1.1o by
Ian Lance Taylor <ian@cygnus.org> in 1997.  Since then it has been
improved by Tom Tromey <tromey@redhat.com>, Richard Boulton
<richard@tartarus.org>, Raja R Harinath <harinath@cs.umn.edu>, Akim
Demaille <akim@epita.fr>, and Pavel Roskin <proski@gnu.org>.
Alexandre Duret-Lutz <adl@gnu.org> extracted the code out of Automake
to create this package in 2002.

=cut

1;

### Setup "GNU" style for perl-mode and cperl-mode.
## Local Variables:
## perl-indent-level: 2
## perl-continued-statement-offset: 2
## perl-continued-brace-offset: 0
## perl-brace-offset: 0
## perl-brace-imaginary-offset: 0
## perl-label-offset: -2
## cperl-indent-level: 2
## cperl-brace-offset: 0
## cperl-continued-brace-offset: 0
## cperl-label-offset: -2
## cperl-extra-newline-before-brace: t
## cperl-merge-trailing-else: nil
## cperl-continued-statement-offset: 2
## End:
