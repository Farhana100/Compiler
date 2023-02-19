%{
	#include <iostream>
	#include <bits/stdc++.h>
	#include <fstream>
	#include "SymbolInfo.h"
	#include "ScopeTable.h"
	#include "SymbolTable.h"
		
	using namespace std;
	
	SymbolTable *table = new SymbolTable(30);
	
	ofstream flog, ferr;

	void yyerror(char *s)
	{
	}
	
	int yyparse(void);
	int yylex(void);
	
	extern FILE* yyin; 
	extern int line_count;
	int err_count = 0;
	
	int function_scope = 0;
	vector <SymbolInfo*>* tempParamList = NULL;

%}

%union 
{
	int const_int;
	double const_float;
	char const_char;
	string* str;
	SymbolInfo* symbolInfo;
	SymbolInfo* pseudoSymbolInfo;
	vector <SymbolInfo*>* symbolVector;
}

%token <str> CONST_CHAR INT CHAR FLOAT DOUBLE VOID STRING IF ELSE FOR WHILE DO BREAK RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ASSIGNOP NOT SEMICOLON COMMA LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP

%token <symbolInfo> ADDOP MULOP RELOP LOGICOP CONST_INT CONST_FLOAT ID

%type <str> program unit func_declaration func_definition compound_statement var_declaration type_specifier statements statement expression_statement

%type <pseudoSymbolInfo> variable factor unary_expression term simple_expression rel_expression logic_expression expression
%type <symbolVector> declaration_list parameter_list arguments argument_list

%nonassoc THEN
%nonassoc ELSE

%%

start : program				{	flog << "Line " << line_count << ": start : program" << endl << endl;

								table->PrintAllScopeTable(flog);
								
								flog << "Total lines: " << line_count << endl;
								flog << "Total errors: " << err_count << endl;
							}
	  ;

program : 					program unit 	{	flog << "Line " << line_count << ": program : program unit" << endl << endl;
												$$ = new string(*$1 + *$2);
												flog << *$$ << endl << endl;
											}
							| unit			{	flog << "Line " << line_count << ": program : unit" << endl << endl;
												flog << *$1 << endl << endl; }
							;

unit : 						var_declaration			{	flog << "Line " << line_count << ": unit : var_declaration" << endl << endl;
														flog << *$1 << endl << endl; }
							| func_declaration		{	flog << "Line " << line_count << ": unit : func_declaration" << endl << endl;
														flog << *$1 << endl << endl; }
							| func_definition		{	flog << "Line " << line_count << ": unit : func_definition" << endl << endl;
														flog << *$1 << endl << endl; }
							;
     
func_declaration : 			type_specifier ID LPAREN parameter_list RPAREN SEMICOLON	{	
														flog << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl << endl;
													
														$2->setReturn_type(*$1);	
														
														$$ = new string(*$1 + ' ' + $2->getName() + '(');
														
														//inserting into symbol table and checking for multiple declaration
														if(table->Insert($2->getName(), $2->getType())){
															// no duplicate
															SymbolInfo* func_sym = table->LookUp($2->getName());
															
															func_sym->setReturn_type(*$1);
															func_sym->setArray_size(-2);		// mark undefined function
															
															for(SymbolInfo* si_: *$4)
															{
																func_sym->insertParameter(*si_);
															}
														}
														else {
															err_count++;
															ferr << "Error at line " << line_count << ": function redeclared" << endl << endl;
															flog << "Error at line " << line_count << ": function redeclared" << endl << endl;
														}
														
														// adding parameter list
														for(SymbolInfo* si_: *$4)
														{
															if(si_->getName() == "--null"){
																*$$ += si_->getReturn_type();
															}
															else{
																*$$ += si_->getReturn_type() + ' ' + si_->getName();
															}
															
															if(si_ != $4->back()){
																*$$ +=  ',';
															}
														}
														
														
														*$$ += ");\n";	
														
														flog << *$$ << endl << endl;
														
														//make tempParamList null
														tempParamList = NULL;
													}
							| type_specifier ID LPAREN RPAREN SEMICOLON		{	
														flog << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl;
														
														//inserting into symbol table and checking for multiple declaration
														if(table->Insert($2->getName(), $2->getType())){
															// no duplicate
															SymbolInfo* func_sym = table->LookUp($2->getName());
															
															func_sym->setReturn_type(*$1);
															func_sym->setArray_size(-2);		// mark undefined function
														}
														else {
															err_count++;
															ferr << "Error at line " << line_count << ": function redeclared" << endl << endl;
															flog << "Error at line " << line_count << ": function redeclared" << endl << endl;
														}
														
														$2->setReturn_type(*$1);
														
														$$ = new string(*$1 + ' ' + $2->getName() + "();\n");	
														flog << *$$ << endl << endl;
														
														
														//make tempParamList null
														tempParamList = NULL;
														}
							;

