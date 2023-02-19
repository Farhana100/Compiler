#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <iostream>
#include <string>
#include "SymbolInfo.h"
#include "ScopeTable.h"

using namespace std;

class SymbolTable
{

private:
    ScopeTable* currentScopeTable;
    ScopeTable* parentScopeTable;
    int total_buckets;
public:
    SymbolTable();

    SymbolTable(int total_buckets);

    void EnterScope(ostream &out);
    bool Insert(string name, string type);
    bool Remove(string symbol);
    SymbolInfo* LookUp(string symbol);
    void PrintCurrentScopeTable(ostream &out);
    void PrintAllScopeTable(ostream &out);
    void ExitScope(ostream &out);

    ~SymbolTable();
};

#endif // SYMBOLTABLE_H
