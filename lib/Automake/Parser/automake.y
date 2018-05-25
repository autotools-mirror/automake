%token value rhs PROGRAMS LIBRARIES LTLIBRARIES LISP PYTHON JAVA SCRIPTS DATA HEADERS MASN TEXINFOS
%%

input : stmts ;
stmts : stmt '\n'
		| stmts stmt '\n'
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