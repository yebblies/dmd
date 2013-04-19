
// Compiler implementation of the D programming language
// Copyright (c) 1999-2012 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "mars.h"
#include "dsymbol.h"
#include "mtype.h"
#include "scope.h"
#include "init.h"
#include "expression.h"
#include "attrib.h"
#include "declaration.h"
#include "template.h"
#include "id.h"
#include "enum.h"
#include "import.h"
#include "aggregate.h"

#if (TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_OPENBSD || TARGET_SOLARIS)

/* Do mangling for C++ linkage.
 * Follows Itanium C++ ABI 1.86
 * No attempt is made to support mangling of templates, operator
 * overloading, or special functions.
 *
 * So why don't we use the C++ ABI for D name mangling?
 * Because D supports a lot of things (like modules) that the C++
 * ABI has no concept of. These affect every D mangled name,
 * so nothing would be compatible anyway.
 */

struct CppMangleState
{
    static Voids components;

    int substitute(OutBuffer *buf, void *p);
    int exist(void *p);
    void store(void *p);
};

Voids CppMangleState::components;


void writeBase36(OutBuffer *buf, unsigned i)
{
    if (i >= 36)
    {
        writeBase36(buf, i / 36);
        i %= 36;
    }
    if (i < 10)
        buf->writeByte(i + '0');
    else if (i < 36)
        buf->writeByte(i - 10 + 'A');
    else
        assert(0);
}

int CppMangleState::substitute(OutBuffer *buf, void *p)
{
    for (size_t i = 0; i < components.dim; i++)
    {
        if (p == components[i])
        {
            /* Sequence is S_, S0_, .., S9_, SA_, ..., SZ_, S10_, ...
             */
            buf->writeByte('S');
            if (i)
                writeBase36(buf, i - 1);
            buf->writeByte('_');
            return 1;
        }
    }
    components.push(p);
    return 0;
}

int CppMangleState::exist(void *p)
{
    for (size_t i = 0; i < components.dim; i++)
    {
        if (p == components[i])
        {
            return 1;
        }
    }
    return 0;
}

void CppMangleState::store(void *p)
{
    components.push(p);
}

void source_name(OutBuffer *buf, Dsymbol *s)
{
    char *name = s->ident->toChars();
    buf->printf("%d%s", strlen(name), name);
}

void prefix_name(OutBuffer *buf, CppMangleState *cms, Dsymbol *s)
{
    if (!cms->substitute(buf, s))
    {
        Dsymbol *p = s->toParent();
        if (p && !p->isModule())
        {
            prefix_name(buf, cms, p);
        }
        source_name(buf, s);
    }
}

void cpp_mangle_name(OutBuffer *buf, CppMangleState *cms, Dsymbol *s)
{
    Dsymbol *p = s->toParent();
    if (p && !p->isModule())
    {
        buf->writeByte('N');

        FuncDeclaration *fd = s->isFuncDeclaration();
        if (!fd)
        {
            s->error("C++ static variables not supported");
        }
        else if (fd->type->isConst())
            buf->writeByte('K');

        prefix_name(buf, cms, p);
        source_name(buf, s);

        buf->writeByte('E');
    }
    else
        source_name(buf, s);
}


char *cpp_mangle(Dsymbol *s)
{
    /*
     * <mangled-name> ::= _Z <encoding>
     * <encoding> ::= <function name> <bare-function-type>
     *         ::= <data name>
     *         ::= <special-name>
     */

    CppMangleState cms;
    memset(&cms, 0, sizeof(cms));
    cms.components.setDim(0);

    OutBuffer buf;
    buf.writestring("__Z" + !global.params.isOSX);      // "_Z" for OSX

    cpp_mangle_name(&buf, &cms, s);

    FuncDeclaration *fd = s->isFuncDeclaration();
    if (fd)
    {   // add <bare-function-type>
        TypeFunction *tf = (TypeFunction *)fd->type;
        assert(tf->ty == Tfunction);
        Parameter::argsCppMangle(&buf, &cms, tf->parameters, tf->varargs);
    }
    buf.writeByte(0);
    return (char *)buf.extractData();
}

