package Tree;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(input stmts stmt automakerule makerule conditional ifblock 
optionalelse optionalcond optionalrhs optionalcomments lhs rhs commentlist primaries 
optionlist traverse printgraph recursesubdirs);

my $isSubdir = 0 , @subdirnodes = ();

# Grammar Rule : (1) input => stmts
# Create a node having child as stmts.
sub input($)
{
	my ( $val ) = @_;
	my %node = ( name => input, childs => [ $val ] );
	push @{$node{childs}}, subdirNode() if $#subdirnodes > -1;
	return \%node;
}

# Creates a Node having all the sub directories which are to be recursed.
sub subdirNode()
{
	my %node = ( name => subdir, empty => 1 );
	my @subdir = ();
	push @subdir, @{ $_ -> { value }} foreach @subdirnodes;
	$node{ subdirs } = \@subdir;
	return \%node;
}

# Grammar Rule : (1) stmts=> stmt '\n'
# Creates a node having a child as stmt
#				 (2) stmts=> stmts stmt '\n'
# Creates a node having a child as stmt. Insert the created node into 
# the childs array of the stmts(First Argument).
sub stmts($$;$)
{
	my ( $val1, $val2, $val3) = @_;
	if($val3 == undef)
	{
		my %node = ( name => stmts, childs => [ $val1 ]);
		return \%node;
	}
	else
	{
		push @{$val1 -> { childs }}, $val2;
		return $val1;
	}
}


# Grammar Rule : (1) stmt => automakerule
#				 (2) stmt => makerule
#				 (3) stmt => commentlist
#				 (4) stmt => conditional
#				 (5) stmt => includerule
# Create a node with corresponding child node.
sub stmt($)
{
	my ( $val1 ) = @_;
	my %node = ( name => stmt , childs => [ $val1 ]);
	return \%node;
}

# Grammar Rule : (1) automakerule => lhs '=' optionalrhs optionalcomments
# 				 (2) automakerule => lhs '+' '=' optionalrhs optionalcomments
# Create a node for automake rule.
sub automakerule($$$$;$)
{
	my ( $val1, $val2, $val3, $val4, $val5 ) = @_;
	my %node = (name => automakerule, childs => [ $val1 ]);
	if($val2->[0] eq '=')
	{
		push @{ $node{ childs }}, $val3;
		push @{ $node{ childs }}, $val4 if $val4;
	}
	else
	{
		push @{ $node{ childs }}, $val4;
		push @{ $node{ childs }}, $val5 if $val5;
		$node{ append } = true;
	}
	return \%node;
}

# Grammar Rule : (1) makerule => value ':' rhs
# Create a node for make rule.
sub makerule($$$)
{
	my ( $val1, $val2, $val3 ) = @_;
	my %node = (name => makerule, childs => [ $val1,$val3 ]);
	return \%node;
}

# Grammar Rule : (1) optionalrhs =>
# Create an empty node.
#				 (2) optionalrhs => rhs
# Create a node with rhs as child.
sub optionalrhs(;$)
{
	my ( $val ) = @_;
	my %node = ( name => optionalrhs );
	if( $val == undef )
	{
		$node{ empty } = 1;
	}
	else
	{
		$node{ childs } = [ $val ];
		push @subdirnodes, $val if $isSubdir;
	}
	$isSubdir = 0;
	return \%node;
}

# Grammar Rule : (1) optionalcomments => 
# Create an empty node.
# 				 (2) optionalcomments => commentlist
# Create a node with commentlist as child.
sub optionalcomments(;$)
{
	my ( $val ) = @_;
	my %node = ( name => optionalcomments );
	if( $val == undef )
	{
		$node{ empty } = 1;
	}
	else
	{
		$node{ childs } = [ $val ];
	}
	return \%node;
}

# Grammar Rule : (1) conditional => ifblock optionalelse endif optionalcond
# Create a node for conditional statement.
sub conditional($$$)
{
	my ( $val1, $val2, $val3 ) = @_;
	my %node = ( name => conditional, childs => [ $val1, $val2]);
	return \%node;
}

# Grammar Rule : (1) ifblock => if value newline stmts
# Create a node for if block.
sub ifblock($$$$$)
{
	my ( $val1, $val2, $val3, $val4, $val5) = @_;
	my %node = ( name => ifblock, condition => $val2 -> [1], childs => [$val4]);
	return \%node;
}

# Grammar Rule : (1) optionalelse =>
# Create an empty node.
#				 (2) optionalelse => else newline stmts
# Create a node with child as automakerule.
sub optionalelse(;$$$$)
{
	my ( $val1, $val2, $val3, $val4 ) = @_;
	my %node = ( name => optionalelse );
	if( $val1 == undef )
	{
		$node{ empty } = 1;
	}
	else
	{
		$node{ childs } = [ $val3 ];
	}
	return \%node;
}

# Grammar Rule : (1) optionalcond =>
# Create an empty node.
#				 (2) optionalcond => value
# Create a node with child as automakerule.
sub optionalcond(;$)
{
	my ( $val1 ) = @_;
	my %node = ( name => optionalcond );
	if( $val1 == undef )
	{
		$node{ empty } = 1;
	}
	else
	{
		$node{ value } = $val1->[1];
	}
	return \%node;
}

