
module root._dchar;

import core.stdc.string;
extern(C) nothrow @system pure
{
    int memicmp(in void* s1, in void* s2, size_t n);
    int stricmp(in char* s1, in char* s2);
}

enum Dchar_mbmax = 1;

alias char _dchar;

extern(C++)
struct Dchar
{
    static _dchar *inc(_dchar *p);
    static _dchar *dec(_dchar *pstart, _dchar *p);
    static int len(const _dchar *p);
    static int get(_dchar *p);
    static int getprev(_dchar *pstart, _dchar *p);
    static _dchar *put(_dchar *p, uint c);
    static int cmp(_dchar *s1, _dchar *s2);
    static int memcmp(const _dchar *s1, const _dchar *s2, int n_dchars);
    static int isDigit(_dchar c);
    static _dchar *chr(_dchar *p, int c);
    static _dchar *rchr(_dchar *p, int c);
    static _dchar *memchr(_dchar *p, int c, int count);
    static _dchar *cpy(_dchar *s1, _dchar *s2);
    static _dchar *str(_dchar *s1, _dchar *s2);
    static hash_t calcHash(const _dchar *str, size_t len);

    // Case insensitive versions
    static int icmp(_dchar *s1, _dchar *s2);
    static int memicmp(const _dchar *s1, const _dchar *s2, int n_dchars);
    static hash_t icalcHash(const _dchar *str, size_t len);
};
