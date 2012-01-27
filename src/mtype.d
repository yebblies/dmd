
// Compiler implementation of the D programming language
// Copyright (c) 1999-2010 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module mtype;
extern(C++):

import root.root;
import root.stringtable;

import declaration;
import aggregate;
import _template;
import mars;
import _scope;
import identifier;
import hdrgen;
import dsymbol;
import expression;
import arraytypes;
import _enum;
import cppmangle;

import fakebackend;

alias ubyte ENUMTY;
enum : ENUMTY
{
    Tarray,             // slice array, aka T[]
    Tsarray,            // static array, aka T[dimension]
    Taarray,            // associative array, aka T[type]
    Tpointer,
    Treference,
    Tfunction,
    Tident,
    Tclass,
    Tstruct,
    Tenum,

    Ttypedef,
    Tdelegate,
    Tnone,
    Tvoid,
    Tint8,
    Tuns8,
    Tint16,
    Tuns16,
    Tint32,
    Tuns32,

    Tint64,
    Tuns64,
    Tfloat32,
    Tfloat64,
    Tfloat80,
    Timaginary32,
    Timaginary64,
    Timaginary80,
    Tcomplex32,
    Tcomplex64,

    Tcomplex80,
    Tbool,
    Tchar,
    Twchar,
    Tdchar,
    Terror,
    Tinstance,
    Ttypeof,
    Ttuple,
    Tslice,

    Treturn,
    Tnull,
    Tvector,
    TMAX
};
alias ubyte TY;       // ENUMTY

enum Tascii = Tchar;


class Type : _Object
{
    TY ty;
    ubyte mod;  // modifiers MODxxxx
        /* pick this order of numbers so switch statements work better
         */
        enum MODconst     = 1;  // type is const
        enum MODimmutable = 4;  // type is immutable
        enum MODshared    = 2;  // type is shared
        enum MODwild      = 8;  // type is wild
        enum MODmutable   = 0x10;       // type is mutable (only used in wildcard matching)
    char *deco;

    /* These are cached values that are lazily evaluated by constOf(), invariantOf(), etc.
     * They should not be referenced by anybody but mtype.c.
     * They can be NULL if not lazily evaluated yet.
     * Note that there is no "shared immutable", because that is just immutable
     * Naked == no MOD bits
     */

    Type cto;          // MODconst ? naked version of this type : const version
    Type ito;          // MODimmutable ? naked version of this type : immutable version
    Type sto;          // MODshared ? naked version of this type : shared mutable version
    Type scto;         // MODshared|MODconst ? naked version of this type : shared const version
    Type wto;          // MODwild ? naked version of this type : wild version
    Type swto;         // MODshared|MODwild ? naked version of this type : shared wild version

    Type pto;          // merged pointer to this type
    Type rto;          // reference to this type
    Type arrayof;      // array of this type
    TypeInfoDeclaration vtinfo;        // TypeInfo object for this Type

    type *ctype;        // for back end

    static ref tvoid() { return basic[Tvoid]; }
    static ref tint8() { return basic[Tint8]; }
    static ref tuns8() { return basic[Tuns8]; }
    static ref tint16() { return basic[Tint16]; }
    static ref tuns16() { return basic[Tuns16]; }
    static ref tint32() { return basic[Tint32]; }
    static ref tuns32() { return basic[Tuns32]; }
    static ref tint64() { return basic[Tint64]; }
    static ref tuns64() { return basic[Tuns64]; }
    static ref tfloat32() { return basic[Tfloat32]; }
    static ref tfloat64() { return basic[Tfloat64]; }
    static ref tfloat80() { return basic[Tfloat80]; }

    static ref timaginary32() { return basic[Timaginary32]; }
    static ref timaginary64() { return basic[Timaginary64]; }
    static ref timaginary80() { return basic[Timaginary80]; }

    static ref tcomplex32() { return basic[Tcomplex32]; }
    static ref tcomplex64() { return basic[Tcomplex64]; }
    static ref tcomplex80() { return basic[Tcomplex80]; }

