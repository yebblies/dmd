
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module statement;
extern(C++):

import root.root;

import mars;
import hdrgen;
import _scope;
import arraytypes;
import expression;
import interpret;
import inline;
import dsymbol;
import declaration;
import lexer;
import mtype;
import cond;
import identifier;
import staticassert;
import irstate;

import fakebackend;

/* How a statement exits; this is returned by blockExit()
 */
alias uint BE;
enum : BE
{
    BEnone =     0,
    BEfallthru = 1,
    BEthrow =    2,
    BEreturn =   4,
    BEgoto =     8,
    BEhalt =     0x10,
    BEbreak =    0x20,
    BEcontinue = 0x40,
    BEany = (BEfallthru | BEthrow | BEreturn | BEgoto | BEhalt),
};

class Statement : _Object
{
    Loc loc;

    this(Loc loc);
    Statement syntaxCopy();

    void print();
    char *toChars();

    final void error(const(char)* format, ...);
    final void warning(const(char)* format, ...);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int incontract;
    ScopeStatement isScopeStatement();
    Statement semantic(Scope *sc);
    final Statement semanticScope(Scope *sc, Statement sbreak, Statement scontinue);
    final Statement semanticNoScope(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    int isEmpty();
    Statement scopeCode(Scope *sc, Statement *sentry, Statement *sexit, Statement *sfinally);
    Statements flatten(Scope *sc);
    Expression interpret(InterState *istate);
    Statement last();

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    // Back end
    void toIR(IRState *irs);

    // Avoid dynamic_cast
    ExpStatement isExpStatement();
    CompoundStatement isCompoundStatement();
    ReturnStatement isReturnStatement();
    IfStatement isIfStatement();
    CaseStatement isCaseStatement();
    DefaultStatement isDefaultStatement();
    LabelStatement isLabelStatement();
};

class PeelStatement : Statement
{
    Statement s;

    this(Statement s);
    Statement semantic(Scope *sc);
};

class ExpStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp);
    this(Loc loc, Dsymbol s);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    int blockExit(bool mustNotThrow);
    int isEmpty();
    Statement scopeCode(Scope *sc, Statement *sentry, Statement *sexit, Statement *sfinally);

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);

    ExpStatement isExpStatement();
};

class DtorExpStatement : ExpStatement
{
    /* Wraps an expression that is the destruction of 'var'
     */

    VarDeclaration var;

    this(Loc loc, Expression exp, VarDeclaration v);
    Statement syntaxCopy();
    void toIR(IRState *irs);
};

class CompileStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statements flatten(Scope *sc);
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
};

class CompoundStatement : Statement
{
    Statements statements;

    this(Loc loc, Statements s);
    this(Loc loc, Statement s1);
    this(Loc loc, Statement s1, Statement s2);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statement semantic(Scope *sc);
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    int isEmpty();
    Statements flatten(Scope *sc);
    ReturnStatement isReturnStatement();
    Expression interpret(InterState *istate);
    Statement last();

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);

    CompoundStatement isCompoundStatement();
};

class CompoundDeclarationStatement : CompoundStatement
{
    this(Loc loc, Statements s);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

/* The purpose of this is so that continue will go to the next
 * of the statements, and break will go to the end of the statements.
 */
class UnrolledLoopStatement : Statement
{
    Statements statements;

