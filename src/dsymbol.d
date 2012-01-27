
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module dsymbol;

import core.stdc.stdarg;

import root.root;
import root.stringtable;

import mars;
import arraytypes;
import identifier;
import _module;
import _scope;
import _template;
import hdrgen;
import aggregate;
import mtype;
import statement;
import _enum;
import declaration;
import _import;
import attrib;
import expression;
import root.aav;

import fakebackend;

enum PROT
{
    PROTundefined,
    PROTnone,           // no access
    PROTprivate,
    PROTpackage,
    PROTprotected,
    PROTpublic,
    PROTexport,
};
alias PROT.PROTundefined PROTundefined;
alias PROT.PROTnone PROTnone;
alias PROT.PROTprivate PROTprivate;
alias PROT.PROTpackage PROTpackage;
alias PROT.PROTprotected PROTprotected;
alias PROT.PROTpublic PROTpublic;
alias PROT.PROTexport PROTexport;

/* State of symbol in winding its way through the passes of the compiler
 */
alias uint PASS;
enum : PASS
{
    PASSinit,           // initial state
    PASSsemantic,       // semantic() started
    PASSsemanticdone,   // semantic() done
    PASSsemantic2,      // semantic2() run
    PASSsemantic3,      // semantic3() started
    PASSsemantic3done,  // semantic3() done
    PASSobj,            // toObjFile() run
};

extern(C++)
class Dsymbol : _Object
{
    Identifier ident;
    Identifier c_ident;
    Dsymbol parent;
    Symbol *csym;               // symbol for code generator
    Symbol *isym;               // import version of csym
    ubyte* comment;     // documentation comment for this Dsymbol
    Loc loc;                    // where defined
    Scope *_scope;               // !=null means context to use for semantic()

    this();
    this(Identifier );
    char *toChars();
    final char *locToChars();
    int equals(_Object o);
    final int isAnonymous();
    final void error(Loc loc, const(char)* format, ...);
    final void error(const(char)* format, ...);
    final void verror(Loc loc, const(char)* format, va_list ap);
    final void checkDeprecated(Loc loc, Scope *sc);
    final Module getModule();
    final Dsymbol pastMixin();
    final Dsymbol toParent();
    final Dsymbol toParent2();
    final TemplateInstance inTemplateInstance();

    int dyncast() { return DYNCAST_DSYMBOL; }   // kludge for template.isSymbol()

    static Dsymbols arraySyntaxCopy(Dsymbols a);

    const(char)* toPrettyChars();
    const(char)* kind();
    Dsymbol toAlias();                 // resolve real symbol
    int addMember(Scope *sc, ScopeDsymbol s, int memnum);
    void setScope(Scope *sc);
    void importAll(Scope *sc);
    void semantic0(Scope *sc);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    void inlineScan();
    Dsymbol search(Loc loc, Identifier ident, int flags);
    final Dsymbol search_correct(Identifier id);
    final Dsymbol searchX(Loc loc, Scope *sc, Identifier id);
    int overloadInsert(Dsymbol s);
    final char *toHChars();
    final void toHBuffer(OutBuffer buf, HdrGenState *hgs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toDocBuffer(OutBuffer buf);
    void toJsonBuffer(OutBuffer buf);
    uint size(Loc loc);
    int isforwardRef();
    void defineRef(Dsymbol s);
    AggregateDeclaration isThis();     // is a 'this' required to access the member
    final AggregateDeclaration isAggregateMember();  // are we a member of an aggregate?
    final ClassDeclaration isClassMember();          // are we a member of a class?
    int isExport();                     // is Dsymbol exported?
    int isImportedSymbol();             // is Dsymbol imported?
    int isDeprecated();                 // is Dsymbol deprecated?
//static if (DMDV2) {
    int isOverloadable();
//}
    LabelDsymbol isLabel();            // is this a LabelDsymbol?
    AggregateDeclaration isMember();   // is this symbol a member of an AggregateDeclaration?
    Type getType();                    // is this a type?
    char *mangle();
    int needThis();                     // need a 'this' pointer?
    PROT prot();
    Dsymbol syntaxCopy(Dsymbol s);    // copy only syntax trees
    int oneMember(Dsymbol *ps);
    static int oneMembers(Dsymbols members, Dsymbol *ps, Identifier ident = null);
    int hasPointers();
    bool hasStaticCtorOrDtor();
    void addLocalClass(ClassDeclarations ) { }
    void checkCtorConstInit() { }

    void addComment(ubyte* comment);
    void emitComment(Scope *sc);
    final void emitDitto(Scope *sc);

    // Backend

    Symbol *toSymbol();                 // to backend symbol
    void toObjFile(int multiobj);                       // compile to .obj file
    int cvMember(ubyte* p);     // emit cv debug info for member

    final Symbol *toImport();                         // to backend import symbol
    static Symbol *toImport(Symbol *s);         // to backend import symbol

    final Symbol *toSymbolX(const(char)* prefix, int sclass, TYPE *t, const(char)* suffix);     // helper

    // Eliminate need for dynamic_cast
    Package isPackage() { return null; }
    Module isModule() { return null; }
    EnumMember isEnumMember() { return null; }
    TemplateDeclaration isTemplateDeclaration() { return null; }
    TemplateInstance isTemplateInstance() { return null; }
    TemplateMixin isTemplateMixin() { return null; }
    Declaration isDeclaration() { return null; }
    ThisDeclaration isThisDeclaration() { return null; }
    TupleDeclaration isTupleDeclaration() { return null; }
    TypedefDeclaration isTypedefDeclaration() { return null; }
    AliasDeclaration isAliasDeclaration() { return null; }
    AggregateDeclaration isAggregateDeclaration() { return null; }
    FuncDeclaration isFuncDeclaration() { return null; }
    FuncAliasDeclaration isFuncAliasDeclaration() { return null; }
    FuncLiteralDeclaration isFuncLiteralDeclaration() { return null; }
    CtorDeclaration isCtorDeclaration() { return null; }
    PostBlitDeclaration isPostBlitDeclaration() { return null; }
    DtorDeclaration isDtorDeclaration() { return null; }
    StaticCtorDeclaration isStaticCtorDeclaration() { return null; }
    StaticDtorDeclaration isStaticDtorDeclaration() { return null; }
    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return null; }
    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return null; }
    InvariantDeclaration isInvariantDeclaration() { return null; }
    UnitTestDeclaration isUnitTestDeclaration() { return null; }
    NewDeclaration isNewDeclaration() { return null; }
    VarDeclaration isVarDeclaration() { return null; }
    ClassDeclaration isClassDeclaration() { return null; }
    StructDeclaration isStructDeclaration() { return null; }
    UnionDeclaration isUnionDeclaration() { return null; }
    InterfaceDeclaration isInterfaceDeclaration() { return null; }
    ScopeDsymbol isScopeDsymbol() { return null; }
    WithScopeSymbol isWithScopeSymbol() { return null; }
    ArrayScopeSymbol isArrayScopeSymbol() { return null; }
    Import isImport() { return null; }
    EnumDeclaration isEnumDeclaration() { return null; }
    DeleteDeclaration isDeleteDeclaration() { return null; }
    SymbolDeclaration isSymbolDeclaration() { return null; }
    AttribDeclaration isAttribDeclaration() { return null; }
    OverloadSet isOverloadSet() { return null; }
