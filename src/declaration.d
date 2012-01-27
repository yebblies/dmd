
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module declaration;
extern(C++):

import dsymbol;
import lexer;
import mtype;
import mars;
import expression;
import arraytypes;
import identifier;
import _scope;
import root.root;
import init;
import hdrgen;
import fakebackend;
import aggregate;
import _module;
import statement;
import interpret;
import inline;
import irstate;

enum STCundefined     = 0;
enum STCstatic        = 1;
enum STCextern        = 2;
enum STCconst         = 4;
enum STCfinal         = 8;
enum STCabstract      = 0x10;
enum STCparameter     = 0x20;
enum STCfield         = 0x40;
enum STCoverride      = 0x80;
enum STCauto          = 0x100;
enum STCsynchronized  = 0x200;
enum STCdeprecated    = 0x400;
enum STCin            = 0x800;         // in parameter
enum STCout           = 0x1000;        // out parameter
enum STClazy          = 0x2000;        // lazy parameter
enum STCforeach       = 0x4000;        // variable for foreach loop
enum STCcomdat        = 0x8000;        // should go into COMDAT record
enum STCvariadic      = 0x10000;       // variadic function argument
enum STCctorinit      = 0x20000;       // can only be set inside constructor
enum STCtemplateparameter   = 0x40000; // template parameter
enum STCscope         = 0x80000;       // template parameter
enum STCimmutable     = 0x100000;
enum STCref           = 0x200000;
enum STCinit          = 0x400000;      // has explicit initializer
enum STCmanifest      = 0x800000;      // manifest constant
enum STCnodtor        = 0x1000000;     // don't run destructor
enum STCnothrow       = 0x2000000;     // never throws exceptions
enum STCpure          = 0x4000000;     // pure function
enum STCtls           = 0x8000000;     // thread local
enum STCalias         = 0x10000000;    // alias parameter
enum STCshared        = 0x20000000;    // accessible from multiple threads
enum STCgshared       = 0x40000000;    // accessible from multiple threads
                                        // but not typed as "shared"
enum STCwild          = 0x80000000;    // for "wild" type constructor
enum STC_TYPECTOR    = (STCconst | STCimmutable | STCshared | STCwild);
enum STC_FUNCATTR    = (STCref | STCnothrow | STCpure | STCproperty | STCsafe | STCtrusted | STCsystem);

enum STCproperty      = 0x100000000;
enum STCsafe          = 0x200000000;
enum STCtrusted       = 0x400000000;
enum STCsystem        = 0x800000000;
enum STCctfe          = 0x1000000000;  // can be used in CTFE, even if it is static
enum STCdisable       = 0x2000000000;  // for functions that are not callable
enum STCresult        = 0x4000000000;  // for result variables passed to out contracts
enum STCnodefaultctor  = 0x8000000000;  // must be set inside constructor

struct Match
{
    int count;                  // number of matches found
    MATCH last;                 // match level of lastf
    FuncDeclaration lastf;     // last matching function we found
    FuncDeclaration nextf;     // current matching function
    FuncDeclaration anyf;      // pick a func, any func, to use for error recovery
};

void overloadResolveX(Match *m, FuncDeclaration f,
        Expression ethis, Expressions arguments);
int overloadApply(FuncDeclaration fstart,
        int function(void *, FuncDeclaration ) fp,
        void *param);

alias uint Semantic;
enum : Semantic
{
    SemanticStart,      // semantic has not been run
    SemanticIn,         // semantic() is in progress
    SemanticDone,       // semantic() has been run
    Semantic2Done,      // semantic2() has been run
};

/**************************************************************/

class Declaration : Dsymbol
{
    Type type;
    Type originalType;         // before semantic analysis
    StorageClass storage_class;
    PROT protection;
    LINK linkage;
    int inuse;                  // used to detect cycles

    Semantic sem;

    this(Identifier id);
    void semantic(Scope *sc);
    const(char)* kind();
    uint size(Loc loc);
    final void checkModify(Loc loc, Scope *sc, Type t);

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toDocBuffer(OutBuffer buf);

