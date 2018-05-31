package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=9;

our @table=(
		{value => 1, stmts => 3, stmt => 4, lhs => 5, optionlist => 6, input => 2},
		{':' => 7, '_' => 8},
		{end => 9},
		{reduce => [1,  \&input], optionlist => 6, lhs => 5, stmt => 10, value => 1},
		{newline => 11},
		{'=' => 12},
		{HEADERS => 22, LTLIBRARIES => 16, value => 13, PROGRAMS => 14, LIBRARIES => 15, SCRIPTS => 20, MASN => 23, primaries => 25, TEXINFOS => 24, DATA => 21, JAVA => 19, PYTHON => 18, LISP => 17},
		{rhs => 26},
		{reduce => [2,  \&optionlist]},
		{},
		{newline => 27},
		{reduce => [2,  \&stmts]},
		{rhs => 28},
		{reduce => [1,  \&primaries], '_' => 29},
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
		{reduce => [3,  \&stmt]},
		{reduce => [3,  \&stmts]},
		{reduce => [3,  \&stmt]},
		{reduce => [3,  \&optionlist]}
);