func_definition : 			type_specifier ID LPAREN parameter_list RPAREN {

							int flag = 1;			 
														
							if(!(table->Insert($2->getName(), $2->getType()))){
								SymbolInfo* func_sym = table->LookUp($2->getName());
								
								if(func_sym->getArray_size() == -2){
									// predeclared
									
									// checking for inconsistent declaration
									
									vector <SymbolInfo> paramList = func_sym->getParameter_list();
									
									if(paramList.size() != $4->size()){
										// inconsistent parameters
										err_count++;
										ferr << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << func_sym->getName() << endl << endl; 
										flog << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << func_sym->getName() << endl << endl; 
										flag = 0;
									}
									else{
										
										int i = 0;
										
										for(SymbolInfo* si_: *$4)
										{
											if(si_->getReturn_type() != paramList[i].getReturn_type()){
												// inconsistent parameter type
												
												err_count++;
												ferr << "Error at line " << line_count << ": " << func_sym->getName() << " function definition parameter " << si_->getName() << " type does not match declaration" << endl << endl; 
												flog << "Error at line " << line_count << ": " << func_sym->getName() << " function definition parameter " << si_->getName() << " type does not match declaration" << endl << endl; 
												flag = 0;
												break;
											}
											i++;
										}
									
									}
									
									if(func_sym->getReturn_type() != *$1){
										// inconsistent return type
										
										err_count++;
										ferr << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << func_sym->getName() << endl << endl; 
										flog << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << func_sym->getName() << endl << endl; 
										flag = 0;
									}
								}
								else if(func_sym->getArray_size() == -3){
									// duplicate definition
									
									
									err_count++;
									ferr << "Error at line " << line_count << ": Multiple defination of function " << func_sym->getName() << endl << endl << endl;
									flog << "Error at line " << line_count << ": Multiple defination of function " << func_sym->getName() << endl << endl << endl;
									flag = 0;
								}
								else {
									// duplicate
									
									err_count++;
									ferr << "Error at line " << line_count << ": Multiple declaration of " << func_sym->getName() << ", function name previously used as variable name" << endl << endl;
									flog << "Error at line " << line_count << ": Multiple declaration of " << func_sym->getName() << ", function name previously used as variable name" << endl << endl;
									flag = 0;
								}
							}
							
							if(flag == 1){
								// definition successful
								
								
								SymbolInfo* func_sym = table->LookUp($2->getName());
								
								func_sym->setReturn_type(*$1);
								func_sym->setArray_size(-3);		// marking defined function
								func_sym->clearParameter_list();		// renewing parameter list for predeclared functions
								
								for(SymbolInfo* si_: *$4)
								{
									func_sym->insertParameter(*si_);
								}
							}
								
								
							
						} compound_statement	{	
														flog << "Line " << line_count << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl << endl;
														
														$2->setReturn_type(*$1);
														$$ = new string(*$1 + ' ' + $2->getName() + '(');
														
														
														
														
														// adding parameter list
														for(SymbolInfo* si_: *$4)
														{
															if(si_->getName() == "--null"){
																*$$ += si_->getReturn_type();
															}
															else{
																*$$ += si_->getReturn_type() + ' ' + si_->getName();
															}
															
															if(si_ != $4->back()){
																*$$ +=  ',';
															}
														}
														
														*$$ += ')' + *$7;		
														flog << *$$ << endl << endl;
														
														}
							| type_specifier ID LPAREN RPAREN {
							
								int flag = 1;			 
															
								if(!(table->Insert($2->getName(), $2->getType()))){
									SymbolInfo* func_sym = table->LookUp($2->getName());
									
									if(func_sym->getArray_size() == -2){
										// predeclared
										
										// checking for inconsistent declaration
										
										vector <SymbolInfo> paramList = func_sym->getParameter_list();
										
										if(paramList.size() != 0){
											// inconsistent parameters
											
											err_count++;
											ferr << "Error at line " << line_count << ": " << func_sym->getName() << " function declaration has no parameter" << endl << endl; 
											flog << "Error at line " << line_count << ": " << func_sym->getName() << " function declaration has no parameter" << endl << endl; 
											flag = 0;
										}
										
										if(func_sym->getReturn_type() != *$1){
											// inconsistent return type
											
											err_count++;
											ferr << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << func_sym->getName() << endl << endl; 
											flog << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << func_sym->getName() << endl << endl; 
											flag = 0;
										}
									}
									else if(func_sym->getArray_size() == -3){
										// duplicate definition
										
										err_count++;
										ferr << "Error at line " << line_count << ": Multiple declaration of function " << func_sym->getName() << endl << endl;
										flog << "Error at line " << line_count << ": Multiple declaration of function " << func_sym->getName() << endl << endl;
										flag = 0;
									}
									else {
										// duplicate
										
										err_count++;
										ferr << "Error at line " << line_count << ": Multiple declaration of " << func_sym->getName() << ", function name previously used as variable name" << endl << endl;
										flog << "Error at line " << line_count << ": Multiple declaration of " << func_sym->getName() << ", function name previously used as variable name" << endl << endl;
										flag = 0;
									}
								}
								
								if(flag == 1){
									// definition successful
									
									
									SymbolInfo* func_sym = table->LookUp($2->getName());
									
									func_sym->setReturn_type(*$1);
									func_sym->setArray_size(-3);		// marking defined function
								}
									
									
							
							} compound_statement	{	
														flog << "Line " << line_count << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl << endl;
														
														$2->setReturn_type(*$1);
														$$ = new string(*$1 + ' ' + $2->getName() + "()" + *$6);	
														flog << *$$ << endl << endl;
														}
							;				