    char *mangle();
    final int isStatic();
    final int isDelete();
    int isDataseg();
    int isThreadlocal();
    int isCodeseg();
    final int isCtorinit();
    abstract int isFinal();
    final int isAbstract();
    final int isConst();
    final int isImmutable();
    final int isWild();
    final int isAuto();
    final int isScope();
    final int isSynchronized();
    final int isParameter();
    final int isDeprecated();
    final int isOverride();
    final StorageClass isResult();

    final int isIn();
    final int isOut();
    final int isRef();

    final PROT prot();

    Declaration isDeclaration();
};

/**************************************************************/

class TupleDeclaration : Declaration
{
    Objects objects;
    int isexp;                  // 1: expression tuple

    TypeTuple tupletype;       // !=NULL if this is a type tuple

    this(Loc loc, Identifier ident, Objects objects);
    Dsymbol syntaxCopy(Dsymbol );
    const(char)* kind();
    Type getType();
    int needThis();

    TupleDeclaration isTupleDeclaration();
};

/**************************************************************/

class TypedefDeclaration : Declaration
{
    Type basetype;
    Initializer init;

    this(Loc loc, Identifier ident, Type basetype, Initializer init);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    char *mangle();
    const(char)* kind();
    Type getType();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Type htype;
    Type hbasetype;

    void toDocBuffer(OutBuffer buf);

    void toObjFile(int multiobj);                       // compile to .obj file
    final void toDebug();
    int cvMember(ubyte *p);

    TypedefDeclaration isTypedefDeclaration();

    Symbol *sinit;
    final Symbol *toInitializer();
};

/**************************************************************/

class AliasDeclaration : Declaration
{
    Dsymbol aliassym;
    Dsymbol overnext;          // next in overload list
    int inSemantic;

    this(Loc loc, Identifier ident, Type type);
    this(Loc loc, Identifier ident, Dsymbol s);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    int overloadInsert(Dsymbol s);
    const(char)* kind();
    Type getType();
    Dsymbol toAlias();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Type htype;
    Dsymbol haliassym;

    void toDocBuffer(OutBuffer buf);

    AliasDeclaration isAliasDeclaration();
};

/**************************************************************/

class VarDeclaration : Declaration
{
    Initializer init;
    uint offset;
    int noscope;                 // no auto semantics
version (DMDV2) {
    FuncDeclarations nestedrefs; // referenced by these lexically nested functions
    bool isargptr;              // if parameter that _argptr points to
} else {
    int nestedref;              // referenced by a lexically nested function
}
    int ctorinit;               // it has been initialized in a ctor
    int onstack;                // 1: it has been allocated on the stack
                                // 2: on stack, run destructor anyway
    int canassign;              // it can be assigned to
    Dsymbol aliassym;          // if redone as alias to another symbol

    // When interpreting, these point to the value (NULL if value not determinable)
    // The index of this variable on the CTFE stack, -1 if not allocated
    size_t ctfeAdrOnStack;
    // The various functions are used only to detect compiler CTFE bugs
    final Expression getValue();
    final bool hasValue();
    final void setValueNull();
    final void setValueWithoutChecking(Expression newval);
    final void setValue(Expression newval);

version (DMDV2) {
    VarDeclaration rundtor;    // if !NULL, rundtor is tested at runtime to see
                                // if the destructor should be run. Used to prevent
                                // dtor calls on postblitted vars
    Expression edtor;          // if !=NULL, does the destruction of the variable
}

    this(Loc loc, Type t, Identifier id, Initializer init);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    const(char)* kind();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Type htype;
    Initializer hinit;
    AggregateDeclaration isThis();
    int needThis();
    int isImportedSymbol();
    int isDataseg();
    int isThreadlocal();
    final int isCTFE();
    int hasPointers();
version (DMDV2) {
    final int canTakeAddressOf();
    final int needsAutoDtor();
}
    final Expression callScopeDtor(Scope *sc);
    final ExpInitializer getExpInitializer();
    final Expression getConstInitializer();
    final void checkCtorConstInit();
    final void checkNestedReference(Scope *sc, Loc loc);
    Dsymbol toAlias();

    Symbol *toSymbol();
    void toObjFile(int multiobj);                       // compile to .obj file
    int cvMember(ubyte *p);

    // Eliminate need for dynamic_cast
    VarDeclaration isVarDeclaration();
};

