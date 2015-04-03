
/* Compiler implementation of the D programming language
 * Copyright (c) 1999-2014 by Digital Mars
 * All Rights Reserved
 * written by Walter Bright
 * http://www.digitalmars.com
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 * https://github.com/D-Programming-Language/dmd/blob/master/src/typinf.c
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "mars.h"
#include "module.h"
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
#include "target.h"
#include "visitor.h"

#include "dt.h"

Symbol *toSymbol(Dsymbol *s);
dt_t **Expression_toDt(Expression *e, dt_t **pdt);
void toObjFile(Dsymbol *ds, bool multiobj);
Symbol *toVtblSymbol(ClassDeclaration *cd);
Symbol *toInitializer(AggregateDeclaration *ad);
Symbol *toInitializer(EnumDeclaration *ed);
Expression *getTypeInfo(Type *t, Scope *sc);
TypeInfoDeclaration *getTypeInfoDeclaration(Type *t);
static bool builtinTypeInfo(Type *t);

FuncDeclaration *search_toString(StructDeclaration *sd);

/****************************************************
 * Get the exact TypeInfo.
 */

void genTypeInfo(Type *torig, Scope *sc)
{
    //printf("Type::genTypeInfo() %p, %s\n", this, toChars());
    if (!Type::dtypeinfo)
    {
        torig->error(Loc(), "TypeInfo not found. object.d may be incorrectly installed or corrupt, compile with -v switch");
        fatal();
    }

    Type *t = torig->merge2(); // do this since not all Type's are merge'd
    if (!t->vtinfo)
    {
        if (t->isShared())      // does both 'shared' and 'shared const'
            t->vtinfo = TypeInfoSharedDeclaration::create(t);
        else if (t->isConst())
            t->vtinfo = TypeInfoConstDeclaration::create(t);
        else if (t->isImmutable())
            t->vtinfo = TypeInfoInvariantDeclaration::create(t);
        else if (t->isWild())
            t->vtinfo = TypeInfoWildDeclaration::create(t);
        else
            t->vtinfo = getTypeInfoDeclaration(t);
        assert(t->vtinfo);

        /* If this has a custom implementation in std/typeinfo, then
         * do not generate a COMDAT for it.
         */
        if (!builtinTypeInfo(t))
        {
            // Generate COMDAT
            if (sc)                     // if in semantic() pass
            {
                if (sc->func && sc->func->inNonRoot())
                {
                    // Bugzilla 13043: Avoid linking TypeInfo if it's not
                    // necessary for root module compilation
                }
                else
                {
                    // Find module that will go all the way to an object file
                    Module *m = sc->module->importedFrom;
                    m->members->push(t->vtinfo);

                    semanticTypeInfo(sc, t);
                }
            }
            else                        // if in obj generation pass
            {
                toObjFile(t->vtinfo, global.params.multiobj);
            }
        }
    }
    if (!torig->vtinfo)
        torig->vtinfo = t->vtinfo;     // Types aren't merged, but we can share the vtinfo's
    assert(torig->vtinfo);
}

Expression *getTypeInfo(Type *t, Scope *sc)
{
    assert(t->ty != Terror);
    genTypeInfo(t, sc);
    Expression *e = VarExp::create(Loc(), t->vtinfo);
    e = e->addressOf();
    e->type = t->vtinfo->type;     // do this so we don't get redundant dereference
    return e;
}

TypeInfoDeclaration *getTypeInfoDeclaration(Type *t)
{
    //printf("Type::getTypeInfoDeclaration() %s\n", t->toChars());
    switch(t->ty)
    {
    case Tpointer:  return TypeInfoPointerDeclaration::create(t);
    case Tarray:    return TypeInfoArrayDeclaration::create(t);
    case Tsarray:   return TypeInfoStaticArrayDeclaration::create(t);
    case Taarray:   return TypeInfoAssociativeArrayDeclaration::create(t);
    case Tstruct:   return TypeInfoStructDeclaration::create(t);
    case Tvector:   return TypeInfoVectorDeclaration::create(t);
    case Tenum:     return TypeInfoEnumDeclaration::create(t);
    case Tfunction: return TypeInfoFunctionDeclaration::create(t);
    case Tdelegate: return TypeInfoDelegateDeclaration::create(t);
    case Ttuple:    return TypeInfoTupleDeclaration::create(t);
    case Tclass:
        if (((TypeClass *)t)->sym->isInterfaceDeclaration())
            return TypeInfoInterfaceDeclaration::create(t);
        else
            return TypeInfoClassDeclaration::create(t);
    default:
        return TypeInfoDeclaration::create(t, 0);
    }
}

