package Lexer;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(lex);

# lex(string,multiline)
# Takes as input a string of line and multiline variable deciding whether 
# current line is related to the previous line. Divides it into tokens as 
# specified by Regex and outputs an array of Tokens. Every Token is an 
# array having two values: token name and its value. If its an operator, 
# it has only one value.
sub lex($$)
{
	my ( $curr_line , $multiline ) = @_;
	my @tokens;
	my $rhs = 0;
	$_ = $curr_line;
	while( $_ )
	{
		if( $multiline )
		{
			my @vals = split;
			if( $multiline eq 'automake_comment' )
			{
				if( $vals[ -1 ] ne '\\' )
				{
					$multiline = undef;
					push @tokens, [ "newline" ];
				}
				$_ = undef;
				last;
			}
			elsif( $multiline eq 'comment' )
			{
			    my $comment;
				foreach my $val ( @vals )
				{
					if($val =~ m/^##/)
					{
						if($vals[ -1 ] eq '\\')
						{
							$multiline = 'automake_comment';
						}
						$_ = undef;
						last;
					}
					elsif( $val eq '\\' )
					{
						last;
					}
					else
					{
						$comment .= " ".$val;
					}
				}
				if( $comment )
				{
					push @tokens, [ "comment" , $comment ];
				}
				if($vals[ -1 ] ne '\\')
				{
					$multiline = undef;
					push @tokens, [ "newline" ];
				}
				$_ = undef;
			}
			else
			{
				$multiline = undef;
				$rhs = 1;
			}
		}
		elsif( $rhs  )
		{
		    my @vals = split;
			my $comment;
			foreach my $val ( @vals )
			{
				if( $val =~ m/^##/ )
				{
					if($vals[ -1 ] eq '\\' )
					{
						$multiline = 'automake_comment';
					}
					$_ = undef;
					last;
				}
				elsif( $val =~ m/^#(.*)/ )
				{
					if($vals[ -1 ] eq '\\' )
					{
						$multiline = 'comment';
					}
					$comment .= " ".$1;
				}
				elsif( $val =~ m/\\/ )
				{
					if( !$multiline )
					{
						$multiline = 'rhsval';
					}
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
			if( $comment )
			{
				push @tokens, [ "comment" , $comment];
			}
			if( !$multiline )
			{
				push @tokens, [ "newline" ];
			}
			$_ = undef;
		}
		elsif( s/^##.*\n$//o )
		{
		}
		elsif( s/^#(.*)\n$//o )
		{
			my $val = $1;
			if($val =~ m/(.*?)\\/o)
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
		elsif( s/^(PROGRAMS|LIBRARIES|LTLIBRARIES|LISP|PYTHON|JAVA|SCRIPTS|DATA|HEADERS|MASN|TEXINFOS)//o)
		{
			push @tokens, [$1];
		}
		elsif( s/^([a-zA-Z0-9]+)//o )
		{
			push @tokens, ["value",$1];
		}
		elsif( s/^(=)//o )
		{
			push @tokens, [$1];
			$rhs = 1;
		}
		elsif( s/^(:|_)//o )
		{
			push @tokens, [$1];
		}
		elsif( s/^\n//o )
		{
			push @tokens, ["newline"];
			$multiline = undef;
		}
		elsif( s/^(\r|\s*)//o )
		{
		}
		else
		{
			die "Incorrect input $_";
		}
	}
	return ( \@tokens , $multiline );
}

