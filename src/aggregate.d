
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module aggregate;

import root.root;

import dsymbol;
import mtype;
import arraytypes;
import mars;
import declaration;
import identifier;
import _scope;
import fakebackend;
import hdrgen;

extern(C++)
class AggregateDeclaration : ScopeDsymbol
{
    Type type;
    StorageClass storage_class;
    PROT protection;
    Type handle;               // 'this' type
    uint structsize;        // size of struct
    uint alignsize;         // size of struct for alignment purposes
    uint structalign;       // struct member alignment in effect
    int hasUnions;              // set if aggregate has overlapping fields
    VarDeclarations fields;     // VarDeclaration fields
    uint sizeok;            // set when structsize contains valid data
                                // 0: no size
                                // 1: size is correct
                                // 2: cannot determine size; fwd referenced
    Dsymbol deferred;          // any deferred semantic2() or semantic3() symbol
    int isdeprecated;           // !=0 if deprecated

//static if (DMDV2) {
    int isnested;               // !=0 if is nested
    VarDeclaration vthis;      // 'this' parameter if this aggregate is nested
//}
    // Special member functions
    InvariantDeclaration inv;          // invariant
    NewDeclaration aggNew;             // allocator
    DeleteDeclaration aggDelete;       // deallocator

//static if (DMDV2) {
    //CtorDeclaration ctor;
    Dsymbol ctor;                      // CtorDeclaration or TemplateDeclaration
    CtorDeclaration defaultCtor;       // default constructor
    Dsymbol aliasthis;                 // forward unresolved lookups to aliasthis
    bool noDefaultCtor;         // no default construction
//}

    FuncDeclarations dtors;     // Array of destructors
    FuncDeclaration dtor;      // aggregate destructor

static if (IN_GCC) {
    Array methods;              // flat list of all methods for debug information
}

    this(Loc loc, Identifier id);
    final void semantic2(Scope *sc);
    final void semantic3(Scope *sc);
    final void inlineScan();
    final uint size(Loc loc);
    static void alignmember(uint salign, uint size, uint *poffset);
    final Type getType();
    final void addField(Scope *sc, VarDeclaration v);
    final int firstFieldInUnion(int indx); // first field in union that includes indx
    final int numFieldsInUnion(int firstIndex); // #fields in union starting at index
    final int isDeprecated();         // is aggregate deprecated?
    final FuncDeclaration buildDtor(Scope *sc);
    final int isNested();
    final int isExport();

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toDocBuffer(OutBuffer buf);

    // For access checking
    PROT getAccess(Dsymbol smember);   // determine access to smember
    final int isFriendOf(AggregateDeclaration cd);
    final int hasPrivateAccess(Dsymbol smember);     // does smember have private access to members of this class?
    final void accessCheck(Loc loc, Scope *sc, Dsymbol smember);

    final PROT prot();

    // Back end
    Symbol *stag;               // tag symbol for debug data
    Symbol *sinit;
    final Symbol *toInitializer();

    AggregateDeclaration isAggregateDeclaration() { return this; }
};

extern(C++)
class AnonymousAggregateDeclaration : AggregateDeclaration
{
    this() { super(Loc(0), null); }

    AnonymousAggregateDeclaration isAnonymousAggregateDeclaration() { return this; }
};

extern(C++)
class StructDeclaration : AggregateDeclaration
{
    int zeroInit;               // !=0 if initialize with 0 fill
//static if (DMDV2) {
    int hasIdentityAssign;      // !=0 if has identity opAssign
    int hasIdentityEquals;      // !=0 if has identity opEquals
    FuncDeclaration cpctor;    // generated copy-constructor, if any
    FuncDeclarations postblits; // Array of postblit functions
    FuncDeclaration postblit;  // aggregate postblit

    FuncDeclaration xeq;       // TypeInfo_Struct.xopEquals
    static FuncDeclaration xerreq;      // object.xopEquals
//}

    this(Loc loc, Identifier id);
    Dsymbol syntaxCopy(Dsymbol s);
    final void semantic(Scope *sc);
    Dsymbol search(Loc, Identifier ident, int flags);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    char *mangle();
    const(char)* kind();
static if (DMDV1) {
    Expression cloneMembers();
}
//static if (DMDV2) {
    final int needOpAssign();
    final int needOpEquals();
    final FuncDeclaration buildOpAssign(Scope *sc);
    final FuncDeclaration buildOpEquals(Scope *sc);
    final FuncDeclaration buildPostBlit(Scope *sc);
    final FuncDeclaration buildCpCtor(Scope *sc);

    final FuncDeclaration buildXopEquals(Scope *sc);
//}
    void toDocBuffer(OutBuffer buf);

    final PROT getAccess(Dsymbol smember);   // determine access to smember

    void toObjFile(int multiobj);                       // compile to .obj file
    final void toDt(dt_t **pdt);
    final void toDebug();                     // to symbolic debug info

    StructDeclaration isStructDeclaration() { return this; }
};

extern(C++)
final class UnionDeclaration : StructDeclaration
{
    this(Loc loc, Identifier id);
    Dsymbol syntaxCopy(Dsymbol s);
    const(char)* kind();

