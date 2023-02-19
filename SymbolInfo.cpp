#include "SymbolInfo.h"

using namespace std;

SymbolInfo::SymbolInfo(){this->nextSymbol = NULL;}
SymbolInfo::SymbolInfo(string name, string type)
{
    this->name = name;
    this->type = type;
    this->return_type = "";
    this->nextSymbol = NULL;
    this->array_size = -1;
}

SymbolInfo::SymbolInfo (const SymbolInfo &obj)
{
    this->name = obj.name;
    this->type = obj.type;
    this->return_type = obj.return_type;
    this->array_size = obj.array_size;
    this->parameter_list = obj.parameter_list;
    this->nextSymbol = NULL;
}

void SymbolInfo::setName(string name){this->name = name;}
void SymbolInfo::setType(string type){this->type = type;}
void SymbolInfo::setReturn_type(string return_type){this->return_type = return_type;}
void SymbolInfo::setArray_size(int array_size){this->array_size = array_size;}
void SymbolInfo::setParameter_list(vector <SymbolInfo> parameter_list){this->parameter_list = parameter_list;}

void SymbolInfo::insertParameter(SymbolInfo parameter){this->parameter_list.push_back(parameter);}
void SymbolInfo::clearParameter_list(){this->parameter_list.clear(); }


string SymbolInfo::getName(){return name;}
string SymbolInfo::getType(){return type;}

string SymbolInfo::getReturn_type(){return return_type;}
int SymbolInfo::getArray_size(){return array_size;}
vector <SymbolInfo> SymbolInfo::getParameter_list(){return parameter_list;}

void SymbolInfo::Print(ostream &out)
{
    out << "< " << name << " : " << type << " >";
}

SymbolInfo::~SymbolInfo()
{
    if(nextSymbol) delete nextSymbol;       /// handle this while deleting single symbol
}

