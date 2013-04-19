
extern(C++)
{
    // Special

    void func_void_void() {}
    void func_void_int_varargs(int a, ...) {}
}

version (Windows)
{
    static assert(func_void_void.mangleof == "?func_void_void@@YAXXZ");
    static assert(func_void_int_varargs.mangleof == "?func_void_int_varargs@@YAXHZZ");
}

string genbasictypes()
{
    string r;
    auto types = ["bool", "char", "wchar", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "real", "ifloat", "idouble", "ireal", "cfloat", "cdouble", "creal"];
    auto mangle = ["_N", "D", "_Y", "C", "E", "F", "G", "H", "I", "_J", "_K", "M", "N", "_Z", "_R", "_S", "_T", "_U", "_V", "_W"];
    auto compress = [true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true];
    assert(types.length == mangle.length);
    assert(types.length == compress.length);
    foreach(i, t; types)
    {
        r ~= "extern(C++) " ~ t ~ " func_" ~ t ~ "_void() { return cast(" ~ t ~ ")0; }\n";
        r ~= "static assert(func_" ~ t ~ "_void.mangleof == \"?func_" ~ t ~ "_void@@YA" ~ mangle[i] ~ "XZ\");\n";

        r ~= "extern(C++) void func_void_" ~ t ~ "(" ~ t ~ " a) { assert(a == cast(" ~ t ~ ")0); }\n";
        r ~= "static assert(func_void_" ~ t ~ ".mangleof == \"?func_void_" ~ t ~ "@@YAX" ~ mangle[i] ~ "@Z\");\n";

        r ~= "extern(C++) " ~ t ~ " func_" ~ t ~ "_" ~ t ~ "(" ~ t ~ " a) { return a; }\n";
        r ~= "static assert(func_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ "@Z\");\n";

        r ~= "extern(C++) " ~ t ~ " func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "(" ~ t ~ " a, " ~ t ~ " b, " ~ t ~ " c) { return a; }\n";
        if (compress[i])
            r ~= "static assert(func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ "00@Z\");\n";
        else
            r ~= "static assert(func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ mangle[i] ~ mangle[i] ~ "@Z\");\n";
    }
    return r;
}

string genpointertypes()
{
    string r;
    auto types = ["void", "bool", "char", "wchar", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "real", "ifloat", "idouble", "ireal", "cfloat", "cdouble", "creal"];
    auto mangle = ["X", "_N", "D", "_Y", "C", "E", "F", "G", "H", "I", "_J", "_K", "M", "N", "_Z", "_R", "_S", "_T", "_U", "_V", "_W"];
    assert(types.length == mangle.length);
    foreach(i, t; types)
    {
        r ~= "extern(C++) " ~ t ~ "* func_" ~ t ~ "ptr_void() { return null; }\n";
        r ~= "static assert(func_" ~ t ~ "ptr_void.mangleof == \"?func_" ~ t ~ "ptr_void@@YAPA" ~ mangle[i] ~ "XZ\");\n";

        r ~= "extern(C++) void func_void_" ~ t ~ "ptr(" ~ t ~ "* a) { assert(a == null); }\n";
        r ~= "static assert(func_void_" ~ t ~ "ptr.mangleof == \"?func_void_" ~ t ~ "ptr@@YAXPA" ~ mangle[i] ~ "@Z\");\n";

        r ~= "extern(C++) " ~ t ~ "* func_" ~ t ~ "ptr_" ~ t ~ "ptr(" ~ t ~ "* a) { return a; }\n";
        r ~= "static assert(func_" ~ t ~ "ptr_" ~ t ~ "ptr.mangleof == \"?func_" ~ t ~ "ptr_" ~ t ~ "ptr@@YAPA" ~ mangle[i] ~ "PA" ~ mangle[i] ~ "@Z\");\n";

        r ~= "extern(C++) " ~ t ~ "* func_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr(" ~ t ~ "* a, " ~ t ~ "* b, " ~ t ~ "* c) { return a; }\n";
        r ~= "static assert(func_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr.mangleof == \"?func_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr_" ~ t ~ "ptr@@YAPA" ~ mangle[i] ~ "PA" ~ mangle[i] ~ "00@Z\");\n";
    }
    return r;
}

