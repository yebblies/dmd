
// Copyright (c) 1999-2013 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

#include "mars.h"
#include "module.h"
#include "mtype.h"
#include "declaration.h"
#include "enum.h"
#include "aggregate.h"
#include "visitor.h"

#include "cc.h"
#include "global.h"
#include "type.h"

void slist_add(Symbol *s);
void slist_reset();

class ToCTypeVisitor : SuperVisitor
{
public:
    type *result;

    void visit(Type *t);
    void visit(TypeVector *t);
    void visit(TypeSArray *t);
    void visit(TypeDArray *t);
    void visit(TypeAArray *t);
    void visit(TypePointer *t);
    void visit(TypeFunction *t);
    void visit(TypeDelegate *t);
    void visit(TypeStruct *t);
    void visit(TypeEnum *t);
    void visit(TypeTypedef *t);
    void visit(TypeClass *t);
};

/***************************************
 * Convert from D type to C type.
 * This is done so C debug info can be generated.
 */

type *Type::toCtype()
{
    ToCTypeVisitor v;
    accept(&v);
    return v.result;
}

void ToCTypeVisitor::visit(Type *t)
{
    if (!t->ctype)
    {   t->ctype = type_fake(t->totym());
        t->ctype->Tcount++;
    }
    result = t->ctype;
}

type *Type::toCParamtype()
{
    return toCtype();
}

type *TypeSArray::toCParamtype()
{
    return toCtype();
}

void ToCTypeVisitor::visit(TypeVector *t)
{
    visit((Type *)t);
}

void ToCTypeVisitor::visit(TypeSArray *t)
{
    if (!t->ctype)
        t->ctype = type_static_array(t->dim->toInteger(), t->next->toCtype());
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeDArray *t)
{
    if (!t->ctype)
    {
        t->ctype = type_dyn_array(t->next->toCtype());
        t->ctype->Tident = t->toChars(); // needed to generate sensible debug info for cv8
    }
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeAArray *t)
{
    if (!t->ctype)
        t->ctype = type_assoc_array(t->index->toCtype(), t->next->toCtype());
    result = t->ctype;
}