    static ref tbool() { return basic[Tbool]; }
    static ref tchar() { return basic[Tchar]; }
    static ref twchar() { return basic[Twchar]; }
    static ref tdchar() { return basic[Tdchar]; }

    // Some special types
    alias tint32 tshiftcnt;         // right side of shift expression
//    alias tint32 tboolean;          // result of boolean expression
    alias tbool tboolean;               // result of boolean expression
    alias tsize_t tindex;         // array/ptr index
    static extern Type tvoidptr;              // void*
    static extern Type tstring;               // immutable(char)[]
    static ref terror() { return basic[Terror]; }   // for error recovery

    static ref tnull() { return basic[Tnull]; }    // for null type

    static ref tsize_t() { return basic[Tsize_t]; }          // matches size_t alias
    static ref tptrdiff_t() { return basic[Tptrdiff_t]; }       // matches ptrdiff_t alias
    alias tsize_t thash_t;                 // matches hash_t alias

    static extern ClassDeclaration typeinfo;
    static extern ClassDeclaration typeinfoclass;
    static extern ClassDeclaration typeinfointerface;
    static extern ClassDeclaration typeinfostruct;
    static extern ClassDeclaration typeinfotypedef;
    static extern ClassDeclaration typeinfopointer;
    static extern ClassDeclaration typeinfoarray;
    static extern ClassDeclaration typeinfostaticarray;
    static extern ClassDeclaration typeinfoassociativearray;
    static extern ClassDeclaration typeinfovector;
    static extern ClassDeclaration typeinfoenum;
    static extern ClassDeclaration typeinfofunction;
    static extern ClassDeclaration typeinfodelegate;
    static extern ClassDeclaration typeinfotypelist;
    static extern ClassDeclaration typeinfoconst;
    static extern ClassDeclaration typeinfoinvariant;
    static extern ClassDeclaration typeinfoshared;
    static extern ClassDeclaration typeinfowild;

    static extern TemplateDeclaration associativearray;

    static extern Type basic[TMAX];
    static extern ubyte mangleChar[TMAX];
    static extern ubyte sizeTy[TMAX];
    static extern StringTable stringtable;

    // These tables are for implicit conversion of binary ops;
    // the indices are the type of operand one, followed by operand two.
    static extern ubyte impcnvResult[TMAX][TMAX];
    static extern ubyte impcnvType1[TMAX][TMAX];
    static extern ubyte impcnvType2[TMAX][TMAX];

    // If !=0, give warning on implicit conversion
    static extern ubyte impcnvWarn[TMAX][TMAX];

