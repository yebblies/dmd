
module root.aav;

extern(C++)
{
    alias void* Value;
    alias void* Key;

    struct AA;

    extern size_t _aaLen(AA* aa);
    extern Value* _aaGet(AA** aa, Key key);
    extern Value _aaGetRvalue(AA* aa, Key key);
    extern void _aaRehash(AA** paa);
}
