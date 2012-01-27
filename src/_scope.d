
// Copyright (c) 1999-2009 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module _scope;

import dsymbol;
import declaration;
import _module;
import statement;
import _template;
import mars;
import aggregate;
import root.root;
import doc;
import identifier;

extern(C++)
struct Scope
{
    Scope *enclosing;           // enclosing Scope

    Module _module;             // Root module
    ScopeDsymbol scopesym;     // current symbol
    ScopeDsymbol sd;           // if in static if, and declaring new symbols,
                                // sd gets the addMember()
    FuncDeclaration func;      // function we are in
    Dsymbol parent;            // parent to use
    LabelStatement slabel;     // enclosing labelled statement
    SwitchStatement sw;        // enclosing switch statement
    TryFinallyStatement tf;    // enclosing try finally statement
    TemplateInstance tinst;    // enclosing template instance
    Statement sbreak;          // enclosing statement that supports "break"
    Statement scontinue;       // enclosing statement that supports "continue"
    ForeachStatement fes;      // if nested function for ForeachStatement, this is it
    uint offset;            // next offset to use in aggregate
    int inunion;                // we're processing members of a union
    int incontract;             // we're inside contract code
    int nofree;                 // set if shouldn't free it
    int noctor;                 // set if constructor calls aren't allowed
    int intypeof;               // in typeof(exp)
    int parameterSpecialization; // if in template parameter specialization
    int noaccesscheck;          // don't do access checks
    int mustsemantic;           // cannot defer semantic()

    uint callSuper;         // primitive flow analysis for constructors
enum CSXthis_ctor   = 1;       // called this()
enum CSXsuper_ctor  = 2;       // called super()
enum CSXthis        = 4;       // referenced this
enum CSXsuper       = 8;       // referenced super
enum CSXlabel       = 0x10;    // seen a label
enum CSXreturn      = 0x20;    // seen a return statement
enum CSXany_ctor    = 0x40;    // either this() or super() was called

    uint structalign;       // alignment for struct members
    LINK linkage;          // linkage for external functions

    PROT protection;       // protection for class members
    int explicitProtection;     // set if in an explicit protection attribute

    StorageClass stc;           // storage class

    uint flags;
enum SCOPEctor         = 1;       // constructor type
enum SCOPEstaticif     = 2;       // inside static if
enum SCOPEfree         = 4;       // is on free list
enum SCOPEstaticassert = 8;       // inside static assert
enum SCOPEdebug        = 0x10;    // inside debug conditional

    AnonymousAggregateDeclaration anonAgg;     // for temporary analysis

    DocComment *lastdc;         // documentation comment for last symbol at this scope
    uint lastoffset;        // offset in docbuf of where to insert next dec
    OutBuffer docbuf;          // buffer for documentation output

    static extern Scope *freelist;
    static void *__new(size_t sz);
    static Scope *createGlobal(Module _module);

    @disable this();
    this(Module _module);
    this(Scope *enclosing);

    Scope *push();
    Scope *push(ScopeDsymbol ss);
    Scope *pop();

    void mergeCallSuper(Loc loc, uint cs);

    Dsymbol search(Loc loc, Identifier ident, Dsymbol *pscopesym);
    Dsymbol search_correct(Identifier ident);
    Dsymbol insert(Dsymbol s);

    ClassDeclaration getClassScope();
    AggregateDeclaration getStructClassScope();
    void setNoFree();
};