string genconstbasictypes()
{
    string r;
    auto types = ["bool", "char", "wchar", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double", "real", "ifloat", "idouble", "ireal", "cfloat", "cdouble", "creal"];
    auto mangle = ["_N", "D", "_Y", "C", "E", "F", "G", "H", "I", "_J", "_K", "M", "N", "_Z", "_R", "_S", "_T", "_U", "_V", "_W"];
    auto compress = [true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true];
    assert(types.length == mangle.length);
    assert(types.length == compress.length);
    foreach(i, t; types)
    {
        r ~= "extern(C++) const(" ~ t ~ ") func_const" ~ t ~ "_void() { return cast(const(" ~ t ~ "))0; }\n";
        r ~= "static assert(func_const" ~ t ~ "_void.mangleof == \"?func_const" ~ t ~ "_void@@YA" ~ mangle[i] ~ "XZ\");\n";

        r ~= "extern(C++) void func_void_const" ~ t ~ "(const(" ~ t ~ ") a) { assert(a == cast(const(" ~ t ~ "))0); }\n";
        r ~= "static assert(func_void_const" ~ t ~ ".mangleof == \"?func_void_const" ~ t ~ "@@YAX" ~ mangle[i] ~ "@Z\");\n";

        /*r ~= "extern(C++) " ~ t ~ " func_" ~ t ~ "_" ~ t ~ "(" ~ t ~ " a) { return a; }\n";
        r ~= "static assert(func_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ "@Z\");\n";

        r ~= "extern(C++) " ~ t ~ " func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "(" ~ t ~ " a, " ~ t ~ " b, " ~ t ~ " c) { return a; }\n";
        if (compress[i])
            r ~= "static assert(func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ "00@Z\");\n";
        else
            r ~= "static assert(func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ ".mangleof == \"?func_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "_" ~ t ~ "@@YA" ~ mangle[i] ~ mangle[i] ~ mangle[i] ~ mangle[i] ~ "@Z\");\n";
            */
    }
    return r;
}

mixin(genbasictypes());
mixin(genpointertypes());
mixin(genconstbasictypes());

// Unsupported types
// dchar

extern(C++) void xmain();

void main()
{
    xmain();
}

/+

void main()
{
    
}

version (Windows) extern(C++)
{
    bool g_i1;
    byte g_i8;
    ubyte g_u8;
    short g_i16;
    ushort g_u16;
    int g_i32;
    uint g_u32;
    long g_i64;
    ulong g_u64;
    char g_c8;
    wchar g_c16;
    dchar g_c32;
    float g_f32;
    double g_f64;
    real g_f80;
    ifloat g_if32;
    idouble g_if64;
    ireal g_if80;
    cfloat g_cf32;
    cdouble g_cf64;
    creal g_cf80;

    static assert(g_i1.mangleof == "?g_i1@@3_NA");
    static assert(g_i8.mangleof == "?g_i8@@3CA");
    static assert(g_u8.mangleof == "?g_u8@@3EA");
    static assert(g_i16.mangleof == "?g_i16@@3FA");
    static assert(g_u16.mangleof == "?g_u16@@3GA");
    static assert(g_i32.mangleof == "?g_i32@@3HA");
    static assert(g_u32.mangleof == "?g_u32@@3IA");
    static assert(g_i64.mangleof == "?g_i64@@3_JA");
    static assert(g_u64.mangleof == "?g_u64@@3_KA");
    static assert(g_c8.mangleof == "?g_c8@@3DA");
    static assert(g_c16.mangleof == "?g_c16@@3_YA");
    static assert(g_c32.mangleof == "?g_c32@@3KA");
    static assert(g_f32.mangleof == "?g_f32@@3MA");
    static assert(g_f64.mangleof == "?g_f64@@3NA");
    static assert(g_f80.mangleof == "?g_f80@@3_ZA");
    static assert(g_if32.mangleof == "?g_if32@@3_RA");
    static assert(g_if64.mangleof == "?g_if64@@3_SA");
    static assert(g_if80.mangleof == "?g_if80@@3_TA");
    static assert(g_cf32.mangleof == "?g_cf32@@3_UA");
    static assert(g_cf64.mangleof == "?g_cf64@@3_VA");
    static assert(g_cf80.mangleof == "?g_cf80@@3_WA");

    const
    {
        bool gc_i1;
        byte gc_i8;
        ubyte gc_u8;
        short gc_i16;
        ushort gc_u16;
        int gc_i32;
        uint gc_u32;
        long gc_i64;
        ulong gc_u64;
        char gc_c8;
        wchar gc_c16;
        dchar gc_c32;
        float gc_f32;
        double gc_f64;
        real gc_f80;
        ifloat gc_if32;
        idouble gc_if64;
        ireal gc_if80;
        cfloat gc_cf32;
        cdouble gc_cf64;
        creal gc_cf80;
    }

    static assert(gc_i1.mangleof == "?gc_i1@@3_NB");
    static assert(gc_i8.mangleof == "?gc_i8@@3CB");
    static assert(gc_u8.mangleof == "?gc_u8@@3EB");
    static assert(gc_i16.mangleof == "?gc_i16@@3FB");
    static assert(gc_u16.mangleof == "?gc_u16@@3GB");
    static assert(gc_i32.mangleof == "?gc_i32@@3HB");
    static assert(gc_u32.mangleof == "?gc_u32@@3IB");
    static assert(gc_i64.mangleof == "?gc_i64@@3_JB");
    static assert(gc_u64.mangleof == "?gc_u64@@3_KB");
    static assert(gc_c8.mangleof == "?gc_c8@@3DB");
    static assert(gc_c16.mangleof == "?gc_c16@@3_YB");
    static assert(gc_c32.mangleof == "?gc_c32@@3KB");
    static assert(gc_f32.mangleof == "?gc_f32@@3MB");
    static assert(gc_f64.mangleof == "?gc_f64@@3NB");
    static assert(gc_f80.mangleof == "?gc_f80@@3_ZB");
    static assert(gc_if32.mangleof == "?gc_if32@@3_RB");
    static assert(gc_if64.mangleof == "?gc_if64@@3_SB");
    static assert(gc_if80.mangleof == "?gc_if80@@3_TB");
    static assert(gc_cf32.mangleof == "?gc_cf32@@3_UB");
    static assert(gc_cf64.mangleof == "?gc_cf64@@3_VB");
    static assert(gc_cf80.mangleof == "?gc_cf80@@3_WB");

    void* g_pv;
    bool* g_pi1;
    byte* g_pi8;
    ubyte* g_pu8;
    short* g_pi16;
    ushort* g_pu16;
    int* g_pi32;
    uint* g_pu32;
    long* g_pi64;
    ulong* g_pu64;
    char* g_pc8;
    wchar* g_pc16;
    dchar* g_pc32;
    float* g_pf32;
    double* g_pf64;
    real* g_pf80;
    ifloat* g_pif32;
    idouble* g_pif64;
    ireal* g_pif80;
    cfloat* g_pcf32;
    cdouble* g_pcf64;
    creal* g_pcf80;

    static assert(g_pv.mangleof == "?g_pv@@3PAXA");
    static assert(g_pi1.mangleof == "?g_pi1@@3PA_NA");
    static assert(g_pi8.mangleof == "?g_pi8@@3PACA");
    static assert(g_pu8.mangleof == "?g_pu8@@3PAEA");
    static assert(g_pi16.mangleof == "?g_pi16@@3PAFA");
    static assert(g_pu16.mangleof == "?g_pu16@@3PAGA");
    static assert(g_pi32.mangleof == "?g_pi32@@3PAHA");
    static assert(g_pu32.mangleof == "?g_pu32@@3PAIA");
    static assert(g_pi64.mangleof == "?g_pi64@@3PA_JA");
    static assert(g_pu64.mangleof == "?g_pu64@@3PA_KA");
    static assert(g_pc8.mangleof == "?g_pc8@@3PADA");
    static assert(g_pc16.mangleof == "?g_pc16@@3PA_YA");
    static assert(g_pc32.mangleof == "?g_pc32@@3PAKA");
    static assert(g_pf32.mangleof == "?g_pf32@@3PAMA");
    static assert(g_pf64.mangleof == "?g_pf64@@3PANA");
    static assert(g_pf80.mangleof == "?g_pf80@@3PA_ZA");
    static assert(g_pif32.mangleof == "?g_pif32@@3PA_RA");
    static assert(g_pif64.mangleof == "?g_pif64@@3PA_SA");
    static assert(g_pif80.mangleof == "?g_pif80@@3PA_TA");
    static assert(g_pcf32.mangleof == "?g_pcf32@@3PA_UA");
    static assert(g_pcf64.mangleof == "?g_pcf64@@3PA_VA");
    static assert(g_pcf80.mangleof == "?g_pcf80@@3PA_WA");

    const
    {
        void* gc_pv;
        bool* gc_pi1;
        byte* gc_pi8;
        ubyte* gc_pu8;
        short* gc_pi16;
        ushort* gc_pu16;
        int* gc_pi32;
        uint* gc_pu32;
        long* gc_pi64;
        ulong* gc_pu64;
        char* gc_pc8;
        wchar* gc_pc16;
        dchar* gc_pc32;
        float* gc_pf32;
        double* gc_pf64;
        real* gc_pf80;
        ifloat* gc_pif32;
        idouble* gc_pif64;
        ireal* gc_pif80;
        cfloat* gc_pcf32;
        cdouble* gc_pcf64;
        creal* gc_pcf80;
    }

    static assert(gc_pv.mangleof == "?gc_pv@@3QBXB");
    static assert(gc_pi1.mangleof == "?gc_pi1@@3QB_NB");
    static assert(gc_pi8.mangleof == "?gc_pi8@@3QBCB");
    static assert(gc_pu8.mangleof == "?gc_pu8@@3QBEB");
    static assert(gc_pi16.mangleof == "?gc_pi16@@3QBFB");
    static assert(gc_pu16.mangleof == "?gc_pu16@@3QBGB");
    static assert(gc_pi32.mangleof == "?gc_pi32@@3QBHB");
    static assert(gc_pu32.mangleof == "?gc_pu32@@3QBIB");
    static assert(gc_pi64.mangleof == "?gc_pi64@@3QB_JB");
    static assert(gc_pu64.mangleof == "?gc_pu64@@3QB_KB");
    static assert(gc_pc8.mangleof == "?gc_pc8@@3QBDB");
    static assert(gc_pc16.mangleof == "?gc_pc16@@3QB_YB");
    static assert(gc_pc32.mangleof == "?gc_pc32@@3QBKB");
    static assert(gc_pf32.mangleof == "?gc_pf32@@3QBMB");
    static assert(gc_pf64.mangleof == "?gc_pf64@@3QBNB");
    static assert(gc_pf80.mangleof == "?gc_pf80@@3QB_ZB");
    static assert(gc_pif32.mangleof == "?gc_pif32@@3QB_RB");
    static assert(gc_pif64.mangleof == "?gc_pif64@@3QB_SB");
    static assert(gc_pif80.mangleof == "?gc_pif80@@3QB_TB");
    static assert(gc_pcf32.mangleof == "?gc_pcf32@@3QB_UB");
    static assert(gc_pcf64.mangleof == "?gc_pcf64@@3QB_VB");
    static assert(gc_pcf80.mangleof == "?gc_pcf80@@3QB_WB");

    const(void)* gtc_pv;
    const(bool)* gtc_pi1;
    const(byte)* gtc_pi8;
    const(ubyte)* gtc_pu8;
    const(short)* gtc_pi16;
    const(ushort)* gtc_pu16;
    const(int)* gtc_pi32;
    const(uint)* gtc_pu32;
    const(long)* gtc_pi64;
    const(ulong)* gtc_pu64;
    const(char)* gtc_pc8;
    const(wchar)* gtc_pc16;
    const(dchar)* gtc_pc32;
    const(float)* gtc_pf32;
    const(double)* gtc_pf64;
    const(real)* gtc_pf80;
    const(ifloat)* gtc_pif32;
    const(idouble)* gtc_pif64;
    const(ireal)* gtc_pif80;
    const(cfloat)* gtc_pcf32;
    const(cdouble)* gtc_pcf64;
    const(creal)* gtc_pcf80;

    static assert(gtc_pv.mangleof == "?gtc_pv@@3PBXB");
    static assert(gtc_pi1.mangleof == "?gtc_pi1@@3PB_NB");
    static assert(gtc_pi8.mangleof == "?gtc_pi8@@3PBCB");
    static assert(gtc_pu8.mangleof == "?gtc_pu8@@3PBEB");
    static assert(gtc_pi16.mangleof == "?gtc_pi16@@3PBFB");
    static assert(gtc_pu16.mangleof == "?gtc_pu16@@3PBGB");
    static assert(gtc_pi32.mangleof == "?gtc_pi32@@3PBHB");
    static assert(gtc_pu32.mangleof == "?gtc_pu32@@3PBIB");
    static assert(gtc_pi64.mangleof == "?gtc_pi64@@3PB_JB");
    static assert(gtc_pu64.mangleof == "?gtc_pu64@@3PB_KB");
    static assert(gtc_pc8.mangleof == "?gtc_pc8@@3PBDB");
    static assert(gtc_pc16.mangleof == "?gtc_pc16@@3PB_YB");
    static assert(gtc_pc32.mangleof == "?gtc_pc32@@3PBKB");
    static assert(gtc_pf32.mangleof == "?gtc_pf32@@3PBMB");
    static assert(gtc_pf64.mangleof == "?gtc_pf64@@3PBNB");
    static assert(gtc_pf80.mangleof == "?gtc_pf80@@3PB_ZB");
    static assert(gtc_pif32.mangleof == "?gtc_pif32@@3PB_RB");
    static assert(gtc_pif64.mangleof == "?gtc_pif64@@3PB_SB");
    static assert(gtc_pif80.mangleof == "?gtc_pif80@@3PB_TB");
    static assert(gtc_pcf32.mangleof == "?gtc_pcf32@@3PB_UB");
    static assert(gtc_pcf64.mangleof == "?gtc_pcf64@@3PB_VB");
    static assert(gtc_pcf80.mangleof == "?gtc_pcf80@@3PB_WB");

    void** g_ppv;
    bool** g_ppi1;
    byte** g_ppi8;
    ubyte** g_ppu8;
    short** g_ppi16;
    ushort** g_ppu16;
    int** g_ppi32;
    uint** g_ppu32;
    long** g_ppi64;
    ulong** g_ppu64;
    char** g_ppc8;
    wchar** g_ppc16;
    dchar** g_ppc32;
    float** g_ppf32;
    double** g_ppf64;
    real** g_ppf80;
    ifloat** g_ppif32;
    idouble** g_ppif64;
    ireal** g_ppif80;
    cfloat** g_ppcf32;
    cdouble** g_ppcf64;
    creal** g_ppcf80;

    static assert(g_ppv.mangleof == "?g_ppv@@3PAPAXA");
    static assert(g_ppi1.mangleof == "?g_ppi1@@3PAPA_NA");
    static assert(g_ppi8.mangleof == "?g_ppi8@@3PAPACA");
    static assert(g_ppu8.mangleof == "?g_ppu8@@3PAPAEA");
    static assert(g_ppi16.mangleof == "?g_ppi16@@3PAPAFA");
    static assert(g_ppu16.mangleof == "?g_ppu16@@3PAPAGA");
    static assert(g_ppi32.mangleof == "?g_ppi32@@3PAPAHA");
    static assert(g_ppu32.mangleof == "?g_ppu32@@3PAPAIA");
    static assert(g_ppi64.mangleof == "?g_ppi64@@3PAPA_JA");
    static assert(g_ppu64.mangleof == "?g_ppu64@@3PAPA_KA");
    static assert(g_ppc8.mangleof == "?g_ppc8@@3PAPADA");
    static assert(g_ppc16.mangleof == "?g_ppc16@@3PAPA_YA");
    static assert(g_ppc32.mangleof == "?g_ppc32@@3PAPAKA");
    static assert(g_ppf32.mangleof == "?g_ppf32@@3PAPAMA");
    static assert(g_ppf64.mangleof == "?g_ppf64@@3PAPANA");
    static assert(g_ppf80.mangleof == "?g_ppf80@@3PAPA_ZA");
    static assert(g_ppif32.mangleof == "?g_ppif32@@3PAPA_RA");
    static assert(g_ppif64.mangleof == "?g_ppif64@@3PAPA_SA");
    static assert(g_ppif80.mangleof == "?g_ppif80@@3PAPA_TA");
    static assert(g_ppcf32.mangleof == "?g_ppcf32@@3PAPA_UA");
    static assert(g_ppcf64.mangleof == "?g_ppcf64@@3PAPA_VA");
    static assert(g_ppcf80.mangleof == "?g_ppcf80@@3PAPA_WA");

    const(void)** gc_ppv;
    const(bool)** gc_ppi1;
    const(byte)** gc_ppi8;
    const(ubyte)** gc_ppu8;
    const(short)** gc_ppi16;
    const(ushort)** gc_ppu16;
    const(int)** gc_ppi32;
    const(uint)** gc_ppu32;
    const(long)** gc_ppi64;
    const(ulong)** gc_ppu64;
    const(char)** gc_ppc8;
    const(wchar)** gc_ppc16;
    const(dchar)** gc_ppc32;
    const(float)** gc_ppf32;
    const(double)** gc_ppf64;
    const(real)** gc_ppf80;
    const(ifloat)** gc_ppif32;
    const(idouble)** gc_ppif64;
    const(ireal)** gc_ppif80;
    const(cfloat)** gc_ppcf32;
    const(cdouble)** gc_ppcf64;
    const(creal)** gc_ppcf80;

    static assert(gc_ppv.mangleof == "?gc_ppv@@3PAPBXA");
    static assert(gc_ppi1.mangleof == "?gc_ppi1@@3PAPB_NA");
    static assert(gc_ppi8.mangleof == "?gc_ppi8@@3PAPBCA");
    static assert(gc_ppu8.mangleof == "?gc_ppu8@@3PAPBEA");
    static assert(gc_ppi16.mangleof == "?gc_ppi16@@3PAPBFA");
    static assert(gc_ppu16.mangleof == "?gc_ppu16@@3PAPBGA");
    static assert(gc_ppi32.mangleof == "?gc_ppi32@@3PAPBHA");
    static assert(gc_ppu32.mangleof == "?gc_ppu32@@3PAPBIA");
    static assert(gc_ppi64.mangleof == "?gc_ppi64@@3PAPB_JA");
    static assert(gc_ppu64.mangleof == "?gc_ppu64@@3PAPB_KA");
    static assert(gc_ppc8.mangleof == "?gc_ppc8@@3PAPBDA");
    static assert(gc_ppc16.mangleof == "?gc_ppc16@@3PAPB_YA");
    static assert(gc_ppc32.mangleof == "?gc_ppc32@@3PAPBKA");
    static assert(gc_ppf32.mangleof == "?gc_ppf32@@3PAPBMA");
    static assert(gc_ppf64.mangleof == "?gc_ppf64@@3PAPBNA");
    static assert(gc_ppf80.mangleof == "?gc_ppf80@@3PAPB_ZA");
    static assert(gc_ppif32.mangleof == "?gc_ppif32@@3PAPB_RA");
    static assert(gc_ppif64.mangleof == "?gc_ppif64@@3PAPB_SA");
    static assert(gc_ppif80.mangleof == "?gc_ppif80@@3PAPB_TA");
    static assert(gc_ppcf32.mangleof == "?gc_ppcf32@@3PAPB_UA");
    static assert(gc_ppcf64.mangleof == "?gc_ppcf64@@3PAPB_VA");
    static assert(gc_ppcf80.mangleof == "?gc_ppcf80@@3PAPB_WA");

    const(void*)* gcc_ppv;
    const(bool*)* gcc_ppi1;
    const(byte*)* gcc_ppi8;
    const(ubyte*)* gcc_ppu8;
    const(short*)* gcc_ppi16;
    const(ushort*)* gcc_ppu16;
    const(int*)* gcc_ppi32;
    const(uint*)* gcc_ppu32;
    const(long*)* gcc_ppi64;
    const(ulong*)* gcc_ppu64;
    const(char*)* gcc_ppc8;
    const(wchar*)* gcc_ppc16;
    const(dchar*)* gcc_ppc32;
    const(float*)* gcc_ppf32;
    const(double*)* gcc_ppf64;
    const(real*)* gcc_ppf80;
    const(ifloat*)* gcc_ppif32;
    const(idouble*)* gcc_ppif64;
    const(ireal*)* gcc_ppif80;
    const(cfloat*)* gcc_ppcf32;
    const(cdouble*)* gcc_ppcf64;
    const(creal*)* gcc_ppcf80;

    static assert(gcc_ppv.mangleof == "?gcc_ppv@@3PBQBXB");
    static assert(gcc_ppi1.mangleof == "?gcc_ppi1@@3PBQB_NB");
    static assert(gcc_ppi8.mangleof == "?gcc_ppi8@@3PBQBCB");
    static assert(gcc_ppu8.mangleof == "?gcc_ppu8@@3PBQBEB");
    static assert(gcc_ppi16.mangleof == "?gcc_ppi16@@3PBQBFB");
    static assert(gcc_ppu16.mangleof == "?gcc_ppu16@@3PBQBGB");
    static assert(gcc_ppi32.mangleof == "?gcc_ppi32@@3PBQBHB");
    static assert(gcc_ppu32.mangleof == "?gcc_ppu32@@3PBQBIB");
    static assert(gcc_ppi64.mangleof == "?gcc_ppi64@@3PBQB_JB");
    static assert(gcc_ppu64.mangleof == "?gcc_ppu64@@3PBQB_KB");
    static assert(gcc_ppc8.mangleof == "?gcc_ppc8@@3PBQBDB");
    static assert(gcc_ppc16.mangleof == "?gcc_ppc16@@3PBQB_YB");
    static assert(gcc_ppc32.mangleof == "?gcc_ppc32@@3PBQBKB");
    static assert(gcc_ppf32.mangleof == "?gcc_ppf32@@3PBQBMB");
    static assert(gcc_ppf64.mangleof == "?gcc_ppf64@@3PBQBNB");
    static assert(gcc_ppf80.mangleof == "?gcc_ppf80@@3PBQB_ZB");
    static assert(gcc_ppif32.mangleof == "?gcc_ppif32@@3PBQB_RB");
    static assert(gcc_ppif64.mangleof == "?gcc_ppif64@@3PBQB_SB");
    static assert(gcc_ppif80.mangleof == "?gcc_ppif80@@3PBQB_TB");
    static assert(gcc_ppcf32.mangleof == "?gcc_ppcf32@@3PBQB_UB");
    static assert(gcc_ppcf64.mangleof == "?gcc_ppcf64@@3PBQB_VB");
    static assert(gcc_ppcf80.mangleof == "?gcc_ppcf80@@3PBQB_WB");

    const(void**) gccc_ppv;
    const(bool**) gccc_ppi1;
    const(byte**) gccc_ppi8;
    const(ubyte**) gccc_ppu8;
    const(short**) gccc_ppi16;
    const(ushort**) gccc_ppu16;
    const(int**) gccc_ppi32;
    const(uint**) gccc_ppu32;
    const(long**) gccc_ppi64;
    const(ulong**) gccc_ppu64;
    const(char**) gccc_ppc8;
    const(wchar**) gccc_ppc16;
    const(dchar**) gccc_ppc32;
    const(float**) gccc_ppf32;
    const(double**) gccc_ppf64;
    const(real**) gccc_ppf80;
    const(ifloat**) gccc_ppif32;
    const(idouble**) gccc_ppif64;
    const(ireal**) gccc_ppif80;
    const(cfloat**) gccc_ppcf32;
    const(cdouble**) gccc_ppcf64;
    const(creal**) gccc_ppcf80;

    static assert(gccc_ppv.mangleof == "?gccc_ppv@@3QBQBXB");
    static assert(gccc_ppi1.mangleof == "?gccc_ppi1@@3QBQB_NB");
    static assert(gccc_ppi8.mangleof == "?gccc_ppi8@@3QBQBCB");
    static assert(gccc_ppu8.mangleof == "?gccc_ppu8@@3QBQBEB");
    static assert(gccc_ppi16.mangleof == "?gccc_ppi16@@3QBQBFB");
    static assert(gccc_ppu16.mangleof == "?gccc_ppu16@@3QBQBGB");
    static assert(gccc_ppi32.mangleof == "?gccc_ppi32@@3QBQBHB");
    static assert(gccc_ppu32.mangleof == "?gccc_ppu32@@3QBQBIB");
    static assert(gccc_ppi64.mangleof == "?gccc_ppi64@@3QBQB_JB");
    static assert(gccc_ppu64.mangleof == "?gccc_ppu64@@3QBQB_KB");
    static assert(gccc_ppc8.mangleof == "?gccc_ppc8@@3QBQBDB");
    static assert(gccc_ppc16.mangleof == "?gccc_ppc16@@3QBQB_YB");
    static assert(gccc_ppc32.mangleof == "?gccc_ppc32@@3QBQBKB");
    static assert(gccc_ppf32.mangleof == "?gccc_ppf32@@3QBQBMB");
    static assert(gccc_ppf64.mangleof == "?gccc_ppf64@@3QBQBNB");
    static assert(gccc_ppf80.mangleof == "?gccc_ppf80@@3QBQB_ZB");
    static assert(gccc_ppif32.mangleof == "?gccc_ppif32@@3QBQB_RB");
    static assert(gccc_ppif64.mangleof == "?gccc_ppif64@@3QBQB_SB");
    static assert(gccc_ppif80.mangleof == "?gccc_ppif80@@3QBQB_TB");
    static assert(gccc_ppcf32.mangleof == "?gccc_ppcf32@@3QBQB_UB");
    static assert(gccc_ppcf64.mangleof == "?gccc_ppcf64@@3QBQB_VB");
    static assert(gccc_ppcf80.mangleof == "?gccc_ppcf80@@3QBQB_WB");

    void f_v_v();
    static assert(f_v_v.mangleof == "?f_v_v@@YAXXZ");

    void f_v_i1(bool);
    void f_v_i8(byte);
    void f_v_u8(ubyte);
    void f_v_i16(short);
    void f_v_u16(ushort);
    void f_v_i32(int);
    void f_v_u32(uint);
    void f_v_i64(long);
    void f_v_u64(ulong);
    void f_v_c8(char);
    void f_v_c16(wchar);
    void f_v_c32(dchar);
    void f_v_f32(float);
    void f_v_f64(double);
    void f_v_f80(real);
    void f_v_if32(ifloat);
    void f_v_if64(idouble);
    void f_v_if80(ireal);
    void f_v_cf32(cfloat);
    void f_v_cf64(cdouble);
    void f_v_cf80(creal);

    static assert(f_v_i1.mangleof == "?f_v_i1@@YAX_N@Z");
    static assert(f_v_i8.mangleof == "?f_v_i8@@YAXC@Z");
    static assert(f_v_u8.mangleof == "?f_v_u8@@YAXE@Z");
    static assert(f_v_i16.mangleof == "?f_v_i16@@YAXF@Z");
    static assert(f_v_u16.mangleof == "?f_v_u16@@YAXG@Z");
    static assert(f_v_i32.mangleof == "?f_v_i32@@YAXH@Z");
    static assert(f_v_u32.mangleof == "?f_v_u32@@YAXI@Z");
    static assert(f_v_i64.mangleof == "?f_v_i64@@YAX_J@Z");
    static assert(f_v_u64.mangleof == "?f_v_u64@@YAX_K@Z");
    static assert(f_v_c8.mangleof == "?f_v_c8@@YAXD@Z");
    static assert(f_v_c16.mangleof == "?f_v_c16@@YAX_Y@Z");
    static assert(f_v_c32.mangleof == "?f_v_c32@@YAXK@Z");
    static assert(f_v_f32.mangleof == "?f_v_f32@@YAXM@Z");
    static assert(f_v_f64.mangleof == "?f_v_f64@@YAXN@Z");
    static assert(f_v_f80.mangleof == "?f_v_f80@@YAX_Z@Z");
    static assert(f_v_if32.mangleof == "?f_v_if32@@YAX_R@Z");
    static assert(f_v_if64.mangleof == "?f_v_if64@@YAX_S@Z");
    static assert(f_v_if80.mangleof == "?f_v_if80@@YAX_T@Z");
    static assert(f_v_cf32.mangleof == "?f_v_cf32@@YAX_U@Z");
    static assert(f_v_cf64.mangleof == "?f_v_cf64@@YAX_V@Z");
    static assert(f_v_cf80.mangleof == "?f_v_cf80@@YAX_W@Z");

    void f_v_i1_i1(bool, bool);
    void f_v_i8_i8(byte, byte);
    void f_v_u8_u8(ubyte, ubyte);
    void f_v_i16_i16(short, short);
    void f_v_u16_u16(ushort, ushort);
    void f_v_i32_i32(int, int);
    void f_v_u32_u32(uint, uint);
    void f_v_i64_i64(long, long);
    void f_v_u64_u64(ulong, ulong);
    void f_v_c8_c8(char, char);
    void f_v_c16_c16(wchar, wchar);
    void f_v_c32_c32(dchar, dchar);
    void f_v_f32_f32(float, float);
    void f_v_f64_f64(double, double);
    void f_v_f80_f80(real, real);
    void f_v_if32_if32(ifloat, ifloat);
    void f_v_if64_if64(idouble, idouble);
    void f_v_if80_if80(ireal, ireal);
    void f_v_cf32_cf32(cfloat, cfloat);
    void f_v_cf64_cf64(cdouble, cdouble);
    void f_v_cf80_cf80(creal, creal);

    static assert(f_v_i1_i1.mangleof == "?f_v_i1_i1@@YAX_N0@Z");
    static assert(f_v_i8_i8.mangleof == "?f_v_i8_i8@@YAXCC@Z");
    static assert(f_v_u8_u8.mangleof == "?f_v_u8_u8@@YAXEE@Z");
    static assert(f_v_i16_i16.mangleof == "?f_v_i16_i16@@YAXFF@Z");
    static assert(f_v_u16_u16.mangleof == "?f_v_u16_u16@@YAXGG@Z");
    static assert(f_v_i32_i32.mangleof == "?f_v_i32_i32@@YAXHH@Z");
    static assert(f_v_u32_u32.mangleof == "?f_v_u32_u32@@YAXII@Z");
    static assert(f_v_i64_i64.mangleof == "?f_v_i64_i64@@YAX_J_J@Z");
    static assert(f_v_u64_u64.mangleof == "?f_v_u64_u64@@YAX_K_K@Z");
    static assert(f_v_c8_c8.mangleof == "?f_v_c8_c8@@YAXDD@Z");
    static assert(f_v_c16_c16.mangleof == "?f_v_c16_c16@@YAX_Y_Y@Z");
    static assert(f_v_c32_c32.mangleof == "?f_v_c32_c32@@YAXKK@Z");
    static assert(f_v_f32_f32.mangleof == "?f_v_f32_f32@@YAXMM@Z");
    static assert(f_v_f64_f64.mangleof == "?f_v_f64_f64@@YAXNN@Z");
    static assert(f_v_f80_f80.mangleof == "?f_v_f80_f80@@YAX_Z_Z@Z");
    static assert(f_v_if32_if32.mangleof == "?f_v_if32_if32@@YAX_R0@Z");
    static assert(f_v_if64_if64.mangleof == "?f_v_if64_if64@@YAX_S0@Z");
    static assert(f_v_if80_if80.mangleof == "?f_v_if80_if80@@YAX_T0@Z");
    static assert(f_v_cf32_cf32.mangleof == "?f_v_cf32_cf32@@YAX_U0@Z");
    static assert(f_v_cf64_cf64.mangleof == "?f_v_cf64_cf64@@YAX_V0@Z");
    static assert(f_v_cf80_cf80.mangleof == "?f_v_cf80_cf80@@YAX_W0@Z");

    void f_v_i1_i1_i1(bool, bool, bool);
    void f_v_i8_i8_i8(byte, byte, byte);
    void f_v_u8_u8_u8(ubyte, ubyte, ubyte);
    void f_v_i16_i16_i16(short, short, short);
    void f_v_u16_u16_u16(ushort, ushort, ushort);
    void f_v_i32_i32_i32(int, int, int);
    void f_v_u32_u32_u32(uint, uint, uint);
    void f_v_i64_i64_i64(long, long, long);
    void f_v_u64_u64_u64(ulong, ulong, ulong);
    void f_v_c8_c8_c8(char, char, char);
    void f_v_c16_c16_c16(wchar, wchar, wchar);
    void f_v_c32_c32_c32(dchar, dchar, dchar);
    void f_v_f32_f32_f32(float, float, float);
    void f_v_f64_f64_f64(double, double, double);
    void f_v_f80_f80_f80(real, real, real);
    void f_v_if32_if32_if32(ifloat, ifloat, ifloat);
    void f_v_if64_if64_if64(idouble, idouble, idouble);
    void f_v_if80_if80_if80(ireal, ireal, ireal);
    void f_v_cf32_cf32_cf32(cfloat, cfloat, cfloat);
    void f_v_cf64_cf64_cf64(cdouble, cdouble, cdouble);
    void f_v_cf80_cf80_cf80(creal, creal, creal);

    static assert(f_v_i1_i1_i1.mangleof == "?f_v_i1_i1_i1@@YAX_N00@Z");
    static assert(f_v_i8_i8_i8.mangleof == "?f_v_i8_i8_i8@@YAXCCC@Z");
    static assert(f_v_u8_u8_u8.mangleof == "?f_v_u8_u8_u8@@YAXEEE@Z");
    static assert(f_v_i16_i16_i16.mangleof == "?f_v_i16_i16_i16@@YAXFFF@Z");
    static assert(f_v_u16_u16_u16.mangleof == "?f_v_u16_u16_u16@@YAXGGG@Z");
    static assert(f_v_i32_i32_i32.mangleof == "?f_v_i32_i32_i32@@YAXHHH@Z");
    static assert(f_v_u32_u32_u32.mangleof == "?f_v_u32_u32_u32@@YAXIII@Z");
    static assert(f_v_i64_i64_i64.mangleof == "?f_v_i64_i64_i64@@YAX_J_J_J@Z");
    static assert(f_v_u64_u64_u64.mangleof == "?f_v_u64_u64_u64@@YAX_K_K_K@Z");
    static assert(f_v_c8_c8_c8.mangleof == "?f_v_c8_c8_c8@@YAXDDD@Z");
    static assert(f_v_c16_c16_c16.mangleof == "?f_v_c16_c16_c16@@YAX_Y_Y_Y@Z");
    static assert(f_v_c32_c32_c32.mangleof == "?f_v_c32_c32_c32@@YAXKKK@Z");
    static assert(f_v_f32_f32_f32.mangleof == "?f_v_f32_f32_f32@@YAXMMM@Z");
    static assert(f_v_f64_f64_f64.mangleof == "?f_v_f64_f64_f64@@YAXNNN@Z");
    static assert(f_v_f80_f80_f80.mangleof == "?f_v_f80_f80_f80@@YAX_Z_Z_Z@Z");
    static assert(f_v_if32_if32_if32.mangleof == "?f_v_if32_if32_if32@@YAX_R00@Z");
    static assert(f_v_if64_if64_if64.mangleof == "?f_v_if64_if64_if64@@YAX_S00@Z");
    static assert(f_v_if80_if80_if80.mangleof == "?f_v_if80_if80_if80@@YAX_T00@Z");
    static assert(f_v_cf32_cf32_cf32.mangleof == "?f_v_cf32_cf32_cf32@@YAX_U00@Z");
    static assert(f_v_cf64_cf64_cf64.mangleof == "?f_v_cf64_cf64_cf64@@YAX_V00@Z");
    static assert(f_v_cf80_cf80_cf80.mangleof == "?f_v_cf80_cf80_cf80@@YAX_W00@Z");

    bool    f_i1_v();
    byte    f_i8_v();
    ubyte   f_u8_v();
    short   f_i16_v();
    ushort  f_u16_v();
    int     f_i32_v();
    uint    f_u32_v();
    long    f_i64_v();
    ulong   f_u64_v();
    char    f_c8_v();
    wchar   f_c16_v();
    dchar   f_c32_v();
    float   f_f32_v();
    double  f_f64_v();
    real    f_f80_v();
    ifloat  f_if32_v();
    idouble f_if64_v();
    ireal   f_if80_v();
    cfloat  f_cf32_v();
    cdouble f_cf64_v();
    creal   f_cf80_v();

    static assert(f_i1_v.mangleof == "?f_i1_v@@YA_NXZ");
    static assert(f_i8_v.mangleof == "?f_i8_v@@YACXZ");
    static assert(f_u8_v.mangleof == "?f_u8_v@@YAEXZ");
    static assert(f_i16_v.mangleof == "?f_i16_v@@YAFXZ");
    static assert(f_u16_v.mangleof == "?f_u16_v@@YAGXZ");
    static assert(f_i32_v.mangleof == "?f_i32_v@@YAHXZ");
    static assert(f_u32_v.mangleof == "?f_u32_v@@YAIXZ");
    static assert(f_i64_v.mangleof == "?f_i64_v@@YA_JXZ");
    static assert(f_u64_v.mangleof == "?f_u64_v@@YA_KXZ");
    static assert(f_c8_v.mangleof == "?f_c8_v@@YADXZ");
    static assert(f_c16_v.mangleof == "?f_c16_v@@YA_YXZ");
    static assert(f_c32_v.mangleof == "?f_c32_v@@YAKXZ");
    static assert(f_f32_v.mangleof == "?f_f32_v@@YAMXZ");
    static assert(f_f64_v.mangleof == "?f_f64_v@@YANXZ");
    static assert(f_f80_v.mangleof == "?f_f80_v@@YA_ZXZ");
    static assert(f_if32_v.mangleof == "?f_if32_v@@YA_RXZ");
    static assert(f_if64_v.mangleof == "?f_if64_v@@YA_SXZ");
    static assert(f_if80_v.mangleof == "?f_if80_v@@YA_TXZ");
    static assert(f_cf32_v.mangleof == "?f_cf32_v@@YA_UXZ");
    static assert(f_cf64_v.mangleof == "?f_cf64_v@@YA_VXZ");
    static assert(f_cf80_v.mangleof == "?f_cf80_v@@YA_WXZ");

    bool    f_i1_i1_i1(bool, bool);
    byte    f_i8_i8_i8(byte, byte);
    ubyte   f_u8_u8_u8(ubyte, ubyte);
    short   f_i16_i16_i16(short, short);
    ushort  f_u16_u16_u16(ushort, ushort);
    int     f_i32_i32_i32(int, int);
    uint    f_u32_u32_u32(uint, uint);
    long    f_i64_i64_i64(long, long);
    ulong   f_u64_u64_u64(ulong, ulong);
    char    f_c8_c8_c8(char, char);
    wchar   f_c16_c16_c16(wchar, wchar);
    dchar   f_c32_c32_c32(dchar, dchar);
    float   f_f32_f32_f32(float, float);
    double  f_f64_f64_f64(double, double);
    real    f_f80_f80_f80(real, real);
    ifloat  f_if32_if32_if32(ifloat, ifloat);
    idouble f_if64_if64_if64(idouble, idouble);
    ireal   f_if80_if80_if80(ireal, ireal);
    cfloat  f_cf32_cf32_cf32(cfloat, cfloat);
    cdouble f_cf64_cf64_cf64(cdouble, cdouble);
    creal   f_cf80_cf80_cf80(creal, creal);

    static assert(f_i1_i1_i1.mangleof == "?f_i1_i1_i1@@YA_N_N0@Z");
    static assert(f_i8_i8_i8.mangleof == "?f_i8_i8_i8@@YACCC@Z");
    static assert(f_u8_u8_u8.mangleof == "?f_u8_u8_u8@@YAEEE@Z");
    static assert(f_i16_i16_i16.mangleof == "?f_i16_i16_i16@@YAFFF@Z");
    static assert(f_u16_u16_u16.mangleof == "?f_u16_u16_u16@@YAGGG@Z");
    static assert(f_i32_i32_i32.mangleof == "?f_i32_i32_i32@@YAHHH@Z");
    static assert(f_u32_u32_u32.mangleof == "?f_u32_u32_u32@@YAIII@Z");
    static assert(f_i64_i64_i64.mangleof == "?f_i64_i64_i64@@YA_J_J_J@Z");
    static assert(f_u64_u64_u64.mangleof == "?f_u64_u64_u64@@YA_K_K_K@Z");
    static assert(f_c8_c8_c8.mangleof == "?f_c8_c8_c8@@YADDD@Z");
    static assert(f_c16_c16_c16.mangleof == "?f_c16_c16_c16@@YA_Y_Y_Y@Z");
    static assert(f_c32_c32_c32.mangleof == "?f_c32_c32_c32@@YAKKK@Z");
    static assert(f_f32_f32_f32.mangleof == "?f_f32_f32_f32@@YAMMM@Z");
    static assert(f_f64_f64_f64.mangleof == "?f_f64_f64_f64@@YANNN@Z");
    static assert(f_f80_f80_f80.mangleof == "?f_f80_f80_f80@@YA_Z_Z_Z@Z");
    static assert(f_if32_if32_if32.mangleof == "?f_if32_if32_if32@@YA_R_R0@Z");
    static assert(f_if64_if64_if64.mangleof == "?f_if64_if64_if64@@YA_S_S0@Z");
    static assert(f_if80_if80_if80.mangleof == "?f_if80_if80_if80@@YA_T_T0@Z");
    static assert(f_cf32_cf32_cf32.mangleof == "?f_cf32_cf32_cf32@@YA_U_U0@Z");
    static assert(f_cf64_cf64_cf64.mangleof == "?f_cf64_cf64_cf64@@YA_V_V0@Z");
    static assert(f_cf80_cf80_cf80.mangleof == "?f_cf80_cf80_cf80@@YA_W_W0@Z");
}
+/