/* ============= Type Encodings ============================================= */

void Type::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    /* Make this the 'vendor extended type' when there is no
     * C++ analog.
     * u <source-name>
     */
    if (!cms->substitute(buf, this))
    {   assert(deco);
        buf->printf("u%d%s", strlen(deco), deco);
    }
}

void TypeBasic::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{   char c;
    char p = 0;

    /* ABI spec says:
     * v        void
     * w        wchar_t
     * b        bool
     * c        char
     * a        signed char
     * h        unsigned char
     * s        short
     * t        unsigned short
     * i        int
     * j        unsigned int
     * l        long
     * m        unsigned long
     * x        long long, __int64
     * y        unsigned long long, __int64
     * n        __int128
     * o        unsigned __int128
     * f        float
     * d        double
     * e        long double, __float80
     * g        __float128
     * z        ellipsis
     * u <source-name>  # vendor extended type
     */

    switch (ty)
    {
        case Tvoid:     c = 'v';        break;
        case Tint8:     c = 'a';        break;
        case Tuns8:     c = 'h';        break;
        case Tint16:    c = 's';        break;
        case Tuns16:    c = 't';        break;
        case Tint32:    c = 'i';        break;
        case Tuns32:    c = 'j';        break;
        case Tfloat32:  c = 'f';        break;
        case Tint64:    c = 'x';        break;
        case Tuns64:    c = 'y';        break;
        case Tfloat64:  c = 'd';        break;
        case Tfloat80:  c = 'e';        break;
        case Tbool:     c = 'b';        break;
        case Tchar:     c = 'c';        break;
        case Twchar:    c = 't';        break;
        case Tdchar:    c = 'w';        break;

        case Timaginary32: p = 'G'; c = 'f';    break;
        case Timaginary64: p = 'G'; c = 'd';    break;
        case Timaginary80: p = 'G'; c = 'e';    break;
        case Tcomplex32:   p = 'C'; c = 'f';    break;
        case Tcomplex64:   p = 'C'; c = 'd';    break;
        case Tcomplex80:   p = 'C'; c = 'e';    break;

        default:        assert(0);
    }
    if (p || isConst())
    {
        if (cms->substitute(buf, this))
            return;
    }

    if (isConst())
        buf->writeByte('K');

    if (p)
        buf->writeByte(p);

    buf->writeByte(c);
}


void TypeVector::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->substitute(buf, this))
    {   buf->writestring("U8__vector");
        basetype->toCppMangle(buf, cms);
    }
}

void TypeSArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->substitute(buf, this))
    {   buf->printf("A%llu_", dim ? dim->toInteger() : 0);
        next->toCppMangle(buf, cms);
    }
}

void TypeDArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    Type::toCppMangle(buf, cms);
}


void TypeAArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    Type::toCppMangle(buf, cms);
}


void TypePointer::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->exist(this))
    {   buf->writeByte('P');
        next->toCppMangle(buf, cms);
        cms->store(this);
    }
    else
        cms->substitute(buf, this);
}


void TypeReference::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->exist(this))
    {   buf->writeByte('R');
        next->toCppMangle(buf, cms);
        cms->store(this);
    }
    else
        cms->substitute(buf, this);
}


void TypeFunction::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{   /*
     *  <function-type> ::= F [Y] <bare-function-type> E
     *  <bare-function-type> ::= <signature type>+
     *  # types are possible return type, then parameter types
     */

    /* ABI says:
        "The type of a non-static member function is considered to be different,
        for the purposes of substitution, from the type of a namespace-scope or
        static member function whose type appears similar. The types of two
        non-static member functions are considered to be different, for the
        purposes of substitution, if the functions are members of different
        classes. In other words, for the purposes of substitution, the class of
        which the function is a member is considered part of the type of
        function."

        BUG: Right now, types of functions are never merged, so our simplistic
        component matcher always finds them to be different.
        We should use Type::equals on these, and use different
        TypeFunctions for non-static member functions, and non-static
        member functions of different classes.
     */
    if (!cms->substitute(buf, this))
    {
        buf->writeByte('F');
        if (linkage == LINKc)
            buf->writeByte('Y');
        next->toCppMangle(buf, cms);
        Parameter::argsCppMangle(buf, cms, parameters, varargs);
        buf->writeByte('E');
    }
}