    this(Loc loc, Statements statements);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class ScopeStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement s);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    ScopeStatement isScopeStatement();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    int isEmpty();
    Expression interpret(InterState *istate);

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class WhileStatement : Statement
{
    Expression condition;
    Statement _body;

    this(Loc loc, Expression c, Statement b);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class DoStatement : Statement
{
    Statement _body;
    Expression condition;

    this(Loc loc, Statement b, Expression c);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class ForStatement : Statement
{
    Statement init;
    Expression condition;
    Expression increment;
    Statement _body;

    this(Loc loc, Statement init, Expression condition, Expression increment, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Statement scopeCode(Scope *sc, Statement *sentry, Statement *sexit, Statement *sfinally);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    int inlineCost(InlineCostState *ics);
    Statement inlineScan(InlineScanState *iss);
    Statement doInlineStatement(InlineDoState *ids);

    void toIR(IRState *irs);
};

class ForeachStatement : Statement
{
    TOK op;                // TOKforeach or TOKforeach_reverse
    Parameters arguments;      // array of Parameter's
    Expression aggr;
    Statement _body;

    VarDeclaration key;
    VarDeclaration value;

    FuncDeclaration func;      // function we're lexically in

    Statements cases;          // put breaks, continues, gotos and returns here
    CompoundStatements gotos;  // forward referenced goto's go here

    this(Loc loc, TOK op, Parameters arguments, Expression aggr, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    final bool checkForArgTypes();
    final int inferAggregate(Scope *sc, ref Dsymbol sapply);
    final int inferApplyArgTypes(Scope *sc, ref Dsymbol sapply);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

version (DMDV2) {
class ForeachRangeStatement : Statement
{
    TOK op;                // TOKforeach or TOKforeach_reverse
    Parameter arg;             // loop index variable
    Expression lwr;
    Expression upr;
    Statement _body;

    VarDeclaration key;

    this(Loc loc, TOK op, Parameter arg,
        Expression lwr, Expression upr, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};
}

class IfStatement : Statement
{
    Parameter arg;
    Expression condition;
    Statement ifbody;
    Statement elsebody;

    VarDeclaration match;      // for MatchExpression results

    this(Loc loc, Parameter arg, Expression condition, Statement ifbody, Statement elsebody);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int usesEH();
    int blockExit(bool mustNotThrow);
    IfStatement isIfStatement();

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class ConditionalStatement : Statement
{
    Condition condition;
    Statement ifbody;
    Statement elsebody;

    this(Loc loc, Condition condition, Statement ifbody, Statement elsebody);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Statements flatten(Scope *sc);
    int usesEH();
    int blockExit(bool mustNotThrow);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class PragmaStatement : Statement
{
    Identifier ident;
    Expressions args;          // array of Expression's
    Statement _body;

    this(Loc loc, Identifier ident, Expressions args, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int usesEH();
    int blockExit(bool mustNotThrow);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class StaticAssertStatement : Statement
{
    StaticAssert sa;

    this(StaticAssert sa);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class SwitchStatement : Statement
{
    Expression condition;
    Statement _body;
    bool isFinal;

    DefaultStatement sdefault;
    TryFinallyStatement tf;
    GotoCaseStatements gotoCases;  // array of unresolved GotoCaseStatement's
    CaseStatements cases;         // array of CaseStatement's
    int hasNoDefault;           // !=0 if no default statement
    int hasVars;                // !=0 if has variable case values

    this(Loc loc, Expression c, Statement b, bool isFinal);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int usesEH();
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class CaseStatement : Statement
{
    Expression exp;
    Statement statement;

    int index;          // which case it is (since we sort this)
    block *cblock;      // back end: label for the block

    this(Loc loc, Expression exp, Statement s);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int compare(_Object obj);
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    CaseStatement isCaseStatement();

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

version (DMDV2) {

class CaseRangeStatement : Statement
{
    Expression first;
    Expression last;
    Statement statement;

    this(Loc loc, Expression first, Expression last, Statement s);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

}

class DefaultStatement : Statement
{
    Statement statement;
version (IN_GCC) {
    block *cblock;      // back end: label for the block
}

    this(Loc loc, Statement s);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    DefaultStatement isDefaultStatement();

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class GotoDefaultStatement : Statement
{
    SwitchStatement sw;

    this(Loc loc);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class GotoCaseStatement : Statement
{
    Expression exp;            // NULL, or which case to goto
    CaseStatement cs;          // case statement it resolves to

    this(Loc loc, Expression exp);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class SwitchErrorStatement : Statement
{
    this(Loc loc);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class ReturnStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);
    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);

    ReturnStatement isReturnStatement();
};

class BreakStatement : Statement
{
    Identifier ident;

    this(Loc loc, Identifier ident);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class ContinueStatement : Statement
{
    Identifier ident;

    this(Loc loc, Identifier ident);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Expression interpret(InterState *istate);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

class SynchronizedStatement : Statement
{
    Expression exp;
    Statement _body;

    this(Loc loc, Expression exp, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

// Back end
    elem *esync;
    this(Loc loc, elem *esync, Statement _body);
    void toIR(IRState *irs);
};

class WithStatement : Statement
{
    Expression exp;
    Statement _body;
    VarDeclaration wthis;

    this(Loc loc, Expression exp, Statement _body);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int usesEH();
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class TryCatchStatement : Statement
{
    Statement _body;
    Catches catches;

    this(Loc loc, Statement _body, Catches catches);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int hasBreak();
    int usesEH();
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

final class Catch : _Object
{
    Loc loc;
    Type type;
    Identifier ident;
    VarDeclaration var;
    Statement handler;

    this(Loc loc, Type t, Identifier id, Statement handler);
    Catch syntaxCopy();
    void semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class TryFinallyStatement : Statement
{
    Statement _body;
    Statement finalbody;

    this(Loc loc, Statement _body, Statement finalbody);
    Statement syntaxCopy();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statement semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class OnScopeStatement : Statement
{
    TOK tok;
    Statement statement;

    this(Loc loc, TOK tok, Statement statement);
    Statement syntaxCopy();
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    Statement semantic(Scope *sc);
    int usesEH();
    Statement scopeCode(Scope *sc, Statement *sentry, Statement *sexit, Statement *sfinally);
    Expression interpret(InterState *istate);

    void toIR(IRState *irs);
};

class ThrowStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class VolatileStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement statement);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Statements flatten(Scope *sc);
    int blockExit(bool mustNotThrow);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class DebugStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement statement);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Statements flatten(Scope *sc);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class GotoStatement : Statement
{
    Identifier ident;
    LabelDsymbol label;
    TryFinallyStatement tf;

    this(Loc loc, Identifier ident);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
    Expression interpret(InterState *istate);

    void toIR(IRState *irs);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class LabelStatement : Statement
{
    Identifier ident;
    Statement statement;
    TryFinallyStatement tf;
    block *lblock;              // back end

    Blocks fwdrefs;            // forward references to this LabelStatement

    this(Loc loc, Identifier ident, Statement statement);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    Statements flatten(Scope *sc);
    int usesEH();
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    Statement inlineScan(InlineScanState *iss);
    LabelStatement isLabelStatement();

    void toIR(IRState *irs);
};

class LabelDsymbol : Dsymbol
{
    LabelStatement statement;
version (IN_GCC) {
    uint asmLabelNum;       // GCC-specific
}

    this(Identifier ident);
    LabelDsymbol isLabel();
};

final class AsmStatement : Statement
{
    Token *tokens;
    code *asmcode;
    uint asmalign;          // alignment of this statement
    uint regs;              // mask of registers modified (must match regm_t in back end)
    ubyte refparam;     // !=0 if function parameter is referenced
    ubyte naked;        // !=0 if function is to be naked

    this(Loc loc, Token *tokens);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
    int comeFrom();
    Expression interpret(InterState *istate);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    //int inlineCost(InlineCostState *ics);
    //Expression doInline(InlineDoState *ids);
    //Statement inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

class ImportStatement : Statement
{
    Dsymbols imports;          // Array of Import's

    this(Loc loc, Dsymbols imports);
    Statement syntaxCopy();
    Statement semantic(Scope *sc);
    int blockExit(bool mustNotThrow);
    int isEmpty();
    Expression interpret(InterState *istate);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    int inlineCost(InlineCostState *ics);
    Expression doInline(InlineDoState *ids);
    Statement doInlineStatement(InlineDoState *ids);

    void toIR(IRState *irs);
};

