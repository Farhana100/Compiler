#include "SymbolTable.h"

using namespace std;

SymbolTable::SymbolTable()
{
    currentScopeTable = NULL;
    parentScopeTable = NULL;
    total_buckets = 1000;
}

SymbolTable::SymbolTable(int total_buckets)
{
    this->total_buckets = total_buckets;
    parentScopeTable = NULL;
    currentScopeTable = new ScopeTable("1", total_buckets);
    currentScopeTable->parentScope = parentScopeTable;
}

void SymbolTable::EnterScope(ostream &out)
{
    parentScopeTable = currentScopeTable;

    string newId = (parentScopeTable)?parentScopeTable->createNewId():"1";
    currentScopeTable = new ScopeTable(newId, total_buckets);
    currentScopeTable->parentScope = parentScopeTable;

    out << "New ScopeTable with id " << newId << " created" << endl;
}

bool SymbolTable::Insert(string name, string type)
{
    SymbolInfo symbol(name, type);
    if(currentScopeTable){
        return currentScopeTable->Insert(symbol);
    }
    return false;
}

bool SymbolTable::Remove(string symbol)
{
    if(currentScopeTable){
        if(currentScopeTable->Delete(symbol)){
            return true;
        }
        else{
            return false;
        }
    }

    return false;
}

SymbolInfo* SymbolTable::LookUp(string symbol)
{
    ScopeTable* temp = currentScopeTable;
    SymbolInfo* foundSymbol;
    while(temp){
        foundSymbol = temp->LookUp(symbol);
        if(foundSymbol) return foundSymbol;

        temp = temp->parentScope;
    }

    return NULL;
}

void SymbolTable::PrintCurrentScopeTable(ostream &out)
{
    if(currentScopeTable) currentScopeTable->Print(out);
    else out << "Empty";
}

void SymbolTable::PrintAllScopeTable(ostream &out)
{
    ScopeTable* temp = currentScopeTable;

    if(!temp){
        out << "Empty"; return;
    }
    while(temp){
        temp->Print(out);
        out << endl;
        temp = temp->parentScope;
    }
}

void SymbolTable::ExitScope(ostream &out)
{
    ScopeTable* temp = currentScopeTable;

    out << "ScopeTable with id " << temp->getId() << " removed" << endl;

    currentScopeTable = parentScopeTable;
    if(currentScopeTable){
        parentScopeTable = currentScopeTable->parentScope;
        currentScopeTable->deletedScopesCount++;
    }
    delete temp;
}

SymbolTable::~SymbolTable()
{
    while(parentScopeTable){
        delete currentScopeTable;
        currentScopeTable = parentScopeTable;
        parentScopeTable = parentScopeTable->parentScope;
    }

    if(currentScopeTable) delete currentScopeTable;
}
