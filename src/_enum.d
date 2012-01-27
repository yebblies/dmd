
// Compiler implementation of the D programming language
// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module _enum;
extern(C++):

import root.root;

import dsymbol;
import mtype;
import mars;
import expression;
import identifier;
import _scope;
import hdrgen;
import fakebackend;

final class EnumDeclaration : ScopeDsymbol
{
    /* enum ident : memtype { ... }
     */
    Type type;                 // the TypeEnum
    Type memtype;              // type of the members

version (DMDV1) {
    dinteger_t maxval;
    dinteger_t minval;
    dinteger_t defaultval;      // default initializer
} else {
    Expression maxval;
    Expression minval;
    Expression defaultval;     // default initializer
}
    int isdeprecated;
    int isdone;                 // 0: not done
                                // 1: semantic() successfully completed

    this(Loc loc, Identifier id, Type memtype);
    Dsymbol syntaxCopy(Dsymbol s);
    void semantic0(Scope *sc);
    void semantic(Scope *sc);
    int oneMember(Dsymbol *ps);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Type getType();
    const(char) *kind();
version (DMDV2) {
    Dsymbol search(Loc, Identifier ident, int flags);
}
    int isDeprecated();                 // is Dsymbol deprecated?

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toDocBuffer(OutBuffer buf);

    EnumDeclaration isEnumDeclaration();

    void toObjFile(int multiobj);                       // compile to .obj file
    void toDebug();
    int cvMember(ubyte *p);

    Symbol *sinit;
    Symbol *toInitializer();
};


class EnumMember : Dsymbol
{
    Expression value;
    Type type;

    this(Loc loc, Identifier id, Expression value, Type type);
    Dsymbol syntaxCopy(Dsymbol s);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char) *kind();

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toDocBuffer(OutBuffer buf);

    EnumMember isEnumMember();
};

