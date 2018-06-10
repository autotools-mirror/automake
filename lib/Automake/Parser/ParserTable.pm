package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=11;

our @table=(
		{commentlist => 7, optionlist => 8, stmts => 4, comment => 2, value => 1, stmt => 5, lhs => 6, input => 3},
		{'_' => 10, ':' => 9},
		{reduce => [1,  \&commentlist]},
		{end => 11},
		{lhs => 6, reduce => [1,  \&input], comment => 2, commentlist => 7, value => 1, optionlist => 8, stmt => 12},
		{newline => 13},
		{'=' => 14},
		{reduce => [1,  \&stmt], comment => 15},
		{PYTHON => 21, HEADERS => 25, JAVA => 22, LTLIBRARIES => 19, PROGRAMS => 17, primaries => 28, MASN => 26, value => 16, SCRIPTS => 23, LISP => 20, DATA => 24, LIBRARIES => 18, TEXINFOS => 27},
		{rhs => 30, rhsval => 29},
		{reduce => [2,  \&optionlist]},
		{},
		{newline => 31},
		{reduce => [2,  \&stmts]},
		{rhsval => 29, rhs => 32},
		{reduce => [2,  \&commentlist]},
		{reduce => [1,  \&primaries], '_' => 33},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [1,  \&primaries]},
		{reduce => [2,  \&lhs]},
		{reduce => [1,  \&rhs]},
		{reduce => [3,  \&stmt], rhsval => 34},
		{reduce => [3,  \&stmts]},
		{commentlist => 35, reduce => [3,  \&stmt], comment => 2, rhsval => 34},
		{reduce => [3,  \&optionlist]},
		{reduce => [2,  \&rhs]},
		{reduce => [4,  \&stmt], comment => 15}
);