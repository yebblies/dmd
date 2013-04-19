
import std.stdio;
import std.random;
import std.conv;
import std.regex;
import std.process;

enum MOD
{
    MODnone,
    MODconst
}

class Type
{
    MOD mod;
    this()
    {
        mod = [MOD.MODnone, MOD.MODconst].randomSample(1).front;
    }
    abstract void toStringD(scope void delegate(const(char)[]) sink) const;
    abstract void toStringC(scope void delegate(const(char)[]) sink) const;
}

immutable string[] dbasics =
[
    "void", "bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong",
    "char", "wchar", /*"dchar",*/ "float", "double", "real", "ifloat", "idouble", "ireal",
    "cfloat", "cdouble", "creal"
];
immutable string[] cbasics =
[
    "void", "bool", "signed char", "unsigned char", "signed short", "unsigned short", "signed int", "unsigned int", "signed long long", "unsigned long long",
    "char", "wchar_t", /*"???",*/ "float", "double", "long double", "_Imaginary float", "_Imaginary double", "_Imaginary long double",
    "_Complex float", "_Complex double", "_Complex long double"
];

class TypeBasic : Type
{
    int i;
    this(bool v = false)
    {
        i = uniform(!v, dbasics.length);
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        if (mod == MOD.MODconst)
            sink("const(");
        sink(dbasics[i]);
        if (mod == MOD.MODconst)
            sink(")");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        sink(cbasics[i]);
        if (mod == MOD.MODconst)
            sink(" const");
    }
}

class TypePointer : Type
{
    Type next;
    this(Type next)
    {
        super();
        this.next = next;
        next.mod = mod;
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        if (mod == MOD.MODconst)
            sink("const(");
        next.toStringD(sink);
        sink("*");
        if (mod == MOD.MODconst)
            sink(")");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        next.toStringC(sink);
        sink("*");
        if (mod == MOD.MODconst)
            sink(" const");
    }
}

class TypeAgg : Type
{
    string id;
    this(string id)
    {
        this.id = id;
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        if (mod == MOD.MODconst)
            sink("const(");
        sink(id);
        if (mod == MOD.MODconst)
            sink(")");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        sink(id);
        if (mod == MOD.MODconst)
            sink(" const");
    }
}

class TypeFunction : Type
{
    Type ret;
    Type[] params;
    this(Type ret, Type[] params)
    {
        this.ret = ret;
        this.params = params;
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        ret.toStringD(sink);
        sink(" function(");
        foreach(i, p; params)
        {
            if (i)
                sink(", ");
            p.toStringD(sink);
        }
        sink(")");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        assert(0);
    }
}

class TypeEnum : Type
{
    string id;
    this(string id)
    {
        this.id = id;
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        if (mod == MOD.MODconst)
            sink("const(");
        sink(id);
        if (mod == MOD.MODconst)
            sink(")");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        sink(id);
        if (mod == MOD.MODconst)
            sink(" const");
    }
}

Type randomType(bool v = true)
{
    switch (uniform(0, 5))
    {
    case 0:
        return new TypeBasic(v);
    case 1:
        return new TypePointer(randomType());
    case 2:
        return new TypeAgg("STRUCT");
    case 3:
        return new TypeAgg("CLASS");
    case 4:
        return new TypeEnum("ENUM");
    case 5:
        return new TypeFunction(randomType(), randomConcretes(4));
    default:
        assert(0);
    }
}

Type randomConcrete()
{
    return randomType(false);
}

Type[] randomConcretes(int n)
{
    Type[] r;
    r.length = uniform(0, n);
    foreach(ref v; r)
        v = randomConcrete();
    return r;
}

Type randomFunction()
{
    return new TypeFunction(randomType(), randomConcretes(20));
}

Type randomFunctionRep()
{
    auto params = new Type[](uniform(0, 20));
    params[] = randomConcrete();
    return new TypeFunction(randomType(), params);
}

class Declaration
{
    Type type;
    string id;
    this(Type type, string id)
    {
        this.type = type;
        this.id = id;
    }
    abstract void toStringD(scope void delegate(const(char)[]) sink) const;
    abstract void toStringC(scope void delegate(const(char)[]) sink) const;
}

