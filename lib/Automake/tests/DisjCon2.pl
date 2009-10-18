# Catch common programming error:
# A non-Condition reference passed to new.
use Automake::Condition;
use Automake::DisjConditions;

my $cond = new Automake::Condition ('TRUE');
my $cond2 = new Automake::DisjConditions ($cond);
new Automake::DisjConditions ($cond2);
