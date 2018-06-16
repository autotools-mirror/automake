
all: ast.png

ast.png: Lexer.pm Tree.pm ParserTable.pm parser.pl input.txt
	perl -I. parser.pl input.txt > ast.gv
	unflatten -f -l 10 -c 10 -o ast1.gv ast.gv
	dot -Tpng ast1.gv > ast.png
	rm ast.gv ast1.gv	
	
build: ParserTable.pm

automake.dot: automake.y
	bison --graph automake.y
	rm automake.tab.c
	unflatten -f -l 16 -c 9 -o automake1.dot automake.dot
	dot -Tpng automake1.dot > automake.png
	rm automake1.dot
	
automake.output: automake.y
	bison --report=all automake.y
	rm automake.tab.c

ParserTable.pm: automake.dot automake.output Converter.pl
	perl -I. Converter.pl automake.output automake.dot > ParserTable.pm

test:
	sh test.sh
