
all: execute

execute: Lexer.pm Tree.pm ParserTable.pm parser.pl
	./Parser.pl
	unflatten -f -l 5 -c 6 -o ast1.gv ast.gv
	dot -Tpng ast1.gv > ast.png
	rm ast1.gv
	
build: buildGrammer buildTree

buildGrammer: automake.y
	bison --graph automake.y
	rm automake.tab.c
	unflatten -f -l 5 -c 6 -o automake1.dot automake.dot
	dot -Tpng automake1.dot > automake.png
	rm automake1.dot

buildTree: automake.dot Converter.pl
	./Converter.pl