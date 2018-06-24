%token value rhsval comment PROGRAMS LIBRARIES LTLIBRARIES LISP PYTHON JAVA SCRIPTS DATA HEADERS MASN TEXINFOS newline if else endif
%%

input : stmts
;
stmts : stmt newline
		| stmts stmt newline
;
stmt  : automakerule
		| makerule
		| commentlist
		| conditional
;
automakerule : lhs '=' optionalrhs optionalcomments
			 | lhs '+' '=' optionalrhs optionalcomments
;
makerule : value ':' rhs
;
conditional : ifblock optionalelse endif optionalcond
;
ifblock : if value newline stmts
;
optionalelse:
			| else newline stmts
;
optionalcond:
			| value
;
optionalrhs : 
		    | rhs
;
optionalcomments : 
			      | commentlist
;
lhs   : optionlist primaries
		| value
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