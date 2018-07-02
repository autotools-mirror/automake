package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=17;

our @table=(
		{stmts => 5, makerule => 8, comment => 2, lhs => 11, input => 4, ifblock => 10, stmt => 6, optionlist => 13, automakerule => 7, conditional => 9, if => 3, commentlist => 12, value => 1},
		{reduce => [1,  \&lhs], ':' => 14, '_' => 15},
		{reduce => [1,  \&commentlist]},
		{value => 16},
		{end => 17},
		{makerule => 8, comment => 2, lhs => 11, ifblock => 10, stmt => 18, optionlist => 13, automakerule => 7, conditional => 9, if => 3, reduce => [1,  \&input], commentlist => 12, value => 1},
		{newline => 19},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{optionalelse => 21, reduce => [0,  \&optionalelse], else => 20},
		{'+' => 23, '=' => 22},
		{comment => 24, reduce => [1,  \&stmt]},
		{PYTHON => 30, SCRIPTS => 32, JAVA => 31, LTLIBRARIES => 28, DATA => 33, value => 25, HEADERS => 34, TEXINFOS => 36, primaries => 37, LIBRARIES => 27, PROGRAMS => 26, LISP => 29, MASN => 35},
		{rhs => 39, rhsval => 38},
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
		{lhs => 11, ifblock => 10, stmts => 49, makerule => 8, comment => 2, conditional => 9, if => 3, commentlist => 12, value => 1, stmt => 6, optionlist => 13, automakerule => 7},
		{reduce => [3,  \&stmts]},
		{comment => 2, stmts => 50, makerule => 8, ifblock => 10, lhs => 11, automakerule => 7, optionlist => 13, stmt => 6, value => 1, commentlist => 12, if => 3, conditional => 9},
		{reduce => [0,  \&optionalcond], value => 51, optionalcond => 52},
		{optionalcomments => 53, comment => 2, commentlist => 54, reduce => [0,  \&optionalcomments]},
		{reduce => [1,  \&optionalrhs], rhsval => 48},
		{rhs => 45, optionalrhs => 55, reduce => [0,  \&optionalrhs], rhsval => 38},
		{reduce => [3,  \&optionlist]},
		{reduce => [2,  \&rhs]},
		{reduce => [4,  \&ifblock], value => 1, commentlist => 12, if => 3, conditional => 9, automakerule => 7, optionlist => 13, stmt => 18, ifblock => 10, lhs => 11, comment => 2, makerule => 8},
		{comment => 2, makerule => 8, ifblock => 10, lhs => 11, automakerule => 7, optionlist => 13, stmt => 18, reduce => [3,  \&optionalelse], value => 1, commentlist => 12, if => 3, conditional => 9},
		{reduce => [1,  \&optionalcond]},
		{reduce => [4,  \&conditional]},
		{reduce => [4,  \&automakerule]},
		{reduce => [1,  \&optionalcomments], comment => 24},
		{reduce => [0,  \&optionalcomments], commentlist => 54, comment => 2, optionalcomments => 56},
		{reduce => [5,  \&automakerule]}
);