parameter_list  : 			parameter_list COMMA type_specifier ID		{	flog << "Line " << line_count << ": parameter_list  : parameter_list COMMA type_specifier ID" << endl << endl;

																			if($4->getName() != "--null"){
																				for(SymbolInfo* si_: *$1)
																				{
																					if(si_->getName() == $4->getName()){
																						// multiple
																						err_count++;
																						ferr << "Error at line " << line_count << ": Multiple declaration of " << $4->getName() << " in parameter" << endl << endl;
																						flog << "Error at line " << line_count << ": Multiple declaration of " << $4->getName() << " in parameter" << endl << endl;
																						break;
																					}
																				}
																				
																			}
																			
																			$4->setReturn_type(*$3);
																			$$->push_back($4);
																			
																			for(SymbolInfo* si_: *$1)
																			{
																				if(si_->getName() == "--null"){
																					flog << si_->getReturn_type();
																				}
																				else{
																					flog << si_->getReturn_type() << ' ' << si_->getName();
																				}
																				
																				if(si_ != $1->back()){
																					flog << ',';
																				}
																			}
																			flog << endl << endl;
																			
																			tempParamList = $$;
																			 
																		
																		}
							| parameter_list COMMA type_specifier		{	flog << "Line " << line_count << ": parameter_list  : parameter_list COMMA type_specifier" << endl << endl;
										
																			SymbolInfo* si = new SymbolInfo("--null", "--null");
																			si->setReturn_type(*$3);
																				
																			
																			$$->push_back(si);
																			
																			for(SymbolInfo* si_: *$1)
																			{
																				if(si_->getName() == "--null"){
																					flog << si_->getReturn_type();
																				}
																				else{
																					flog << si_->getReturn_type() << ' ' << si_->getName();
																				}
																				
																				if(si_ != $1->back()){
																					flog << ',';
																				}
																			}
																			flog << endl << endl;
																			
																			tempParamList = $$;
																		
																		}
							| type_specifier ID							{	flog << "Line " << line_count << ": parameter_list  : type_specifier ID" << endl << endl;
							
																			$2->setReturn_type(*$1);
																			
																			$$ = new vector <SymbolInfo*>();
																			$$->push_back($2);
																			
																			flog << $$->back()->getReturn_type() << ' ' << $$->back()->getName() << endl << endl;
																			
																			tempParamList = $$;
																			
																		}
							| type_specifier							{	flog << "Line " << line_count << ": parameter_list  : type_specifier" << endl << endl;
																			
																			// parameter without ID ... idk what to do with it :(
																			SymbolInfo* si = new SymbolInfo("--null", "--null");
																			si->setReturn_type(*$1);
																				
																			$$ = new vector <SymbolInfo*>();
																			$$->push_back(si);
																			
																			flog << $$->back()->getReturn_type() << endl << endl;
																			
																			tempParamList = $$;
																		}
							;

 		
compound_statement : 		LCURL {

									// entering scope
									
									table->EnterScope(flog);
									
									if(tempParamList != NULL){
										// inserting parameters in scope
										
										for(SymbolInfo* si_: *tempParamList)
										{
											if(si_->getName() != "--null"){
												table->Insert(si_->getName(), si_->getType());
												table->LookUp(si_->getName())->setReturn_type(si_->getReturn_type());
											}
										}
						
									}
									
									// clearing tempParamList
									tempParamList = NULL;
								
								} statements RCURL		{	flog << "Line " << line_count << ": compound_statement : LCURL statements RCURL" << endl << endl;

															$$ = new string("{\n" + *$3 + "}\n");
															flog << *$$ << endl << endl;
															
															
															table->PrintAllScopeTable(flog);
															flog << endl << endl;
															table->ExitScope(flog);
															
														}
							| LCURL {
									table->EnterScope(flog);
									
									if(tempParamList != NULL){
										// inserting parameters in scope
										
										for(SymbolInfo* si_: *tempParamList)
										{
											if(si_->getName() != "--null"){
												table->Insert(si_->getName(), si_->getType());
												table->LookUp(si_->getName())->setReturn_type(si_->getReturn_type());
											}
										}
						
									}
									// clearing tempParamList
									tempParamList = NULL;
								
								} RCURL		{	flog << "Line " << line_count << ": compound_statement : LCURL RCURL" << endl << endl;
													$$ = new string("{}\n");
													flog << *$$ << endl << endl;
													
													table->PrintAllScopeTable(flog);
													flog << endl << endl;
													table->ExitScope(flog);
													
											}
							;

