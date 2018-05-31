%token value rhs PROGRAMS LIBRARIES LTLIBRARIES LISP PYTHON JAVA SCRIPTS DATA HEADERS MASN TEXINFOS newline
%%

input : stmts ;
stmts : stmt newline
		| stmts stmt newline
stmt  : lhs '=' rhs  
		| value ':' rhs 
lhs   : optionlist primaries
primaries : PROGRAMS 
			| LIBRARIES
			| LTLIBRARIES
			| LISP
			| PYTHON
			| JAVA
			| SCRIPTS
			| DATA
			| HEADERS
			| MASN
			| TEXINFOS
			| value
optionlist : value '_'
			| optionlist value '_'
%%