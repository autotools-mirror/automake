package ParserTable;

use Exporter;
use Tree;

our @ISA=qw(Exporter);
our @Export=qw(@table $accept);

our $accept=9;

our @table=(
		{stmt => 4, input => 2, lhs => 5, stmts => 3, value => 1, optionlist => 6},
		{'_' => 8, ':' => 7},
		{end => 9},
		{value => 1, optionlist => 6, stmt => 10, lhs => 5, reduce => [1,  \&input]},
		{newline => 11},
		{'=' => 12},
		{DATA => 21, PYTHON => 18, LIBRARIES => 15, TEXINFOS => 24, PROGRAMS => 14, MASN => 23, value => 13, JAVA => 19, HEADERS => 22, SCRIPTS => 20, LTLIBRARIES => 16, primaries => 25, LISP => 17},
		{rhs => 26},
		{reduce => [2,  \&optionlist]},
		{},
		{newline => 27},
		{reduce => [2,  \&stmts]},
		{rhs => 28},
		{'_' => 29, reduce => [1,  \&primaries]},
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