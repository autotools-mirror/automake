package Lexer;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(lex);

# lex(string)
# Takes as input a string of line. Divides it into tokens as specified 
# by Regex and outputs an array of Tokens. Every Token is an array having 
# two values: token name and its value. If its an operator, it has only 
# one value.
sub lex($)
{
	my @tokens;
	my $rhs = 0;
	while( $_ )
	{
		if( $rhs && s/^(.+)//o )
		{
			push @tokens, ["rhs",$1];
			$rhs=0;
		}
		elsif(s/^(PROGRAMS|LIBRARIES|LTLIBRARIES|LISP|PYTHON|JAVA|SCRIPTS|DATA|HEADERS|MASN|TEXINFOS)//o)
		{
			push @tokens, [$1];
		}
		elsif(s/^([a-zA-Z0-9]+)//o)
		{
			push @tokens, ["value",$1];
		}
		elsif(s/^(=)//o)
		{
			push @tokens, [$1];
			$rhs = 1;
		}
		elsif(s/^(:|_)//o)
		{
			push @tokens, [$1];
		}
		elsif(s/^\n//o)
		{
			push @tokens, ["newline"];
		}
		elsif(s/^(\r| )//o)
		{
		}
		else
		{
			die "Incorrect input $_";
		}
	}
	return @tokens;
}

