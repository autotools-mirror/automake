#!/usr/bin/perl
use strict;

#Stores the parser table. Its an array of hashes. Each index corresponds 
#to ith state. Every key in hash corresponds to a token, value corresponds 
#to next state. reduce key specifies the reduction of token and its 
#value is an array consisting of number of elements to be reduced and a 
#reference to a function to create a node.
my @table;

#Stores labels of nodes.
my @labels;

my $acceptstate = 0;

while( <> )
{
	#Finding label word in the current line as every node and edge description 
	#contains label property. The value of label is extracted.
	if( m/label=\"(.*)\"/ )
	{
		my $token = $1;
		#Every edge is denoted as state_number -> state_number . The current 
		#line is searched for this and to and from state number are extracted.
		if( m/(\d+) -> (\d+)/ )
		{
			# "$end" token is replaced with end.
			if( $token eq "\$end" )
			{
				$table[ $1 ]{ end } = $2;
			}
			else
			{
				$table[ $1 ]{ $token } = $2;
			}
		}
		#The line describing the node contains State word in its description 
		#followed by state number. The state number is extracted and its value 
		#is stored.
		elsif( m/State (\d+)\\n/ )
		{
			$labels[ $1 ] = $token;
		}
	}
	#Edges denoting reduction are represented as:
	#state_number -> state_number R production_number.
	#production_number denotes the production by which reduction is to happen. 
	#It is extracted from the label value of the specified state.
	elsif( m/(\d+) -> "\d+R(\d+)"/ )
	{
		my $state_number = $1;
		my $production_number = $2;
		#The production is specified as:
		#production_number left side: right side .\l
		#If left side is $accept then acceptance state number is set to the 
		#current state number else a reduce key is inserted into current state 
		#with value equal to an array having number of words on right side and 
		#function with name of the value of left side.
		$labels[$state_number] =~ m/$production_number (.+): (.+)\.\\l/;
		if( $1 eq "\$accept" )
		{
			$table[ $state_number ] = {};
			$acceptstate = $state_number;
		}
		else
		{
			$table[ $state_number ]{ reduce } = [scalar( split( /\s+/ , $2 )) , " \\&$1" ];
		}
	}
}

print "package ParserTable;\n\nuse Exporter;\nuse Tree;\n\nour \@ISA=qw(Exporter);\nour \@Export=qw(\@table \$accept);\n\nour \$accept=$acceptstate;\n\n";

#Prints the table.
my @data;
for my $href ( @table )
{
	my @hashval;
	for my $key ( keys %$href )
	{
		if( $key eq "reduce" )
		{
			push @hashval , sprintf( "$key => [%s]",join(", ",@{ $href -> { $key } }));
		}
		else
		{
			push @hashval, sprintf( "$key => %s",$href -> { $key });
		}
	}
	push @data, sprintf( "{%s}" , join(", " , @hashval ));
}

print sprintf( "our \@table=(\n\t\t%s\n);" , join ( ",\n\t\t" , @data ));