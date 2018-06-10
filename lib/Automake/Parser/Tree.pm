package Tree;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(input stmt stmts lhs rhs primaries optionlist commentlist traverse printgraph);

# Grammar Rule : (1) input => stmts
# Create a node having child as stmts.
sub input($)
{
	my ( $val ) = @_;
	my %node = (name => input, childs => [ $val ]);
	return \%node;
}

# Grammar Rule : (1) stmt => lhs '=' rhs
# Create a node for Automake rule having lhs and rhs as its childs.
#				 (2) stmt => lhs '=' rhs commentlist
# Create a node for Automake rule having lhs, rhs and comments as its child.
#				 (3) stmt => value ':' rhs
# Create a node for Make rule having lhs and rhs as its childs.
#				 (4) stmt => commentlist
# Create a node for comments.
sub stmt($;$$;$)
{
	my ( $val1, $val2, $val3, $val4 ) = @_;
	my %node;
	if( !$val2 )
	{
		%node = (name => stmt, childs => [ $val1 ], type => comment);
	}
	elsif( $val2 -> [0] eq '=' )
	{
		%node = (name => stmt, childs => [ $val1,$val3 ],type => automake);
		if( $val4 )
		{
			push @{ $node{ childs }}, $val4;
		}
	}
	else
	{
		%node = (name => stmt, childs => [ $val1,$val3 ],type => make);
	} 
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
		my %node = (name => stmts, childs => [ $val1 ]);
		my %nodeval = (name => stmts, childs => [ \%node ]);
		return \%nodeval;
	}
	else
	{
		my %node = (name => stmts,childs => [ $val2 ]);
		push @{ $val1 -> { childs }}, \%node;
		return $val1;
	}
}

# Grammar Rule : (1) lhs => optionlist primaries
# Create a node for left hand side of variable defination consisting of 
# option list and primary.
sub lhs($$)
{
	my ( $val1, $val2 ) = @_;
	my %node = (name => lhs, childs => [ $val1, $val2 ]);
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
	if($val2 == undef)
	{
		my %node = ( name => commentlist, value => [ $val1 -> [1]]);
		return \%node;
	}
	else
	{
		push @{ $val1 -> {value}} , $val2 -> [1];
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
	my %node;
	if( $val -> [0] eq 'value')
	{
		%node = ( name => primaries, val=> $val -> [1]);
	}
	else
	{
		%node = ( name => primaries, val => $val);
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

# printgraph(Hash)
# prints the AST by traversing the tree starting at node pointed by hash.
sub printgraph($)
{
	my $FH;
	open( $FH, '>', 'ast.gv' ) or die $!;
	print $FH "graph graphname {\n";
	my ( $ref ) = @_;
	print $FH "0 [label=\"Root\"];";
	traverse( $ref, $FH, 0);
	print $FH "}\n";
	close $FH;
}

#Stores the next id to be alloted to new node.
my $id=0;

# traverse(Hash, File Handle, Parent Id)
# Traverses the tree recursively. Prints the information about the current 
# node to file. Call all its child with Parent Id equal to current Node Id.
sub traverse($$$)
{
	my ( $ref,$FH,$parent ) = @_;
	$id++;
	my $curr_id = $id;
	my %node = %$ref;
	print $FH "$parent--$id;\n";
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
	print $FH "$curr_id [label=\"$label\"];";
	if( $node{childs} )
	{
		my $val1 = $node{childs};
		foreach $child (@$val1)
		{
			traverse($child,$FH,$curr_id);
		}
	}
}
1;