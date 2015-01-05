
import std.file;
import std.stdio;
import std.range;
import std.path;
import std.algorithm;
import std.json;

import tokens;
import parser;
import dprinter;
import scanner;
import ast;
import namer;
import typenames;

void main(string[] args)
{
    Module[] asts;

    auto srcdir = args[1];
    auto destdir = args[2];

    auto settings = parseJSON(readText("settings.json")).object;
    auto src = settings["src"].array.map!"a.str"().array;
    auto mapping = settings["mapping"].array.loadMapping();
    foreach(t; settings["basicTypes"].array.map!"a.str")
        basicTypes[t] = false;
    foreach(t; settings["structTypes"].array.map!"a.str")
        structTypes[t] = false;
    foreach(t; settings["rootclasses"].array.map!"a.str")
        rootClasses[t] = false;
    foreach(t; settings["overriddenfuncs"].array.map!(j => j.array.map!("a.str").array))
        overridenFuncs ~= t;
    foreach(t; settings["nonfinalclasses"].array.map!"a.str")
        nonFinalClasses ~= t;

    Token[][string] toks;
    foreach(xfn; src)
    {
        auto fn = buildPath(srcdir, xfn);
        writeln("loading -- ", fn);
        assert(fn.exists(), fn ~ " does not exist");
        auto pp = cast(string)read(fn);
        pp = pp.replace("\"v\"\n#include \"verstr.h\"\n    ;", "__IMPORT__;");
        auto tx = Lexer(pp, fn).array;
        toks[fn] = tx;
        foreach(i, t; tx)
        {
            string[] matchSeq(string[] strs...)
            {
                string[] res;
                foreach(j, s; strs)
                {
                    if (i + j > tx.length)
                        return null;
                    if (s == null)
                    {
                        res ~= tx[i + j].text;
                        continue;
                    }
                    if (s != tx[i + j].text)
                        return null;
                }
                return res;
            }
            if (auto v = matchSeq("class", null, ";"))
                classTypes[v[0]] = false;
            if (auto v = matchSeq("class", null, "{"))
                classTypes[v[0]] = false;
            if (auto v = matchSeq("class", null, ":"))
                classTypes[v[0]] = false;
            if (auto v = matchSeq("struct", null, ";"))
                structTypes[v[0]] = false;
            if (auto v = matchSeq("struct", null, "{"))
                structTypes[v[0]] = false;
            if (auto v = matchSeq("union", null, "{"))
                structTypes[v[0]] = false;
            if (auto v = matchSeq("typedef", "Array", "<", "class", null, "*", ">", null, ";"))
            {
                structTypes[v[1]] = false;
            }
            if (auto v = matchSeq("typedef", "Array", "<", "struct", null, "*", ">", null, ";"))
            {
                structTypes[v[1]] = false;
            }
        }
    }

    auto scan = new Scanner();
    foreach(fn, tx; toks)
    {
        asts ~= parse(tx, fn);
        asts[$-1].visit(scan);
    }

    foreach(t, used; basicTypes)
        if (!used)
            writeln("type ", t, " not referenced");
    foreach(t, used; structTypes)
        if (!used)
            writeln("type ", t, " not referenced");
    foreach(t, used; classTypes)
        if (!used)
            writeln("type ", t, " not referenced");

    writeln("collapsing ast...");
    auto superast = collapse(asts, scan);
    auto map = buildMap(superast);
    auto longmap = buildLongMap(superast);

    bool failed;
    try { mkdir(destdir); } catch {}
    foreach(m; mapping)
    {
        auto dir = buildPath(destdir, m.p);
        if (m.p.length)
            try { mkdir(dir); } catch {}

        auto fn = buildPath(dir, m.m).setExtension(".d");
        auto f = File(fn, "wb");
        writeln("writing -- ", fn);

        f.writeln("
// Compiler implementation of the D programming language
// Copyright (c) 1999-2015 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// Distributed under the Boost Software License, Version 1.0.
// http://www.boost.org/LICENSE_1_0.txt");

        f.writeln();
        if (m.p.length)
            f.writefln("module ddmd.%s.%s;", m.p, m.m);
        else
            f.writefln("module ddmd.%s;", m.m);
        f.writeln();

        void importList(R)(R imports)
        {
            bool found;
            foreach(i; imports)
            {
                if (!found)
                    f.writef("import %s", i);
                else
                    f.writef(", %s", i);
                found = true;
            }
            if (found)
                f.writeln(";");
        }
        importList(m.imports.filter!(i => i.startsWith("core.")));
        importList(m.imports.filter!(i => i.startsWith("root.")));
        importList(m.imports.filter!(i => !i.startsWith("core.", "root.")));
        if (m.imports.length)
            f.writeln();

        foreach(e; m.extra)
        {
            f.writeln(e);
        }
        if (m.extra.length)
            f.writeln();

        auto printer = new DPrinter((string s) { f.write(s); }, scan);
        foreach(d; m.members)
        {
            if (auto p = d in map)
            {
                if (!p.d)
                {
                    writeln(d, " needs mangled name");
                    foreach(id, x; longmap)
                    {
                        if (id.startsWith(d))
                        {
                            writeln(" - ", id);
                        }
                    }
                }
                else
                {
                    printer.visitX(p.d);
                    p.count++;
                }
            }
            else if (auto p = d in longmap)
            {
                assert(p.d);
                map[p.d.getName].count++;
                printer.visitX(p.d);
                p.count++;
            }
            else
            {
                writeln("Not found: ", d);
                failed = true;
            }
        }
    }
    foreach(id, d; map)
    {
        if (d.count == 0)
        {
            assert(d.d, id);
            writeln("unreferenced: ", d.d.getName);
            failed = true;
        }
        if (d.count > 1 && d.d)
        {
            writeln("duplicate: ", d.d.getName);
        }
    }
    foreach(id, d; longmap)
    {
        if (d.count > 1)
        {
            assert(d.d);
            writeln("duplicate: ", d.d.getName);
        }
    }
    bool badIdent(string s)
    {
        switch(s)
        {
        case "import", "module", "version", "ref", "scope",
            "body", "alias", "is",
            "delegate", "cast", "mangleof",
            "foreach", "super", "init", "tupleof":
            return true;
        default:
            return false;
        }
    }
    auto skiplist =
    [
        "TypeDeduced", "PostorderExpressionVisitor", "CtfeStack", "InterState", "CompiledCtfeFunction", "CtfeCompiler",
        "Interpreter", "PrefixAttributes", "Ptrait", "PushAttributes", "GetNthSymbolCtx", "PostorderStatementVisitor",
        "PrettyPrintVisitor", "Escape", "Section", "DocComment", "GetNthParamCtx", "StatementRewriteWalker",
        "TemplateCandidateWalker", "NrvoWalker", "FuncCandidateWalker", "ToJsonVisitor", "Mangler", "aaA",
        "AA", "InlineCostVisitor", "InlineDoState", "InlineScanVisitor", "StringEntry", "Keyword", "NOGCVisitor",
        "ParamSection", "MacroSection", "ParamDeduce", "DeduceType", "ReliesOnTident", "ParamBest", "ParamNeedsInf",
        "BlockExit", "StringTable", "VarWalker", "SCstring", "BuildArrayIdentVisitor", "BuildArrayLoopVisitor",
        "PointerBitmapVisitor", "EnumDeclaration", "CppMangleVisitor", "LambdaSetParent", "LambdaCheckForNestedRef",
        "ImplicitCastTo", "ImplicitConvTo", "CastTo", "InferType", "IntRangeVisitor", "CommutativeVisitor",
        "OpIdVisitor", "OpIdRVisitor", "OpOverload", "ParamOpOver", "ScopeDsymbol", "PrePostAppendStrings",
        "OptimizeVisitor", "EmitComment", "ToDocBuffer", "Macro", "ParamExact", "CountWalker", "PrevSibling",
        "RetWalker", "ToArgTypes", "FullTypeInfoVisitor", "Ctxt", "CanThrow", "LambdaInlineCost", "InlineAsStatement",
        "InlineStatement", "InlineExpression", "ParamFwdTi", "ParamFwdResTm", "UsesEH", "ComeFrom", "HasCode",
        "PushIdentsDg", "PushBaseMembers", "ClassCheck", "ParamUniqueSym", "IsTrivialExp", "LambdaHasSideEffect",
        "ParamUnique", "N", "SV"
    ];
    {
        auto fn = buildPath(destdir, "abitestd").setExtension(".d");
        auto f = File(fn, "wb");
        writeln("writing -- ", fn);

        f.writeln("module ddmd.abitest;");
        f.writeln();
        foreach(m; mapping)
        {
            if (m.p.length)
                f.writefln("import ddmd.%s.%s;", m.p, m.m);
            else
                f.writefln("import ddmd.%s;", m.m);
        }
        f.writeln();
        f.writeln("extern(C++) size_t getOffset(const(char)* agg, const(char)* member);");
        f.writeln("extern(C++) size_t getSize(const(char)* agg);");
        f.writeln();
        f.writeln("void checkOffset(string sd, string vd)()");
        f.writeln("{");
        f.writeln("    auto doff = cast(int)mixin(sd ~ \".\" ~ vd).offsetof;");
        f.writeln("    auto coff = cast(int)getOffset(sd, vd);");
        f.writeln("    if (doff != coff)");
        f.writeln("    {");
        f.writeln("        import core.stdc.stdio;");
        f.writeln("        printf(\"Offset mismatch - %s:%s %d (d) %d (c++)\n\", sd.ptr, vd.ptr, doff, coff);");
        f.writeln("    }");
        f.writeln("}");
        f.writeln();
        f.writeln("static this()");
        f.writeln("{");

        foreach(sd; scan.structDeclarations)
        {writeln(sd.id);
            if (skiplist.canFind(sd.id))
                continue;
            foreach(d; sd.decls)
            {
                if (auto vd = cast(VarDeclaration)d)
                {
                    if (!(vd.stc & (STCstatic | STCconst)) && !badIdent(vd.id))
                    {
                        f.writefln("    checkOffset!(\"%s\", \"%s\")();", sd.id, vd.id);
                    }
                }
            }
            if (sd.kind == "class"){}
                // f.writefln("    assert(getSize(\"%s\") == __traits(classInstanceSize, %s));", sd.id, sd.id);
            else
                f.writefln("    assert(getSize(\"%s\") == %s.sizeof);", sd.id, sd.id);
        }

        f.writeln("}");
        f.writeln();
    }
    {
        auto fn = buildPath(destdir, "abitestc").setExtension(".c");
        auto f = File(fn, "wb");
        writeln("writing -- ", fn);
        f.writeln();
        f.writeln("#include <stdio.h>");
        f.writeln();
        f.writeln("#include \"aggregate.h\"");
        f.writeln("#include \"aliasthis.h\"");
        f.writeln("#include \"arraytypes.h\"");
        f.writeln("#include \"attrib.h\"");
        f.writeln("#include \"complex_t.h\"");
        f.writeln("#include \"cond.h\"");
        f.writeln("#include \"ctfe.h\"");
        f.writeln("#include \"declaration.h\"");
        f.writeln("#include \"doc.h\"");
        f.writeln("#include \"dsymbol.h\"");
        f.writeln("#include \"enum.h\"");
        f.writeln("#include \"errors.h\"");
        f.writeln("#include \"expression.h\"");
        f.writeln("#include \"globals.h\"");
        f.writeln("#include \"hdrgen.h\"");
        f.writeln("#include \"id.h\"");
        f.writeln("#include \"identifier.h\"");
        f.writeln("#include \"import.h\"");
        f.writeln("#include \"init.h\"");
        f.writeln("#include \"intrange.h\"");
        f.writeln("#include \"irstate.h\"");
        f.writeln("#include \"json.h\"");
        f.writeln("#include \"lexer.h\"");
        f.writeln("#include \"lib.h\"");
        f.writeln("#include \"macro.h\"");
        f.writeln("#include \"module.h\"");
        f.writeln("#include \"mtype.h\"");
        f.writeln("#include \"nspace.h\"");
        f.writeln("#include \"parse.h\"");
        f.writeln("#include \"scope.h\"");
        f.writeln("#include \"statement.h\"");
        f.writeln("#include \"staticassert.h\"");
        f.writeln("#include \"target.h\"");
        f.writeln("#include \"template.h\"");
        f.writeln("#include \"toir.h\"");
        f.writeln("#include \"tokens.h\"");
        f.writeln("#include \"utf.h\"");
        f.writeln("#include \"version.h\"");
        f.writeln("#include \"visitor.h\"");
        f.writeln();
        f.writeln("size_t getOffset(const char *agg, const char *member)");
        f.writeln("{");
        foreach(sd; scan.structDeclarations)
        {
            if (skiplist.canFind(sd.id))
                continue;
            f.writefln("    if (!strcmp(agg, \"%s\"))", sd.id);
            f.writefln("    {");
            foreach(d; sd.decls)
            {
                if (auto vd = cast(VarDeclaration)d)
                {
                    if (!(vd.stc & (STCstatic | STCconst)) && !badIdent(vd.id))
                    {
                        f.writefln("        if (!strcmp(member, \"%s\"))", vd.id);
                        f.writefln("        {");
                        f.writefln("            return (size_t)((char*)&((%s*)NULL)->%s);", sd.id, vd.id);
                        f.writefln("        }");
                    }
                }
            }
            f.writefln("        printf(\"%s.%%s\", member);", sd.id);
            f.writefln("        assert(0);");
            f.writefln("    }");
        }
        f.writeln("    assert(0);");
        f.writeln("    return 0;");
        f.writeln("}");
        f.writeln();
        f.writeln("size_t getSize(const char *agg)");
        f.writeln("{");
        foreach(sd; scan.structDeclarations)
        {
            if (skiplist.canFind(sd.id))
                continue;
            f.writefln("    if (!strcmp(agg, \"%s\"))", sd.id);
            f.writefln("        return sizeof(%s);", sd.id);
        }
        f.writeln("    assert(0);");
        f.writeln("    return 0;");
        f.writeln("}");
        f.writeln();
    }
    if (failed)
        assert(0);
}

struct D
{
    Declaration d;
    int count;
}

D[string] buildMap(Module m)
{
    D[string] map;
    foreach(d; m.decls)
    {
        auto s = d.getName();
        if (s in map)
            map[s] = D(null, 0);
        else
            map[s] = D(d, 0);
    }
    return map;
}

D[string] buildLongMap(Module m)
{
    D[string] map;
    foreach(d; m.decls)
    {
        auto s = d.getLongName();
        assert(s !in map, s);
        map[s] = D(d, 0);
    }
    return map;
}

struct M
{
    string m;
    string p;
    string[] imports;
    string[] members;
    string[] extra;
}

auto loadMapping(JSONValue[] modules)
{
    M[] r;
    foreach(j; modules)
    {
        auto imports = j.object["imports"].array.map!"a.str"().array;
        sort(imports);
        foreach(ref i; imports)
            if (!i.startsWith("core"))
                i = "ddmd." ~ i;
        string[] extra;
        if ("extra" in j.object)
            extra = j.object["extra"].array.map!"a.str"().array;
        r ~= M(
            j.object["module"].str,
            j.object["package"].str,
            imports,
            j.object["members"].array.map!"a.str"().array,
            extra
        );
    }
    return r;
}
