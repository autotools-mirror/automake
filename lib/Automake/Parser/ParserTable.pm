package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=17;

our @table=(
		{commentlist => 12, if => 3, lhs => 11, value => 1, makerule => 8, optionlist => 13, comment => 2, input => 4, automakerule => 7, stmt => 6, stmts => 5, conditional => 9, ifblock => 10},
		{reduce => [1,  \&lhs], ':' => 14, '_' => 15},
		{reduce => [1,  \&commentlist]},
		{value => 16},
		{end => 17},
		{value => 1, lhs => 11, if => 3, commentlist => 12, automakerule => 7, comment => 2, optionlist => 13, makerule => 8, reduce => [1,  \&input], stmt => 18, ifblock => 10, conditional => 9},
		{newline => 19},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{optionalelse => 21, reduce => [0,  \&optionalelse], else => 20},
		{'=' => 22},
		{comment => 23, reduce => [1,  \&stmt]},
		{JAVA => 30, PROGRAMS => 25, TEXINFOS => 35, DATA => 32, primaries => 36, HEADERS => 33, LTLIBRARIES => 27, LISP => 28, PYTHON => 29, SCRIPTS => 31, value => 24, MASN => 34, LIBRARIES => 26},
		{rhs => 38, rhsval => 37},
		{reduce => [2,  \&optionlist]},
		{newline => 39},
		{},
		{newline => 40},
		{reduce => [2,  \&stmts]},
		{newline => 41},
		{endif => 42},
		{rhsval => 37, rhs => 44, optionalrhs => 43, reduce => [0,  \&optionalrhs]},
		{reduce => [2,  \&commentlist]},
		{'_' => 45, reduce => [1,  \&primaries]},
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
		{reduce => [3,  \&makerule], rhsval => 46},
		{automakerule => 48, optionlist => 13, lhs => 11, value => 47},
		{reduce => [3,  \&stmts]},
		{lhs => 11, value => 47, automakerule => 49, optionlist => 13},
		{reduce => [3,  \&conditional]},
		{optionalcomments => 50, comment => 2, commentlist => 51, reduce => [0,  \&optionalcomments]},
		{reduce => [1,  \&optionalrhs], rhsval => 46},
		{reduce => [3,  \&optionlist]},
		{reduce => [2,  \&rhs]},
		{reduce => [1,  \&lhs], '_' => 15},
		{newline => 52},
		{newline => 53},
		{reduce => [4,  \&automakerule]},
		{comment => 23, reduce => [1,  \&optionalcomments]},
		{reduce => [5,  \&ifblock]},
		{reduce => [4,  \&optionalelse]}
);