var_declaration : 			type_specifier declaration_list SEMICOLON	{
											flog << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
											
											//----->>> setting type of declaration list <<<--------------
											
											// checking if type is viod
											
											if(*$1 == "void"){
												err_count++;
												ferr << "Error at line " << line_count << ":  Variable type cannot be void" << endl << endl;
												flog << "Error at line " << line_count << ":  Variable type cannot be void" << endl << endl;
											}
											
											$$ = new string(*$1 + ' ');	
											
											for(SymbolInfo* si : *$2)
											{
												si->setReturn_type(*$1);
												
												*$$ += si->getName();
												
												if(table->Insert(si->getName(), si->getType())){
													// successful insertion
													
													//if array, considering size
													if(si->getArray_size() > -1){
														*$$ += '[' + to_string(si->getArray_size()) + ']';
														table->LookUp(si->getName())->setArray_size(si->getArray_size());
													}
													table->LookUp(si->getName())->setReturn_type(*$1);
												}
												else{
													// multiple definition
													err_count++;
													ferr << "Error at line " << line_count << ": Multiple declaration of " << si->getName() << endl << endl;
													flog << "Error at line " << line_count << ": Multiple declaration of " << si->getName() << endl << endl;
												}
												
												if($2->back() != si){*$$ += ',';}
											}
											
											*$$ += ";\n";	
											flog << *$$ << endl << endl;
										}
 		 					;
 		 
type_specifier	: 			INT			{	flog << "Line " << line_count << ": type_specifier : INT" << endl << endl;
											flog << "int" << endl << endl;
											$$ = new string("int"); }
							| FLOAT		{	flog << "Line " << line_count << ": type_specifier : FLOAT" << endl << endl;
											flog << "float" << endl << endl;
											$$ = new string("float"); }
							| VOID		{	flog << "Line " << line_count << ": type_specifier : VOID" << endl << endl;
											flog << "void" << endl << endl;
											$$ = new string("void"); }
							;

declaration_list : 			declaration_list COMMA ID			{	flog << "Line " << line_count << ": declaration_list : declaration_list COMMA ID" << endl << endl;
																	
																	int flag = 1;
																	
																	for(SymbolInfo* si : *$1)	// checking multiple declaration
																	{
																		if(si->getName() == $3->getName()){flag = 0; break;}
																	}
																	
																	if(flag == 1){
																		//not multiple	
																	}
																	else{
																		err_count++;
																		ferr << "Error at line " << line_count << ": Multiple declaration of " << $3->getName() << " in declaration list" << endl << endl;	
																		flog << "Error at line " << line_count << ": Multiple declaration of " << $3->getName() << " in declaration list" << endl << endl;	
																	}
																	
																	$1->push_back($3);
																	
																	// flogging
																	for(SymbolInfo* si : *$1)
																	{
																		flog << si->getName();
																		
																		//if array, considering size
																		if(si->getArray_size() > -1){
																			flog << '[' << to_string(si->getArray_size()) << ']';
																		}
																		
																		if($1->back() != si){flog << ',';}
																	}
																	
																	flog << endl << endl;	
																	
																}
							| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD		{	
																	flog << "Line " << line_count << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
																	
																	int flag = 1;
																	
																	for(SymbolInfo* si : *$1)	// checking multiple declaration
																	{
																		if(si->getName() == $3->getName()){flag = 0; break;}
																	}
																	
																	if(flag == 1){
																		//not multiple
																	}
																	else{
																	
																		err_count++;
																		ferr << "Error at line " << line_count << ": multiple declaration " << $3->getName() << endl << endl;	
																		flog << "Error at line " << line_count << ": multiple declaration " << $3->getName() << endl << endl;	
																	}
																	
																	$3->setArray_size(stoi($5->getName()));
																
																	$1->push_back($3);
																	
																	// flogging
																	for(SymbolInfo* si : *$1)
																	{
																		flog << si->getName();
																		
																		//if array, considering size
																		if(si->getArray_size() > -1){
																			flog << '[' << to_string(si->getArray_size()) << ']';
																		}
																		
																		if($1->back() != si){flog << ',';}
																	}
																	
																	flog << endl << endl;	
																	
																}
							| ID								{	flog << "Line " << line_count << ": declaration_list : ID" << endl << endl;
																	
																	$$ = new vector<SymbolInfo*>();
																	$$->push_back($1);
																	
																	flog << $$->back()->getName() << endl << endl; }
							| ID LTHIRD CONST_INT RTHIRD		{	flog << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl << endl;
																	
																	$1->setArray_size(stoi($3->getName()));
																	
																	$$ = new vector<SymbolInfo*>();
																	$$->push_back($1);
																	
																	flog << $3->getName() << endl << endl;
																	
																	flog << $$->back()->getName() << '[' << $3->getName() << ']' << endl << endl; }
							;
 		  
