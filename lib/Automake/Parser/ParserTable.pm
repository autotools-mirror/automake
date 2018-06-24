package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=17;

our @table=(
		{input => 4, optionlist => 13, ifblock => 10, value => 1, lhs => 11, if => 3, makerule => 8, automakerule => 7, stmts => 5, stmt => 6, comment => 2, conditional => 9, commentlist => 12},
		{reduce => [1,  \&lhs], ':' => 14, '_' => 15},
		{reduce => [1,  \&commentlist]},
		{value => 16},
		{end => 17},
		{stmt => 18, comment => 2, commentlist => 12, conditional => 9, reduce => [1,  \&input], lhs => 11, value => 1, optionlist => 13, ifblock => 10, if => 3, makerule => 8, automakerule => 7},
		{newline => 19},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{reduce => [1,  \&stmt]},
		{else => 20, reduce => [0,  \&optionalelse], optionalelse => 21},
		{'=' => 22, '+' => 23},
		{comment => 24, reduce => [1,  \&stmt]},
		{LISP => 29, primaries => 37, HEADERS => 34, LIBRARIES => 27, JAVA => 31, PROGRAMS => 26, TEXINFOS => 36, DATA => 33, MASN => 35, LTLIBRARIES => 28, PYTHON => 30, SCRIPTS => 32, value => 25},
		{rhs => 39, rhsval => 38},
		{reduce => [2,  \&optionlist]},
		{newline => 40},
		{},
		{newline => 41},
		{reduce => [2,  \&stmts]},
		{newline => 42},
		{endif => 43},
		{reduce => [0,  \&optionalrhs], rhs => 45, optionalrhs => 44, rhsval => 38},
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
		{if => 3, makerule => 8, automakerule => 7, stmts => 49, value => 1, lhs => 11, ifblock => 10, optionlist => 13, commentlist => 12, conditional => 9, stmt => 6, comment => 2},
		{reduce => [3,  \&stmts]},
		{ifblock => 10, optionlist => 13, value => 1, lhs => 11, stmts => 50, makerule => 8, automakerule => 7, if => 3, stmt => 6, comment => 2, conditional => 9, commentlist => 12},
		{optionalcond => 52, reduce => [0,  \&optionalcond], value => 51},
		{commentlist => 54, reduce => [0,  \&optionalcomments], comment => 2, optionalcomments => 53},
		{reduce => [1,  \&optionalrhs], rhsval => 48},
		{rhsval => 38, optionalrhs => 55, reduce => [0,  \&optionalrhs], rhs => 45},
		{reduce => [3,  \&optionlist]},
		{reduce => [2,  \&rhs]},
		{makerule => 8, automakerule => 7, if => 3, value => 1, lhs => 11, ifblock => 10, optionlist => 13, commentlist => 12, reduce => [4,  \&ifblock], conditional => 9, stmt => 18, comment => 2},
		{commentlist => 12, conditional => 9, reduce => [3,  \&optionalelse], stmt => 18, comment => 2, makerule => 8, automakerule => 7, if => 3, value => 1, lhs => 11, ifblock => 10, optionlist => 13},
		{reduce => [1,  \&optionalcond]},
		{reduce => [4,  \&conditional]},
		{reduce => [4,  \&automakerule]},
		{comment => 24, reduce => [1,  \&optionalcomments]},
		{comment => 2, optionalcomments => 56, commentlist => 54, reduce => [0,  \&optionalcomments]},
		{reduce => [5,  \&automakerule]}
);