static if (TARGET_NET) {
    PragmaScope isPragmaScope() { return null; }
}
};

// Dsymbol that generates a scope

extern(C++)
class ScopeDsymbol : Dsymbol
{
    Dsymbols members;          // all Dsymbol's in this scope
    DsymbolTable symtab;       // members[] sorted into table

    Dsymbols imports;          // imported Dsymbol's
    ubyte* prots;       // array of PROT, one for each import

    this();
    this(Identifier id);
    Dsymbol syntaxCopy(Dsymbol s);
    abstract void semantic(Scope *sc);
    Dsymbol search(Loc loc, Identifier ident, int flags);
    final void importScope(Dsymbol s, PROT protection);
    int isforwardRef();
    void defineRef(Dsymbol s);
    static void multiplyDefined(Loc loc, Dsymbol s1, Dsymbol s2);
    final Dsymbol nameCollision(Dsymbol s);
    const(char)* kind();
    final FuncDeclaration findGetMembers();
    Dsymbol symtabInsert(Dsymbol s);
    bool hasStaticCtorOrDtor();
    abstract int isExport();

    final void emitMemberComments(Scope *sc);

    static size_t dim(Dsymbols members);
    static Dsymbol getNth(Dsymbols members, size_t nth, size_t *pn = null);

    alias int function(void *ctx, size_t idx, Dsymbol s) ForeachDg;
    static int _foreach(Dsymbols members, ForeachDg dg, void *ctx, size_t *pn=null);

    ScopeDsymbol isScopeDsymbol() { return this; }
};

// With statement scope

extern(C++)
class WithScopeSymbol : ScopeDsymbol
{
    WithStatement withstate;

    this(WithStatement withstate);
    Dsymbol search(Loc loc, Identifier ident, int flags);

    WithScopeSymbol isWithScopeSymbol() { return this; }
};

// Array Index/Slice scope

extern(C++)
class ArrayScopeSymbol : ScopeDsymbol
{
    Expression exp;    // IndexExp or SliceExp
    TypeTuple type;    // for tuple[length]
    TupleDeclaration td;       // for tuples of objects
    Scope *sc;

    this(Scope *sc, Expression e);
    this(Scope *sc, TypeTuple t);
    this(Scope *sc, TupleDeclaration td);
    Dsymbol search(Loc loc, Identifier ident, int flags);

    ArrayScopeSymbol isArrayScopeSymbol() { return this; }
};

// Overload Sets

//static if (DMDV2) {
extern(C++)
final class OverloadSet : Dsymbol
{
    Dsymbols a;         // array of Dsymbols

    this();
    void push(Dsymbol s);
    OverloadSet isOverloadSet() { return this; }
    const(char)* kind();
};
//}

// Table of Dsymbol's

extern(C++)
final class DsymbolTable : _Object
{
    AA *tab;

    this();
    ~this();

    // Look up Identifier. Return Dsymbol if found, null if not.
    Dsymbol lookup(Identifier ident);

    // Insert Dsymbol in table. Return null if already there.
    Dsymbol insert(Dsymbol s);

    // Look for Dsymbol in table. If there, return it. If not, insert s and return that.
    Dsymbol update(Dsymbol s);
    Dsymbol insert(Identifier ident, Dsymbol s);     // when ident and s are not the same
};