statements : 				statement				{	flog << "Line " << line_count << ": statements : statement" << endl << endl;
														flog << *$1 << endl << endl;
														}
							| statements statement	{	flog << "Line " << line_count << ": statements : statements statement" << endl << endl;
														*$1 += *$2;
														flog << *$1 << endl << endl;	
													}
							;
	   
statement : 				var_declaration			{	flog << "Line " << line_count << ": statement : var_declaration" << endl << endl;
														flog << *$1 << endl << endl;}
							| expression_statement	{	flog << "Line " << line_count << ": statement : expression_statement" << endl << endl;
														flog << *$1 << endl << endl;}
							| compound_statement	{	flog << "Line " << line_count << ": statement : compound_statement" << endl << endl;
														flog << *$1 << endl << endl;}
							| FOR LPAREN expression_statement expression_statement expression RPAREN statement			{	
													flog << "Line " << line_count << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl;
													$$ = new string("for(" + *$3 + *$4 + $5->getName() + ')' + *$7);
													flog << *$$ << endl << endl;
													}
							| IF LPAREN expression RPAREN statement		%prec THEN				{	
													flog << "Line " << line_count << ": statement : IF LPAREN expression RPAREN statement" << endl << endl;
													$$ = new string("\nif(" + $3->getName() + ')' + *$5);
													flog << *$$ << endl << endl;
													}
							| IF LPAREN expression RPAREN statement ELSE statement		{	
													flog << "Line " << line_count << ": statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl;
													$$ = new string("\nif(" + $3->getName() + ')' + *$5 + "else" + *$7);
													flog << *$$ << endl << endl;
													}
							| WHILE LPAREN expression RPAREN statement	{	flog << "Line " << line_count << ": statement : WHILE LPAREN expression RPAREN statement" << endl << endl;
																			$$ = new string("while(" + $3->getName() + ')' + *$5);
																			flog << *$$ << endl << endl;
																			}
							| PRINTLN LPAREN ID RPAREN SEMICOLON		{	flog << "Line " << line_count << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl;
																			$$ = new string("printf(" + $3->getName() + ");\n");
																			
																			// checking if id declared and as non array, non function
																			SymbolInfo* si = table->LookUp($3->getName());
																			if(si == NULL){
																				err_count++;
																				ferr << "Error at line " << line_count << ": Undeclared variable " << $3->getName() << endl << endl;
																				flog << "Error at line " << line_count << ": Undeclared variable " << $3->getName() << endl << endl;
																			}
																			else if(si->getArray_size() != -1){
																				err_count++;
																				ferr << "Error at line " << line_count << ": " << $3->getName() << " is not declared as a variable" << endl << endl;
																				flog << "Error at line " << line_count << ": " << $3->getName() << " is not declared as a variable" << endl << endl;
																			}
																			else if(si->getReturn_type() == "void"){
																				err_count++;
																				ferr << "Error at line " << line_count << ": Parameter type cannot be void" << endl << endl;
																				flog << "Error at line " << line_count << ": Parameter type cannot be void" << endl << endl;
																			}
																			
																			flog << *$$ << endl << endl;
																			}
							| RETURN expression SEMICOLON				{	
																			// check if expression type matches the returntype of the current function scope
																			
																			flog << "Line " << line_count << ": statement : RETURN expression SEMICOLON" << endl << endl;
																			$$ = new string("return " + $2->getName() + ";\n");
																			flog << *$$ << endl << endl;
																			}
							;

expression_statement 		: SEMICOLON					{	flog << "Line " << line_count << ": expression_statement : SEMICOLON" << endl << endl;
															$$ = new string(";\n");
															flog << *$$ << endl << endl;
															}
							| expression SEMICOLON 		{	flog << "Line " << line_count << ": expression_statement : expression SEMICOLON" << endl << endl;
															$$ = new string($1->getName() + ";\n");
															flog << *$$ << endl << endl;
															}
							;

