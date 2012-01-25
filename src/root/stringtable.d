// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module root.stringtable;

import root.root;
import root._dchar;
import root.lstring;

extern(C++)
struct StringValue
{
    union
    {   int intvalue;
        void *ptrvalue;
        dchar *string;
    };
    Lstring lstring;
};

extern(C++)
struct StringTable
{
    void **table;
    uint count;
    uint tabledim;

    void init(uint size = 37);
    ~this();

    StringValue *lookup(const(_dchar)* s, uint len);
    StringValue *insert(const(_dchar)* s, uint len);
    StringValue *update(const(_dchar)* s, uint len);

private:
    void **search(const(_dchar)* s, uint len);
};

