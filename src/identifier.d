
// Compiler implementation of the D programming language
// Copyright (c) 1999-2006 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module identifier;

import root.root;

extern(C++)
class Identifier : _Object
{
    int value;
    const(char)* string;
    uint len;

    this(const(char)* string, int value);
    int equals(_Object o);
    hash_t hashCode();
    int compare(_Object o);
    void print();
    char *toChars();
    char *toHChars();
    const(char)* toHChars2();
    int dyncast();

    static Identifier generateId(const(char)* prefix);
    static Identifier generateId(const(char)* prefix, size_t i);
};