    UnionDeclaration isUnionDeclaration() { return this; }
};

extern(C++)
final class BaseClass
{
    Type type;                         // (before semantic processing)
    PROT protection;               // protection for the base interface

    ClassDeclaration base;
    int offset;                         // 'this' pointer offset
    FuncDeclarations vtbl;              // for interfaces: Array of FuncDeclaration's
                                        // making up the vtbl[]

    size_t baseInterfaces_dim;
    BaseClass baseInterfaces;          // if BaseClass is an interface, these
                                        // are a copy of the InterfaceDeclaration::interfaces

    this();
    this(Type type, PROT protection);

    int fillVtbl(ClassDeclaration cd, FuncDeclarations vtbl, int newinstance);
    void copyBaseInterfaces(BaseClasses );
};

//static if (DMDV2) {
    enum CLASSINFO_SIZE_64 = 0x98;         // value of ClassInfo.size
    enum CLASSINFO_SIZE = (0x3C+12+4);     // value of ClassInfo.size
//} else {
//    enum CLASSINFO_SIZE = (0x3C+12+4);     // value of ClassInfo.size
//}

extern(C++)
class ClassDeclaration : AggregateDeclaration
{
    static extern ClassDeclaration object;
    static extern ClassDeclaration classinfo;
    static extern ClassDeclaration throwable;
    static extern ClassDeclaration exception;
    static extern ClassDeclaration errorException;

    ClassDeclaration baseClass;        // NULL only if this is Object
//static if (DMDV1) {
//    CtorDeclaration ctor;
//    CtorDeclaration defaultCtor;       // default constructor
//}
    FuncDeclaration staticCtor;
    FuncDeclaration staticDtor;
    Dsymbols vtbl;                      // Array of FuncDeclaration's making up the vtbl[]
    Dsymbols vtblFinal;                 // More FuncDeclaration's that aren't in vtbl[]

    BaseClasses baseclasses;           // Array of BaseClass's; first is super,
                                        // rest are Interface's

    size_t interfaces_dim;
    BaseClass *interfaces;             // interfaces[interfaces_dim] for this class
                                        // (does not include baseClass)

    BaseClasses vtblInterfaces;        // array of base interfaces that have
                                        // their own vtbl[]

    TypeInfoClassDeclaration vclassinfo;       // the ClassInfo object for this ClassDeclaration
    int com;                            // !=0 if this is a COM class (meaning
                                        // it derives from IUnknown)
    int isscope;                         // !=0 if this is an auto class
    int isabstract;                     // !=0 if abstract class
//static if (DMDV1) {
//    int isnested;                       // !=0 if is nested
//    VarDeclaration vthis;              // 'this' parameter if this class is nested
//}
    int inuse;                          // to prevent recursive attempts

    this(Loc loc, Identifier id, BaseClasses baseclasses);
    Dsymbol syntaxCopy(Dsymbol s);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    final int isBaseOf2(ClassDeclaration cd);

    enum OFFSET_RUNTIME = 0x76543210;
    final int isBaseOf(ClassDeclaration cd, int *poffset);

    final int isBaseInfoComplete();
    final Dsymbol search(Loc, Identifier ident, int flags);
    final Dsymbol searchBase(Loc, Identifier ident);
//static if (DMDV2) {
    final int isFuncHidden(FuncDeclaration fd);
//}
    final FuncDeclaration findFunc(Identifier ident, TypeFunction tf);
    final void interfaceSemantic(Scope *sc);
//static if (DMDV1) {
//    int isNested();
//}
    final int isCOMclass();
    final int isCOMinterface();
//static if (DMDV2) {
    final int isCPPinterface();
//}
    final int isAbstract();
    final int vtblOffset();
    const(char)* kind();
    char *mangle();
    void toDocBuffer(OutBuffer buf);

    final PROT getAccess(Dsymbol smember);   // determine access to smember

    void addLocalClass(ClassDeclarations );

    // Back end
    void toObjFile(int multiobj);                       // compile to .obj file
    final void toDebug();
    final uint baseVtblOffset(BaseClass bc);
    Symbol *toSymbol();
    final Symbol *toVtblSymbol();
    final void toDt(dt_t **pdt);
    final void toDt2(dt_t **pdt, ClassDeclaration cd);

    Symbol *vtblsym;

    ClassDeclaration isClassDeclaration() { return this; }
};

extern(C++)
final class InterfaceDeclaration : ClassDeclaration
{
//static if (DMDV2) {
    int cpp;                            // !=0 if this is a C++ interface
//}
    this(Loc loc, Identifier id, BaseClasses baseclasses);
    Dsymbol syntaxCopy(Dsymbol s);
    void semantic(Scope *sc);
    int isBaseOf(ClassDeclaration cd, int *poffset);
    int isBaseOf(BaseClass bc, int *poffset);
    const(char)* kind();
    final int isBaseInfoComplete();
    int vtblOffset();
//static if (DMDV2) {
    int isCPPinterface();
//}
    int isCOMinterface();

    void toObjFile(int multiobj);                       // compile to .obj file
    Symbol *toSymbol();

    InterfaceDeclaration isInterfaceDeclaration() { return this; }
};

