
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module _macro;
extern(C++):

import root.root;


struct Macro
{
  private:
    Macro *next;                // next in list

    ubyte *name;        // macro name
    size_t namelen;             // length of macro name

    ubyte *text;        // macro replacement text
    size_t textlen;             // length of replacement text

    int inuse;                  // macro is in use (don't expand)

    this(ubyte *name, size_t namelen, ubyte *text, size_t textlen);
    Macro *search(ubyte *name, size_t namelen);

  public:
    static Macro *define(Macro **ptable, ubyte *name, size_t namelen, ubyte *text, size_t textlen);

    void expand(OutBuffer buf, uint start, uint *pend,
        ubyte *arg, uint arglen);
};