    this(TY ty);
    Type syntaxCopy();
    int equals(_Object o);
    int dyncast(); // kludge for template.isType()
    final int covariant(Type t);
    char *toChars();
    static char needThisPrefix();
    static void init();
    final d_uns64 size();
    d_uns64 size(Loc loc);
    uint alignsize();
    Type semantic(Loc loc, Scope *sc);
    final Type trySemantic(Loc loc, Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag = 0);
    final Type merge();
    final Type merge2();
    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState *hgs);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    final void toCBuffer3(OutBuffer buf, HdrGenState *hgs, int mod);
    final void modToBuffer(OutBuffer buf);
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}
    int isintegral();
    int isfloating();   // real, imaginary, or complex
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    int isscope();
    int isString();
    int isAssignable();
    int checkBoolean(); // if can be converted to boolean value
    void checkDeprecated(Loc loc, Scope *sc);
    int isConst()       { return mod & MODconst; }
    int isImmutable()   { return mod & MODimmutable; }
    int isMutable()     { return !(mod & (MODconst | MODimmutable | MODwild)); }
    int isShared()      { return mod & MODshared; }
    int isSharedConst() { return mod == (MODshared | MODconst); }
    int isWild()        { return mod & MODwild; }
    int isSharedWild()  { return mod == (MODshared | MODwild); }
    int isNaked()       { return mod == 0; }
    final Type constOf();
    final Type invariantOf();
    final Type mutableOf();
    final Type sharedOf();
    final Type sharedConstOf();
    final Type unSharedOf();
    final Type wildOf();
    final Type sharedWildOf();
    final void fixTo(Type t);
    final void check();
    final Type addSTC(StorageClass stc);
    final Type castMod(uint mod);
    final Type addMod(uint mod);
    final Type addStorageClass(StorageClass stc);
    final Type pointerTo();
    final Type referenceTo();
    final Type arrayOf();
    final Type aliasthisOf();
    Type makeConst();
    Type makeInvariant();
    Type makeShared();
    Type makeSharedConst();
    Type makeWild();
    Type makeSharedWild();
    Type makeMutable();
    Dsymbol toDsymbol(Scope *sc);
    Type toBasetype();
    int isBaseOf(Type t, int *poffset);
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    uint wildConvTo(Type tprm);
    final Type substWildTo(uint mod);
    Type toHeadMutable();
    ClassDeclaration isClassHandle();
    Expression getProperty(Loc loc, Identifier ident);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    final Expression noMember(Scope *sc, Expression e, Identifier ident);
    uint memalign(uint salign);
    Expression defaultInit(Loc loc);
    Expression defaultInitLiteral(Loc loc);
    int isZeroInit(Loc loc);                // if initializer is 0
    dt_t **toDt(dt_t **pdt);
    final Identifier getTypeInfoIdent(int internal);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    final Expression getInternalTypeInfo(Scope *sc);
    final Expression getTypeInfo(Scope *sc);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int builtinTypeInfo();
    Type reliesOnTident();
    int hasWild();
    Expression toExpression();
    int hasPointers();
    TypeTuple toArgTypes();
    Type nextOf();
    final uinteger_t sizemask();
    int needsDestruction();

    static void error(Loc loc, const(char)* format, ...);
    static void warning(Loc loc, const(char)* format, ...);

    // For backend
    final uint totym();
    type *toCtype();
    type *toCParamtype();
    Symbol *toSymbol();

    // For eliminating dynamic_cast
    TypeBasic isTypeBasic();
};

class TypeError : Type
{
    this();
    Type syntaxCopy();

    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState *hgs);

    d_uns64 size(Loc loc);
    Expression getProperty(Loc loc, Identifier ident);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression defaultInit(Loc loc);
    Expression defaultInitLiteral(Loc loc);
};

class TypeNext : Type
{
    Type next;

    this(TY ty, Type next);
    void toDecoBuffer(OutBuffer buf, int flag);
    void checkDeprecated(Loc loc, Scope *sc);
    Type reliesOnTident();
    int hasWild();
    Type nextOf();
    Type makeConst();
    Type makeInvariant();
    Type makeShared();
    Type makeSharedConst();
    Type makeWild();
    Type makeSharedWild();
    Type makeMutable();
    MATCH constConv(Type to);
    uint wildConvTo(Type tprm);
    final void transitive();
};

class TypeBasic : Type
{
    const(char)* dstring;
    uint flags;

    this(TY ty);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    uint alignsize();
    Expression getProperty(Loc loc, Identifier ident);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    char *toChars();
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}
    int isintegral();
    int isfloating();
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    MATCH implicitConvTo(Type to);
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    int builtinTypeInfo();
    TypeTuple toArgTypes();

    // For eliminating dynamic_cast
    TypeBasic isTypeBasic();
};

class TypeVector : Type
{
    Type basetype;

    this(Loc loc, Type basetype);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    uint alignsize();
    Expression getProperty(Loc loc, Identifier ident);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    char *toChars();
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void toDecoBuffer(OutBuffer buf, int flag);
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}
    int isintegral();
    int isfloating();
    int isscalar();
    int isunsigned();
    int checkBoolean();
    MATCH implicitConvTo(Type to);
    Expression defaultInit(Loc loc);
    final TypeBasic elementType();
    int isZeroInit(Loc loc);
    TypeInfoDeclaration getTypeInfoDeclaration();
    TypeTuple toArgTypes();
};

