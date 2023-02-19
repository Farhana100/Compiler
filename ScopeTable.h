#ifndef SCOPETABLE_H
#define SCOPETABLE_H

#include <iostream>
#include <string>
#include "SymbolInfo.h"

using namespace std;

class ScopeTable
{

private:
    string id;
    int total_buckets;
    SymbolInfo** symbols;


    int hashFun(string name);

public:
    int deletedScopesCount;
    ScopeTable* parentScope;
    ScopeTable();
    ScopeTable(string id, int total_buckets = 1000);

    ScopeTable(int total_buckets = 1000);

    string getId();
    string createNewId();

    bool Insert(SymbolInfo symbol);
    SymbolInfo* LookUp(string symbol);
    bool Delete(string symbol);
    void Print(ostream &out);

    ~ScopeTable();
};

#endif // SCOPETABLE_H
