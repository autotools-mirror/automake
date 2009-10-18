# Catch common programming error:
# A non-reference passed to new.
use Automake::Condition qw/TRUE FALSE/;
use Automake::DisjConditions;

my $cond = new Automake::Condition ("COND1_TRUE");
new Automake::DisjConditions ("$cond");