/**************************************************************/

// This is a shell around a back end symbol

class SymbolDeclaration : Declaration
{
    Symbol *sym;
    StructDeclaration dsym;

    this(Loc loc, Symbol *s, StructDeclaration dsym);

    Symbol *toSymbol();

    // Eliminate need for dynamic_cast
    SymbolDeclaration isSymbolDeclaration();
};

class ClassInfoDeclaration : VarDeclaration
{
    ClassDeclaration cd;

    this(ClassDeclaration cd);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);

    Symbol *toSymbol();
};

class ModuleInfoDeclaration : VarDeclaration
{
    Module mod;

    this(Module mod);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);

    Symbol *toSymbol();
};

class TypeInfoDeclaration : VarDeclaration
{
    Type tinfo;

    this(Type tinfo, int internal);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);

    Symbol *toSymbol();
    void toObjFile(int multiobj);                       // compile to .obj file
    void toDt(dt_t **pdt);
};

class TypeInfoStructDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoClassDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);
    Symbol *toSymbol();

    void toDt(dt_t **pdt);
};

class TypeInfoInterfaceDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoTypedefDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoPointerDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoArrayDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoStaticArrayDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoAssociativeArrayDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoEnumDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoFunctionDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoDelegateDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoTupleDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

version (DMDV2) {
class TypeInfoConstDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoInvariantDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoSharedDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoWildDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};

class TypeInfoVectorDeclaration : TypeInfoDeclaration
{
    this(Type tinfo);

    void toDt(dt_t **pdt);
};
}

/**************************************************************/

class ThisDeclaration : VarDeclaration
{
    this(Loc loc, Type t);
    Dsymbol syntaxCopy(Dsymbol );
    ThisDeclaration isThisDeclaration();
};

alias uint ILS;
enum : ILS
{
    ILSuninitialized,   // not computed yet
    ILSno,              // cannot inline
    ILSyes,             // can inline
};

/**************************************************************/
version (DMDV2) {

alias int BUILTIN;
enum : BUILTIN
{
    BUILTINunknown = -1,        // not known if this is a builtin
    BUILTINnot,                 // this is not a builtin
    BUILTINsin,                 // std.math.sin
    BUILTINcos,                 // std.math.cos
    BUILTINtan,                 // std.math.tan
    BUILTINsqrt,                // std.math.sqrt
    BUILTINfabs,                // std.math.fabs
    BUILTINatan2,               // std.math.atan2
    BUILTINrndtol,              // std.math.rndtol
    BUILTINexpm1,               // std.math.expm1
    BUILTINexp2,                // std.math.exp2
    BUILTINyl2x,                // std.math.yl2x
    BUILTINyl2xp1,              // std.math.yl2xp1
    BUILTINbsr,                 // core.bitop.bsr
    BUILTINbsf,                 // core.bitop.bsf
    BUILTINbswap,               // core.bitop.bswap
};

Expression eval_builtin(Loc loc, BUILTIN builtin, Expressions arguments);

} else {
enum BUILTIN { };
}

class FuncDeclaration : Declaration
{
    Types fthrows;                     // Array of Type's of exceptions (not used)
    Statement frequire;
    Statement fensure;
    Statement fbody;

    FuncDeclarations foverrides;        // functions this function overrides
    FuncDeclaration fdrequire;         // function that does the in contract
    FuncDeclaration fdensure;          // function that does the out contract

    Identifier outId;                  // identifier for out statement
    VarDeclaration vresult;            // variable corresponding to outId
    LabelDsymbol returnLabel;          // where the return goes

