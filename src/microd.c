
// This implements microD

#include "microd.h"

#include <assert.h>

#include "rmem.h"
#include "root.h"

#include "module.h"
#include "declaration.h"
#include "statement.h"
#include "attrib.h"
#include "init.h"

OutBuffer declf;
OutBuffer declr;

void microd_declf(const char *format, ...);
void microd_decl(const char *format, ...);
void microd_all(const char *format, ...);

char *comment1(const char *format, ...);
char *comment2(const char *format, ...);

//////////////////////////////////////////////////////////////////////////

void microd_generate(Modules *modules)
{
    microd_declf("#include \"microdbase.h\"\n\n");
    microd_declf(comment1("Forward declarations"));
    microd_decl(comment1("Declarations"));

    for (size_t i = 0; i < modules->dim; i++)
    {
        Module *m = modules->tdata()[i];
        if (global.params.verbose)
            printf("microd gen %s\n", m->toChars());

        m->toMicroD();
    }

    char *n = FileName::name((*global.params.objfiles)[0]);
    File *mdfile = new File(FileName::forceExt(n, "md"));
    mdfile->ref = 1;

    declf.writestring(declr.toChars());

    mdfile->setbuffer(declf.data, declf.offset);
    mdfile->writev();
}

//////////////////////////////////////////////////////////////////////////

void Module::toMicroD()
{
    microd_all(comment2("Module %s", toChars()));

    for (size_t i = 0; i < members->dim; i++)
    {
        Dsymbol *s = (*members)[i];
        s->toMicroD();
    }
}

//////////////////////////////////////////////////////////////////////////

void Dsymbol::toMicroD()
{
    printf("ignored: %s %s\n", kind(), toChars());
}

void AttribDeclaration::toMicroD()
{
    Dsymbols *d = include(NULL, NULL);

    if (d)
    {
        for (size_t i = 0; i < d->dim; i++)
        {
            Dsymbol *s = (*d)[i];
            s->toMicroD();
        }
    }
}

//////////////////////////////////////////////////////////////////////////

void FuncDeclaration::toMicroD()
{
    // Forward declaration
    md_fptr sink = &microd_all;

    assert(type->ty == Tfunction);
    TypeFunction *tf = (TypeFunction *)type;
    tf->next->toMicroD(sink);
    sink(" ");
    sink(mangle());
    sink("(");
    for (size_t i = 0; i < tf->parameters->dim; i++)
    {
        Parameter *p = (*tf->parameters)[i];
        p->toMicroD(sink);
        if (i != tf->parameters->dim - 1)
            sink(", ");
    }
    microd_declf(");\n");

    // Body
    sink = &microd_decl;
    if (fbody)
    {
        sink(")\n{\n");
        fbody->toMicroD(sink);
        sink("}\n");
    }
    else
        sink(");\n");
}

void VarDeclaration::toMicroD()
{
    md_fptr sink = &microd_all;

    type->toMicroD(sink);
    sink(" ");
    sink(mangle());

    if (init)
    {
        microd_decl(" = ");
        init->toMicroD(&microd_decl);
    }
    sink(";\n");
}

//////////////////////////////////////////////////////////////////////////

void Declaration::toMicroD(md_fptr sink)
{
    error("Declaration not supported ('%s')", toChars());
    sink("__Declaration__");
}

void VarDeclaration::toMicroD(md_fptr sink)
{
    type->toMicroD(sink);
    sink(" ");
    sink(mangle());

    if (init)
    {
        sink(" = ");
        ExpInitializer *ie = init->isExpInitializer();
        if (ie && (ie->exp->op == TOKconstruct || ie->exp->op == TOKblit))
            ((AssignExp *)ie->exp)->e2->toMicroD(sink);
        else
            init->toMicroD(sink);
    }
}

//////////////////////////////////////////////////////////////////////////

void Type::toMicroD(md_fptr sink)
{
    error(0, "Type '%s' not supported in MicroD", toChars());
    sink("__type__");
}

void TypeBasic::toMicroD(md_fptr sink)
{
    switch(ty)
    {
    case Tvoid:
    case Tint8:
    case Tuns8:
    case Tint16:
    case Tuns16:
    case Tint32:
    case Tuns32:
        sink("__d_%s", toChars());
        return;
    default:
        Type::toMicroD(sink);
    }
}

//////////////////////////////////////////////////////////////////////////

void Parameter::toMicroD(md_fptr sink)
{
    type->toMicroD(sink);
    sink(" ");
    sink(ident->toChars());
    if (defaultArg)
    {
        sink(" = ");
        defaultArg->toMicroD(sink);
    }
}

//////////////////////////////////////////////////////////////////////////