variable : 					ID 								{	flog << "Line " << line_count << ": variable : ID" << endl << endl;

																
																$$ = $1;
																$$->setType("pseudo");
																
																// checking if id declared and as non array, non function
																SymbolInfo* si = table->LookUp($1->getName());
																if(si == NULL){
																	err_count++;
																	ferr << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl << endl;
																	flog << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl << endl;
																}
																else if(si->getArray_size() != -1){
																	err_count++;
																	ferr << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is an array" << endl << endl;
																	flog << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is an array" << endl << endl;
																}
																else if(si->getReturn_type() == "void"){
																	err_count++;
																	ferr << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is void" << endl << endl;
																	flog << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is void" << endl << endl;
																}
																else{
																	// setting other properties return_type etc.
																	
																	$$->setReturn_type(si->getReturn_type());
																}
																
																
																flog << $$->getName() << endl << endl;															
															}
							| ID LTHIRD expression RTHIRD 	{	flog << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD" << endl << endl;
							
																
																// checkint if expression is int
																if($3->getReturn_type() != "int"){
																	err_count++;
																	ferr << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl;
																	flog << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl;
																}
																
																
																$$ = $1;
																$$->setType("pseudo");
																
																
																// checking if id declared and as array, non function
																SymbolInfo* si = table->LookUp($1->getName());
																if(si == NULL){
																	err_count++;
																	ferr << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl << endl;
																	flog << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl << endl;
																}
																else if(si->getArray_size() < 0){
																	err_count++;
																	ferr << "Error at line " << line_count << ": " << $1->getName() << " is not an array" << endl << endl;
																	flog << "Error at line " << line_count << ": " << $1->getName() << " is not an array" << endl << endl;
																}
																else if(si->getReturn_type() == "void"){
																	err_count++;
																	ferr << "Error at line " << line_count << ": " << $1->getName() << " is void" << endl << endl;
																	flog << "Error at line " << line_count << ": " << $1->getName() << " is void" << endl << endl;
																}
																else{
																	// setting other properties return_type etc.
																	
																	$$->setReturn_type(si->getReturn_type());
																}
																
																
																$$->setName($1->getName() + '[' + $3->getName() + ']');
																
																flog << $$->getName() << endl << endl;										
															}
							;

expression : 				logic_expression							{	flog << "Line " << line_count << ": expression : logic_expression" << endl << endl;
																			
																			flog << $1->getName() << endl << endl;
																		}	
							| variable ASSIGNOP logic_expression 		{	flog << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression" << endl << endl;
																		
																			// error if operands are void and warning if type don't match or smth .. don't know
																			if($1->getReturn_type() == "void"){
																				err_count++;
																				ferr << "Error at line " << line_count << ": " << $1->getName() << " is void" << endl << endl;
																				flog << "Error at line " << line_count << ": " << $1->getName() << " is void" << endl << endl;
																			}
																			if($3->getReturn_type() == "void"){
																			
																				err_count++;
																				ferr << "Error at line " << line_count << ": " << $3->getName() << " is void" << endl << endl;
																				flog << "Error at line " << line_count << ": " << $3->getName() << " is void" << endl << endl;
																			}
																			
																			if($1->getReturn_type() != $3->getReturn_type()){
																				ferr << "Error at line " << line_count << ": Type Mismatch" << endl << endl;
																				flog << "Error at line " << line_count << ": Type Mismatch" << endl << endl;
																			}
																																						
																			$$ = $1;
																			$$->setName($1->getName() + '=' + $3->getName());
																			flog << $$->getName() << endl << endl;
																		}	
							;
			
logic_expression : 			rel_expression 								{	flog << "Line " << line_count << ": logic_expression : rel_expression" << endl << endl;
																			
																			flog << $1->getName() << endl << endl;
																		}
							| rel_expression LOGICOP rel_expression 	{	flog << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;
																			
																			// checking return type
																			
																			if($1->getReturn_type() != "int" || $3->getReturn_type() != "int"){
																				err_count++;
																				ferr << "Error at line " << line_count << ": invalid operands" << endl << endl;
																				flog << "Error at line " << line_count << ": invalid operands" << endl << endl;
																			}
																			
																			$$ = $1;
																			$$->setName($1->getName() + $2->getName() + $3->getName());
																			
																			flog << $$->getName() << endl << endl;
																		}	
							;
			
rel_expression	: 			simple_expression 							{	flog << "Line " << line_count << ": rel_expression : simple_expression" << endl << endl;
																			flog << $1->getName() << endl << endl;
																		}
							| simple_expression RELOP simple_expression	{	flog << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression" << endl << endl;
																			$$ = $1;
																			$$->setName($1->getName() + $2->getName() + $3->getName());
																			$$->setReturn_type("int");			// boolean basically
																			
																			flog << $$->getName() << endl << endl;
																			
																		}
							;		
							
simple_expression : 		term 								{	flog << "Line " << line_count << ": simple_expression : term" << endl << endl;
																	flog << $1->getName() << endl << endl;
																}
							| simple_expression ADDOP term 		{	flog << "Line " << line_count << ": simple_expression : simple_expression ADDOP term" << endl << endl;
																	// handle return type
																	
																	$$ = $1;
																	$$->setName($1->getName() + $2->getName() + $3->getName());
																	
																	// possibly need to show a warning or smth .. don't know
																	// promoting type
																	if($3->getReturn_type() == "float"){
																		$$->setReturn_type("float");
																	}
																	
																	flog << $$->getName() << endl << endl;
																}
							;
							
