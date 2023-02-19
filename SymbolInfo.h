#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H

#include <iostream>
#include <vector>
#include <string>

using namespace std;

class SymbolInfo
{

private:
    string name;
    string type;
    string return_type;
    vector <SymbolInfo> parameter_list;
    int array_size;         /** holds
                                    - array size if symbol is an array
                                    - -2         if symbol is an undefined but declared function
                                    - -3         if symbol is a defined function
                                    - else holds -1 */

public:
    SymbolInfo* nextSymbol;
    SymbolInfo();
    SymbolInfo(string name, string type);

    SymbolInfo (const SymbolInfo &obj);

    void setName(string name);
    void setType(string type);
    void setReturn_type(string return_type);
    void setArray_size(int array_size);
    void setParameter_list(vector <SymbolInfo> parameter_list);
    void insertParameter(SymbolInfo parameter);
    void clearParameter_list();

    string getName();
    string getType();
    string getReturn_type();
    int getArray_size();
    vector <SymbolInfo> getParameter_list();


    void Print(ostream &out);

    ~SymbolInfo();
};


#endif // SYMBOLINFO_H
