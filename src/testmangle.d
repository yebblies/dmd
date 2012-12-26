
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
