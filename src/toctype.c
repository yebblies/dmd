
/* Compiler implementation of the D programming language
 * Copyright (c) 1999-2014 by Digital Mars
 * All Rights Reserved
 * written by Walter Bright
 * http://www.digitalmars.com
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 * https://github.com/D-Programming-Language/dmd/blob/master/src/toctype.c
 */

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
#include "id.h"
#include "aav.h"

#include "cc.h"
#include "global.h"
#include "type.h"

void slist_add(Symbol *s);
void slist_reset();
unsigned totym(Type *tx);

/***************************************
 * Convert from D type to C type.
 * This is done so C debug info can be generated.
 */

type *Type_toCtype(Type *t);

class ToCtypeVisitor : public Visitor
{
public:
    type *result;
    ToCtypeVisitor()
    {
        result = NULL;
    }

    void visit(Type *t)
    {
        result = type_fake(totym(t));
        result->Tcount++;
    }

    void visit(TypeSArray *t)
    {
        result = type_static_array(t->dim->toInteger(), Type_toCtype(t->next));
    }

    void visit(TypeDArray *t)
    {
        result = type_dyn_array(Type_toCtype(t->next));
        result->Tident = t->toPrettyChars(true);
    }

    void visit(TypeAArray *t)
    {
        result = type_assoc_array(Type_toCtype(t->index), Type_toCtype(t->next));
    }

    void visit(TypePointer *t)
    {
        //printf("TypePointer::toCtype() %s\n", t->toChars());
        result = type_pointer(Type_toCtype(t->next));
    }

    void visit(TypeFunction *t)
    {
        size_t nparams = Parameter::dim(t->parameters);

        type *tmp[10];
        type **ptypes = tmp;
        if (nparams > 10)
            ptypes = (type **)malloc(sizeof(type*) * nparams);

        for (size_t i = 0; i < nparams; i++)
        {
            Parameter *p = Parameter::getNth(t->parameters, i);
            type *tp = Type_toCtype(p->type);
            if (p->storageClass & (STCout | STCref))
                tp = type_allocn(TYnref, tp);
            else if (p->storageClass & STClazy)
            {
                // Mangle as delegate
                type *tf = type_function(TYnfunc, NULL, 0, false, tp);
                tp = type_delegate(tf);
            }
            ptypes[i] = tp;
        }

        result = type_function(totym(t), ptypes, nparams, t->varargs == 1, Type_toCtype(t->next));

        if (nparams > 10)
            free(ptypes);
    }

    void visit(TypeDelegate *t)
    {
        result = type_delegate(Type_toCtype(t->next));
    }

    void visit(TypeStruct *t)
    {
        //printf("TypeStruct::toCtype() '%s'\n", t->sym->toChars());
        // Generate a new struct type from scratch for types with no modifiers
        if (t->mod == 0)
        {
            StructDeclaration *sym = t->sym;
            if (sym->ident == Id::__c_long_double)
            {
                result = type_fake(TYdouble);
                result->Tcount++;
                return;
            }
            result = type_struct_class(sym->toPrettyChars(true), sym->alignsize, sym->structsize,
                    sym->arg1type ? Type_toCtype(sym->arg1type) : NULL,
                    sym->arg2type ? Type_toCtype(sym->arg2type) : NULL,
                    sym->isUnionDeclaration() != 0,
                    false,
                    sym->isPOD() != 0);
            setCtype(t, result);

            /* Add in fields of the struct
             * (after setting ctype to avoid infinite recursion)
             */
            if (global.params.symdebug)
            {
                for (size_t i = 0; i < sym->fields.dim; i++)
                {
                    VarDeclaration *v = sym->fields[i];
                    symbol_struct_addField(result->Ttag, v->ident->toChars(), Type_toCtype(v->type), v->offset);
                }
            }
            return;
        }

        // Copy the ctype from the mutable version and add mods
        type *mctype = Type_toCtype(t->mutableOf()->unSharedOf());

        result = type_alloc(tybasic(mctype->Tty));
        result->Tcount++;
        if (result->Tty == TYstruct)
        {
            Symbol *s = mctype->Ttag;
            result->Ttag = (Classsym *)s;            // structure tag name
        }
        // Add modifiers
        switch (t->mod)
        {
            case 0:
                assert(0);
                break;
            case MODconst:
            case MODwild:
            case MODwildconst:
                result->Tty |= mTYconst;
                break;
            case MODshared:
                result->Tty |= mTYshared;
                break;
            case MODshared | MODconst:
            case MODshared | MODwild:
            case MODshared | MODwildconst:
                result->Tty |= mTYshared | mTYconst;
                break;
            case MODimmutable:
                result->Tty |= mTYimmutable;
                break;
            default:
                assert(0);
        }

        //printf("t = %p, Tflags = x%x\n", ctype, ctype->Tflags);
    }

    void visit(TypeEnum *t)
    {
        //printf("TypeEnum::toCtype() '%s'\n", t->sym->toChars());
        if (t->sym->memtype->toBasetype()->ty == Tint32)
        {
            if (t->mod == 0)
            {
                result = type_enum(t->sym->toPrettyChars(true), Type_toCtype(t->sym->memtype));
                return;
            }

            type *mctype = Type_toCtype(t->mutableOf()->unSharedOf());
            Symbol *s = mctype->Ttag;
            assert(s);
            result = type_alloc(TYenum);
            result->Ttag = (Classsym *)s;            // enum tag name
            result->Tcount++;
            result->Tnext = mctype->Tnext;
            result->Tnext->Tcount++;
            // Add modifiers
            switch (t->mod)
            {
                case 0:
                    assert(0);
                    break;
                case MODconst:
                case MODwild:
                case MODwildconst:
                    result->Tty |= mTYconst;
                    break;
                case MODshared:
                    result->Tty |= mTYshared;
                    break;
                case MODshared | MODconst:
                case MODshared | MODwild:
                case MODshared | MODwildconst:
                    result->Tty |= mTYshared | mTYconst;
                    break;
                case MODimmutable:
                    result->Tty |= mTYimmutable;
                    break;
                default:
                    assert(0);
            }
            return;
        }
        result = Type_toCtype(t->sym->memtype);

        //printf("t = %p, Tflags = x%x\n", t, t->Tflags);
    }

    void visit(TypeClass *t)
    {
        //printf("TypeClass::toCtype() %s\n", toChars());
        type *tc = type_struct_class(t->sym->toPrettyChars(true), t->sym->alignsize, t->sym->structsize,
                NULL,
                NULL,
                false,
                true,
                true);

        result = type_pointer(tc);
        setCtype(t, result);

        /* Add in fields of the class
         * (after setting ctype to avoid infinite recursion)
         */
        if (global.params.symdebug)
        {
            for (size_t i = 0; i < t->sym->fields.dim; i++)
            {
                VarDeclaration *v = t->sym->fields[i];
                symbol_struct_addField(tc->Ttag, v->ident->toChars(), Type_toCtype(v->type), v->offset);
            }
        }
    }

    static AA *ctypeMap;

    static void setCtype(Type *t, type *ctype)
    {
        *(type **)dmd_aaGet(&ctypeMap, t) = ctype;
    }

    static type *toCtype(Type *t)
    {
        if (type *ctype = (type *)dmd_aaGetRvalue(ctypeMap, t))
            return ctype;
        ToCtypeVisitor v;
        t->accept(&v);
        setCtype(t, v.result);
        return v.result;
    }
};

AA *ToCtypeVisitor::ctypeMap = NULL;

type *Type_toCtype(Type *t)
{
    return ToCtypeVisitor::toCtype(t);
}
