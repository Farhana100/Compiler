%option noyywrap

%x	MULTICOMMENT1
%x	MULTICOMMENT2
%x	MULTICOMMENT2_SKIP
%x	STRING_START
%x  STRING_SKIP
%x  STRING_ESC
%x 	NUMBER
%x 	EXP
%x 	FLOAT_NUMBER


%{
	#include <iostream>
	#include <bits/stdc++.h>
	#include "SymbolInfo.h"
	#include "ScopeTable.h"
	#include "SymbolTable.h"
		
	#include "y.tab.h"
	using namespace std;
	
	
	extern SymbolTable *table;
	
	void yyerror(char *);
	
	
	//int error_count = 0;
	int line_count = 1;
	int strt_mark = 0;
	string str = "";
	string lexeme = "";
	
	

	char toChar(string str)
	{
		if(str.length() == 3)return str[1];
		if(str == "'\\n'")return '\n';
		if(str == "'\\t'")return '\t';
		if(str == "'\\\\'")return '\\';
		if(str == "'\\''")return '\'';
		if(str == "'\\\"'")return '\"';
		if(str == "'\\a'")return '\a';
		if(str == "'\\f'")return '\f';
		if(str == "'\\r'")return '\r';
		if(str == "'\\b'")return '\b';
		if(str == "'\\v'")return '\v';
		if(str == "'\\0'")return '\0';

		///wrong esc character
		return -1;
	}

	int chkChar(string lexeme)
	{
		if(lexeme.length() == 2)return -1; // Empty character constant error
		if(lexeme.length() > 4)return 2;  // multi char
		if(lexeme[1] == '\\') return 1;     // normal escape
		if(lexeme.length() > 3)return 2;  // multi char
		return  0;  //normal char
	}

	char getEscapeChar(string str)
	{
		switch(str[0]){
		    case '\'':  return '\'';
		    case '\"':  return '\"';
		    case '\\':  return '\\';
		    case '0':  return '\0';
		    case 'a':  return '\a';
		    case 'b':  return '\b';
		    case 'f':  return '\f';
		    case 'n':  return '\n';
		    case 'r':  return '\r';
		    case 't':  return '\t';
		    case 'v':  return '\v';
		    default:    return -1; // nonescapable
		}
	}


%}


IDENTIFIERS [a-zA-Z_][a-zA-Z_0-9]*
SINGLE_LINE_COMMENT		"//"(.)*$
NEWLINE		"\n"|"\r\n"
ADDOP [+-] 
MULOP [*/%]
	
%%
[ \t\v]+	{}


"if" 		{ return IF;}
"else" 		{ return ELSE;}
"for" 		{ return FOR;}
"while" 	{ return WHILE;}
"do"		{ return DO;}
"break"		{ return BREAK;}
"int" 		{ return INT;}
"char"		{ return CHAR;}
"float" 	{ return FLOAT;}
"double" 	{ return DOUBLE;}
"void" 		{ return VOID;}
"return" 	{ return RETURN;}
"switch" 	{ return SWITCH;}
"case" 		{ return CASE;}
"default" 	{ return DEFAULT;}
"continue" 	{ return CONTINUE;}
"printf"	{ return PRINTLN;}

{ADDOP} { 
			SymbolInfo *s= new  SymbolInfo(yytext, "ADDOP");
			yylval.symbolInfo = s;
			return ADDOP;
		}



{MULOP}	{
			SymbolInfo *s= new  SymbolInfo(yytext, "MULOP");
			yylval.symbolInfo = s;
			return MULOP;
		}
		

"=" 	{
			return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		SymbolInfo *s= new  SymbolInfo(yytext, "RELOP");
		yylval.symbolInfo = s;			
		return RELOP;
	}

"&&"	|
"||"	{
			SymbolInfo *s= new  SymbolInfo(yytext, "LOGICOP");
			yylval.symbolInfo = s;			
			return LOGICOP;
		}
"!"		{ return NOT;}


