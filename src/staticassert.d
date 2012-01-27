
// Compiler implementation of the D programming language
// Copyright (c) 1999-2006 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module staticassert;
extern(C++):

import dsymbol;
import expression;
import hdrgen;
import mars;
import root.root;
import _scope;

final class StaticAssert : Dsymbol
{
    Expression exp;
    Expression msg;

    this(Loc loc, Expression exp, Expression msg);

    Dsymbol syntaxCopy(Dsymbol s);
    int addMember(Scope *sc, ScopeDsymbol sd, int memnum);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void inlineScan();
    int oneMember(Dsymbol *ps);
    void toObjFile(int multiobj);
    const(char)* kind();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
};

