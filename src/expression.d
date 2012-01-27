
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module expression;
extern(C++):

import root.root;

import _scope;
import mars;
import declaration;
import dsymbol;
import identifier;
import arraytypes;
import hdrgen;
import mtype;
import interpret;
import fakebackend;
import lexer;
import inline;
import _template;
import intrange;
import aggregate;
import irstate;

void initPrecedence();

alias int function(Expression , void *) apply_fp_t;

Expression resolveProperties(Scope *sc, Expression e);
void accessCheck(Loc loc, Scope *sc, Expression e, Declaration d);
Expression build_overload(Loc loc, Scope *sc, Expression ethis, Expression earg, Dsymbol d);
Dsymbol search_function(ScopeDsymbol ad, Identifier funcid);
void argExpTypesToCBuffer(OutBuffer buf, Expressions arguments, HdrGenState *hgs);
void argsToCBuffer(OutBuffer buf, Expressions arguments, HdrGenState *hgs);
void expandTuples(Expressions exps);
TupleDeclaration isAliasThisTuple(Expression e);
int expandAliasThisTuples(Expressions exps, int starti = 0);
FuncDeclaration hasThis(Scope *sc);
Expression fromConstInitializer(int result, Expression e);
int arrayExpressionCanThrow(Expressions exps, bool mustNotThrow);
TemplateDeclaration getFuncTemplateDecl(Dsymbol s);
void valueNoDtor(Expression e);
void modifyFieldVar(Loc loc, Scope *sc, VarDeclaration var, Expression e1);


/* Interpreter: what form of return value expression is required?
 */
enum CtfeGoal
{   ctfeNeedRvalue,   // Must return an Rvalue
    ctfeNeedLvalue,   // Must return an Lvalue
    ctfeNeedAnyValue, // Can return either an Rvalue or an Lvalue
    ctfeNeedLvalueRef,// Must return a reference to an Lvalue (for ref types)
    ctfeNeedNothing   // The return value is not required
};
alias CtfeGoal.ctfeNeedRvalue ctfeNeedRvalue;
alias CtfeGoal.ctfeNeedLvalue ctfeNeedLvalue;
alias CtfeGoal.ctfeNeedAnyValue ctfeNeedAnyValue;
alias CtfeGoal.ctfeNeedLvalueRef ctfeNeedLvalueRef;
alias CtfeGoal.ctfeNeedNothing ctfeNeedNothing;

class Expression : _Object
{
    Loc loc;                    // file location
    TOK op;                // handy to minimize use of dynamic_cast
    Type type;                 // !=NULL means that semantic() has been run
    ubyte size;         // # of bytes in Expression so we can copy() it
    ubyte parens;       // if this is a parenthesized expression

    this(Loc loc, TOK op, int size);
    final Expression copy();
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    final Expression trySemantic(Scope *sc);

    int dyncast() { return DYNCAST_EXPRESSION; }        // kludge for template.isExpression()

    void print();
    char *toChars();
    void dump(int indent);
    final void error(const(char)* format, ...);
    final void warning(const(char)* format, ...);
    int rvalue();

    static Expression combine(Expression e1, Expression e2);
    static Expressions arraySyntaxCopy(Expressions exps);

    dinteger_t toInteger();
    uinteger_t toUInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    StringExp _toString();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    Expression implicitCastTo(Scope *sc, Type t);
    MATCH implicitConvTo(Type t);
    IntRange getIntRange();
    Expression castTo(Scope *sc, Type t);
    void checkEscape();
    void checkEscapeRef();
    Expression resolveLoc(Loc loc, Scope *sc);
    final void checkScalar();
    final void checkNoBool();
    final Expression checkIntegral();
    final Expression checkArithmetic();
    final void checkDeprecated(Scope *sc, Dsymbol s);
    final void checkPurity(Scope *sc, FuncDeclaration f);
    final void checkPurity(Scope *sc, VarDeclaration v, Expression e1);
    final void checkSafety(Scope *sc, FuncDeclaration f);
    Expression checkToBoolean(Scope *sc);
    Expression addDtorHook(Scope *sc);
    final Expression checkToPointer();
    final Expression addressOf(Scope *sc);
    final Expression deref();
    final Expression integralPromotions(Scope *sc);
    final Expression isTemp();

