
// Compiler implementation of the D programming language
// Copyright (c) 2009-2009 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module aliasthis;
extern(C++):

import mars;
import dsymbol;
import identifier;
import root.root;
import hdrgen;
import _scope;

/**************************************************************/

version (DMDV2) {

final class AliasThis : Dsymbol
{
public:
   // alias Identifier this;
    Identifier ident;

    this(Loc loc, Identifier ident);

    Dsymbol syntaxCopy(Dsymbol );
    void semantic(Scope *sc);
    const(char)* kind();
    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    AliasThis isAliasThis();
};

}
