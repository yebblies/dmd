
module root.lstring;
extern(C++):

import root._dchar;

//static Lstring LSTRING(T, U)(T p, U length) { return Lstring(length, p); }
//static Lstring LSTRING_EMPTY() { return LSTRING("".dup.ptr, 0); }

struct Lstring
{
   uint length;

    // Disable warning about nonstandard extension
    _dchar* string;

    static extern Lstring zero;        // 0 length string

    // No constructors because we want to be able to statically
    // initialize Lstring's, and Lstrings are of variable size.

    static Lstring *ctor(const _dchar *p);
    static Lstring *ctor(const _dchar *p, uint length);
    static uint size(uint length);
    static Lstring *alloc(uint length);
    Lstring *clone();

    uint len();

    _dchar *toDchars();

    hash_t hash();
    hash_t ihash();

    static int cmp(const Lstring *s1, const Lstring *s2);

    static int icmp(const Lstring *s1, const Lstring *s2);

    Lstring *append(const Lstring *s);
    Lstring *substring(int start, int end);
};