/****************************************************
 */

class TypeInfoDtVisitor : public Visitor
{
private:
    dt_t **pdt;

    /*
     * Used in TypeInfo*::toDt to verify the runtime TypeInfo sizes
     */
    static void verifyStructSize(ClassDeclaration *typeclass, size_t expected)
    {
            if (typeclass->structsize != expected)
            {
#ifdef DEBUG
                printf("expected = x%x, %s.structsize = x%x\n", (unsigned)expected,
                    typeclass->toChars(), (unsigned)typeclass->structsize);
#endif
                error(typeclass->loc, "mismatch between compiler and object.d or object.di found. Check installation and import paths with -v compiler switch.");
                fatal();
            }
    }

public:
    TypeInfoDtVisitor(dt_t **pdt)
        : pdt(pdt)
    {
    }

    void visit(TypeInfoDeclaration *d)
    {
        //printf("TypeInfoDeclaration::toDt() %s\n", toChars());
        verifyStructSize(Type::dtypeinfo, 2 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::dtypeinfo), 0); // vtbl for TypeInfo
        dtsize_t(pdt, 0);                        // monitor
    }

    void visit(TypeInfoConstDeclaration *d)
    {
        //printf("TypeInfoConstDeclaration::toDt() %s\n", toChars());
        verifyStructSize(Type::typeinfoconst, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoconst), 0); // vtbl for TypeInfo_Const
        dtsize_t(pdt, 0);                        // monitor
        Type *tm = d->tinfo->mutableOf();
        tm = tm->merge();
        genTypeInfo(tm, NULL);
        dtxoff(pdt, toSymbol(tm->vtinfo), 0);
    }

    void visit(TypeInfoInvariantDeclaration *d)
    {
        //printf("TypeInfoInvariantDeclaration::toDt() %s\n", toChars());
        verifyStructSize(Type::typeinfoinvariant, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoinvariant), 0); // vtbl for TypeInfo_Invariant
        dtsize_t(pdt, 0);                        // monitor
        Type *tm = d->tinfo->mutableOf();
        tm = tm->merge();
        genTypeInfo(tm, NULL);
        dtxoff(pdt, toSymbol(tm->vtinfo), 0);
    }

    void visit(TypeInfoSharedDeclaration *d)
    {
        //printf("TypeInfoSharedDeclaration::toDt() %s\n", toChars());
        verifyStructSize(Type::typeinfoshared, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoshared), 0); // vtbl for TypeInfo_Shared
        dtsize_t(pdt, 0);                        // monitor
        Type *tm = d->tinfo->unSharedOf();
        tm = tm->merge();
        genTypeInfo(tm, NULL);
        dtxoff(pdt, toSymbol(tm->vtinfo), 0);
    }

    void visit(TypeInfoWildDeclaration *d)
    {
        //printf("TypeInfoWildDeclaration::toDt() %s\n", toChars());
        verifyStructSize(Type::typeinfowild, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfowild), 0); // vtbl for TypeInfo_Wild
        dtsize_t(pdt, 0);                        // monitor
        Type *tm = d->tinfo->mutableOf();
        tm = tm->merge();
        genTypeInfo(tm, NULL);
        dtxoff(pdt, toSymbol(tm->vtinfo), 0);
    }

    void visit(TypeInfoEnumDeclaration *d)
    {
        //printf("TypeInfoEnumDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfoenum, 7 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoenum), 0); // vtbl for TypeInfo_Enum
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tenum);

        TypeEnum *tc = (TypeEnum *)d->tinfo;
        EnumDeclaration *sd = tc->sym;

        /* Put out:
         *  TypeInfo base;
         *  char[] name;
         *  void[] m_init;
         */

        if (sd->memtype)
        {
            genTypeInfo(sd->memtype, NULL);
            dtxoff(pdt, toSymbol(sd->memtype->vtinfo), 0);        // TypeInfo for enum members
        }
        else
            dtsize_t(pdt, 0);

        const char *name = sd->toPrettyChars();
        size_t namelen = strlen(name);
        dtsize_t(pdt, namelen);
        dtabytes(pdt, 0, namelen + 1, name);

        // void[] init;
        if (!sd->members || d->tinfo->isZeroInit())
        {
            // 0 initializer, or the same as the base type
            dtsize_t(pdt, 0);        // init.length
            dtsize_t(pdt, 0);        // init.ptr
        }
        else
        {
            dtsize_t(pdt, sd->type->size()); // init.length
            dtxoff(pdt, toInitializer(sd), 0);    // init.ptr
        }
    }

    void visit(TypeInfoPointerDeclaration *d)
    {
        //printf("TypeInfoPointerDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfopointer, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfopointer), 0); // vtbl for TypeInfo_Pointer
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tpointer);

        TypePointer *tc = (TypePointer *)d->tinfo;

        genTypeInfo(tc->next, NULL);
        dtxoff(pdt, toSymbol(tc->next->vtinfo), 0); // TypeInfo for type being pointed to
    }

    void visit(TypeInfoArrayDeclaration *d)
    {
        //printf("TypeInfoArrayDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfoarray, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoarray), 0); // vtbl for TypeInfo_Array
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tarray);

        TypeDArray *tc = (TypeDArray *)d->tinfo;

        genTypeInfo(tc->next, NULL);
        dtxoff(pdt, toSymbol(tc->next->vtinfo), 0); // TypeInfo for array of type
    }

    void visit(TypeInfoStaticArrayDeclaration *d)
    {
        //printf("TypeInfoStaticArrayDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfostaticarray, 4 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfostaticarray), 0); // vtbl for TypeInfo_StaticArray
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tsarray);

        TypeSArray *tc = (TypeSArray *)d->tinfo;

        genTypeInfo(tc->next, NULL);
        dtxoff(pdt, toSymbol(tc->next->vtinfo), 0); // TypeInfo for array of type

        dtsize_t(pdt, tc->dim->toInteger());         // length
    }

    void visit(TypeInfoVectorDeclaration *d)
    {
        //printf("TypeInfoVectorDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfovector, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfovector), 0); // vtbl for TypeInfo_Vector
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tvector);

        TypeVector *tc = (TypeVector *)d->tinfo;

        genTypeInfo(tc->basetype, NULL);
        dtxoff(pdt, toSymbol(tc->basetype->vtinfo), 0); // TypeInfo for equivalent static array
    }

    void visit(TypeInfoAssociativeArrayDeclaration *d)
    {
        //printf("TypeInfoAssociativeArrayDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfoassociativearray, 4 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfoassociativearray), 0); // vtbl for TypeInfo_AssociativeArray
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Taarray);

        TypeAArray *tc = (TypeAArray *)d->tinfo;

        genTypeInfo(tc->next, NULL);
        dtxoff(pdt, toSymbol(tc->next->vtinfo), 0); // TypeInfo for array of type

        genTypeInfo(tc->index, NULL);
        dtxoff(pdt, toSymbol(tc->index->vtinfo), 0); // TypeInfo for array of type
    }

    void visit(TypeInfoFunctionDeclaration *d)
    {
        //printf("TypeInfoFunctionDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfofunction, 5 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfofunction), 0); // vtbl for TypeInfo_Function
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tfunction);

        TypeFunction *tc = (TypeFunction *)d->tinfo;

        genTypeInfo(tc->next, NULL);
        dtxoff(pdt, toSymbol(tc->next->vtinfo), 0); // TypeInfo for function return value

        const char *name = d->tinfo->deco;
        assert(name);
        size_t namelen = strlen(name);
        dtsize_t(pdt, namelen);
        dtabytes(pdt, 0, namelen + 1, name);
    }

    void visit(TypeInfoDelegateDeclaration *d)
    {
        //printf("TypeInfoDelegateDeclaration::toDt()\n");
        verifyStructSize(Type::typeinfodelegate, 5 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfodelegate), 0); // vtbl for TypeInfo_Delegate
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tdelegate);

        TypeDelegate *tc = (TypeDelegate *)d->tinfo;

        genTypeInfo(tc->next->nextOf(), NULL);
        dtxoff(pdt, toSymbol(tc->next->nextOf()->vtinfo), 0); // TypeInfo for delegate return value

        const char *name = d->tinfo->deco;
        assert(name);
        size_t namelen = strlen(name);
        dtsize_t(pdt, namelen);
        dtabytes(pdt, 0, namelen + 1, name);
    }

    void visit(TypeInfoStructDeclaration *d)
    {
        //printf("TypeInfoStructDeclaration::toDt() '%s'\n", toChars());
        if (global.params.is64bit)
            verifyStructSize(Type::typeinfostruct, 17 * Target::ptrsize);
        else
            verifyStructSize(Type::typeinfostruct, 15 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfostruct), 0); // vtbl for TypeInfo_Struct
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tstruct);

        TypeStruct *tc = (TypeStruct *)d->tinfo;
        StructDeclaration *sd = tc->sym;

        if (!sd->members)
            return;

        /* Put out:
         *  char[] name;
         *  void[] init;
         *  hash_t function(in void*) xtoHash;
         *  bool function(in void*, in void*) xopEquals;
         *  int function(in void*, in void*) xopCmp;
         *  string function(const(void)*) xtoString;
         *  StructFlags m_flags;
         *  //xgetMembers;
         *  xdtor;
         *  xpostblit;
         *  uint m_align;
         *  version (X86_64)
         *      TypeInfo m_arg1;
         *      TypeInfo m_arg2;
         *  xgetRTInfo
         */

        const char *name = sd->toPrettyChars();
        size_t namelen = strlen(name);
        dtsize_t(pdt, namelen);
        dtabytes(pdt, 0, namelen + 1, name);

        // void[] init;
        dtsize_t(pdt, sd->structsize);       // init.length
        if (sd->zeroInit)
            dtsize_t(pdt, 0);                // NULL for 0 initialization
        else
            dtxoff(pdt, toInitializer(sd), 0);    // init.ptr

        if (FuncDeclaration *fd = sd->xhash)
        {
            dtxoff(pdt, toSymbol(fd), 0);
            TypeFunction *tf = (TypeFunction *)fd->type;
            assert(tf->ty == Tfunction);
            /* I'm a little unsure this is the right way to do it. Perhaps a better
             * way would to automatically add these attributes to any struct member
             * function with the name "toHash".
             * So I'm leaving this here as an experiment for the moment.
             */
            if (!tf->isnothrow || tf->trust == TRUSTsystem) /*|| tf->purity == PUREimpure*/
                warning(fd->loc, "toHash() must be declared as extern (D) size_t toHash() const nothrow @safe, not %s", tf->toChars());
        }
        else
            dtsize_t(pdt, 0);

        if (sd->xeq)
            dtxoff(pdt, toSymbol(sd->xeq), 0);
        else
            dtsize_t(pdt, 0);

        if (sd->xcmp)
            dtxoff(pdt, toSymbol(sd->xcmp), 0);
        else
            dtsize_t(pdt, 0);

        if (FuncDeclaration *fd = search_toString(sd))
        {
            dtxoff(pdt, toSymbol(fd), 0);
        }
        else
            dtsize_t(pdt, 0);

        unsigned m_flags = 0;
        if (tc->hasPointers()) m_flags |= StructFlags::hasPointers;
        dtsize_t(pdt, m_flags);

    #if 0
        // xgetMembers
        FuncDeclaration *sgetmembers = sd->findGetMembers();
        if (sgetmembers)
            dtxoff(pdt, toSymbol(sgetmembers), 0);
        else
            dtsize_t(pdt, 0);                        // xgetMembers
    #endif

        // xdtor
        FuncDeclaration *sdtor = sd->dtor;
        if (sdtor)
            dtxoff(pdt, toSymbol(sdtor), 0);
        else
            dtsize_t(pdt, 0);                        // xdtor

        // xpostblit
        FuncDeclaration *spostblit = sd->postblit;
        if (spostblit && !(spostblit->storage_class & STCdisable))
            dtxoff(pdt, toSymbol(spostblit), 0);
        else
            dtsize_t(pdt, 0);                        // xpostblit

        // uint m_align;
        dtsize_t(pdt, tc->alignsize());

        if (global.params.is64bit)
        {
            Type *t = sd->arg1type;
            for (int i = 0; i < 2; i++)
            {
                // m_argi
                if (t)
                {
                    genTypeInfo(t, NULL);
                    dtxoff(pdt, toSymbol(t->vtinfo), 0);
                }
                else
                    dtsize_t(pdt, 0);

                t = sd->arg2type;
            }
        }

        // xgetRTInfo
        if (sd->getRTInfo)
            Expression_toDt(sd->getRTInfo, pdt);
        else if (m_flags & StructFlags::hasPointers)
            dtsize_t(pdt, 1);
        else
            dtsize_t(pdt, 0);
    }

    void visit(TypeInfoClassDeclaration *d)
    {
        //printf("TypeInfoClassDeclaration::toDt() %s\n", tinfo->toChars());
        assert(0);
    }

    void visit(TypeInfoInterfaceDeclaration *d)
    {
        //printf("TypeInfoInterfaceDeclaration::toDt() %s\n", tinfo->toChars());
        verifyStructSize(Type::typeinfointerface, 3 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfointerface), 0); // vtbl for TypeInfoInterface
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Tclass);

        TypeClass *tc = (TypeClass *)d->tinfo;
        Symbol *s;

        if (!tc->sym->vclassinfo)
            tc->sym->vclassinfo = TypeInfoClassDeclaration::create(tc);
        s = toSymbol(tc->sym->vclassinfo);
        dtxoff(pdt, s, 0);          // ClassInfo for tinfo
    }

    void visit(TypeInfoTupleDeclaration *d)
    {
        //printf("TypeInfoTupleDeclaration::toDt() %s\n", tinfo->toChars());
        verifyStructSize(Type::typeinfotypelist, 4 * Target::ptrsize);

        dtxoff(pdt, toVtblSymbol(Type::typeinfotypelist), 0); // vtbl for TypeInfoInterface
        dtsize_t(pdt, 0);                        // monitor

        assert(d->tinfo->ty == Ttuple);

        TypeTuple *tu = (TypeTuple *)d->tinfo;

        size_t dim = tu->arguments->dim;
        dtsize_t(pdt, dim);                      // elements.length

        dt_t *dt = NULL;
        for (size_t i = 0; i < dim; i++)
        {
            Parameter *arg = (*tu->arguments)[i];
            Expression *e = getTypeInfo(arg->type, NULL);
            e = e->optimize(WANTvalue);
            Expression_toDt(e, &dt);
        }

        dtdtoff(pdt, dt, 0);              // elements.ptr
    }

};

void TypeInfo_toDt(dt_t **pdt, TypeInfoDeclaration *d)
{
    TypeInfoDtVisitor v(pdt);
    d->accept(&v);
}

/* ========================================================================= */

/* These decide if there's an instance for them already in std.typeinfo,
 * because then the compiler doesn't need to build one.
 */

static bool builtinTypeInfo(Type *t)
{
    if (t->isTypeBasic() || t->ty == Tclass)
        return !t->mod;
    if (t->ty == Tarray)
    {
        Type *next = t->nextOf();
        // strings are so common, make them builtin
        return !t->mod && (next->isTypeBasic() != NULL && !next->mod ||
            next->ty == Tchar && next->mod == MODimmutable ||
            next->ty == Tchar && next->mod == MODconst);
    }
    return false;
}
