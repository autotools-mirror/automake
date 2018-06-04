
all: ast.png

ast.png: Lexer.pm Tree.pm ParserTable.pm parser.pl
	perl -I. parser.pl
	unflatten -f -l 5 -c 6 -o ast1.gv ast.gv
	dot -Tpng ast1.gv > ast.png
	rm ast1.gv

build: automake.dot ParserTable.pm

automake.dot: automake.y
	bison --graph automake.y
	rm automake.tab.c
	unflatten -f -l 5 -c 6 -o automake1.dot automake.dot
	dot -Tpng automake1.dot > automake.png
	rm automake1.dot

ParserTable.pm: automake.dot Converter.pl
	perl -I. Converter.pl < automake.dot > ParserTable.pm