    final Expression toDelegate(Scope *sc, Type t);

    Expression optimize(int result);
    enum WANTflags = 1;
    enum WANTvalue = 2;
    // A compile-time result is required. Give an error if not possible
    enum WANTinterpret = 4;
    // Same as WANTvalue, but also expand variables as far as possible
    enum WANTexpand = 8;

    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);

    int isConst();
    int isBool(int result);
    int isBit();
    final bool hasSideEffect();
    final void discardValue();
    final void useValue();
    final int canThrow(bool mustNotThrow);

    int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
    final Expression inlineCopy(Scope *sc);

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    // For array ops
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    final int isArrayOperand();

    // Back end
    elem *toElem(IRState *irs);
    final elem *toElemDtor(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

class IntegerExp : Expression
{
    dinteger_t value;

    this(Loc loc, dinteger_t value, Type type);
    this(dinteger_t value);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    char *toChars();
    void dump(int indent);
    IntRange getIntRange();
    dinteger_t toInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    final int isConst();
    int isBool(int result);
    MATCH implicitConvTo(Type t);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    Expression toLvalue(Scope *sc, Expression e);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

final class ErrorExp : IntegerExp
{
    this();

    Expression implicitCastTo(Scope *sc, Type t);
    Expression castTo(Scope *sc, Type t);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Expression toLvalue(Scope *sc, Expression e);
};

final class RealExp : Expression
{
    real_t value;

    this(Loc loc, real_t value, Type type);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    char *toChars();
    dinteger_t toInteger();
    uinteger_t toUInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    Expression castTo(Scope *sc, Type t);
    int isConst();
    int isBool(int result);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

final class ComplexExp : Expression
{
    complex_t value;

    this(Loc loc, complex_t value, Type type);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    char *toChars();
    dinteger_t toInteger();
    uinteger_t toUInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    Expression castTo(Scope *sc, Type t);
    int isConst();
    int isBool(int result);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    OutBuffer hexp;
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

class IdentifierExp : Expression
{
    Identifier ident;
    Declaration var;

    this(Loc loc, Identifier ident);
    this(Loc loc, Declaration var);
    Expression semantic(Scope *sc);
    char *toChars();
    void dump(int indent);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
};

final class DollarExp : IdentifierExp
{
    this(Loc loc);
};

final class DsymbolExp : Expression
{
    Dsymbol s;
    int hasOverloads;

    this(Loc loc, Dsymbol s, int hasOverloads = 0);
    Expression semantic(Scope *sc);
    char *toChars();
    void dump(int indent);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
};

class ThisExp : Expression
{
    Declaration var;

    this(Loc loc);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBool(int result);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);

    int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    //Expression inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

final class SuperExp : ThisExp
{
    this(Loc loc);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Expression doInline(InlineDoState *ids);
    //Expression inlineScan(InlineScanState *iss);
};

final class NullExp : Expression
{
    ubyte committed;    // !=0 if type is committed

    this(Loc loc, Type t = null);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    int isBool(int result);
    int isConst();
    StringExp _toString();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

final class StringExp : Expression
{
    void *string;       // char, wchar, or dchar data
    size_t len;         // number of chars, wchars, or dchars
    ubyte sz;   // 1: char, 2: wchar, 4: dchar
    ubyte committed;    // !=0 if type is committed
    ubyte postfix;      // 'c', 'w', 'd'
    bool ownedByCtfe;   // true = created in CTFE

    this(Loc loc, char *s);
    this(Loc loc, void *s, size_t len);
    this(Loc loc, void *s, size_t len, ubyte postfix);
    //Expression syntaxCopy();
    int equals(_Object o);
    char *toChars();
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    size_t length();
    StringExp _toString();
    StringExp toUTF8(Scope *sc);
    Expression implicitCastTo(Scope *sc, Type t);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    int compare(_Object obj);
    int isBool(int result);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    uint charAt(size_t i);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

// Tuple

final class TupleExp : Expression
{
    Expressions exps;

    this(Loc loc, Expressions exps);
    this(Loc loc, TupleDeclaration tup);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void checkEscape();
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    Expression castTo(Scope *sc, Type t);
    elem *toElem(IRState *irs);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class ArrayLiteralExp : Expression
{
    Expressions elements;
    bool ownedByCtfe;   // true = created in CTFE

    this(Loc loc, Expressions elements);
    this(Loc loc, Expression e);

    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    int isBool(int result);
    elem *toElem(IRState *irs);
    StringExp _toString();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    dt_t **toDt(dt_t **pdt);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class AssocArrayLiteralExp : Expression
{
    Expressions keys;
    Expressions values;
    bool ownedByCtfe;   // true = created in CTFE

    this(Loc loc, Expressions keys, Expressions values);

    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    int isBool(int result);
    elem *toElem(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class StructLiteralExp : Expression
{
    StructDeclaration sd;      // which aggregate this is for
    Expressions elements;      // parallels sd->fields[] with
                                // NULL entries for fields to skip
    Type stype;                // final type of result (can be different from sd's type)

    Symbol *sym;                // back end symbol to initialize with literal
    size_t soffset;             // offset from start of s
    int fillHoles;              // fill alignment 'holes' with zero
    bool ownedByCtfe;           // true = created in CTFE

    this(Loc loc, StructDeclaration sd, Expressions elements, Type stype = null);

    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    Expression getField(Type type, uint offset);
    int getFieldIndex(Type type, uint offset);
    elem *toElem(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer buf);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    dt_t **toDt(dt_t **pdt);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    MATCH implicitConvTo(Type t);

    int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

Expression typeDotIdExp(Loc loc, Type type, Identifier ident);

final class TypeExp : Expression
{
    this(Loc loc, Type type);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    int rvalue();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Expression optimize(int result);
    elem *toElem(IRState *irs);
};

final class ScopeExp : Expression
{
    ScopeDsymbol sds;

    this(Loc loc, ScopeDsymbol sds);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    elem *toElem(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class TemplateExp : Expression
{
    TemplateDeclaration td;

    this(Loc loc, TemplateDeclaration td);
    int rvalue();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class NewExp : Expression
{
    /* thisexp.new(newargs) newtype(arguments)
     */
    Expression thisexp;        // if !NULL, 'this' for class being allocated
    Expressions newargs;       // Array of Expression's to call new operator
    Type newtype;
    Expressions arguments;     // Array of Expression's

    CtorDeclaration member;    // constructor function
    NewDeclaration allocator;  // allocator function
    int onstack;                // allocate on stack

    this(Loc loc, Expression thisexp, Expressions newargs,
        Type newtype, Expressions arguments);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    Expression optimize(int result);
    elem *toElem(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    //int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    //Expression inlineScan(InlineScanState *iss);
};

final class NewAnonClassExp : Expression
{
    /* thisexp.new(newargs) class baseclasses { } (arguments)
     */
    Expression thisexp;        // if !NULL, 'this' for class being allocated
    Expressions newargs;       // Array of Expression's to call new operator
    ClassDeclaration cd;       // class being instantiated
    Expressions arguments;     // Array of Expression's to call class constructor

    this(Loc loc, Expression thisexp, Expressions newargs,
        ClassDeclaration cd, Expressions arguments);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

//static if (DMDV2) {
class SymbolExp : Expression
{
    Declaration var;
    int hasOverloads;

    this(Loc loc, TOK op, int size, Declaration var, int hasOverloads);

    elem *toElem(IRState *irs);
};
//}

// Offset from symbol

final class SymOffExp : SymbolExp
{
    uint offset;

    this(Loc loc, Declaration var, uint offset, int hasOverloads = 0);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void checkEscape();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int isConst();
    int isBool(int result);
    Expression doInline(InlineDoState *ids);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);

    dt_t **toDt(dt_t **pdt);
};

// Variable

final class VarExp : SymbolExp
{
    this(Loc loc, Declaration var, int hasOverloads = 0);
    int equals(_Object o);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void dump(int indent);
    char *toChars();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void checkEscape();
    void checkEscapeRef();
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    dt_t **toDt(dt_t **pdt);

    Expression doInline(InlineDoState *ids);
    //Expression inlineScan(InlineScanState *iss);
};

//static if (DMDV2) {
// Overload Set

final class OverExp : Expression
{
    OverloadSet vars;

    this(OverloadSet s);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
};
//}

// Function/Delegate literal

final class FuncExp : Expression
{
    FuncLiteralDeclaration fd;
    TemplateDeclaration td;
    TOK tok;
    Type tded;
    Scope *_scope;

    this(Loc loc, FuncLiteralDeclaration fd, TemplateDeclaration td = null);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    Expression semantic(Scope *sc, Expressions arguments);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    Expression inferType(Scope *sc, Type t);
    void setType(Type t);
    char *toChars();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);

    int inlineCost3(InlineCostState *ics);
    //Expression doInline(InlineDoState *ids);
    //Expression inlineScan(InlineScanState *iss);
};

// Declaration of a symbol

final class DeclarationExp : Expression
{
    Dsymbol declaration;

    this(Loc loc, Dsymbol declaration);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);

    int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class TypeidExp : Expression
{
    _Object obj;

    this(Loc loc, _Object obj);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

//static if (DMDV2) {
final class TraitsExp : Expression
{
    Identifier ident;
    Objects args;

    this(Loc loc, Identifier ident, Objects args);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};
//}

final class HaltExp : Expression
{
    this(Loc loc);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    elem *toElem(IRState *irs);
};

final class IsExp : Expression
{
    /* is(targ id tok tspec)
     * is(targ id == tok2)
     */
    Type targ;
    Identifier id;     // can be NULL
    TOK tok;       // ':' or '=='
    Type tspec;        // can be NULL
    TOK tok2;      // 'struct', 'union', 'typedef', etc.
    TemplateParameters parameters;

    this(Loc loc, Type targ, Identifier id, TOK tok, Type tspec,
        TOK tok2, TemplateParameters parameters);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

/****************************************************************/

class UnaExp : Expression
{
    Expression e1;

    this(Loc loc, TOK op, int size, Expression e1);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Expression optimize(int result);
    void dump(int indent);
    final Expression interpretCommon(InterState *istate, CtfeGoal goal,
        Expression function(Type , Expression ) fp);
    Expression resolveLoc(Loc loc, Scope *sc);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);

    Expression op_overload(Scope *sc);
};

class BinExp : Expression
{
    Expression e1;
    Expression e2;

    this(Loc loc, TOK op, int size, Expression e1, Expression e2);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    final Expression semanticp(Scope *sc);
    final void checkComplexMulAssign();
    final void checkComplexAddAssign();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    final Expression scaleFactor(Scope *sc);
    final Expression typeCombine(Scope *sc);
    Expression optimize(int result);
    final int isunsigned();
    final Expression incompatibleTypes();
    void dump(int indent);
    final Expression interpretCommon(InterState *istate, CtfeGoal goal,
        Expression function(Type , Expression , Expression ) fp);
    final Expression interpretCommon2(InterState *istate, CtfeGoal goal,
        Expression function(TOK, Type , Expression , Expression ) fp);
    final Expression interpretAssignCommon(InterState *istate, CtfeGoal goal,
        Expression function(Type , Expression , Expression ) fp, int post = 0);
    final Expression arrayOp(Scope *sc);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);

    final Expression op_overload(Scope *sc);
    final Expression compare_overload(Scope *sc, Identifier id);

    final elem *toElemBin(IRState *irs, int op);
};

class BinAssignExp : BinExp
{
    this(Loc loc, TOK op, int size, Expression e1, Expression e2)
    {
        super(loc, op, size, e1, e2);
    }

    final Expression commonSemanticAssign(Scope *sc);
    final Expression commonSemanticAssignIntegral(Scope *sc);

    final Expression op_overload(Scope *sc);

    int isLvalue();
    Expression toLvalue(Scope *sc, Expression ex);
    Expression modifiableLvalue(Scope *sc, Expression e);
};

/****************************************************************/

final class CompileExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class FileExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class AssertExp : UnaExp
{
    Expression msg;

    this(Loc loc, Expression e, Expression msg = null);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

final class DotIdExp : UnaExp
{
    Identifier ident;

    this(Loc loc, Expression e, Identifier ident);
    Expression semantic(Scope *sc);
    Expression semantic(Scope *sc, int flag);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void dump(int i);
};

final class DotTemplateExp : UnaExp
{
    TemplateDeclaration td;

    this(Loc loc, Expression e, TemplateDeclaration td);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class DotVarExp : UnaExp
{
    Declaration var;
    int hasOverloads;

    this(Loc loc, Expression e, Declaration var, int hasOverloads = 0);
    Expression semantic(Scope *sc);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void dump(int indent);
    elem *toElem(IRState *irs);
};

final class DotTemplateInstanceExp : UnaExp
{
    TemplateInstance ti;

    this(Loc loc, Expression e, Identifier name, Objects tiargs);
    Expression syntaxCopy();
    TemplateDeclaration getTempdecl(Scope *sc);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void dump(int indent);
};

final class DelegateExp : UnaExp
{
    FuncDeclaration func;
    int hasOverloads;

    this(Loc loc, Expression e, FuncDeclaration func, int hasOverloads = 0);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void dump(int indent);

    int inlineCost3(InlineCostState *ics);
    elem *toElem(IRState *irs);
};

final class DotTypeExp : UnaExp
{
    Dsymbol sym;               // symbol that represents a type

    this(Loc loc, Expression e, Dsymbol sym);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

final class CallExp : UnaExp
{
    Expressions arguments;     // function arguments
    FuncDeclaration f;         // symbol to call

    this(Loc loc, Expression e, Expressions exps);
    this(Loc loc, Expression e);
    this(Loc loc, Expression e, Expression earg1);
    this(Loc loc, Expression e, Expression earg1, Expression earg2);

    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression resolveUFCS(Scope *sc);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void dump(int indent);
    elem *toElem(IRState *irs);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression addDtorHook(Scope *sc);
    MATCH implicitConvTo(Type t);

    int inlineCost3(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class AddrExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    void checkEscape();
    elem *toElem(IRState *irs);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
};

final class PtrExp : UnaExp
{
    this(Loc loc, Expression e);
    this(Loc loc, Expression e, Type t);
    Expression semantic(Scope *sc);
    int isLvalue();
    void checkEscapeRef();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);

    // For operator overloading
    Identifier opId();
};

final class NegExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();

    elem *toElem(IRState *irs);
};

final class UAddExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);

    // For operator overloading
    Identifier opId();
};

final class ComExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();

    elem *toElem(IRState *irs);
};

final class NotExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBit();
    elem *toElem(IRState *irs);
};

final class BoolExp : UnaExp
{
    this(Loc loc, Expression e, Type type);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBit();
    elem *toElem(IRState *irs);
};

final class DeleteExp : UnaExp
{
    this(Loc loc, Expression e);
    Expression semantic(Scope *sc);
    Expression checkToBoolean(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

final class CastExp : UnaExp
{
    // Possible to cast to one type while painting to another type
    Type to;                   // type to cast to
    uint mod;               // MODxxxxx

    this(Loc loc, Expression e, Type t);
    this(Loc loc, Expression e, uint mod);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    MATCH implicitConvTo(Type t);
    IntRange getIntRange();
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void checkEscape();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    elem *toElem(IRState *irs);

    // For operator overloading
    Identifier opId();
    Expression op_overload(Scope *sc);
};

final class VectorExp : UnaExp
{
    Type to;
    uint dim;               // number of elements in the vector

    this(Loc loc, Expression e, Type t);
    Expression syntaxCopy();
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

final class SliceExp : UnaExp
{
    Expression upr;            // NULL if implicit 0
    Expression lwr;            // NULL if implicit [length - 1]
    VarDeclaration lengthVar;

    this(Loc loc, Expression e1, Expression lwr, Expression upr);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    void checkEscape();
    void checkEscapeRef();
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    int isBool(int result);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void dump(int indent);
    elem *toElem(IRState *irs);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

final class ArrayLengthExp : UnaExp
{
    this(Loc loc, Expression e1);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);

    static Expression rewriteOpAssign(BinExp exp);
};

// e1[a0,a1,a2,a3,...]

final class ArrayExp : UnaExp
{
    Expressions arguments;             // Array of Expression's
    size_t currentDimension;            // for opDollar
    VarDeclaration lengthVar;

    this(Loc loc, Expression e1, Expressions arguments);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    // For operator overloading
    Identifier opId();
    Expression op_overload(Scope *sc);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);
};

/****************************************************************/

final class DotExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class CommaExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    void checkEscape();
    void checkEscapeRef();
    IntRange getIntRange();
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    int isBool(int result);
    MATCH implicitConvTo(Type t);
    Expression addDtorHook(Scope *sc);
    Expression castTo(Scope *sc, Type t);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    elem *toElem(IRState *irs);
};

final class IndexExp : BinExp
{
    VarDeclaration lengthVar;
    int modifiable;

    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    Expression doInline(InlineDoState *ids);

    elem *toElem(IRState *irs);
};

/* For both i++ and i--
 */
final class PostExp : BinExp
{
    this(TOK op, Loc loc, Expression e);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Identifier opId();    // For operator overloading
    elem *toElem(IRState *irs);
};

/* For both ++i and --i
 */
final class PreExp : UnaExp
{
    this(TOK op, Loc loc, Expression e);
    Expression semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class AssignExp : BinExp
{
   int ismemset;       // !=0 if setting the contents of an array

    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression checkToBoolean(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    Identifier opId();    // For operator overloading
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    elem *toElem(IRState *irs);
};

final class ConstructExp : AssignExp
{
    this(Loc loc, Expression e1, Expression e2);
};

template ASSIGNEXP(string op, bool array)
{
    enum ASSIGNEXP =
        "final class " ~ op ~ "AssignExp : BinAssignExp" ~
        "{" ~
            "this(Loc loc, Expression e1, Expression e2);" ~
            "Expression semantic(Scope *sc);" ~
            "Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);" ~
            (array ? "void buildArrayIdent(OutBuffer buf, Expressions arguments);" : "") ~
            (array ? "Expression buildArrayLoop(Parameters fparams);" : "") ~
            "Identifier opId();    /* For operator overloading */" ~
            "elem *toElem(IRState *irs);" ~
        "};"
        ;
}

mixin(ASSIGNEXP!("Add", true));
mixin(ASSIGNEXP!("Min", true));
mixin(ASSIGNEXP!("Mul", true));
mixin(ASSIGNEXP!("Div", true));
mixin(ASSIGNEXP!("Mod", true));
mixin(ASSIGNEXP!("And", true));
mixin(ASSIGNEXP!("Or", true));
mixin(ASSIGNEXP!("Xor", true));
//static if (DMDV2) {
mixin(ASSIGNEXP!("Pow", true));
//}

mixin(ASSIGNEXP!("Shl", false));
mixin(ASSIGNEXP!("Shr", false));
mixin(ASSIGNEXP!("Ushr", false));
mixin(ASSIGNEXP!("Cat", false));

final class AddExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class MinExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class CatExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class MulExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class DivExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class ModExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

//static if (DMDV2) {
final class PowExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};
//}

final class ShlExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class ShrExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class UshrExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    IntRange getIntRange();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class AndExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class OrExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    MATCH implicitConvTo(Type t);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class XorExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void buildArrayIdent(OutBuffer buf, Expressions arguments);
    Expression buildArrayLoop(Parameters fparams);
    MATCH implicitConvTo(Type t);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class OrOrExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression checkToBoolean(Scope *sc);
    int isBit();
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    elem *toElem(IRState *irs);
};

final class AndAndExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression checkToBoolean(Scope *sc);
    int isBit();
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    elem *toElem(IRState *irs);
};

final class CmpExp : BinExp
{
    this(TOK op, Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBit();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Expression op_overload(Scope *sc);

    elem *toElem(IRState *irs);
};

final class InExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBit();

    // For operator overloading
    Identifier opId();
    Identifier opId_r();

    elem *toElem(IRState *irs);
};

final class RemoveExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

// == and !=

final class EqualExp : BinExp
{
    this(TOK op, Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    int isBit();

    // For operator overloading
    int isCommutative();
    Identifier opId();
    Expression op_overload(Scope *sc);

    elem *toElem(IRState *irs);
};

// === and !===

final class IdentityExp : BinExp
{
    this(TOK op, Loc loc, Expression e1, Expression e2);
    Expression semantic(Scope *sc);
    int isBit();
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    elem *toElem(IRState *irs);
};

/****************************************************************/

final class CondExp : BinExp
{
    Expression econd;

    this(Loc loc, Expression econd, Expression e1, Expression e2);
    Expression syntaxCopy();
    int apply(apply_fp_t fp, void *param);
    Expression semantic(Scope *sc);
    Expression optimize(int result);
    Expression interpret(InterState *istate, CtfeGoal goal = ctfeNeedRvalue);
    void checkEscape();
    void checkEscapeRef();
    int isLvalue();
    Expression toLvalue(Scope *sc, Expression e);
    Expression modifiableLvalue(Scope *sc, Expression e);
    Expression checkToBoolean(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    MATCH implicitConvTo(Type t);
    Expression castTo(Scope *sc, Type t);

    Expression doInline(InlineDoState *ids);
    Expression inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

//static if (DMDV2) {
/****************************************************************/

class DefaultInitExp : Expression
{
    TOK subop;             // which of the derived classes this is

    this(Loc loc, TOK subop, int size);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class FileInitExp : DefaultInitExp
{
    this(Loc loc);
    Expression semantic(Scope *sc);
    Expression resolveLoc(Loc loc, Scope *sc);
};

final class LineInitExp : DefaultInitExp
{
    this(Loc loc);
    Expression semantic(Scope *sc);
    Expression resolveLoc(Loc loc, Scope *sc);
};
//}

/****************************************************************/

/* Special values used by the interpreter
 */
//auto EXP_CANT_INTERPRET()     { union uu { Expression e; void* v; } uu u; u.v = cast(void*)1; return u.e; }
//auto EXP_CONTINUE_INTERPRET() { union uu { Expression e; void* v; } uu u; u.v = cast(void*)2; return u.e; }
//auto EXP_BREAK_INTERPRET()    { union uu { Expression e; void* v; } uu u; u.v = cast(void*)3; return u.e; }
//auto EXP_GOTO_INTERPRET()     { union uu { Expression e; void* v; } uu u; u.v = cast(void*)4; return u.e; }
//auto EXP_VOID_INTERPRET()     { union uu { Expression e; void* v; } uu u; u.v = cast(void*)5; return u.e; }

Expression expType(Type type, Expression e);

Expression Neg(Type type, Expression e1);
Expression Com(Type type, Expression e1);
Expression Not(Type type, Expression e1);
Expression Bool(Type type, Expression e1);
Expression Cast(Type type, Type to, Expression e1);
Expression ArrayLength(Type type, Expression e1);
Expression Ptr(Type type, Expression e1);

Expression Add(Type type, Expression e1, Expression e2);
Expression Min(Type type, Expression e1, Expression e2);
Expression Mul(Type type, Expression e1, Expression e2);
Expression Div(Type type, Expression e1, Expression e2);
Expression Mod(Type type, Expression e1, Expression e2);
Expression Pow(Type type, Expression e1, Expression e2);
Expression Shl(Type type, Expression e1, Expression e2);
Expression Shr(Type type, Expression e1, Expression e2);
Expression Ushr(Type type, Expression e1, Expression e2);
Expression And(Type type, Expression e1, Expression e2);
Expression Or(Type type, Expression e1, Expression e2);
Expression Xor(Type type, Expression e1, Expression e2);
Expression Index(Type type, Expression e1, Expression e2);
Expression Cat(Type type, Expression e1, Expression e2);

Expression Equal(TOK op, Type type, Expression e1, Expression e2);
Expression Cmp(TOK op, Type type, Expression e1, Expression e2);
Expression Identity(TOK op, Type type, Expression e1, Expression e2);

Expression Slice(Type type, Expression e1, Expression lwr, Expression upr);

