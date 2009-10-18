# Catch common programming error:
# A Condition passed as a string to 'new'.
use Automake::Condition;

my $cond = new Automake::Condition ("COND1_TRUE");
new Automake::Condition ("$cond");
