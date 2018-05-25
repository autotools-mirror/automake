package ParserTable;

use Exporter;
use Tree;

our @ISA = qw(Exporter);
our @Export = qw(@table $accept);

#Stores the state number where the input is accepted
our $accept=9;

# Stores the state diagram. Its an array of hashes. Each index corresponds 
# to ith state. Every key in hash corresponds to a token, value corresponds 
# to next state. reduce key specifies the reduction of token. Its an array 
# consisting of number of elements to be reduced and a reference to a function 
# to create a node.
our @table=(
		{value => 1, input => 2, stmts => 3, stmt => 4, lhs => 5, optionlist => 6},
		{":" => 7, "_" => 8},
		{end => 9},
		{value => 1, lhs => 5, optionlist => 6, stmt => 10, reduce => [1, \&input]}, #input : stmts
		{"\n" => 11},
		{"=" => 12},
		{value => 13, PROGRAMS => 14, LIBRARIES => 15, LTLIBRARIES => 16, LISP => 17, PYTHON => 18, JAVA => 19, SCRIPTS => 20, DATA => 21, HEADERS => 22, MASN => 23, TEXINFOS => 24, primaries => 25},
		{rhs => 26},
		{reduce => [2, \&optionlist]}, #optionlist : value '_'
		{},
		{"\n" => 27},
		{reduce => [2, \&stmts]}, #stmts : stmt '\n'
		{rhs => 28},
		{"_" =>29, reduce => [1, \&primaries]}, #primaries : value
		{reduce => [1, \&primaries]}, #primaries : PROGRAMS
		{reduce => [1, \&primaries]}, #primaries : LIBRARIES
		{reduce => [1, \&primaries]}, #primaries : LTLIBRARIES
		{reduce => [1, \&primaries]}, #primaries : LISP
		{reduce => [1, \&primaries]}, #primaries : PYTHON
		{reduce => [1, \&primaries]}, #primaries : JAVA
		{reduce => [1, \&primaries]}, #primaries : SCRIPTS
		{reduce => [1, \&primaries]}, #primaries : DATA
		{reduce => [1, \&primaries]}, #primaries : HEADERS
		{reduce => [1, \&primaries]}, #primaries : MASN
		{reduce => [1, \&primaries]}, #primaries : TEXINFOS
		{reduce => [2, \&lhs]}, #lhs : optionlist primaries
		{reduce => [3, \&stmt]}, #stmt : value ':' rhs
		{reduce => [3, \&stmts]}, #stmts : stmts stmt '\n'
		{reduce => [3, \&stmt]}, #stmt : lhs '=' rhs 
		{reduce => [3, \&optionlist]} #optionlist : optionlist value '_'
		); 