class TypeArray : TypeNext
{
    this(TY ty, Type next);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
};

// Static array, one with a fixed dimension
final class TypeSArray : TypeArray
{
    Expression dim;

    this(Type t, Expression dim);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    uint alignsize();
    Type semantic(Loc loc, Scope *sc);
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    int isString();
    int isZeroInit(Loc loc);
    uint memalign(uint salign);
    MATCH constConv(Type to);
    MATCH implicitConvTo(Type to);
    Expression defaultInit(Loc loc);
    Expression defaultInitLiteral(Loc loc);
    dt_t **toDt(dt_t **pdt);
    dt_t **toDtElem(dt_t **pdt, Expression e);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    Expression toExpression();
    int hasPointers();
    int needsDestruction();
    TypeTuple toArgTypes();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
    type *toCParamtype();
};

// Dynamic array, no dimension
final class TypeDArray : TypeArray
{
    this(Type t);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    uint alignsize();
    Type semantic(Loc loc, Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    int isString();
    int isZeroInit(Loc loc);
    int checkBoolean();
    MATCH implicitConvTo(Type to);
    Expression defaultInit(Loc loc);
    int builtinTypeInfo();
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
};

final class TypeAArray : TypeArray
{
    Type index;                // key type
    Loc loc;
    Scope *sc;

    StructDeclaration impl;    // implementation

    this(Type t, Type index);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    Type semantic(Loc loc, Scope *sc);
    StructDeclaration getImpl();
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression defaultInit(Loc loc);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    int isZeroInit(Loc loc);
    int checkBoolean();
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    // Back end
    Symbol *aaGetSymbol(const(char)* func, int flags);

    type *toCtype();
};

final class TypePointer : TypeNext
{
    this(Type t);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    int isscalar();
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
};

class TypeReference : TypeNext
{
    this(Type t);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}
};

alias uint RET;
enum : RET
{
    RETregs     = 1,    // returned in registers
    RETstack    = 2,    // returned on stack
};

alias uint TRUST;
enum : TRUST
{
    TRUSTdefault = 0,
    TRUSTsystem = 1,    // @system (same as TRUSTdefault)
    TRUSTtrusted = 2,   // @trusted
    TRUSTsafe = 3,      // @safe
};

alias uint PURE;
enum : PURE
{
    PUREimpure = 0,     // not pure at all
    PUREweak = 1,       // no mutable globals are read or written
    PUREconst = 2,      // parameters are values or const
    PUREstrong = 3,     // parameters are values or immutable
    PUREfwdref = 4,     // it's pure, but not known which level yet
};

final class TypeFunction : TypeNext
{
    // .next is the return type

    Parameters parameters;     // function parameters
    int varargs;        // 1: T t, ...) style for variable number of arguments
                        // 2: T t ...) style for variable number of arguments
    bool isnothrow;     // true: nothrow
    bool isproperty;    // can be called without parentheses
    bool isref;         // true: returns a reference
    LINK linkage;  // calling convention
    TRUST trust;   // level of trust
    PURE purity;   // PURExxxx
    Expressions fargs; // function arguments

    int inuse;

    this(Parameters parameters, Type treturn, int varargs, LINK linkage, StorageClass stc = 0);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    void purityLevel();
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState *hgs);
    void toCBufferWithAttributes(OutBuffer buf, Identifier ident, HdrGenState *hgs, TypeFunction attrs, TemplateDeclaration td);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void attributesToCBuffer(OutBuffer buf, int mod);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    Type reliesOnTident();
    bool hasLazyParameters();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}
    bool parameterEscapes(Parameter p);

    int callMatch(Expression ethis, Expressions toargs, int flag = 0);
    type *toCtype();
    RET retStyle();

    uint totym();

    Expression defaultInit(Loc loc);
};

