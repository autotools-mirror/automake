%token value rhsval comment PROGRAMS LIBRARIES LTLIBRARIES LISP PYTHON JAVA SCRIPTS DATA HEADERS MASN TEXINFOS newline
%%

input : stmts
;
stmts : stmt newline
		| stmts stmt newline
;
stmt  : lhs '=' rhs
		| lhs '=' rhs commentlist
		| value ':' rhs
		| commentlist
;		
lhs   : optionlist primaries
;
rhs   : rhsval
		| rhs rhsval
;
commentlist: comment
			 | commentlist comment
;
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
;
optionlist : value '_'
			| optionlist value '_'
;
%%