# Grammar Rule : (1) lhs => optionlist primaries
# Create a node for left hand side of variable defination consisting of 
# option list and primary.
#                (2) lhs => value
# Create a node for left hand side of variable defination having a simple
# variable defination.
sub lhs($;$)
{
	my ( $val1, $val2 ) = @_;
	my %node = ( name => lhs);
	if( $val2 == undef )
	{
		$node{ value } = $val1 -> [1];
		$isSubdir = 1 if $node{value} eq 'SUBDIRS';
	}
	else
	{
		$node{ childs } = [ $val1, $val2 ];
	}
	return \%node;
}

# Grammar Rule : (1) rhs => rhsval
# Creates a node having rhsval as its value.
#				(2) rhs => rhs rhsval
# Inserts rhsval into the array pointed by value key in rhs.		
sub rhs($;$)
{
	my ( $val1, $val2 ) = @_;
	if($val2 == undef)
	{
		my %node = ( name => rhs, value => [$val1 -> [1]]);
		return \%node;
	}
	else
	{
		push @{ $val1 -> { value }}, $val2 -> [1];
		return $val1;
	}
}

# Grammar Rule : (1) commentlist => comment
# Creates a node having comment as its value.
#				(2) commentlist => commentlist comment
# Inserts comment into the array pointed by value key in commentlist.
sub commentlist($;$)
{
	my ( $val1, $val2 ) = @_;
	if( $val2 == undef )
	{
		my %node = ( name => commentlist, value => [ $val1 -> [1]]);
		return \%node;
	}
	else
	{
		push @{ $val1 -> { value }} , $val2 -> [1];
		return $val1;
	}
}

# Grammar Rule : (1) primaries : PROGRAMS
#				 (2) primaries : LIBRARIES
#				 (3) primaries : LTLIBRARIES
#				 (4) primaries : LISP
#				 (5) primaries : PYTHON
#				 (6) primaries : JAVA
#				 (7) primaries : SCRIPTS
#				 (8) primaries : DATA
#				 (9) primaries : HEADERS
#				 (10) primaries : MASN
#				 (11) primaries : TEXINFOS
#				 (12) primaries : value
# Creates a node corresponding to the given primary.
sub primaries($)
{
	my ( $val ) = @_;
	my %node = ( name => primaries );
	if( $val -> [0] eq 'value')
	{
		$node{ value } = $val -> [1];
	}
	else
	{
		$node{ value } = $val;
	}
	return \%node;
}

# Grammar Rule : (1) optionlist : value '_'
# Create a node having data value in val key.
#				 (2) optionlist : optionlist value '_'
# Add the data value to val key in the node pointed by optionlist(First Argument).
sub optionlist($$;$)
{
	my ( $val1, $val2, $val3 ) = @_;
	if($val3 == undef)
	{
		my %node = (name => optionlist, val => [$val1 -> [1]]);
		return \%node;
	}
	else
	{
		push @{$val1 -> {val}},$val2 -> [1];
		return $val1;
	}
}

sub includerule($$)
{
	my ( $val1, $val2 ) = @_;
	print STDERR $val2;
	my %node = (name => includerule, value => $val2);
	return \%node;
}

# printgraph(Hash)
# prints the AST to Standard Output by traversing the tree starting at node
# pointed by hash.
sub printgraph($)
{
	print "graph graphname {\n";
	my ( $ref ) = @_;
	print "0 [label=\"Root\"];";
	traverse( $ref, 0);
	print "}\n";
}

#Stores the next id to be alloted to new node.
my $id = 0;

# traverse(Hash, Parent Id)
# Traverses the tree recursively. Prints the information about the current node
# to Standard Output. Call all its child with Parent Id equal to current Node Id.
sub traverse($$)
{
	my ( $ref,$parent ) = @_;
	my %node = %$ref;
	return if $node{empty};
	$id++;
	my $curr_id = $id;
	print "$parent--$id;\n";
	my $label = "";
	@keys = sort grep {!/^childs/} keys %node;
	foreach $key ( @keys )
	{
		$label .= $key."=>";
		if(ref( $node{ $key }) eq 'ARRAY')
		{
			$label .= join(" ",@{$node{$key}})."\n";
		}
		else
		{
			$label .= $node{$key}." ";
		}
	}
	print "$curr_id [label=\"$label\"];";
	if( $node{childs} )
	{
		my $val1 = $node{childs};
		foreach $child (@$val1)
		{
			traverse( $child, $curr_id );
		}
	}
}

# recursesubdirs(Basedir, Reference)
# Recurse into sub directories to generate AST 
sub recursesubdirs($$)
{
	my ( $basedir , $ref) = @_;
	my %node= %$ref;
	if( scalar @{ $node{childs} } == 2)
	{
		my $subdirRef = $node{childs} -> [1];
		my %subdirNode = %$subdirRef;
		foreach $val ( @{ $subdirNode{subdirs} } )
		{
			system( "parser.pl $basedir/$val/Makefile.am > $basedir/$val/ast.gv" );
			system( "unflatten -f -l 10 -c 10 -o $basedir/$val/ast1.gv $basedir/$val/ast.gv" );
			system( "dot -Tpng $basedir/$val/ast1.gv > $basedir/$val/ast.png" );
			system( "rm $basedir/$val/ast.gv $basedir/$val/ast1.gv" );
		}
	}
}
1;