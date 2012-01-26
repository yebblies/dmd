
// Compiler implementation of the D programming language
// Copyright (c) 1999-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module init;
extern(C++):

import root.root;

import mars;
import arraytypes;
import identifier;
import expression;
import _scope;
import mtype;
import fakebackend;
import aggregate;
import hdrgen;

class Initializer : _Object
{
    Loc loc;

    this(Loc loc);
    Initializer syntaxCopy();
    // needInterpret is WANTinterpret if must be a manifest constant, 0 if not.
    Initializer semantic(Scope *sc, Type t, int needInterpret);
    Type inferType(Scope *sc);
    abstract Expression toExpression();
    abstract void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    char *toChars();

    static Initializers arraySyntaxCopy(Initializers ai);

    dt_t *toDt();

    VoidInitializer isVoidInitializer() { return null; }
    StructInitializer  isStructInitializer()  { return null; }
    ArrayInitializer  isArrayInitializer()  { return null; }
    ExpInitializer  isExpInitializer()  { return null; }
};

class VoidInitializer : Initializer
{
    Type type;         // type that this will initialize to

    this(Loc loc);
    Initializer syntaxCopy();
    Initializer semantic(Scope *sc, Type t, int needInterpret);
    Expression toExpression();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    dt_t *toDt();

    VoidInitializer isVoidInitializer() { return this; }
};

class StructInitializer : Initializer
{
    Identifiers field;  // of Identifier 's
    Initializers value; // parallel array of Initializer 's

    VarDeclarations vars;       // parallel array of VarDeclaration 's
    AggregateDeclaration ad;   // which aggregate this is for

    this(Loc loc);
    Initializer syntaxCopy();
    void addInit(Identifier field, Initializer value);
    Initializer semantic(Scope *sc, Type t, int needInterpret);
    Expression toExpression();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    dt_t *toDt();

    StructInitializer isStructInitializer() { return this; }
};

class ArrayInitializer : Initializer
{
    Expressions index;  // indices
    Initializers value; // of Initializer 's
    uint dim;       // length of array being initialized
    Type type;         // type that array will be used to initialize
    int sem;            // !=0 if semantic() is run

    this(Loc loc);
    Initializer syntaxCopy();
    void addInit(Expression index, Initializer value);
    Initializer semantic(Scope *sc, Type t, int needInterpret);
    int isAssociativeArray();
    Type inferType(Scope *sc);
    Expression toExpression();
    Expression toAssocArrayLiteral();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    dt_t *toDt();
    dt_t *toDtBit();    // for bit arrays

    ArrayInitializer isArrayInitializer() { return this; }
};

class ExpInitializer : Initializer
{
    Expression exp;

    this(Loc loc, Expression exp);
    Initializer syntaxCopy();
    Initializer semantic(Scope *sc, Type t, int needInterpret);
    Type inferType(Scope *sc);
    Expression toExpression();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);

    dt_t *toDt();

    ExpInitializer isExpInitializer() { return this; }
};