    DsymbolTable localsymtab;          // used to prevent symbols in different
                                        // scopes from having the same name
    VarDeclaration vthis;              // 'this' parameter (member and nested)
    VarDeclaration v_arguments;        // '_arguments' parameter
version (IN_GCC) {
    VarDeclaration v_argptr;           // '_argptr' variable
}
    VarDeclaration v_argsave;          // save area for args passed in registers for variadic functions
    VarDeclarations parameters;        // Array of VarDeclaration's for parameters
    DsymbolTable labtab;               // statement label symbol table
    Declaration overnext;              // next in overload list
    Loc endloc;                         // location of closing curly bracket
    int vtblIndex;                      // for member functions, index into vtbl[]
    int naked;                          // !=0 if naked
    ILS inlineStatusStmt;
    ILS inlineStatusExp;
    int inlineNest;                     // !=0 if nested inline
    int isArrayOp;                      // !=0 if array operation
    PASS semanticRun;
    int semantic3Errors;                // !=0 if errors in semantic3
                                        // this function's frame ptr
    ForeachStatement fes;              // if foreach body, this is the foreach
    int introducing;                    // !=0 if 'introducing' function
    Type tintro;                       // if !=NULL, then this is the type
                                        // of the 'introducing' function
                                        // this one is overriding
    int inferRetType;                   // !=0 if return type is to be inferred
    StorageClass storage_class2;        // storage class for template onemember's

    // Things that should really go into Scope
    int hasReturnExp;                   // 1 if there's a return exp; statement
                                        // 2 if there's a throw statement
                                        // 4 if there's an assert(0)
                                        // 8 if there's inline asm

    // Support for NRVO (named return value optimization)
    int nrvo_can;                       // !=0 means we can do it
    VarDeclaration nrvo_var;           // variable to replace with shidden
    Symbol *shidden;                    // hidden pointer passed to function

version (DMDV2) {
    BUILTIN builtin;               // set if this is a known, builtin
                                        // function we can evaluate at compile
                                        // time

    int tookAddressOf;                  // set if someone took the address of
                                        // this function
    VarDeclarations closureVars;        // local variables in this function
                                        // which are referenced by nested
                                        // functions

    uint flags;
    enum FUNCFLAGpurityInprocess = 1;   // working on determining purity
    enum FUNCFLAGsafetyInprocess = 2;   // working on determining safety
    enum FUNCFLAGnothrowInprocess = 4;  // working on determining nothrow

    int forceNonVirtual;
} else {
    int nestedFrameRef;                 // !=0 if nested variables referenced
}

    this(Loc loc, Loc endloc, Identifier id, StorageClass storage_class, Type type);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    // called from semantic3
    final void varArgs(Scope *sc, TypeFunction, ref VarDeclaration , ref VarDeclaration );
    final VarDeclaration declareThis(Scope *sc, AggregateDeclaration ad);
    int equals(_Object o);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    final void bodyToCBuffer(OutBuffer buf, HdrGenState *hgs);
    final int overrides(FuncDeclaration fd);
    final int findVtblIndex(Dsymbols vtbl, int dim);
    int overloadInsert(Dsymbol s);
    final FuncDeclaration overloadExactMatch(Type t);
    final FuncDeclaration overloadResolve(Loc loc, Expression ethis, Expressions arguments, int flags = 0);
    final MATCH leastAsSpecialized(FuncDeclaration g);
    final LabelDsymbol searchLabel(Identifier ident);
    AggregateDeclaration isThis();
    final AggregateDeclaration isMember2();
    final int getLevel(Loc loc, FuncDeclaration fd); // lexical nesting level difference
    final void appendExp(Expression e);
    final void appendState(Statement s);
    char *mangle();
    const(char)* toPrettyChars();
    final int isMain();
    final int isWinMain();
    final int isDllMain();
    final BUILTIN isBuiltin();
    int isExport();
    int isImportedSymbol();
    final int isAbstract();
    int isCodeseg();
    int isOverloadable();
    final PURE isPure();
    final PURE isPureBypassingInference();
    final bool setImpure();
    final int isSafe();
    final int isTrusted();
    final bool setUnsafe();
    int isNested();
    int needThis();
    final int isVirtualMethod();
    int isVirtual();
    int isFinal();
    int addPreInvariant();
    int addPostInvariant();
    final Expression interpret(InterState istate, Expressions arguments, Expression thisexp = null);
    void inlineScan();
    final int canInline(int hasthis, int hdrscan, int statementsToo);
    final Expression expandInline(InlineScanState iss, Expression ethis, Expressions arguments, Statement *ps);
    const(char)* kind();
    void toDocBuffer(OutBuffer buf);
    final FuncDeclaration isUnique();
    final void checkNestedReference(Scope *sc, Loc loc);
    final int needsClosure();
    final Statement mergeFrequire(Statement );
    final Statement mergeFensure(Statement );
    final Parameters getParameters(int *pvarargs);