class VarDeclaration : Declaration
{
    this(Type type, string id)
    {
        super(type, id);
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        type.toStringD(sink);
        sink(" ");
        sink(id);
        sink(";");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        type.toStringC(sink);
        sink(" ");
        sink(id);
        sink(";");
    }
}

class FuncDeclaration : Declaration
{
    this(Type type, string id)
    {
        super(type, id);
    }
    override void toStringD(scope void delegate(const(char)[]) sink) const
    {
        auto tf = cast(TypeFunction)type;
        tf.ret.toStringD(sink);
        sink(" ");
        sink(id);
        sink("(");
        foreach(i, p; tf.params)
        {
            if (i)
                sink(", ");
            p.toStringD(sink);
        }
        sink(") { static if (is(typeof(typeof(return).init))) return typeof(return).init; } ");
    }
    override void toStringC(scope void delegate(const(char)[]) sink) const
    {
        auto tf = cast(TypeFunction)type;
        tf.ret.toStringC(sink);
        sink(" ");
        sink(id);
        sink("(");
        foreach(i, p; tf.params)
        {
            if (i)
                sink(", ");
            p.toStringC(sink);
        }
        sink(");");
    }
}

Declaration randomDecl(string id)
{
    switch(uniform(0, 3))
    {
    case 0:
        return new VarDeclaration(randomConcrete(), id);
    case 1:
        return new FuncDeclaration(randomFunction(), id);
    case 2:
        return new FuncDeclaration(randomFunctionRep(), id);
    default:
        assert(0);
    }
}

void main()
{
    enum dfn = "randomdecl_d.d";
    enum cfn = "randomdecl_c.cpp";
    enum dmap = "randomdecl_d.map";
    enum cmap = "randomdecl_c.map";

    auto dfile = File(dfn, "wb");
    auto cfile = File(cfn, "wb");

    dfile.writeln("struct STRUCT {}");
    dfile.writeln("class CLASS {}");
    dfile.writeln("enum ENUM { A, B, C }");
    dfile.writeln("extern(C++):");

    cfile.writeln("struct STRUCT {};");
    cfile.writeln("class CLASS {};");
    cfile.writeln("enum ENUM { A, B, C };");

    Declaration[string] decl;

    foreach(i; 0..10000)
    {
        auto d = randomDecl(text("_id_", i, "_id_"));
        decl[d.id] = d;

        void delegate(const(char)[]) sinkd = delegate (s) { dfile.write(s); };
        d.toStringD(sinkd);
        dfile.writeln();

        void delegate(const(char)[]) sinkcpp = delegate (s) { cfile.write(s); };
        d.toStringC(sinkcpp);
        cfile.writeln();
    }

    dfile.close();
    cfile.close();

    system("dmd " ~ dfn);
    system("objconv -ds randomdecl_d.obj > randomdecl_d.map");
    system("dmc " ~ cfn ~ " -Map");

    auto r = regex(r"\?(_id_\d+_id_)([@A-Z0-9_]+)", "g");
    string[string] mangle;
    bool[string] found;

    foreach(l; File(dmap, "rb").byLine)
    {
        foreach(c; match(l, r))
        {
            mangle[c[1].idup] = c[0].idup;
        }
    }
    foreach(l; File(dmap, "rb").byLine)
    {
        foreach(c; match(l, r))
        {
            if (c[1] !in mangle)
            {
                writeln("missing?!?! ", c[0]);
            }
            else if (mangle[c[1]] != c[0])
            {
                void delegate(const(char)[]) sink = delegate (s) { write(s); };
                write("mismatch: ");
                decl[c[1]].toStringD(sink);
                writeln();
                writeln("D:   ", mangle[c[1]]);
                writeln("C++: ", c[0]);
                assert(0);
            }
            else
            {
                if (0)
                {
                    void delegate(const(char)[]) sink = delegate (s) { write(s); };
                    write("match: ", c[0], " ");
                    decl[c[1]].toStringD(sink);
                    writeln();
                }
                found[c[1].idup] = true;
            }
        }
    }
    foreach(key, v; mangle)
        if (key !in found)
            assert(0, key ~ " not found");
    writeln("Finished");
}
