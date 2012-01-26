

import std.file, std.string, std.array;

void main()
{
    auto names = ["AggregateDeclaration", "AnonymousAggregateDeclaration", "StructDeclaration", "UnionDeclaration", "ClassDeclaration", "InterfaceDeclaration", "AliasThis", "AttribDeclaration", "LinkDeclaration", "ProtDeclaration", "AlignDeclaration", "AnonDeclaration", "PragmaDeclaration", "ConditionalDeclaration", "StaticIfDeclaration", "CompileDeclaration", "Classsym", "Nspacesym", "Aliassym", "TypeInfo_Abuf", "TypeInfo_Atype", "TypeInfo_Adata", "TypeInfo_Idxstr", "TypeInfo_Achar", "TypeInfo_Pvoid", "DVCondition", "DebugCondition", "VersionCondition", "StaticIfCondition", "IftypeCondition", "Declaration", "TupleDeclaration", "TypedefDeclaration", "AliasDeclaration", "VarDeclaration", "SymbolDeclaration", "ClassInfoDeclaration", "ModuleInfoDeclaration", "TypeInfoDeclaration", "TypeInfoStructDeclaration", "TypeInfoClassDeclaration", "TypeInfoInterfaceDeclaration", "TypeInfoTypedefDeclaration", "TypeInfoPointerDeclaration", "TypeInfoArrayDeclaration", "TypeInfoStaticArrayDeclaration", "TypeInfoAssociativeArrayDeclaration", "TypeInfoEnumDeclaration", "TypeInfoFunctionDeclaration", "TypeInfoDelegateDeclaration", "TypeInfoTupleDeclaration", "TypeInfoConstDeclaration", "TypeInfoInvariantDeclaration", "TypeInfoSharedDeclaration", "TypeInfoWildDeclaration", "TypeInfoVectorDeclaration", "ThisDeclaration", "FuncDeclaration", "FuncAliasDeclaration", "FuncLiteralDeclaration", "CtorDeclaration", "PostBlitDeclaration", "DtorDeclaration", "StaticCtorDeclaration", "SharedStaticCtorDeclaration", "StaticDtorDeclaration", "SharedStaticDtorDeclaration", "InvariantDeclaration", "UnitTestDeclaration", "NewDeclaration", "DeleteDeclaration", "ParamSection", "MacroSection", "Dsymbol", "ScopeDsymbol", "WithScopeSymbol", "ArrayScopeSymbol", "OverloadSet", "DsymbolTable", "EnumDeclaration", "EnumMember", "Expression", "IntegerExp", "ErrorExp", "RealExp", "ComplexExp", "IdentifierExp", "DollarExp", "DsymbolExp", "ThisExp", "SuperExp", "NullExp", "StringExp", "TupleExp", "ArrayLiteralExp", "AssocArrayLiteralExp", "StructLiteralExp", "TypeExp", "ScopeExp", "TemplateExp", "NewExp", "NewAnonClassExp", "SymbolExp", "SymOffExp", "VarExp", "OverExp", "FuncExp", "DeclarationExp", "TypeidExp", "TraitsExp", "HaltExp", "IsExp", "UnaExp", "BinExp", "BinAssignExp", "CompileExp", "FileExp", "AssertExp", "DotIdExp", "DotTemplateExp", "DotVarExp", "DotTemplateInstanceExp", "DelegateExp", "DotTypeExp", "CallExp", "AddrExp", "PtrExp", "NegExp", "UaddExp", "ComExp", "NotExp", "BoolExp", "DeleteExp", "CastExp", "VectorExp", "SliceExp", "ArrayLengthExp", "ArrayExp", "DotExp", "CommaExp", "IndexExp", "PostExp", "PreExp", "AssignExp", "ConstructExp", "AddExp", "MinExp", "CatExp", "MulExp", "DivExp", "ModExp", "PowExp", "ShlExp", "ShrExp", "UshrExp", "AndExp", "OrExp", "XorExp", "OrOrExp", "AndAndExp", "CmpExp", "InExp", "RemoveExp", "EqualExp", "IdentityExp", "CondExp", "DefaultInitExp", "FileInitExp", "LineInitExp", "Identifier", "Import", "Initializer", "VoidInitializer", "StructInitializer", "ArrayInitializer", "ExpInitializer", "ClassReferenceExp", "ThrownExceptionExp", "Package", "Module", "Type", "TypeError", "TypeNext", "TypeBasic", "TypeVector", "TypeArray", "TypeSArray", "TypeDArray", "TypeAArray", "TypePointer", "TypeReference", "TypeFunction", "TypeDelegate", "TypeQualified", "TypeIdentifier", "TypeInstance", "TypeTypeof", "TypeReturn", "TypeStruct", "TypeEnum", "TypeTypedef", "TypeClass", "TypeTuple", "TypeSlice", "TypeNull", "Parameter", "ObjFile", "Parser", "Statement", "PeelStatement", "ExpStatement", "DtorExpStatement", "CompileStatement", "CompoundStatement", "CompoundDeclarationStatement", "UnrolledLoopStatement", "ScopeStatement", "WhileStatement", "DoStatement", "ForStatement", "ForeachStatement", "ForeachRangeStatement", "IfStatement", "ConditionalStatement", "PragmaStatement", "StaticAssertStatement", "SwitchStatement", "CaseStatement", "CaseRangeStatement", "DefaultStatement", "GotoDefaultStatement", "GotoCaseStatement", "SwitchErrorStatement", "ReturnStatement", "BreakStatement", "ContinueStatement", "SynchronizedStatement", "WithStatement", "TryCatchStatement", "Catch", "TryFinallyStatement", "OnScopeStatement", "ThrowStatement", "VolatileStatement", "DebugStatement", "GotoStatement", "LabelStatement", "LabelDsymbol", "AsmStatement", "ImportStatement", "StaticAssert", "Tuple", "TemplateDeclaration", "TemplateTypeParameter", "TemplateThisParameter", "TemplateValueParameter", "TemplateAliasParameter", "TemplateTupleParameter", "TemplateInstanceParameter", "TemplateMixin", "DebugSymbol", "VersionSymbol"];
    
    auto fx = splitLines(readText("source.txt"));
    
    foreach(fn; fx)
    {
        auto d = cast(string)read(fn);
        
        foreach(n; names)
        {
            auto t = "struct " ~ n ~ ";";
            auto x = "class " ~ n ~ ";";
            string old = null;
            
            while (d !is old)
            {
                old = d;
                d = replace(d, t, x);
            }
        }
        
        write(fn, d);
    }    
}