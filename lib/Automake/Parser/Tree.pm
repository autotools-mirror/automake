package Tree;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(input stmt stmts lhs primaries optionlist traverse printgraph);

# Grammar Rule : (1) input => stmts
# Create a node having child as stmts.
sub input($)
{
	my ($val) = @_;
	my %node = (name => input, childs => [$val]);
	return \%node;
}

# Grammar Rule : (1) stmt => lhs '=' rhs
# Create a node for Automake rule. It has lhs and rhs as childs.
#				 (2) stmt => value ':' rhs
# Create a node for Make rule. It has value and rhs as childs.
sub stmt($$$)
{
	my ($lhs, $sym, $rhs) = @_;
	my %node;
	if($sym -> [0] eq '=')
	{
		my %rhsnode = (name => rhs, val => $rhs -> [1]);
		%node = (name => stmt, childs => [$lhs, \%rhsnode],type => automake);
	}
	else
	{
		%node = (name => stmt, lhs => $lhs, rhs =>$rhs->[1],type => make);
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
	my ($val1,$val2,$val3) = @_;
	if($val3 == undef)
	{
		my %node = (name => stmts, childs => [$val1]);
		my %nodeval = (name => stmts, childs => [\%node]);
		return \%nodeval;
	}
	else
	{
		my %node = (name => stmts,childs => [$val2]);
		push @{$val1->{childs}},\%node;
		return $val1;
	}
}

# Grammar Rule : (1) lhs => optionlist primaries
# Create a node for left hand side of variable defination consisting of 
# option list and primary.
sub lhs($$)
{
	my ($val1, $val2) = @_;
	my %node = (name => lhs, childs => [$val1, $val2]);
	return \%node;
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
	my ($val) = @_;
	my %node;
	if( $val -> [0] eq 'value')
	{
		%node = ( name => primaries, val=> $val -> [1]);
	}
	else
	{
		%node = ( name => primaries, val => $val1);
	}
	return \%node;
}

# Grammar Rule : (1) optionlist : value '_'
# Create a node having data value in val key.
#				 (2) optionlist : optionlist value '_'
# Add the data value to val key in the node pointed by optionlist(First Argument).
sub optionlist($$;$)
{
	my ($val1, $val2, $val3) = @_;
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
	open($FH, '>', 'ast.gv') or die $!;
	print $FH "graph graphname {\n";
	my ($ref) = @_;
	print $FH "0 [label=\"Root\"];";
	traverse($ref, $FH, 0, 1);
	print $FH "}\n";
	close $FH;
}
# traverse(Hash, File Handle, Parent Id, Node Id)
# Traverses the tree recursively. Prints the information about the current 
# node to file. Call all its child with Parent Id equal to current Node Id 
# and Node Id equal to (Parent Id*2+i) where i is the ith Child.
sub traverse($$$$)
{
	my ($ref,$FH,$parent,$id)=@_;
	my %node = %$ref;
	#print $level," ",$pos," ",$node{name}," ";
	print $FH "$parent--$id;\n";
	my $label = "";
	@keys = sort grep {!/^childs/} keys %node;
	foreach $key (@keys)
	{
		$label .= $key."=>";
		if(ref($node{$key}) eq 'ARRAY')
		{
			$label .= join(" ",@{$node{$key}})."\n";
		}
		else
		{
			$label .= $node{$key}." ";
		}
	}
	print $FH "$id [label=\"$label\"];";
	if( $node{childs} )
	{
		my $val1 = $node{childs};
		my $i = 1;
		foreach $child (@$val1)
		{
			traverse($child,$FH,$id,2*$id+$i);
			$i++;
		}
	}
}