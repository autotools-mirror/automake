package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=17;

our @table=(
		{makerule => 8, stmt => 6, value => 1, input => 4, if => 3, automakerule => 7, ifblock => 10, comment => 2, optionlist => 13, lhs => 11, stmts => 5, conditional => 9, commentlist => 12},
		{'_' => 15, reduce => [1,  \&lhs], ':' => 14},
		{reduce => [1,  \&commentlist]},
		{value => 16},
		{end => 17},
		{optionlist => 13, comment => 2, commentlist => 12, lhs => 11, conditional => 9, automakerule => 7, ifblock => 10, reduce => [1,  \&input], if => 3, stmt => 18, makerule => 8, value => 1},
		{newline => 19},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{else => 20, reduce => [0,  \&optionalelse], optionalelse => 21},
		{'+' => 23, '=' => 22},
		{comment => 24, reduce => [1,  \&stmt]},
		{primaries => 37, value => 25, PROGRAMS => 26, MASN => 35, TEXINFOS => 36, LIBRARIES => 27, HEADERS => 34, SCRIPTS => 32, DATA => 33, LTLIBRARIES => 28, LISP => 29, JAVA => 31, PYTHON => 30},
		{rhsval => 38, rhs => 39},
		{reduce => [2,  \&optionlist]},
		{newline => 40},
		{},
		{newline => 41},
		{reduce => [2,  \&stmts]},
		{newline => 42},
		{endif => 43},
		{optionalrhs => 44, rhs => 45, rhsval => 38, reduce => [0,  \&optionalrhs]},
		{'=' => 46},
		{reduce => [2,  \&commentlist]},
		{reduce => [1,  \&primaries], '_' => 47},
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
		{reduce => [3,  \&makerule], rhsval => 48},
		{automakerule => 7, ifblock => 10, comment => 2, optionlist => 13, commentlist => 12, lhs => 11, stmts => 49, conditional => 9, stmt => 6, makerule => 8, value => 1, if => 3},
		{reduce => [3,  \&stmts]},
		{if => 3, value => 1, stmt => 6, makerule => 8, commentlist => 12, lhs => 11, stmts => 50, conditional => 9, comment => 2, optionlist => 13, ifblock => 10, automakerule => 7},
		{value => 51, optionalcond => 52, reduce => [0,  \&optionalcond]},
		{comment => 2, reduce => [0,  \&optionalcomments], optionalcomments => 53, commentlist => 54},
		{rhsval => 48, reduce => [1,  \&optionalrhs]},
		{optionalrhs => 55, rhsval => 38, reduce => [0,  \&optionalrhs], rhs => 45},
		{reduce => [3,  \&optionlist]},
		{reduce => [2,  \&rhs]},
		{if => 3, reduce => [4,  \&ifblock], value => 1, stmt => 18, makerule => 8, commentlist => 12, conditional => 9, lhs => 11, optionlist => 13, comment => 2, ifblock => 10, automakerule => 7},
		{value => 1, stmt => 18, makerule => 8, if => 3, reduce => [3,  \&optionalelse], ifblock => 10, automakerule => 7, commentlist => 12, conditional => 9, lhs => 11, optionlist => 13, comment => 2},
		{reduce => [1,  \&optionalcond]},
		{reduce => [4,  \&conditional]},
		{reduce => [4,  \&automakerule]},
		{comment => 24, reduce => [1,  \&optionalcomments]},
		{comment => 2, reduce => [0,  \&optionalcomments], optionalcomments => 56, commentlist => 54},
		{reduce => [5,  \&automakerule]}
);