";" 	{ return SEMICOLON;}
"," 	{ return COMMA;}
"(" 	{ return LPAREN;}
")" 	{ return RPAREN;}
"{" 	{ return LCURL;}
"}" 	{ return RCURL;}
"[" 	{ return LTHIRD;}
"]" 	{ return RTHIRD;}
"++" 	{ return INCOP;}
"--" 	{ return DECOP;}


"/*"	{
			strt_mark = line_count;
			lexeme = yytext;
			
			BEGIN MULTICOMMENT1;
}

<MULTICOMMENT1>"*/"	{
			lexeme += yytext;
			//flog << "Line no " << strt_mark << ": Token <COMMENT> Lexeme " << lexeme << " found" << endl << endl;
			BEGIN INITIAL;
			}

<MULTICOMMENT1>{NEWLINE}	{
			line_count++;
			lexeme += yytext;
			}

<MULTICOMMENT1><<EOF>>		{
			//flog << "Error at line no " << strt_mark << ": Unterminated Comment " << lexeme << endl << endl;
			//error_count++;
            
            return 0;
			}
			
<MULTICOMMENT1>.		{
			lexeme += yytext;
			}
			
		
"//"(.)*("\\"|"\\\r")$	{
			//flog << "Line no " << line_count << ": Token <COMMENT> Lexeme " << yytext;
			BEGIN MULTICOMMENT2_SKIP;
}
<MULTICOMMENT2_SKIP>{NEWLINE} {
			line_count++;
			//flog << yytext;
			BEGIN MULTICOMMENT2;
			}
<MULTICOMMENT2>{NEWLINE}	{
			line_count++;
			//flog << " found" << endl << endl;
			BEGIN INITIAL;
			}
<MULTICOMMENT2>("\\"|"\\\r")$	{
			line_count++;
			//flog << yytext;
			BEGIN MULTICOMMENT2_SKIP;
			}
<MULTICOMMENT2>.		{
			//flog << yytext;
			}
			
{SINGLE_LINE_COMMENT}	{
			//flog << "Line no " << line_count << ": Token <COMMENT> Lexeme " << yytext << " found" << endl << endl;
			}
			
\"	{
			strt_mark = line_count;
			str = "";
			lexeme = yytext;
			BEGIN STRING_START;
			}
<STRING_START>("\\"|"\\\r")$	{

			lexeme += yytext;
			BEGIN STRING_SKIP;
}
<STRING_START>\"	{
			lexeme += yytext;
			BEGIN INITIAL;
			
			SymbolInfo *s= new  SymbolInfo(str, "STRING");
			yylval.symbolInfo = s;	
			
			return STRING;
}
<STRING_START>{NEWLINE}	{
			//flog << "Error at line no " << strt_mark << " : Unterminated String " << lexeme << endl << endl;
			//error_count++;
			line_count++;
			BEGIN INITIAL;	
}

<STRING_START>"\\"	{
			lexeme += yytext;
			BEGIN STRING_ESC;
}
<STRING_START><<EOF>>		{
			//flog << "Error at line no " << strt_mark << ": Unterminated String " << lexeme << endl << endl;
			//error_count++;
			
            return 0;
			}

<STRING_START>.	{
			str += yytext;
			lexeme += yytext;
}

<STRING_ESC>. {
			lexeme += yytext;
			char ch = getEscapeChar(yytext);
			if(ch == -1){
				str += "\\";
				str += yytext;
			}
			else {
				str += ch;
			}
			BEGIN STRING_START;
}

<STRING_SKIP>{NEWLINE} {
			line_count++;
			lexeme += yytext;
			BEGIN STRING_START;
}	
			

"'\\'"[^\n\r']*{NEWLINE}	{	
			//error_count++;
			//flog << "Error at line no " << line_count << ": Unterminated character " << yytext << endl << endl;
			line_count++;
}
'(.)*'		{
			switch(chkChar(yytext)){
				case -1:
					//error_count++;
					//flog << "Error at line no " << line_count << ": Empty character constant error " << yytext << endl << endl;
					break;
				case 0:
					yylval.const_char = toChar(yytext);	
					return CONST_CHAR;
					
					break;
				case 1:
					
					yylval.const_char = toChar(yytext);	
					return CONST_CHAR;
					
					break;
				case 2:
					//error_count++;
					//flog << "Error at line no " << line_count << ": Multi character constant error " << yytext << endl << endl;
					break;
				default:
					break;
			}
			}