    static FuncDeclaration genCfunc(Type treturn, const(char)* name);
    static FuncDeclaration genCfunc(Type treturn, Identifier id);

    Symbol *toSymbol();
    final Symbol *toThunkSymbol(int offset);  // thunk version
    void toObjFile(int multiobj);                       // compile to .obj file
    int cvMember(ubyte *p);
    final void buildClosure(IRState *irs);

    FuncDeclaration isFuncDeclaration();
};

version (DMDV2) {
FuncDeclaration resolveFuncCall(Scope *sc, Loc loc, Dsymbol s,
        Objects tiargs,
        Expression ethis,
        Expressions arguments,
        int flags);
}

class FuncAliasDeclaration : FuncDeclaration
{
    FuncDeclaration funcalias;

    this(FuncDeclaration funcalias);

    FuncAliasDeclaration isFuncAliasDeclaration();
    const(char)* kind();
    Symbol *toSymbol();
};

class FuncLiteralDeclaration : FuncDeclaration
{
    TOK tok;                       // TOKfunction or TOKdelegate

    this(Loc loc, Loc endloc, Type type, TOK tok,
        ForeachStatement fes);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Dsymbol syntaxCopy(Dsymbol );
    int isNested();
    int isVirtual();

    FuncLiteralDeclaration isFuncLiteralDeclaration();
    const(char)* kind();
};

final class CtorDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc, StorageClass stc, Type type);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    const(char)* kind();
    char *toChars();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();

    CtorDeclaration isCtorDeclaration();
};

version (DMDV2) {
final class PostBlitDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc, StorageClass stc = STCundefined);
    this(Loc loc, Loc endloc, Identifier id);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    int overloadInsert(Dsymbol s);
    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);

    PostBlitDeclaration isPostBlitDeclaration();
};
}

final class DtorDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc);
    this(Loc loc, Loc endloc, Identifier id);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char)* kind();
    char *toChars();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    int overloadInsert(Dsymbol s);
    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);

    DtorDeclaration isDtorDeclaration();
};

class StaticCtorDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc);
    this(Loc loc, Loc endloc, const(char)* name);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    AggregateDeclaration isThis();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    bool hasStaticCtorOrDtor();
    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    StaticCtorDeclaration isStaticCtorDeclaration();
};

version (DMDV2) {
final class SharedStaticCtorDeclaration : StaticCtorDeclaration
{
    this(Loc loc, Loc endloc);
    Dsymbol syntaxCopy(Dsymbol );
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration();
};
}

class StaticDtorDeclaration : FuncDeclaration
{   VarDeclaration vgate;      // 'gate' variable

    this(Loc loc, Loc endloc);
    this(Loc loc, Loc endloc, const(char)* name);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    AggregateDeclaration isThis();
    final int isVirtual();
    bool hasStaticCtorOrDtor();
    int addPreInvariant();
    int addPostInvariant();
    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    StaticDtorDeclaration isStaticDtorDeclaration();
};

version (DMDV2) {
final class SharedStaticDtorDeclaration : StaticDtorDeclaration
{
    this(Loc loc, Loc endloc);
    Dsymbol syntaxCopy(Dsymbol );
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration();
};
}

final class InvariantDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer buf);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    InvariantDeclaration isInvariantDeclaration();
};

final class UnitTestDeclaration : FuncDeclaration
{
    this(Loc loc, Loc endloc);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    AggregateDeclaration isThis();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toJsonBuffer(OutBuffer buf);

    UnitTestDeclaration isUnitTestDeclaration();
};

final class NewDeclaration : FuncDeclaration
{   Parameters arguments;
    int varargs;

    this(Loc loc, Loc endloc, Parameters arguments, int varargs);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char)* kind();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();

    NewDeclaration isNewDeclaration();
};


final class DeleteDeclaration : FuncDeclaration
{   Parameters arguments;

    this(Loc loc, Loc endloc, Parameters arguments);
    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    const(char)* kind();
    int isDelete();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    DeleteDeclaration isDeleteDeclaration();
};