term :						unary_expression					{	flog << "Line " << line_count << ": term : unary_expression" << endl << endl;
																	flog << $1->getName() << endl << endl;
																}
							|  term MULOP unary_expression		{	flog << "Line " << line_count << ": term : term MULOP unary_expression" << endl << endl;
																	
																	$$ = new SymbolInfo();
																	*$$ = *$3;
																	
																	$$->setName($1->getName() + $2->getName() + $3->getName());
																	
																	// possibly need to show a warning or smth .. don't know
																	// promoting type
																	if($1->getReturn_type() == "float"){
																		$$->setReturn_type("float");
																	}
																	
																	
																	if($2->getName() == "%"){
																		if($$->getReturn_type() == "float"){
																			err_count++;
																			ferr << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl;
																			flog << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl;
																		}
																		else{
																			string temp = $3->getName();
																			if(temp[0] == '0'){
																				err_count++;
																				ferr << "Error at line " << line_count << ": Modulus by Zero" << endl << endl;
																				flog << "Error at line " << line_count << ": Modulus by Zero" << endl << endl;
																			}
																		}
																	}
																	
																	flog << $$->getName() << endl << endl;
																}
							;

unary_expression : 			ADDOP unary_expression  	{	flog << "Line " << line_count << ": unary_expression : ADDOP unary_expression" << endl << endl;
															$$ = $2;
															$$->setName($1->getName() + $2->getName());
															
															flog << $$->getName() << endl << endl;
														}
							| NOT unary_expression 		{	flog << "Line " << line_count << ": unary_expression : NOT unary_expression" << endl << endl;
															
															$$ = $2;
															$$->setName('!' + $2->getName());
															
															// changing expression type to int -->>> not sure if this needs to be done
															$$->setReturn_type("int");
															
															flog << $$->getName() << endl << endl;
														}
							| factor 					{	flog << "Line " << line_count << ": unary_expression : factor" << endl << endl;
															
															// unary_expression gets factor's return type
															flog << $1->getName() << endl << endl;
														}
							;

