
all: install

install: Lexer.pm Tree.pm ParserTable.pm parser.pl
	mkdir -p /tmp/parser
	cp *.pm /tmp/parser/
	cp parser.pl /usr/bin/	
	
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
