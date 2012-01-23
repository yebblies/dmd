
module root.lstring;

import root._dchar;

static Lstring LSTRING(T, U)(T p, U length) { return Lstring(length, p); }
static Lstring LSTRING_EMPTY() { return LSTRING("".dup.ptr, 0); }

extern(C++)
struct Lstring
{
   uint length;

    // Disable warning about nonstandard extension
    _dchar* string;

    extern __gshared static Lstring zero;        // 0 length string

    // No constructors because we want to be able to statically
    // initialize Lstring's, and Lstrings are of variable size.

    static Lstring *ctor(const _dchar *p) { return ctor(p, Dchar.len(p)); }
    static Lstring *ctor(const _dchar *p, uint length);
    static uint size(uint length) { return (Lstring).sizeof + (length + 1) * (_dchar).sizeof; }
    static Lstring *alloc(uint length);
    Lstring *clone();

    uint len() { return length; }

    _dchar *toDchars() { return string; }

    hash_t hash() { return Dchar.calcHash(string, length); }
    hash_t ihash() { return Dchar.icalcHash(string, length); }

    static int cmp(const Lstring *s1, const Lstring *s2)
    {
        int c = s2.length - s1.length;
        return c ? c : Dchar.memcmp(s1.string, s2.string, s1.length);
    }

    static int icmp(const Lstring *s1, const Lstring *s2)
    {
        int c = s2.length - s1.length;
        return c ? c : Dchar.memicmp(s1.string, s2.string, s1.length);
    }

    Lstring *append(const Lstring *s);
    Lstring *substring(int start, int end);
};