factor	: 					variable 								{	flog << "Line " << line_count << ": factor : variable" << endl << endl;
																		flog << $1->getName() << endl << endl;
																	}
							| ID LPAREN argument_list RPAREN		{	flog << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN" << endl << endl;
							
																		//function call
																		
																		$$ = new SymbolInfo();
																		*$$ = *$1;
																		
																		SymbolInfo* tempSymb;
																		tempSymb = table->LookUp($$->getName());
																		
																		if(tempSymb == NULL){
																		
																		
																			//checking if id declared
																			
																			err_count++;
																			ferr << "Error at line " << line_count << ": Undeclared function " << $$->getName() << endl << endl;
																			flog << "Error at line " << line_count << ": Undeclared function " << $$->getName() << endl << endl;
																		}
																		else{
																			// checking if argument list is consistent with function declaration
																			
																			$$->setReturn_type(tempSymb->getReturn_type());
																			vector <SymbolInfo> funcParams = tempSymb->getParameter_list();
																			int i = 0;
																			
																			for(SymbolInfo* si: *$3)
																			{
																				
																				if(i >= funcParams.size()){
																					err_count++;
																					ferr << "Error at line " << line_count << ": too many parameters " << $$->getName() << endl << endl;
																					flog << "Error at line " << line_count << ": too many parameters " << $$->getName() << endl << endl;
																					break;
																				}
																			
																			
																				if(funcParams[i].getArray_size() < 0){
																					if(si->getArray_size() >= 0){
																						err_count++;
																						ferr << "Error at line " << line_count << ": function parameter requires non-array. " << si->getName() << " is an array." << endl << endl;
																			
																						flog << "Error at line " << line_count << ": function parameter requires non-array. " << si->getName() << " is an array." << endl << endl;
																					}
																					if(funcParams[i].getReturn_type() != si->getReturn_type()){
																						err_count++;
																						ferr << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getName() << ", Type mismatch " << funcParams[i].getReturn_type() << ' ' << si->getName() << endl << endl;
																						
																						flog << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getName() << ", Type mismatch " << funcParams[i].getReturn_type() << ' ' << si->getName() << endl << endl;
																					}
																				
																				}
																				else{
																					if(si->getArray_size() < 0){
																						err_count++;
																						ferr << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getName() <<  ", function parameter requires array. " << si->getName() << " is not an array." << endl << endl;
																						flog << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getName() <<  ", function parameter requires array. " << si->getName() << " is not an array." << endl << endl;
																					}
																					else if(si->getArray_size() != funcParams[i].getArray_size()){
																						err_count++;
																						ferr << "Error at line " << line_count << ": function parameter requires array of size " << funcParams[i].getArray_size() << ". " << si->getName() << endl << endl;
																						flog << "Error at line " << line_count << ": function parameter requires array of size " << funcParams[i].getArray_size() << ". " << si->getName() << endl << endl;
																					}
																					if(funcParams[i].getReturn_type() != si->getReturn_type()){
																						err_count++;
																						ferr << "Error at line " << line_count << ": Type mismatch" << funcParams[i].getReturn_type() << ' ' << si->getName() << endl << endl;
																						flog << "Error at line " << line_count << ": Type mismatch" << funcParams[i].getReturn_type() << ' ' << si->getName() << endl << endl;
																					}
																				
																				
																				}
																				
																				i++;
																			}
																			
																			
																			if(i < funcParams.size()){
																				err_count++;
																				ferr << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $$->getName() << endl << endl;
																			
																				flog << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $$->getName() << endl << endl;
																				//ferr << "Error at line " << line_count << ": not enough parameters " << $$->getName() << endl << endl;
																				break;
																			}
																		}
																		
																		string temps = "";
																		
																		for(SymbolInfo* si: *$3)
																		{
																			temps += si->getName();
																			if(si != $3->back()){temps += ',';}
																		}
																		
																		$$->setName($1->getName() + '(' + temps + ')');
																		$$->setType("pseudo");
																		
																		flog << $$->getName() << endl << endl;	
																	}
							| LPAREN expression RPAREN				{	flog << "Line " << line_count << ": factor : LPAREN expression RPAREN" << endl << endl;
																	
																		$$ = $2;
																		
																		$$->setName('(' + $2->getName() + ')');
																		
																		flog << $$->getName() << endl << endl;
																	
																	}
							| CONST_INT 							{	flog << "Line " << line_count << ": factor : CONST_INT" << endl << endl;
																		$$ = $1;
																		$$->setReturn_type("int");
																		$$->setType("pseudo");
																		flog << $$->getName() << endl << endl;
																	}	
							| CONST_FLOAT							{	flog << "Line " << line_count << ": factor : CONST_FLOAT" << endl << endl;
																		$$ = $1;
																		$$->setReturn_type("float");
																		$$->setType("pseudo");
																		flog << $$->getName() << endl << endl;
																	}
							| variable INCOP 						{	flog << "Line " << line_count << ": factor : variable INCOP" << endl << endl;
																		
																		// checking if variable is non function integer
																		if($1->getArray_size() < -1){
																			err_count++;
																			ferr << "Error at line " << line_count << ": invalid operation on " << $1->getName() << endl << endl; 
																			flog << "Error at line " << line_count << ": invalid operation on " << $1->getName() << endl << endl; 
																		}
																		else if($1->getReturn_type() != "int"){
																			err_count++;
																			ferr << "Error at line " << line_count << ": invalid operation on " << $1->getName() << ", " << $1->getName() << " is not an integer" << endl << endl;
																			flog << "Error at line " << line_count << ": invalid operation on " << $1->getName() << ", " << $1->getName() << " is not an integer" << endl << endl;
																		}
																		
																		$$ = $1;
																		$$->setName($1->getName() + "++");
																		flog << $$->getName() << endl << endl;
																		
																	}
							| variable DECOP						{	flog << "Line " << line_count << ": factor : variable DECOP" << endl << endl;
																		
																		// checking if variable is non function integer
																		if($1->getArray_size() < -1){
																			err_count++;
																			ferr << "Error at line " << line_count << ": invalid operation on " << $1->getName() << endl << endl; 
																			flog << "Error at line " << line_count << ": invalid operation on " << $1->getName() << endl << endl; 
																		}
																		else if($1->getReturn_type() != "int"){
																			err_count++;
																			ferr << "Error at line " << line_count << ": invalid operation on " << $1->getName() << ", " << $1->getName() << " is not an integer" << endl << endl;
																			flog << "Error at line " << line_count << ": invalid operation on " << $1->getName() << ", " << $1->getName() << " is not an integer" << endl << endl;
																		}
																		
																		$$ = $1;
																		$$->setName($1->getName() + "--");
																		flog << $$->getName() << endl << endl;
																	}
							;

argument_list : 			arguments		{	flog << "Line " << line_count << ": argument_list : arguments" << endl << endl;
												
												for(SymbolInfo* si: *$1)
												{
													flog << si->getName();
													if(si != $1->back()){flog << ',';}
												}
												
												flog << endl << endl;}
							|				{	flog << "Line " << line_count << ": argument_list : empty" << endl << endl;
												$$ = new vector <SymbolInfo*>();
												}
							;

arguments : 				arguments COMMA logic_expression		{	flog << "Line " << line_count << ": arguments : arguments COMMA logic_expression" << endl << endl;
																		$1->push_back($3);
																		
																		for(SymbolInfo* si: *$1)
																		{
																			flog << si->getName();
																			if(si != $1->back()){flog << ',';}
																		}
																		
																		flog << endl << endl;	
																																				
																	}
							| logic_expression						{	flog << "Line " << line_count << ": arguments : logic_expression" << endl << endl;
																		$$ = new vector <SymbolInfo*>();
																		$$->push_back($1);
																		
																		flog << $1->getName() << endl << endl;}
							;
 

%%

int main(int argc, char* argv[])
{
	FILE* fp;

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
	
	flog.open("log.txt", ios::out);
	ferr.open("error.txt", ios::out);
	
	yyin=fp;
	yyparse();
	
	flog.close();
	return 0;

}