'[^'\n\r]*{NEWLINE}	{
			//error_count++;
			//flog << "Error at line no " << line_count << ": Unterminated character " << yytext << endl << endl;
			line_count++;
}
			

[0-9]+	{
			lexeme = yytext;
			BEGIN NUMBER;
			}
[0-9]+(\.)	{
			lexeme = yytext;
			BEGIN FLOAT_NUMBER;
			}
[0-9]*(\.)[0-9]+	{
			lexeme = yytext;
			BEGIN FLOAT_NUMBER;
			}

<NUMBER>[eE]	{
			lexeme += yytext;
			BEGIN EXP;
			}
<NUMBER>[a-zA-Z_]+	{
			//flog << "Error at line no " << line_count << ": Invalid prefix on ID or invalid suffix on Number " << lexeme + yytext << endl << endl;
			//error_count++;
			BEGIN INITIAL;
}
<NUMBER>{NEWLINE}	{
			line_count++;
			BEGIN INITIAL;	
			
			SymbolInfo *s= new  SymbolInfo(lexeme, "CONST_INT");
			yylval.symbolInfo = s;
			return CONST_INT;
			
			}
<NUMBER>.	{
			yyless(0); 
			BEGIN INITIAL;	
			
			SymbolInfo *s= new  SymbolInfo(lexeme, "CONST_INT");
			yylval.symbolInfo = s;
			return CONST_INT;
			}

<FLOAT_NUMBER>[eE]	{
			
			lexeme += yytext;
			BEGIN EXP;
}	
<FLOAT_NUMBER>[0-9\.]+([eE]?[0-9\.]*)	{
			//flog << "Error at line no " << line_count << ": Too many decimal points " << lexeme + yytext << endl << endl;
			//error_count++;
			BEGIN INITIAL;
			}
<FLOAT_NUMBER>[a-zA-Z_]+	{
			//flog << "Error at line no " << line_count << ": Invalid prefix on ID or invalid suffix on Number " << lexeme + yytext << endl << endl;
			//error_count++;
			BEGIN INITIAL;
			}
<FLOAT_NUMBER>{NEWLINE}	{
			line_count++;
			BEGIN INITIAL;
			
			SymbolInfo *s= new  SymbolInfo(lexeme, "CONST_FLOAT");
			yylval.symbolInfo = s;				
			return CONST_FLOAT;
			}
<FLOAT_NUMBER>.	{
			yyless(0); 
			BEGIN INITIAL;
			
			SymbolInfo *s= new  SymbolInfo(lexeme, "CONST_FLOAT");
			yylval.symbolInfo = s;		
			return CONST_FLOAT;
			}

<EXP>[+-]?[0-9]+	{
			lexeme += yytext;
			BEGIN INITIAL;
			
			SymbolInfo *s= new  SymbolInfo(lexeme, "CONST_FLOAT");
			yylval.symbolInfo = s;		
			return CONST_FLOAT;
			}
<EXP>[+-]?[0-9\.]+	{
			//flog << "Error at line no " << line_count << ": Ill formed number " << lexeme + yytext << endl << endl;
			//error_count++;
			BEGIN INITIAL;
			}
<EXP>{NEWLINE}		{
			//flog << "Error at line no " << line_count << ": Exponent has no digits " << lexeme << endl << endl;
			//error_count++;
			line_count++;
			BEGIN INITIAL;
			}
<EXP>.		{
			//flog << "Error at line no " << line_count << ": Exponent has no digits " << lexeme << endl << endl;
			//error_count++;
			yyless(0);
			BEGIN INITIAL;
			}

{IDENTIFIERS}		{	
			SymbolInfo *s= new  SymbolInfo(yytext, "ID");
			yylval.symbolInfo = s;	
			return ID;}


{NEWLINE}		{line_count++;}

<<EOF>> 	{ // file end
			return 0;
}
            
            
.			{
			//Error at line no line_count: Unrecognized character yytext
			//error_count++;
}

%%



