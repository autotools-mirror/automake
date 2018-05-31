#!/usr/bin/perl
use strict;

#Input data for conversion
my $data;
open ( $data , "< automake.dot" );

#Storing parser table
my @table;

#Stores labels of nodes.
my @labels;

my $acceptstate = 0;

while( <$data> )
{
	if(m/label=\"(.*)\"/)
	{
		my $token = $1;
		if(m/(\d+) -> (\d+)/)
		{
			if($token eq "\$end")
			{
				$table[ $1 ]{ end } = $2;
			}
			else
			{
				$table[ $1 ]{ $token } = $2;
			}
		}
		elsif(m/State (\d+)\\n/)
		{
			$labels[ $1 ] = $token;
		}
	}
	elsif(m/(\d+) -> "\d+R(\d+)"/)
	{
		my $state_number = $1;
		my $production_number = $2;
		$labels[$state_number] =~ m/$production_number (.+): (.+)\.\\l/;
		if($1 eq "\$accept")
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

#Output file
my $ptable;
open ( $ptable , ">ParserTable.pm" );

print $ptable "package ParserTable;\n\nuse Exporter;\nuse Tree;\n\nour \@ISA=qw(Exporter);\nour \@Export=qw(\@table \$accept);\n\nour \$accept=$acceptstate;\n\n";

my @data;

for my $href ( @table )
{
	my @hashval;
	for my $key ( keys %$href )
	{
		if($key eq "reduce")
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

print $ptable sprintf( "our \@table=(\n\t\t%s\n);" , join ( ",\n\t\t" , @data ));