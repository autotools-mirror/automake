package Automake::ConditionalSet;

use Carp;
use strict;
use Automake::Conditional;

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
  my $str = $set->string;

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

# Compare condition names.
# Issue them in alphabetical order, foo_TRUE before foo_FALSE.
sub by_condition
{
    # Be careful we might be comparing `' or `#'.
    $a->string =~ /^(.*)_(TRUE|FALSE)$/;
    my ($aname, $abool) = ($1 || '', $2 || '');
    $b->string =~ /^(.*)_(TRUE|FALSE)$/;
    my ($bname, $bbool) = ($1 || '', $2 || '');
    return ($aname cmp $bname
	    # Don't bother with IFs, given that TRUE is after FALSE
	    # just cmp in the reverse order.
	    || $bbool cmp $abool
	    # Just in case...
	    || $a cmp $b);
}

=item C<@conds = $set-$<gt>conds>

Return the list of C<Conditional> objects involved in C<$set>.

=cut

sub conds ($ )
{
  my ($self) = @_;
  return @{$self->{'conds'}} if exists $self->{'conds'};
  my @conds = map { $self->{'hash'}{$_} } (keys %{$self->{'hash'}});
  $self->{'conds'} = [sort by_condition @conds];
  return @conds;
}

=item C<$cond = $set-$<gt>one_cond>

Return one C<Conditional> object involved in C<$set>.

=cut

sub one_cond ($)
{
  my ($self) = @_;
  return (%{$self->{'hash'}},)[1];
}

=item C<$et = $set-$<gt>false>

Return 1 iff the C<ConditionalSet> object is always false (i.e., if it
is empty, or if it contains only false C<Conditional>s). Return 0
otherwise.

=cut

sub false ($ )
{
  my ($self) = @_;
  return 0 == keys %{$self->{'hash'}};
}

=item C<$et = $set-$<gt>true>

Return 1 iff the C<ConditionalSet> object is always true (i.e. covers all
conditions). Return 0 otherwise.

=cut

sub true ($ )
{
  my ($self) = @_;
  return $self->invert->false;
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
      $res = join (',', $self->conds);
    }

  $self->{'string'} = $res;
  return $res;
}


sub _permutations_worker (@)
{
  my @conds = @_;
  return () unless @conds;

  my $cond = shift @conds;
  (my $neg = $cond) =~ s/TRUE$/FALSE/;

  # Recurse.

  # Don't merge `FALSE' conditions, since this will just create
  # a false Conditional, and we'll drop them later in ConditionalSet.
  # (Dropping them now limits the combinatoric explosion.)
  my @ret = ();
  foreach my $c (&_permutations_worker (@conds))
    {
      push (@ret, $c->merge_conds ($cond));
      push (@ret, $c->merge_conds ($neg)) if $neg ne 'FALSE';
    }
  if (! @ret)
    {
      push (@ret, new Automake::Conditional $cond);
      push (@ret, new Automake::Conditional $neg) if $neg ne 'FALSE';
    }

  return @ret;
}

=item C<$perm = $set-E<gt>permutations>

Return a permutations of the subconditions involved in a C<ConditionalSet>.

For instance consider this initial C<ConditionalSet>.

  my $set = new Automake::ConditionalSet
    (new Automake::Conditional ("COND1_TRUE", "COND2_TRUE"),
     new Automake::Conditional ("COND3_FALSE", "COND2_TRUE"));

Calling $<$set-E<gt>permutations> will return the following Conditional set.

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
  my $res = new Automake::ConditionalSet @res;

  $self->{'permutations'} = $res;

  return $res;
}

=item C<$inv = $res-E<gt>invert>

Invert a C<ConditionalSet>.  Return a C<ConditionalSet> which is true
when C<$res> is false, and vice-versa.

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

  # Generate permutations for all subconditions.
  my @perm = $self->permutations->conds;
  # Remove redundant conditions.
  @perm = Automake::Conditional::reduce @perm;

  # Now remove all conditions which imply one of the input conditions.
  my @conds = $self->conds;
  my @notconds = ();
  foreach my $perm (@perm)
    {
      push @notconds, $perm
	if ! $perm->implies_any (@conds);
    }

  my $res = new Automake::ConditionalSet @notconds;

  # Cache result.
  $self->{'invert'} = $res;
  # It's tempting to also set $res->{'invert'} to $self, but that
  # isn't a bad idea as $self hasn't been normalized in any way.
  # (Different inputs can produce the same inverted set.)
  return $res;
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