void TypeDelegate::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    Type::toCppMangle(buf, cms);
}


void TypeStruct::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->exist(this))
    {
        if (isConst())
            buf->writeByte('K');

        if (!cms->substitute(buf, sym))
            cpp_mangle_name(buf, cms, sym);

        if (isConst())
            cms->store(this);
    }
    else
        cms->substitute(buf, this);
}


void TypeEnum::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->exist(this))
    {
        if (isConst())
            buf->writeByte('K');

        if (!cms->substitute(buf, sym))
            cpp_mangle_name(buf, cms, sym);

        if (isConst())
            cms->store(this);
    }
    else
        cms->substitute(buf, this);
}


void TypeTypedef::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    Type::toCppMangle(buf, cms);
}


void TypeClass::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    if (!cms->substitute(buf, this))
    {   buf->writeByte('P');
        if (!cms->substitute(buf, sym))
            cpp_mangle_name(buf, cms, sym);
    }
}

struct ArgsCppMangleCtx
{
    OutBuffer *buf;
    CppMangleState *cms;
    size_t cnt;
};

static int argsCppMangleDg(void *ctx, size_t n, Parameter *arg)
{
    ArgsCppMangleCtx *p = (ArgsCppMangleCtx *)ctx;

    Type *t = arg->type;
    if (arg->storageClass & (STCout | STCref))
        t = t->referenceTo();
    else if (arg->storageClass & STClazy)
    {   // Mangle as delegate
        Type *td = new TypeFunction(NULL, t, 0, LINKd);
        td = new TypeDelegate(td);
        t = t->merge();
    }
    if (t->ty == Tsarray)
    {   // Mangle static arrays as pointers
        t = t->pointerTo();
    }

    /* If it is a basic, enum or struct type,
     * then don't mark it const
     */
    if ((t->ty == Tenum || t->ty == Tstruct || t->isTypeBasic()) && t->isConst())
        t->mutableOf()->toCppMangle(p->buf, p->cms);
    else
        t->toCppMangle(p->buf, p->cms);

    p->cnt++;
    return 0;
}

void Parameter::argsCppMangle(OutBuffer *buf, CppMangleState *cms, Parameters *arguments, int varargs)
{
    size_t n = 0;
    if (arguments)
    {
        ArgsCppMangleCtx ctx = { buf, cms, 0 };
        foreach(arguments, &argsCppMangleDg, &ctx);
        n = ctx.cnt;
    }
    if (varargs)
        buf->writestring("z");
    else if (!n)
        buf->writeByte('v');            // encode ( ) arguments
}

#elif TARGET_WINDOS

struct CppMangleState
{
    Strings cache;
    void substitute(OutBuffer *buf, char *s)
    {
        for (size_t i = 0; i < cache.dim; i++)
        {
            if (!strcmp(cache[i], s))
            {
                buf->printf("%d", i);
                return;
            }
        }
        cache.push(s);
        buf->writestring(s);
    }
};

