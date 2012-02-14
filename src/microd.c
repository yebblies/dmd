
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
#include "aggregate.h"
#include "arraytypes.h"
#include "id.h"

Dsymbols xdeferred;

OutBuffer buf1; // struct/union/enum forward declaration & includes
OutBuffer buf2; // struct/union/enum definition & var/func forward declaration
OutBuffer buf3; // var/func definition

void microd_decl1(const char *format, ...);
void microd_decl2(const char *format, ...);
void microd_decl3(const char *format, ...);

void microd_decl12(const char *format, ...);
void microd_decl23(const char *format, ...);
void microd_decl123(const char *format, ...);

char *comment1(const char *format, ...);
char *comment2(const char *format, ...);

//////////////////////////////////////////////////////////////////////////

struct MDState;

MDState *mds = NULL;

struct MDState
{
    VarDeclaration *sthis;
    MDState *prev;
    Module *m;
    Dsymbol *symbol;

    /////////////////////

    FuncDeclaration *getFunc()
    {
        MDState *bc = this;
        for (; bc->prev; bc = bc->prev);
        return (FuncDeclaration *)(bc->symbol);
    }

    /////////////////////

    MDState(Module *m, Dsymbol *s)
    {
        autopop = 1;
        push(m, s);
    }
    ~MDState()
    {
        if (autopop)
            pop();
    }
private:

    MDState *next;
    int autopop;

    MDState()
    {
        autopop = 0;
    }

    static void push(Module *m, Dsymbol *s)
    {
        MDState *x = new MDState;
        x->next = mds;
        mds = x;

        mds->prev = NULL;
        mds->m = m;
        mds->symbol = s;
        mds->sthis = NULL;
    }

    static void pop()
    {
        mds = mds->next;
    }
};

//////////////////////////////////////////////////////////////////////////

void getEthis(md_fptr sink, Loc loc, FuncDeclaration *fd);
void callfunc(md_fptr sink, int directcall, Type *tret, Expression *ec, Type *ectype,
              FuncDeclaration *fd, Type *t, Expression *ehidden, Expressions *arguments);
void escapeString(md_fptr sink, StringExp *se);

//////////////////////////////////////////////////////////////////////////

void microd_generate(Modules *modules)
{
    microd_decl1("#include \"microdbase.h\"\n\n");
    microd_decl1(comment1("Type declarations"));
    microd_decl2(comment1("Type definitions and Var/Func declarations"));
    microd_decl3(comment1("Var/Func definitions"));

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

    buf1.writestring(buf2.toChars());
    buf1.writestring(buf3.toChars());

    mdfile->setbuffer(buf1.data, buf1.offset);
    mdfile->writev();
}

//////////////////////////////////////////////////////////////////////////

void Module::toMicroD()
{
    microd_decl123(comment2("Module %s", toChars()));

    for (size_t i = 0; i < members->dim; i++)
    {
        Dsymbol *s = (*members)[i];
        s->toMicroD();
    }

    while (xdeferred.dim != 0)
    {
        Dsymbol *s = xdeferred[0];
        xdeferred.remove(0);
        s->toMicroD();
    }
}

//////////////////////////////////////////////////////////////////////////

void Dsymbol::toMicroD()
{
    printf("ignored: %s %s\n", kind(), toChars());
    assert(!isStructDeclaration());
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
    // Find module m for this function
    Module *m = NULL;
    for (Dsymbol *p = parent; p; p = p->parent)
    {
        m = p->isModule();
        if (m)
            break;
    }
    MDState xmds(m, this);

    // Forward declaration
    md_fptr sink = &microd_decl23;

    assert(type->ty == Tfunction);
    TypeFunction *tf = (TypeFunction *)type;
    tf->next->toMicroD(sink);
    sink(" ");
    sink(mangle());
    sink("(");
    for (size_t i = 0; parameters && i < parameters->dim; i++)
    {
        if (i != 0)
            sink(", ");
        VarDeclaration *p = (*parameters)[i];
        p->toMicroD(sink);
    }
    if (vthis)
    {
        if (tf->parameters->dim)
            sink(", ");
        mds->sthis = vthis;
        vthis->toMicroD(sink);
    }
    microd_decl2(");\n");

    // Body
    sink = &microd_decl3;
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
    md_fptr sink = &microd_decl23;

    type->toMicroD(sink);
    sink(" ");
    sink(mangle());

    if (init)
    {
        microd_decl3(" = ");
        init->toMicroD(&microd_decl3);
    }
    sink(";\n");
}

