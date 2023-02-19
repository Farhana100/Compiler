#include "ScopeTable.h"

using namespace std;

int ScopeTable::hashFun(string name)
{
    int sum_ascii = 0;
    for(char ch: name)sum_ascii += ch;
    return sum_ascii%total_buckets;
}

ScopeTable::ScopeTable(){}

ScopeTable::ScopeTable(string id, int total_buckets)
{
    deletedScopesCount = 0;
    this->id  = id;
    this->total_buckets = total_buckets;
    symbols = new SymbolInfo*[total_buckets];
    for(int i = 0; i < total_buckets; i++) symbols[i] = NULL;
    this->parentScope = NULL;
}

ScopeTable::ScopeTable(int total_buckets)
{
    this->total_buckets = total_buckets;
    symbols = new SymbolInfo*[total_buckets];
    for(int i = 0; i < total_buckets; i++) symbols[i] = NULL;
    this->parentScope = NULL;
}

string ScopeTable::getId(){return id;}

string ScopeTable::createNewId()
{
    return id + "." + to_string(deletedScopesCount + 1);
}



bool ScopeTable::Insert(SymbolInfo symbol)
{
    int hashValue = hashFun(symbol.getName());

    int cnt = 0;
    if(!symbols[hashValue]){
        symbols[hashValue] = new SymbolInfo(symbol);
        return true;
    }
    SymbolInfo* temp = symbols[hashValue];

    while(true){
        cnt++;
        if(temp->getName() == symbol.getName()){
            return false;
        }
        if((temp->nextSymbol == NULL))break;
        temp = temp->nextSymbol;
    }


    temp->nextSymbol = new SymbolInfo(symbol);
    temp = NULL;

    return true;
}

SymbolInfo* ScopeTable::LookUp(string symbol)
{
    int hashValue = hashFun(symbol);

    SymbolInfo* temp = symbols[hashValue];

    int cnt = 0;
    while(temp != NULL){
        if(temp->getName() == symbol){
            return temp;
        }
        cnt++;
        temp = temp->nextSymbol;
    }

    return NULL;
}

bool ScopeTable::Delete(string symbol)
{
    int hashValue = hashFun(symbol);
    SymbolInfo* temp = symbols[hashValue];
    if(!temp){
        return false;
    }

    int cnt = 0;
    if(temp->getName() == symbol){
        symbols[hashValue] = temp->nextSymbol;
        temp->nextSymbol = NULL;
        delete temp;
        return true;
    }

    while(temp->nextSymbol != NULL){
        cnt++;
        if(temp->nextSymbol->getName() == symbol){
            SymbolInfo* deleteThis = temp->nextSymbol;
            temp->nextSymbol = temp->nextSymbol->nextSymbol;
            deleteThis->nextSymbol = NULL;

            delete deleteThis;
            return true;
        }
        temp = temp->nextSymbol;
    }
    return false;

}

void ScopeTable::Print(ostream &out)
{
    out << "ScopeTable # " << id << endl;

    for(int i = 0; i < total_buckets; i++){
        if(!symbols[i])continue;
        out << i << " --> ";
        SymbolInfo* temp = symbols[i];
        while(temp){
            temp->Print(out);
            out << ' ';
            temp = temp->nextSymbol;
        }
        out << endl;
    }
}

ScopeTable::~ScopeTable()
{
    for(int i = 0; i < total_buckets; i++) delete symbols[i];
    delete []symbols;
}