char *cpp_mangle(Dsymbol *s)
{
    CppMangleState cms;
    memset(&cms, 0, sizeof(cms));

    //printf("cpp_mangle: %s\n", s->toPrettyChars());

    OutBuffer buf;

    Declaration *d = s->isDeclaration();
    assert(d);
    FuncDeclaration *fd = s->isFuncDeclaration();
    VarDeclaration *vd = s->isVarDeclaration();
    if (fd)
    {
        buf.writebyte('?');
        buf.writestring(fd->ident->toChars());
        buf.writebyte('@');

        Dsymbol *parent = fd->toParent();
        if (parent->isModule())
        {
            buf.writestring("@Y");
        }
        else
        {
            assert(0);
        }

        buf.writestring("A"); // __cdecl
        TypeFunction *tf = (TypeFunction *)fd->type;
        tf->next->toCppMangle(&buf, &cms);

        Parameter::argsCppMangle(&buf, &cms, tf->parameters, tf->varargs);
        buf.writebyte('Z');
    }
    else if (vd)
    {
        buf.writebyte('?');
        buf.writestring(vd->ident->toChars());
        buf.writebyte('@');

        Dsymbol *parent = vd->toParent();
        if (parent->isModule())
        {
            buf.writestring("@3");
        }
        else
        {
            assert(0);
        }

        vd->type->toCppMangle(&buf, &cms);

        int mod;
        if (vd->type->ty == Tpointer)
            mod = vd->type->nextOf()->mod;
        else
            mod = vd->type->mod;
        if (mod & MODconst)
            buf.writebyte('B');
        else
            buf.writebyte('A');
    }

    if (!buf.offset)
        buf.writestring("__dummy__");
    buf.writebyte(0);
    //printf("%s -> %s %s\n", s->toChars(), buf.toChars(), d->type->toChars());
    //assert(0);
    return buf.extractData();
}

void Parameter::argsCppMangle(OutBuffer *buf, CppMangleState *, Parameters *arguments, int varargs)
{
    CppMangleState cms;
    if (arguments && Parameter::dim(arguments))
    {
        for (size_t i = 0; i < Parameter::dim(arguments); i++)
        {
            Type *t = (*arguments)[i]->type;
            t->toCppMangle(buf, &cms);
        }
        if (varargs)
            buf->writebyte('Z');
        else
            buf->writebyte('@');
    }
    else
    {
        buf->writebyte('X');
    }
}

void Type::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeBasic::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    switch(ty)
    {
    case Tvoid:    buf->writebyte('X'); break;
    case Tchar:    buf->writebyte('D'); break;
    case Twchar:   buf->writestring("_Y"); break;
    case Tdchar:   buf->writestring("K"); break;
    case Tint8:    buf->writebyte('C'); break;
    case Tuns8:    buf->writebyte('E'); break;
    case Tint16:   buf->writebyte('F'); break;
    case Tuns16:   buf->writebyte('G'); break;
    case Tint32:   buf->writebyte('H'); break;
    case Tuns32:   buf->writebyte('I'); break;
    case Tint64:   buf->writestring("_J"); break;
    case Tuns64:   buf->writestring("_K"); break;
    case Tfloat32: buf->writebyte('M'); break;
    case Tfloat64: buf->writebyte('N'); break;
    case Tfloat80: buf->writestring("_Z"); break;

    case Tbool:        cms->substitute(buf, "_N"); break;
    case Timaginary32: cms->substitute(buf, "_R"); break;
    case Timaginary64: cms->substitute(buf, "_S"); break;
    case Timaginary80: cms->substitute(buf, "_T"); break;
    case Tcomplex32:   cms->substitute(buf, "_U"); break;
    case Tcomplex64:   cms->substitute(buf, "_V"); break;
    case Tcomplex80:   cms->substitute(buf, "_W"); break;
    default:
        printf("Internal error: Cannot mangle type %s\n", toChars());
        assert(0);
    }
}

void TypeVector::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeSArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeDArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeAArray::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypePointer::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    CppMangleState cms2;
    OutBuffer buf2;
    if (mod & MODconst)
        buf2.writebyte('Q');
    else
        buf2.writebyte('P');
    if (next->mod & MODconst)
        buf2.writebyte('B');
    else
        buf2.writebyte('A');
    next->toCppMangle(&buf2, &cms2);
    buf2.writebyte(0);
    cms->substitute(buf, buf2.extractData());
}

void TypeReference::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeFunction::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeDelegate::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeEnum::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    Type *tb = toBasetype();
    if (tb->ty == Tint32)
    {
        buf->writebyte('W');
    }
    else
    {
        tb->toCppMangle(buf, cms);
    }
}

void TypeTypedef::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    assert(0);
}

void TypeStruct::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    buf->writebyte('U');
}

void TypeClass::toCppMangle(OutBuffer *buf, CppMangleState *cms)
{
    buf->writebyte('V');
}

#else

#error "fix this"

#endif

