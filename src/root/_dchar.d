
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
    static _dchar *inc(_dchar *p) { return p + 1; }
    static _dchar *dec(_dchar *pstart, _dchar *p) { return p - 1; }
    static int len(const _dchar *p) { return strlen(p); }
    static int get(_dchar *p) { return *p & 0xFF; }
    static int getprev(_dchar *pstart, _dchar *p) { return p[-1] & 0xFF; }
    static _dchar *put(_dchar *p, uint c) { *p = cast(_dchar)c; return p + 1; }
    static int cmp(_dchar *s1, _dchar *s2) { return strcmp(s1, s2); }
    static int memcmp(const _dchar *s1, const _dchar *s2, int n_dchars) { return .memcmp(s1, s2, n_dchars); }
    static int isDigit(_dchar c) { return '0' <= c && c <= '9'; }
    static _dchar *chr(_dchar *p, int c) { return strchr(p, c); }
    static _dchar *rchr(_dchar *p, int c) { return strrchr(p, c); }
    static _dchar *memchr(_dchar *p, int c, int count)
        { return cast(_dchar *).memchr(p, c, count); }
    static _dchar *cpy(_dchar *s1, _dchar *s2) { return strcpy(s1, s2); }
    static _dchar *str(_dchar *s1, _dchar *s2) { return strstr(s1, s2); }
    static hash_t calcHash(const _dchar *str, size_t len);

    // Case insensitive versions
    static int icmp(_dchar *s1, _dchar *s2) { return stricmp(s1, s2); }
    static int memicmp(const _dchar *s1, const _dchar *s2, int n_dchars) { return .memicmp(s1, s2, n_dchars); }
    static hash_t icalcHash(const _dchar *str, size_t len);
};
