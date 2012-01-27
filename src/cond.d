
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module cond;
extern(C++):

import expression;
import identifier;
import root.root;
import _module;
import _scope;
import dsymbol;
import lexer;
import hdrgen;
import mars;
import mtype;
import arraytypes;

int findCondition(Strings ids, Identifier ident);

class Condition
{
    Loc loc;
    int inc;            // 0: not computed yet
                        // 1: include
                        // 2: do not include

    this(Loc loc);

    abstract Condition syntaxCopy();
    abstract int include(Scope *sc, ScopeDsymbol s);
    abstract void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    DebugCondition isDebugCondition();
};

class DVCondition : Condition
{
    uint level;
    Identifier ident;
    Module mod;

    this(Module mod, uint level, Identifier ident);

    Condition syntaxCopy();
};

class DebugCondition : DVCondition
{
    static void setGlobalLevel(uint level);
    static void addGlobalIdent(const(char)* ident);
    static void addPredefinedGlobalIdent(const(char)* ident);

    this(Module mod, uint level, Identifier ident);

    int include(Scope *sc, ScopeDsymbol s);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    DebugCondition isDebugCondition();
};

class VersionCondition : DVCondition
{
    static void setGlobalLevel(uint level);
    static void checkPredefined(Loc loc, const(char)* ident);
    static void addGlobalIdent(const(char)* ident);
    static void addPredefinedGlobalIdent(const(char)* ident);

    this(Module mod, uint level, Identifier ident);

    int include(Scope *sc, ScopeDsymbol s);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class StaticIfCondition : Condition
{
    Expression exp;

    this(Loc loc, Expression exp);
    Condition syntaxCopy();
    int include(Scope *sc, ScopeDsymbol s);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

class IftypeCondition : Condition
{
    /* iftype (targ id tok tspec)
     */
    Type targ;
    Identifier id;     // can be NULL
    TOK tok;       // ':' or '=='
    Type tspec;        // can be NULL

    this(Loc loc, Type targ, Identifier id, TOK tok, Type tspec);
    Condition syntaxCopy();
    int include(Scope *sc, ScopeDsymbol s);
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

