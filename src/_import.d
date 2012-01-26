
// Compiler implementation of the D programming language
// Copyright (c) 1999-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module _import;
extern(C++):

import dsymbol;
import identifier;
import _scope;
import root.root;
import _module;
import declaration;
import hdrgen;
import arraytypes;
import mars;

class Import : Dsymbol
{
    Identifiers packages;      // array of Identifier's representing packages
    Identifier id;             // module Identifier
    Identifier aliasId;
    int isstatic;               // !=0 if static import

    // Pairs of alias=name to bind into current namespace
    Identifiers names;
    Identifiers aliases;

    Module mod;
    Package pkg;               // leftmost package/module

    this(Loc loc, Identifiers packages, Identifier id, Identifier aliasId,
        int isstatic);
    void addAlias(Identifier name, Identifier _alias);

    const(char)* kind();
    Dsymbol syntaxCopy(Dsymbol s);    // copy only syntax trees
    void load(Scope *sc);
    void importAll(Scope *sc);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    Dsymbol search(Loc loc, Identifier ident, int flags);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    char *toChars();

    Import isImport() { return this; }
};