void ToCTypeVisitor::visit(TypePointer *t)
{
    //printf("TypePointer::toCtype() %s\n", toChars());
    if (!t->ctype)
        t->ctype = type_pointer(t->next->toCtype());
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeFunction *t)
{
    if (!t->ctype)
    {
        size_t nparams = Parameter::dim(t->parameters);

        type *tmp[10];
        type **ptypes = tmp;
        if (nparams > 10)
            ptypes = (type **)malloc(sizeof(type*) * nparams);

        for (size_t i = 0; i < nparams; i++)
        {   Parameter *arg = Parameter::getNth(t->parameters, i);
            type *tp = arg->type->toCtype();
            if (arg->storageClass & (STCout | STCref))
                tp = type_allocn(TYref, tp);
            ptypes[i] = tp;
        }

        t->ctype = type_function(t->totym(), ptypes, nparams, t->varargs == 1, t->next->toCtype());

        if (nparams > 10)
            free(ptypes);
    }
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeDelegate *t)
{
    if (!t->ctype)
        t->ctype = type_delegate(t->next->toCtype());
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeStruct *t)
{
    if (t->ctype)
    {
        result = t->ctype;
        return;
    }

    //printf("TypeStruct::toCtype() '%s'\n", sym->toChars());
    Type *tm = t->mutableOf();
    if (tm->ctype)
    {
        Symbol *s = tm->ctype->Ttag;
        t->ctype = type_alloc(TYstruct);
        t->ctype->Ttag = (Classsym *)s;            // structure tag name
        t->ctype->Tcount++;
        // Add modifiers
        switch (t->mod)
        {
            case 0:
                assert(0);
                break;
            case MODconst:
            case MODwild:
                t->ctype->Tty |= mTYconst;
                break;
            case MODimmutable:
                t->ctype->Tty |= mTYimmutable;
                break;
            case MODshared:
                t->ctype->Tty |= mTYshared;
                break;
            case MODshared | MODwild:
            case MODshared | MODconst:
                t->ctype->Tty |= mTYshared | mTYconst;
                break;
            default:
                assert(0);
        }
    }
    else
    {
        t->ctype = type_struct_class(t->sym->toPrettyChars(), t->sym->alignsize, t->sym->structsize,
                t->sym->arg1type ? t->sym->arg1type->toCtype() : NULL,
                t->sym->arg2type ? t->sym->arg2type->toCtype() : NULL,
                t->sym->isUnionDeclaration() != 0,
                false,
                t->sym->isPOD() != 0);

        tm->ctype = t->ctype;

        /* Add in fields of the struct
         * (after setting ctype to avoid infinite recursion)
         */
        if (global.params.symdebug)
            for (size_t i = 0; i < t->sym->fields.dim; i++)
            {   VarDeclaration *v = t->sym->fields[i];

                symbol_struct_addField(t->ctype->Ttag, v->ident->toChars(), v->type->toCtype(), v->offset);
            }
    }

    //printf("t = %p, Tflags = x%x\n", ctype, ctype->Tflags);
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeEnum *t)
{
    if (t->ctype)
    {
        result = t->ctype;
        return;
    }

    //printf("TypeEnum::toCtype() '%s'\n", sym->toChars());
    Type *tm = t->mutableOf();
    if (tm->ctype && tybasic(tm->ctype->Tty) == TYenum)
    {
        Symbol *s = tm->ctype->Ttag;
        assert(s);
        t->ctype = type_alloc(TYenum);
        t->ctype->Ttag = (Classsym *)s;            // enum tag name
        t->ctype->Tcount++;
        t->ctype->Tnext = tm->ctype->Tnext;
        t->ctype->Tnext->Tcount++;
        // Add modifiers
        switch (t->mod)
        {
            case 0:
                assert(0);
                break;
            case MODconst:
            case MODwild:
                t->ctype->Tty |= mTYconst;
                break;
            case MODimmutable:
                t->ctype->Tty |= mTYimmutable;
                break;
            case MODshared:
                t->ctype->Tty |= mTYshared;
                break;
            case MODshared | MODwild:
            case MODshared | MODconst:
                t->ctype->Tty |= mTYshared | mTYconst;
                break;
            default:
                assert(0);
        }
    }
    else if (t->sym->memtype->toBasetype()->ty == Tint32)
    {
        t->ctype = type_enum(t->sym->toPrettyChars(), t->sym->memtype->toCtype());
        tm->ctype = t->ctype;
    }
    else
    {
        t->ctype = t->sym->memtype->toCtype();
    }

    //printf("t = %p, Tflags = x%x\n", t, t->Tflags);
    result = t->ctype;
}

void ToCTypeVisitor::visit(TypeTypedef *t)
{
    result = t->sym->basetype->toCtype();
}

type *TypeTypedef::toCParamtype()
{
    return sym->basetype->toCParamtype();
}

void ToCTypeVisitor::visit(TypeClass *t)
{
    //printf("TypeClass::toCtype() %s\n", toChars());
    if (t->ctype)
    {
        result = t->ctype;
        return;
    }

    t->ctype = type_struct_class(t->sym->toPrettyChars(), t->sym->alignsize, t->sym->structsize,
            NULL,
            NULL,
            false,
            true,
            true);

    t->ctype = type_pointer(t->ctype);

    /* Add in fields of the class
     * (after setting ctype to avoid infinite recursion)
     */
    if (global.params.symdebug)
        for (size_t i = 0; i < t->sym->fields.dim; i++)
        {   VarDeclaration *v = t->sym->fields[i];

            symbol_struct_addField(t->ctype->Ttag, v->ident->toChars(), v->type->toCtype(), v->offset);
        }

    result = t->ctype;
}