final class TypeDelegate : TypeNext
{
    // .next is a TypeFunction

    this(Type t);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    uint alignsize();
    MATCH implicitConvTo(Type to);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    int checkBoolean();
    TypeInfoDeclaration getTypeInfoDeclaration();
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    int hasPointers();
    TypeTuple toArgTypes();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
};

class TypeQualified : Type
{
    Loc loc;
    Identifiers idents;       // array of Identifier's representing ident.ident.ident etc.

    this(TY ty, Loc loc);
    final void syntaxCopyHelper(TypeQualified t);
    final void addIdent(Identifier ident);
    final void toCBuffer2Helper(OutBuffer buf, HdrGenState *hgs);
    d_uns64 size(Loc loc);
    final void resolveHelper(Loc loc, Scope *sc, Dsymbol s, Dsymbol scopesym,
        Expression *pe, Type *pt, Dsymbol *ps);
};

class TypeIdentifier : TypeQualified
{
    Identifier ident;

    this(Loc loc, Identifier ident);
    Type syntaxCopy();
    //char *toChars();
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    Dsymbol toDsymbol(Scope *sc);
    Type semantic(Loc loc, Scope *sc);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    Type reliesOnTident();
    Expression toExpression();
};

/* Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
class TypeInstance : TypeQualified
{
    TemplateInstance tempinst;

    this(Loc loc, TemplateInstance tempinst);
    Type syntaxCopy();
    //char *toChars();
    //void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    Type semantic(Loc loc, Scope *sc);
    Dsymbol toDsymbol(Scope *sc);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
};

class TypeTypeof : TypeQualified
{
    Expression exp;
    int inuse;

    this(Loc loc, Expression exp);
    Type syntaxCopy();
    Dsymbol toDsymbol(Scope *sc);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Type semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
};

class TypeReturn : TypeQualified
{
    this(Loc loc);
    Type syntaxCopy();
    Dsymbol toDsymbol(Scope *sc);
    Type semantic(Loc loc, Scope *sc);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
};

class TypeStruct : Type
{
    StructDeclaration sym;

    this(StructDeclaration sym);
    d_uns64 size(Loc loc);
    uint alignsize();
    char *toChars();
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    Dsymbol toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    uint memalign(uint salign);
    Expression defaultInit(Loc loc);
    Expression defaultInitLiteral(Loc loc);
    int isZeroInit(Loc loc);
    int isAssignable();
    int checkBoolean();
    int needsDestruction();
    dt_t **toDt(dt_t **pdt);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    uint wildConvTo(Type tprm);
    Type toHeadMutable();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    final type *toCtype();
};

class TypeEnum : Type
{
    EnumDeclaration sym;

    this(EnumDeclaration sym);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    uint alignsize();
    char *toChars();
    Type semantic(Loc loc, Scope *sc);
    Dsymbol toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression getProperty(Loc loc, Identifier ident);
    int isintegral();
    int isfloating();
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    int checkBoolean();
    int isAssignable();
    int needsDestruction();
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    Type toBasetype();
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
};

final class TypeTypedef : Type
{
    TypedefDeclaration sym;

    this(TypedefDeclaration sym);
    Type syntaxCopy();
    d_uns64 size(Loc loc);
    uint alignsize();
    char *toChars();
    Type semantic(Loc loc, Scope *sc);
    Dsymbol toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression getProperty(Loc loc, Identifier ident);
    int isintegral();
    int isfloating();
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    int checkBoolean();
    int isAssignable();
    int needsDestruction();
    Type toBasetype();
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    Type toHeadMutable();
    Expression defaultInit(Loc loc);
    Expression defaultInitLiteral(Loc loc);
    int isZeroInit(Loc loc);
    dt_t **toDt(dt_t **pdt);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
    int hasWild();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();
    type *toCParamtype();
};

class TypeClass : Type
{
    ClassDeclaration sym;

    this(ClassDeclaration sym);
    d_uns64 size(Loc loc);
    char *toChars();
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    Dsymbol toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer buf, int flag);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    Expression dotExp(Scope *sc, Expression e, Identifier ident);
    ClassDeclaration isClassHandle();
    int isBaseOf(Type t, int *poffset);
    MATCH implicitConvTo(Type to);
    MATCH constConv(Type to);
    uint wildConvTo(Type tprm);
    Type toHeadMutable();
    Expression defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    MATCH deduceType(Scope *sc, Type tparam, TemplateParameters parameters, Objects dedtypes, uint *wildmatch = null);
    int isscope();
    int checkBoolean();
    TypeInfoDeclaration getTypeInfoDeclaration();
    int hasPointers();
    TypeTuple toArgTypes();
    int builtinTypeInfo();
static if (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState *cms);
}

    type *toCtype();

    Symbol *toSymbol();
};

class TypeTuple : Type
{
    Parameters arguments;      // types making up the tuple

    this(Parameters arguments);
    this(Expressions exps);
    this();
    this(Type t1);
    this(Type t1, Type t2);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    int equals(_Object o);
    Type reliesOnTident();
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
    void toDecoBuffer(OutBuffer buf, int flag);
    Expression getProperty(Loc loc, Identifier ident);
    TypeInfoDeclaration getTypeInfoDeclaration();
};

class TypeSlice : TypeNext
{
    Expression lwr;
    Expression upr;

    this(Type next, Expression lwr, Expression upr);
    Type syntaxCopy();
    Type semantic(Loc loc, Scope *sc);
    void resolve(Loc loc, Scope *sc, Expression *pe, Type *pt, Dsymbol *ps);
    void toCBuffer2(OutBuffer buf, HdrGenState *hgs, int mod);
};

class TypeNull : Type
{
    this();

    Type syntaxCopy();
    void toDecoBuffer(OutBuffer buf, int flag);
    MATCH implicitConvTo(Type to);

    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState *hgs);

    d_uns64 size(Loc loc);
    //Expression getProperty(Loc loc, Identifier ident);
    //Expression dotExp(Scope *sc, Expression e, Identifier ident);
    Expression defaultInit(Loc loc);
    //Expression defaultInitLiteral(Loc loc);
};

/**************************************************************/

