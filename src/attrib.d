
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module attrib;
extern(C++):

import dsymbol;
import expression;
import statement;
import init;
import _module;
import cond;
import hdrgen;
import arraytypes;
import _scope;
import mars;
import root.root;
import identifier;

/**************************************************************/

class AttribDeclaration : Dsymbol
{
    Dsymbols decl;     // array of Dsymbol's

    this(Dsymbols decl);
    Dsymbols include(Scope *sc, ScopeDsymbol s);
    int addMember(Scope *sc, ScopeDsymbol s, int memnum);
    final void setScopeNewSc(Scope *sc,
        StorageClass newstc, LINK linkage, PROT protection, int explictProtection,
        uint structalign);
    final void semanticNewSc(Scope *sc,
        StorageClass newstc, LINK linkage, PROT protection, int explictProtection,
        uint structalign);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    void inlineScan();
    void addComment(ubyte *comment);
    void emitComment(Scope *sc);
    const(char)* kind();
    int oneMember(Dsymbol *ps);
    int hasPointers();
    bool hasStaticCtorOrDtor();
    void checkCtorConstInit();
    final void addLocalClass(ClassDeclarations );
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toJsonBuffer(OutBuffer buf);
    AttribDeclaration isAttribDeclaration();

    void toObjFile(int multiobj);                       // compile to .obj file
    int cvMember(ubyte *p);
};

class StorageClassDeclaration : AttribDeclaration
{
    StorageClass stc;

    this(StorageClass stc, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void setScope(Scope *sc);
    void semantic(Scope *sc);
    int oneMember(Dsymbol *ps);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    static void stcToCBuffer(OutBuffer buf, StorageClass stc);
};

class LinkDeclaration : AttribDeclaration
{
    LINK linkage;

    this(LINK p, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void setScope(Scope *sc);
    void semantic(Scope *sc);
    void semantic3(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    char *toChars();
};

class ProtDeclaration : AttribDeclaration
{
    PROT protection;

    this(PROT p, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void importAll(Scope *sc);
    void setScope(Scope *sc);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    static void protectionToCBuffer(OutBuffer buf, PROT protection);
};

class AlignDeclaration : AttribDeclaration
{
    uint salign;

    this(uint sa, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void setScope(Scope *sc);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class AnonDeclaration : AttribDeclaration
{
    int isunion;
    int sem;                    // 1 if successful semantic()

    this(Loc loc, int isunion, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char)* kind();
};

class PragmaDeclaration : AttribDeclaration
{
    Expressions args;          // array of Expression's

    this(Loc loc, Identifier ident, Expressions args, Dsymbols decl);
    Dsymbol syntaxCopy(Dsymbol s);
    void semantic(Scope *sc);
    void setScope(Scope *sc);
    int oneMember(Dsymbol *ps);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char)* kind();
    void toObjFile(int multiobj);                       // compile to .obj file
};

class ConditionalDeclaration : AttribDeclaration
{
    Condition condition;
    Dsymbols elsedecl; // array of Dsymbol's for else block

    this(Condition condition, Dsymbols decl, Dsymbols elsedecl);
    Dsymbol syntaxCopy(Dsymbol s);
    int oneMember(Dsymbol *ps);
    void emitComment(Scope *sc);
    Dsymbols include(Scope *sc, ScopeDsymbol s);
    void addComment(ubyte *comment);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toJsonBuffer(OutBuffer buf);
    void importAll(Scope *sc);
    void setScope(Scope *sc);
};

class StaticIfDeclaration : ConditionalDeclaration
{
    ScopeDsymbol sd;
    int addisdone;

    this(Condition condition, Dsymbols decl, Dsymbols elsedecl);
    Dsymbol syntaxCopy(Dsymbol s);
    int addMember(Scope *sc, ScopeDsymbol s, int memnum);
    void semantic(Scope *sc);
    void importAll(Scope *sc);
    void setScope(Scope *sc);
    const(char)* kind();
};

// Mixin declarations

final class CompileDeclaration : AttribDeclaration
{
    Expression exp;

    ScopeDsymbol sd;
    int compiled;

    this(Loc loc, Expression exp);
    Dsymbol syntaxCopy(Dsymbol s);
    int addMember(Scope *sc, ScopeDsymbol sd, int memnum);
    void compileIt(Scope *sc);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