void StructDeclaration::toMicroD()
{
    char *name = mangle();
    microd_decl1("typedef struct __d_%s __d_%s;\n", name, name);

    md_fptr sink = &microd_decl2;

    sink("struct __d_");
    sink(name);
    sink("\n{\n");

    for (size_t i = 0; i < members->dim; i++)
    {
        Dsymbol *s = (*members)[i];

        if (Declaration *vd = s->isVarDeclaration())
        {
            vd->toMicroD(sink);
            sink(";\n");
        }
        else if (FuncDeclaration *fd = s->isFuncDeclaration())
        {
            xdeferred.push(fd);
        }
        else
        {
            s->error("not supported in MicroD");
            sink("__dsymbol__;\n");
        }
    }

    sink("};\n");
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
    if (isRef())
        sink("*");
    sink(" ");
    sink(mangle());


    if (init)
    {
        sink(" = ");
        ExpInitializer *ie = init->isExpInitializer();
        if (ie && (ie->exp->op == TOKconstruct || ie->exp->op == TOKblit))
        {
            Expression *ex = ((AssignExp *)ie->exp)->e2;
            if (ex->op == TOKint64 && type->ty == Tstruct)
                goto Ldefault;
            else
                ex->toMicroD(sink);
        }
        else if (ie->exp->op == TOKint64 && type->ty == Tstruct)
            goto Ldefault;
        else
            init->toMicroD(sink);
    }
    else if (!isParameter() && !isThis())
    {
        sink(" = ");
    Ldefault:
        type->defaultInitLiteral(loc)->toMicroD(sink);
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

void TypeStruct::toMicroD(md_fptr sink)
{
    sink("__d_");
    sink(sym->mangle());
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

        sink("(");
        e1->toMicroD(sink);
        sink(" %s ", Token::toChars(op));
        e2->toMicroD(sink);
        sink(")");
        break;
    default:
        Expression::toMicroD(sink);
        break;
    }
}

void CallExp::toMicroD(md_fptr sink)
{
    Type *t1 = e1->type->toBasetype();
    Type *ectype = t1;
    Expression *ec;
    FuncDeclaration *fd;
    int directcall;
    Expression *ehidden = NULL;

    if (e1->op == TOKdotvar && t1->ty != Tdelegate)
    {
        DotVarExp *dve = (DotVarExp *)e1;

        fd = dve->var->isFuncDeclaration();
        Expression *ex = dve->e1;
        while (1)
        {
            switch (ex->op)
            {
                case TOKsuper:          // super.member() calls directly
                case TOKdottype:        // type.member() calls directly
                    directcall = 1;
                    break;

                case TOKcast:
                    ex = ((CastExp *)ex)->e1;
                    continue;

                default:
                    //ex->dump(0);
                    break;
            }
            break;
        }
        ec = dve->e1;
        ectype = dve->e1->type->toBasetype();
    }
    else if (e1->op == TOKvar)
    {
        fd = ((VarExp *)e1)->var->isFuncDeclaration();
        ec = e1;
    }
    else
    {
        ec = e1;
    }

    callfunc(sink, directcall, type, ec, ectype, fd, t1, ehidden, arguments);
}

void DotVarExp::toMicroD(md_fptr sink)
{
    sink("(");
    e1->toMicroD(sink);
    sink(").");
    sink(var->mangle());
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

void AssertExp::toMicroD(md_fptr sink)
{
    e1->toMicroD(sink);
    sink(" || ");
    if (msg)
    {
        sink("__d_assert_msg(");
        msg->toMicroD(sink);
        sink(", ");
    }
    else
        sink("__d_assert(");

    sink("__d_array(");
    escapeString(sink, new StringExp(0, (char*)loc.filename, strlen(loc.filename)));
    sink(", %d), %d);", strlen(loc.filename), loc.linnum);
}

void StringExp::toMicroD(md_fptr sink)
{
    Type *tb = type->toBasetype();
    if (!tb->nextOf() || tb->nextOf()->ty != Tchar)
    {
        error("only utf-8 strings are supported in MicroD, not %s", toChars());
        sink("__StringExp__");
        return;
    }

    if (tb->ty == Tpointer)
    {
        escapeString(sink, this);
    }
    else if (tb->ty == Tarray)
    {
        sink("__d_array(");
        escapeString(sink, this);
        sink(", %d)", len);
    }
    else
    {
        error("only char* strings are supported in MicroD, not %s", toChars());
        sink("__StringExp__");
        return;
    }
}

void NullExp::toMicroD(md_fptr sink)
{
    sink("0");
}

void AddrExp::toMicroD(md_fptr sink)
{
    sink("&");
    e1->toMicroD(sink);
}

void ThisExp::toMicroD(md_fptr sink)
{
    FuncDeclaration *fd;
    assert(mds->sthis);

    if (type->ty == Tstruct)
        sink("*");

    if (var)
    {
        assert(var->parent);
        fd = var->toParent2()->isFuncDeclaration();
        assert(fd);
        getEthis(sink, loc, fd);
    }
    else
        sink(mds->sthis->mangle());
}

void StructLiteralExp::toMicroD(md_fptr sink)
{
    sink("{");
    for (size_t i = 0; i < elements->dim; i++)
    {
        Expression *e = (*elements)[i];
        if (i)
            sink(", ");
        e->toMicroD(sink);
    }
    sink("}");
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
    sink("__statement__;\n");
}

void CompoundStatement::toMicroD(md_fptr sink)
{
    for (size_t i = 0; i < statements->dim; i++)
    {
        Statement *s = (*statements)[i];
        s->toMicroD(sink);
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
    sink(";\n");
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

void microd_decl1(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf1.vprintf(format,ap);
    va_end(ap);
}

void microd_decl2(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf2.vprintf(format,ap);
    va_end(ap);
}

void microd_decl3(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf3.vprintf(format,ap);
    va_end(ap);
}

void microd_decl12(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf1.vprintf(format,ap);
    buf2.vprintf(format,ap);
    va_end(ap);
}

void microd_decl23(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf2.vprintf(format,ap);
    buf3.vprintf(format,ap);
    va_end(ap);
}

void microd_decl123(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    buf1.vprintf(format,ap);
    buf2.vprintf(format,ap);
    buf3.vprintf(format,ap);
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

void getEthis(md_fptr sink, Loc loc, FuncDeclaration *fd)
{
    FuncDeclaration *thisfd = mds->getFunc();
    Dsymbol *fdparent = fd->toParent2();

    if (fd->ident == Id::require || fd->ident == Id::ensure)
        assert(0);

    if (fdparent == thisfd)
    {
        //if (mds->sclosure)

        if (mds->sthis)
        {
            if (thisfd->hasNestedFrameRefs())
                sink("&");
            sink(mds->sthis->mangle());
        }
        else
        {
            assert(0);
        }
    }
    else
    {
        if (!mds->sthis)
        {
            fd->error(loc, "is a nested function and cannot be accessed from %s", mds->getFunc()->toPrettyChars());
            sink("__ethis__");
            return;
        }
        else
        {
            VarDeclaration *ethis = mds->sthis;
            Dsymbol *s = thisfd;
            while (fd != s)
            {
                thisfd = s->isFuncDeclaration();
                if (thisfd)
                {
                    if (fdparent == s->toParent2())
                        break;
                    if (thisfd->isNested())
                    {
                        FuncDeclaration *p = s->toParent2()->isFuncDeclaration();
                        if (!p || p->hasNestedFrameRefs())
                            sink("*");
                    }
                    else if (thisfd->vthis)
                    {
                    }
                    else
                    {   // Error should have been caught by front end
                        assert(0);
                    }
                }
                else
                {
                    assert(0);
                }
                s = s->toParent2();
                assert(s);
            }
            sink(ethis->mangle());
        }
    }
}

void callfunc(md_fptr sink, int directcall, Type *tret, Expression *ec, Type *ectype,
              FuncDeclaration *fd, Type *t, Expression *ehidden, Expressions *arguments)
{
    t = t->toBasetype();
    TypeFunction *tf;
    Expression *ethis = NULL;

    if (t->ty == Tdelegate)
    {
        ec->error("delegate calls are not supported in MicroD");
        sink("__callfunc__");
        return;
    }
    else
    {
        assert(t->ty == Tfunction);
        tf = (TypeFunction *)t;
    }

    if (fd && fd->isMember2())
    {
        AggregateDeclaration *ad = fd->isThis();

        if (ad)
        {
            ethis = ec;
            if (ad->isStructDeclaration() && ectype->toBasetype()->ty != Tpointer)
                ethis = ethis->addressOf(NULL);
        }
        else
        {
            assert(0);
        }

        if (!fd->isVirtual() ||
            directcall ||
            fd->isFinal())
        {
            ec = new VarExp(0, fd);
        }
        else
        {
            ec->error("virtual function calls are not supported in MicroD");
            sink("__callfunc__");
            return;
        }
    }
    else if (fd && fd->isNested())
    {
        ec->error("nested function calls are not supported in MicroD");
        sink("__callfunc__");
        return;
    }

    if (tf->isref)
        sink("*");

    ec->toMicroD(sink);
    sink("(");

    if (arguments)
    {
        int j = (tf->linkage == LINKd && tf->varargs == 1);

        for (size_t i = 0; i < arguments->dim; i++)
        {
            if (i != 0)
                sink(", ");

            Expression *arg = (*arguments)[i];
            size_t nparams = Parameter::dim(tf->parameters);
            if (i - j < nparams && i >= j)
            {
                Parameter *p = Parameter::getNth(tf->parameters, i - j);

                if (p->storageClass & (STCout | STCref))
                    sink("&");
            }
            arg->toMicroD(sink);
        }
    }

    if (ethis)
    {
        if (arguments && arguments->dim)
            sink(", ");
        ethis->toMicroD(sink);
    }
    sink(")");
}

void escapeString(md_fptr sink, StringExp *se)
{
    sink("\"");
    for (size_t i = 0; i < se->len; i++)
    {
        unsigned c = se->charAt(i);

        switch (c)
        {
            case '"':
            case '\\':
                sink("\\");
            default:
                if (c <= 0xFF)
                {   if (c <= 0x7F && isprint(c))
                        sink("%c", c);
                    else
                        sink("\\x%02x", c);
                }
                else if (c <= 0xFFFF)
                    sink("\\x%02x\\x%02x", c & 0xFF, c >> 8);
                else
                    sink("\\x%02x\\x%02x\\x%02x\\x%02x",
                        c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, c >> 24);
                break;
        }
    }
    sink("\"");
}