//enum InOut { None, In, Out, InOut, Lazy };

final class Parameter : _Object
{
    //enum InOut inout;
    StorageClass storageClass;
    Type type;
    Identifier ident;
    Expression defaultArg;

    this(StorageClass storageClass, Type type, Identifier ident, Expression defaultArg);
    Parameter syntaxCopy();
    Type isLazyArray();
    void toDecoBuffer(OutBuffer buf);
    static Parameters arraySyntaxCopy(Parameters args);
    static char *argsTypesToChars(Parameters args, int varargs);
    static void argsCppMangle(OutBuffer buf, CppMangleState *cms, Parameters arguments, int varargs);
    static void argsToCBuffer(OutBuffer buf, HdrGenState *hgs, Parameters arguments, int varargs);
    static void argsToDecoBuffer(OutBuffer buf, Parameters arguments);
    static int isTPL(Parameters arguments);
    static size_t dim(Parameters arguments);
    static Parameter getNth(Parameters arguments, size_t nth, size_t *pn = null);

    alias int function(void *ctx, size_t paramidx, Parameter param) ForeachDg;
    static int _foreach(Parameters args, ForeachDg dg, void *ctx, size_t *pn=null);
};

extern int PTRSIZE;
extern int REALSIZE;
extern int REALPAD;
extern int Tsize_t;
extern int Tptrdiff_t;

int arrayTypeCompatible(Loc loc, Type t1, Type t2);
int arrayTypeCompatibleWithoutCasting(Loc loc, Type t1, Type t2);
void MODtoBuffer(OutBuffer buf, ubyte mod);
int MODimplicitConv(ubyte modfrom, ubyte modto);
int MODmerge(ubyte mod1, ubyte mod2);

