package Lexer;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(lex);

# Store end token.
my @end_tok = ["end"];

# lex(string,multiline)
# Takes as input a string of line and multiline variable deciding whether 
# current line is related to the previous line. Divides it into tokens as 
# specified by Regex and outputs an array of Tokens. Every Token is an 
# array having two values: token name and its value. If its an operator, 
# it has only one value.
sub lex($)
{
	my ( $multiline ) = @_;
	my @tokens;
	my $rhs = 0;
    $_ = scalar <>;
	
	# Send an end token when EOF is reached.
	return ( \@end_tok, $multiline ) unless $_;
	
	while( $_ )
	{
		if( $multiline )
		{
			if( $multiline eq 'comment' )
			{
				die 'comment following trailing backslash' if m/^#/o;
				die 'blank line following trailing backslash' if m/^\s*$/;
				chomp;
				$multiline = undef unless s/\\//o;
				push @tokens, [ "comment" , $_ ];
				push @tokens, [ "newline" ] unless $multiline;
				$_ = undef;
			}
			else
			{
				if( m/^##/ )
				{
					$_ = undef;
					last;
				}
				elsif( m/^#/ )
				{
					die 'comment following trailing backslash';
				}
				else
				{
					$multiline = undef;
					$rhs = 1;
				}
			}
		}
		elsif( $rhs  )
		{
		    my @vals = split;
			my $comment;
			foreach my $val ( @vals )
			{
				if( $val =~ m/^#(.*)/ )
				{
					$multiline = 'comment' if $vals[ -1 ] eq '\\';
					$comment .= " ".$1;
				}
				elsif( $val =~ m/\\/ )
				{
					$multiline = 'rhsval' unless$multiline;
				}
				elsif( $comment )
				{
					$comment .= " ".$val;
				}
				else
				{
					push @tokens, [ "rhsval" , $val];
				}
			}
			push @tokens, [ "comment" , $comment] if $comment;
			push @tokens, [ "newline" ] unless $multiline;
			$_ = undef;
		}
		elsif( s/^##.*\n$//o )
		{
		}
		elsif( s/^#(.*)\n$//o )
		{
			my $val = $1;
			if( $val =~ m/(.*?)\\/o )
			{
				push @tokens, [ "comment" , substr( $1 , 0 , -1 )];
				$multiline = 'comment';
			}
			else
			{
				push @tokens, [ "comment" , $1];
				push @tokens, [ "newline" ];
			}
		}
		elsif( s/^(PROGRAMS|LIBRARIES|LTLIBRARIES|LISP|PYTHON|JAVA|SCRIPTS|DATA|HEADERS|MASN|TEXINFOS|if|else|endif|include)//o)
		{
			push @tokens, [$1];
		}
		elsif( s/^([a-zA-Z0-9_]+)//o )
		{
			push @tokens, ["value",$1];
		}
		elsif( s/^(\+=)//o )
		{
			push @tokens,['+'];
			push @tokens,['='];
			$rhs = 1;
		}
		elsif( s/^(=)//o )
		{
			push @tokens, [$1];
			$rhs = 1;
		}
		elsif( s/^(:|_|!)//o )
		{
			push @tokens, [$1];
		}
		elsif( s/^\n//o )
		{
			push @tokens, ["newline"] if $#tokens > -1;
			$multiline = undef;
		}
		elsif( s/^(\r|\s+)//o )
		{
		}
		else
		{
			die "Incorrect input $_";
		}
	}
	
	# Returns undef when no tokens.
	return ( undef, $multiline ) if !@tokens;
	
	return ( \@tokens , $multiline );
}

