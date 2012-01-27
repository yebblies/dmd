
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module parse;
extern(C++):

import arraytypes;
import lexer;
import _enum;
import mtype;
import expression;
import declaration;
import statement;
import _import;
import init;
import cond;
import _module;
import _template;
import staticassert;
import mars;
import dsymbol;
import identifier;

/************************************
 * These control how parseStatement() works.
 */

alias uint ParseStatementFlags;
enum : ParseStatementFlags
{
    PSsemi = 1,         // empty ';' statements are allowed, but deprecated
    PSscope = 2,        // start a new scope
    PScurly = 4,        // { } statement is required
    PScurlyscope = 8,   // { } starts a new scope
    PSsemi_ok = 0x10,   // empty ';' are really ok
};


final class Parser : Lexer
{
    ModuleDeclaration md;
    LINK linkage;
    Loc endloc;                 // set to location of last right curly
    int inBrackets;             // inside [] of array index or slice
    Loc lookingForElse;         // location of lonely if looking for an else

    this(Module _module, ubyte *base, uint length, int doDocComment);

    Dsymbols parseModule();
    Dsymbols parseDeclDefs(int once);
    Dsymbols parseAutoDeclarations(StorageClass storageClass, ubyte *comment);
    Dsymbols parseBlock();
    void composeStorageClass(StorageClass stc);
    StorageClass parseAttribute();
    StorageClass parsePostfix();
    Expression parseConstraint();
    TemplateDeclaration parseTemplateDeclaration(int ismixin);
    TemplateParameters parseTemplateParameterList(int flag = 0);
    Dsymbol parseMixin();
    Objects parseTemplateArgumentList();
    Objects parseTemplateArgumentList2();
    Objects parseTemplateArgument();
    StaticAssert parseStaticAssert();
    TypeQualified parseTypeof();
    Type parseVector();
    LINK parseLinkage();
    Condition parseDebugCondition();
    Condition parseVersionCondition();
    Condition parseStaticIfCondition();
    Dsymbol parseCtor();
    PostBlitDeclaration parsePostBlit();
    DtorDeclaration parseDtor();
    StaticCtorDeclaration parseStaticCtor();
    StaticDtorDeclaration parseStaticDtor();
    SharedStaticCtorDeclaration parseSharedStaticCtor();
    SharedStaticDtorDeclaration parseSharedStaticDtor();
    InvariantDeclaration parseInvariant();
    UnitTestDeclaration parseUnitTest();
    NewDeclaration parseNew();
    DeleteDeclaration parseDelete();
    Parameters parseParameters(int *pvarargs, TemplateParameters *tpl = null);
    EnumDeclaration parseEnum();
    Dsymbol parseAggregate();
    BaseClasses parseBaseClasses();
    Import parseImport(Dsymbols decldefs, int isstatic);
    Type parseType(Identifier *pident = null, TemplateParameters *tpl = null);
    Type parseBasicType();
    Type parseBasicType2(Type t);
    Type parseDeclarator(Type t, Identifier *pident, TemplateParameters *tpl = null, StorageClass storage_class = 0, int* pdisable = null);
    Dsymbols parseDeclarations(StorageClass storage_class, ubyte *comment);
    void parseContracts(FuncDeclaration f);
    void checkDanglingElse(Loc elseloc);
    Statement parseStatement(int flags);
    Initializer parseInitializer();
    Expression parseDefaultInitExp();
    void check(Loc loc, TOK value);
    void check(TOK value);
    void check(TOK value, const(char)* string);
    void checkParens(TOK value, Expression e);
    int isDeclaration(Token *t, int needId, TOK endtok, Token **pt);
    int isBasicType(Token **pt);
    int isDeclarator(Token **pt, int *haveId, TOK endtok);
    int isParameters(Token **pt);
    int isExpression(Token **pt);
    int isTemplateInstance(Token *t, Token **pt);
    int skipParens(Token *t, Token **pt);
    int skipAttributes(Token *t, Token **pt);

    Expression parseExpression();
    Expression parsePrimaryExp();
    Expression parseUnaryExp();
    Expression parsePostExp(Expression e);
    Expression parseMulExp();
    Expression parseAddExp();
    Expression parseShiftExp();
version (DMDV1) {
    Expression parseRelExp();
    Expression parseEqualExp();
}
    Expression parseCmpExp();
    Expression parseAndExp();
    Expression parseXorExp();
    Expression parseOrExp();
    Expression parseAndAndExp();
    Expression parseOrOrExp();
    Expression parseCondExp();
    Expression parseAssignExp();

    Expressions parseArguments();

    Expression parseNewExp(Expression thisexp);

    void addComment(Dsymbol s, ubyte *blockComment);
};

// Operator precedence - greater values are higher precedence

alias uint PREC;
enum : PREC
{
    PREC_zero,
    PREC_expr,
    PREC_assign,
    PREC_cond,
    PREC_oror,
    PREC_andand,
    PREC_or,
    PREC_xor,
    PREC_and,
    PREC_equal,
    PREC_rel,
    PREC_shift,
    PREC_add,
    PREC_mul,
    PREC_pow,
    PREC_unary,
    PREC_primary,
};

extern PREC precedence[TOKMAX];

void initPrecedence();