void Expression::toMicroD(md_fptr sink)
{
    error("Expression not supported in MicroD ('%s')", toChars());
    sink("__Expression__");
}

void IntegerExp::toMicroD(md_fptr sink)
{
    sink(toChars());
}

void DeclarationExp::toMicroD(md_fptr sink)
{
    Declaration *d = declaration->isDeclaration();
    assert(d);
    d->toMicroD(sink);
}

void BinExp::toMicroD(md_fptr sink)
{
    switch (op)
    {
    case TOKlt:
    case TOKle:
    case TOKgt:
    case TOKge:
    case TOKequal:
    case TOKnotequal:

    case TOKadd:
    case TOKmin:
    case TOKmul:
    case TOKdiv:
    case TOKand:
    case TOKor:
    case TOKxor:

    case TOKaddass:
    case TOKminass:
    case TOKmulass:
    case TOKdivass:
    case TOKandass:
    case TOKorass:
    case TOKxorass:

    case TOKassign:

        e1->toMicroD(sink);
        sink(" %s ", Token::toChars(op));
        e2->toMicroD(sink);
        break;
    default:
        Expression::toMicroD(sink);
        break;
    }
}

void VarExp::toMicroD(md_fptr sink)
{
    sink(var->mangle());
}

void CastExp::toMicroD(md_fptr sink)
{
    sink("((");
    type->toMicroD(sink);
    sink(")");
    e1->toMicroD(sink);
    sink(")");
}

//////////////////////////////////////////////////////////////////////////

void Initializer::toMicroD(md_fptr sink)
{
    error("This type of initializer not supported in MicroD ('%s')", toChars());
    sink("__init__");
}

void ExpInitializer::toMicroD(md_fptr sink)
{
    exp->toMicroD(sink);
}

//////////////////////////////////////////////////////////////////////////

void Statement::toMicroD(md_fptr sink)
{
    error("Statement not supported in MicroD ('%s')", toChars());
    sink("__statement__");__asm int 3;
}

void CompoundStatement::toMicroD(md_fptr sink)
{
    for (size_t i = 0; i < statements->dim; i++)
    {
        Statement *s = (*statements)[i];
        s->toMicroD(sink);
        sink(";\n");
    }
}

void CompoundDeclarationStatement::toMicroD(md_fptr sink)
{
    int nwritten = 0;
    for (size_t i = 0; i < statements->dim; i++)
    {
        Statement *s = (*statements)[i];
        ExpStatement *es = s->isExpStatement();
        assert(es && es->exp->op == TOKdeclaration);
        DeclarationExp *de = (DeclarationExp *)es->exp;
        Declaration *d = de->declaration->isDeclaration();
        assert(d);
        VarDeclaration *v = d->isVarDeclaration();
        if (v)
        {
            if (nwritten)
                sink(",");
            // write storage classes
            if (v->type && !nwritten)
                v->type->toMicroD(sink);
            sink(" ");
            sink(v->mangle());
            if (v->init)
            {
                sink(" = ");
                ExpInitializer *ie = v->init->isExpInitializer();
                if (ie && (ie->exp->op == TOKconstruct || ie->exp->op == TOKblit))
                    ((AssignExp *)ie->exp)->e2->toMicroD(sink);
                else
                    v->init->toMicroD(sink);
            }
        }
        else
            d->toMicroD(sink);
        nwritten++;
    }
    sink(";\n");
}

void ExpStatement::toMicroD(md_fptr sink)
{
    exp->toMicroD(sink);
}

void ForStatement::toMicroD(md_fptr sink)
{
    sink("for (");
    init->toMicroD(sink);
    condition->toMicroD(sink);
    sink("; ");
    increment->toMicroD(sink);
    sink(")\n");
    body->toMicroD(sink);
}

void ReturnStatement::toMicroD(md_fptr sink)
{
    sink("return ");
    exp->toMicroD(sink);
    sink(";\n");
}

//////////////////////////////////////////////////////////////////////////

void microd_declf(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    declf.vprintf(format,ap);
    va_end(ap);
}
void microd_decl(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    declr.vprintf(format,ap);
    va_end(ap);
}
void microd_all(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    declf.vprintf(format,ap);
    declr.vprintf(format,ap);
    va_end(ap);
}
char *comment1(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    OutBuffer buf;
    buf.writestring("/***********************************************************\n * \n * ");
    buf.vprintf(format, ap);
    buf.writestring("\n * \n */\n\n");
    va_end(ap);
    return buf.extractData();
}
char *comment2(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    OutBuffer buf;
    buf.writestring("/***********************************************************\n * ");
    buf.vprintf(format, ap);
    buf.writestring("\n */\n\n");
    va_end(ap);
    return buf.extractData();
}
