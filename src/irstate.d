
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

module irstate;
extern(C++):

import _module;
import statement;
import fakebackend;
import dsymbol;
import identifier;
import declaration;
import arraytypes;

struct IRState
{
    IRState *prev;
    Statement statement;
    Module m;                  // module
    Dsymbol symbol;
    Identifier ident;
    Symbol *shidden;            // hidden parameter to function
    Symbol *sthis;              // 'this' parameter to function (member and nested)
    Symbol *sclosure;           // pointer to closure instance
    Blockx *blx;
    Dsymbols deferToObj;       // array of Dsymbol's to run toObjFile(int multiobj) on later
    elem *ehidden;              // transmit hidden pointer to CallExp::toElem()
    Symbol *startaddress;
    VarDeclarations varsInScope; // variables that are in scope that will need destruction later

    block *breakBlock;
    block *contBlock;
    block *switchBlock;
    block *defaultBlock;

    this(IRState *irs, Statement s);
    this(IRState *irs, Dsymbol s);
    this(Module m, Dsymbol s);

    block *getBreakBlock(Identifier ident);
    block *getContBlock(Identifier ident);
    block *getSwitchBlock();
    block *getDefaultBlock();
    FuncDeclaration getFunc();
    int arrayBoundsCheck();
};

