yacc -d -y -v parser_generator.y
echo '1'
g++ -w -c -o y.o y.tab.c
echo '2'
flex lexical_analyzer.l		
echo '3'
g++ -w -c -o l.o lex.yy.c
echo '4'
g++ SymbolInfo.cpp ScopeTable.cpp SymbolTable.cpp -c
g++ -o a.out SymbolInfo.o ScopeTable.o SymbolTable.o y.o l.o -lfl
echo '5'
./a.out input.txt
