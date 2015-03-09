// Compiler implementation of the D programming language
// Copyright (c) 1999-2015 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// Distributed under the Boost Software License, Version 1.0.
// http://www.boost.org/LICENSE_1_0.txt

module ddmd.aggregate;

import ddmd.access, ddmd.arraytypes, ddmd.backend, ddmd.clone, ddmd.declaration, ddmd.doc, ddmd.dscope, ddmd.dstruct, ddmd.dsymbol, ddmd.dtemplate, ddmd.expression, ddmd.func, ddmd.globals, ddmd.hdrgen, ddmd.id, ddmd.identifier, ddmd.mtype, ddmd.opover, ddmd.root.outbuffer, ddmd.statement, ddmd.tokens, ddmd.visitor;

enum Sizeok : int
{
    SIZEOKnone, // size of aggregate is not computed yet
    SIZEOKdone, // size of aggregate is set correctly
    SIZEOKfwd, // error in computing size of aggregate
}

alias SIZEOKnone = Sizeok.SIZEOKnone;
alias SIZEOKdone = Sizeok.SIZEOKdone;
alias SIZEOKfwd = Sizeok.SIZEOKfwd;

extern (C++) class AggregateDeclaration : ScopeDsymbol
{
public:
    Type type;
    StorageClass storage_class;
    Prot protection;
    uint structsize; // size of struct
    uint alignsize; // size of struct for alignment purposes
    VarDeclarations fields; // VarDeclaration fields
    Sizeok sizeok; // set when structsize contains valid data
    Dsymbol deferred; // any deferred semantic2() or semantic3() symbol
    bool isdeprecated; // true if deprecated
    bool mutedeprecation; // true while analysing RTInfo to avoid deprecation message
    Dsymbol enclosing;
    /* !=NULL if is nested
     * pointing to the dsymbol that directly enclosing it.
     * 1. The function that enclosing it (nested struct and class)
     * 2. The class that enclosing it (nested class only)
     * 3. If enclosing aggregate is template, its enclosing dsymbol.
     * See AggregateDeclaraton::makeNested for the details.
     */
    VarDeclaration vthis; // 'this' parameter if this aggregate is nested
    // Special member functions
    FuncDeclarations invs; // Array of invariants
    FuncDeclaration inv; // invariant
    NewDeclaration aggNew; // allocator
    DeleteDeclaration aggDelete; // deallocator
    Dsymbol ctor; // CtorDeclaration or TemplateDeclaration
    CtorDeclaration defaultCtor; // default constructor - should have no arguments, because
    // it would be stored in TypeInfo_Class.defaultConstructor
    Dsymbol aliasthis; // forward unresolved lookups to aliasthis
    bool noDefaultCtor; // no default construction
    FuncDeclarations dtors; // Array of destructors
    FuncDeclaration dtor; // aggregate destructor
    Expression getRTInfo; // pointer to GC info generated by object.RTInfo(this)

    /********************************* AggregateDeclaration ****************************/
    final extern (D) this(Loc loc, Identifier id)
    {
        super(id);
        this.loc = loc;
        storage_class = 0;
        protection = Prot(PROTpublic);
        type = null;
        structsize = 0; // size of struct
        alignsize = 0; // size of struct for alignment purposes
        sizeok = SIZEOKnone; // size not determined yet
        deferred = null;
        isdeprecated = false;
        mutedeprecation = false;
        inv = null;
        aggNew = null;
        aggDelete = null;
        stag = null;
        sinit = null;
        enclosing = null;
        vthis = null;
        ctor = null;
        defaultCtor = null;
        aliasthis = null;
        noDefaultCtor = false;
        dtor = null;
        getRTInfo = null;
    }

    final void setScope(Scope* sc)
    {
        if (sizeok == SIZEOKdone)
            return;
        ScopeDsymbol.setScope(sc);
    }

    final void semantic2(Scope* sc)
    {
        //printf("AggregateDeclaration::semantic2(%s) type = %s, errors = %d\n", toChars(), type->toChars(), errors);
        if (!members)
            return;
        if (_scope && sizeok == SIZEOKfwd) // Bugzilla 12531
            semantic(null);
        if (_scope)
        {
            error("has forward references");
            return;
        }
        Scope* sc2 = sc.push(this);
        sc2.stc &= STCsafe | STCtrusted | STCsystem;
        sc2.parent = this;
        //if (isUnionDeclaration())     // TODO
        //    sc2->inunion = 1;
        sc2.protection = Prot(PROTpublic);
        sc2.explicitProtection = 0;
        sc2.structalign = STRUCTALIGN_DEFAULT;
        sc2.userAttribDecl = null;
        for (size_t i = 0; i < members.dim; i++)
        {
            Dsymbol s = (*members)[i];
            //printf("\t[%d] %s\n", i, s->toChars());
            s.semantic2(sc2);
        }
        sc2.pop();
    }

    final void semantic3(Scope* sc)
    {
        //printf("AggregateDeclaration::semantic3(%s) type = %s, errors = %d\n", toChars(), type->toChars(), errors);
        if (!members)
            return;
        StructDeclaration sd = isStructDeclaration();
        if (!sc) // from runDeferredSemantic3 for TypeInfo generation
        {
            assert(sd);
            sd.semanticTypeInfoMembers();
            return;
        }
        Scope* sc2 = sc.push(this);
        sc2.stc &= STCsafe | STCtrusted | STCsystem;
        sc2.parent = this;
        if (isUnionDeclaration())
            sc2.inunion = 1;
        sc2.protection = Prot(PROTpublic);
        sc2.explicitProtection = 0;
        sc2.structalign = STRUCTALIGN_DEFAULT;
        sc2.userAttribDecl = null;
        for (size_t i = 0; i < members.dim; i++)
        {
            Dsymbol s = (*members)[i];
            s.semantic3(sc2);
        }
        sc2.pop();
        // don't do it for unused deprecated types
        // or error types
        if (!getRTInfo && Type.rtinfo && (!isDeprecated() || global.params.useDeprecated) && (type && type.ty != Terror))
        {
            // we do not want to report deprecated uses of this type during RTInfo
            //  generation, so we disable reporting deprecation temporarily
            // WARNING: Muting messages during analysis of RTInfo might silently instantiate
            //  templates that use (other) deprecated types. If these template instances
            //  are used in other parts of the program later, they will be reused without
            //  ever producing the deprecation message. The implementation here restricts
            //  muting to the types that RTInfo is currently generated for.
            bool wasmuted = mutedeprecation;
            mutedeprecation = true;
            // Evaluate: RTinfo!type
            auto tiargs = new Objects();
            tiargs.push(type);
            auto ti = new TemplateInstance(loc, Type.rtinfo, tiargs);
            ti.semantic(sc);
            ti.semantic2(sc);
            ti.semantic3(sc);
            Dsymbol s = ti.toAlias();
            Expression e = new DsymbolExp(Loc(), s, 0);
            Scope* sc3 = ti.tempdecl._scope.startCTFE();
            sc3.tinst = sc.tinst;
            e = e.semantic(sc3);
            sc3.endCTFE();
            e = e.ctfeInterpret();
            getRTInfo = e;
            mutedeprecation = wasmuted;
        }
        if (sd)
            sd.semanticTypeInfoMembers();
    }

    final uint size(Loc loc)
    {
        //printf("AggregateDeclaration::size() %s, scope = %p\n", toChars(), scope);
        if (loc.linnum == 0)
            loc = this.loc;
        if (sizeok != SIZEOKdone && _scope)
            semantic(null);
        StructDeclaration sd = isStructDeclaration();
        if (sizeok != SIZEOKdone && sd && sd.members)
        {
            /* See if enough is done to determine the size,
             * meaning all the fields are done.
             */
            struct SV
            {
                /* Returns:
                 *  0       this member doesn't need further processing to determine struct size
                 *  1       this member does
                 */
                extern (C++) static int func(Dsymbol s, void* param)
                {
                    VarDeclaration v = s.isVarDeclaration();
                    if (v)
                    {
                        if (v._scope)
                            v.semantic(null);
                        if (v.storage_class & (STCstatic | STCextern | STCtls | STCgshared | STCmanifest | STCctfe | STCtemplateparameter))
                            return 0;
                        if (v.isField() && v.sem >= SemanticDone)
                            return 0;
                        return 1;
                    }
                    return 0;
                }
            }

            SV sv;
            for (size_t i = 0; i < members.dim; i++)
            {
                Dsymbol s = (*members)[i];
                if (s.apply(&SV.func, &sv))
                    goto L1;
            }
            sd.finalizeSize(null);
        L1:
        }
        if (!members)
        {
            error(loc, "unknown size");
        }
        else if (sizeok != SIZEOKdone)
        {
            error(loc, "no size yet for forward reference");
            //*(char*)0=0;
        }
        return structsize;
    }

    /****************************
     * Do byte or word alignment as necessary.
     * Align sizes of 0, as we may not know array sizes yet.
     *
     * alignment: struct alignment that is in effect
     * size: alignment requirement of field
     */
    final static void alignmember(structalign_t alignment, uint size, uint* poffset)
    {
        //printf("alignment = %d, size = %d, offset = %d\n",alignment,size,offset);
        switch (alignment)
        {
        case cast(structalign_t)1:
            // No alignment
            break;
        case cast(structalign_t)STRUCTALIGN_DEFAULT:
            // Alignment in Target::fieldalignsize must match what the
            // corresponding C compiler's default alignment behavior is.
            assert(size > 0 && !(size & (size - 1)));
            *poffset = (*poffset + size - 1) & ~(size - 1);
            break;
        default:
            // Align on alignment boundary, which must be a positive power of 2
            assert(alignment > 0 && !(alignment & (alignment - 1)));
            *poffset = (*poffset + alignment - 1) & ~(alignment - 1);
            break;
        }
    }

    /****************************************
     * Place a member (mem) into an aggregate (agg), which can be a struct, union or class
     * Returns:
     *      offset to place field at
     *
     * nextoffset:    next location in aggregate
     * memsize:       size of member
     * memalignsize:  size of member for alignment purposes
     * alignment:     alignment in effect for this member
     * paggsize:      size of aggregate (updated)
     * paggalignsize: size of aggregate for alignment purposes (updated)
     * isunion:       the aggregate is a union
     */
    final static uint placeField(uint* nextoffset, uint memsize, uint memalignsize, structalign_t alignment, uint* paggsize, uint* paggalignsize, bool isunion)
    {
        uint ofs = *nextoffset;
        alignmember(alignment, memalignsize, &ofs);
        uint memoffset = ofs;
        ofs += memsize;
        if (ofs > *paggsize)
            *paggsize = ofs;
        if (!isunion)
            *nextoffset = ofs;
        if (alignment == STRUCTALIGN_DEFAULT)
        {
            if (global.params.is64bit && memalignsize == 16)
            {
            }
            else if (8 < memalignsize)
                memalignsize = 8;
        }
        else
        {
            if (memalignsize < alignment)
                memalignsize = alignment;
        }
        if (*paggalignsize < memalignsize)
            *paggalignsize = memalignsize;
        return memoffset;
    }

    final Type getType()
    {
        return type;
    }

    /****************************************
     * If field[indx] is not part of a union, return indx.
     * Otherwise, return the lowest field index of the union.
     */
    final int firstFieldInUnion(int indx)
    {
        if (isUnionDeclaration())
            return 0;
        VarDeclaration vd = fields[indx];
        int firstNonZero = indx; // first index in the union with non-zero size
        for (;;)
        {
            if (indx == 0)
                return firstNonZero;
            VarDeclaration v = fields[indx - 1];
            if (v.offset != vd.offset)
                return firstNonZero;
            --indx;
            /* If it is a zero-length field, it's ambiguous: we don't know if it is
             * in the union unless we find an earlier non-zero sized field with the
             * same offset.
             */
            if (v.size(loc) != 0)
                firstNonZero = indx;
        }
    }

    /****************************************
     * Count the number of fields starting at firstIndex which are part of the
     * same union as field[firstIndex]. If not a union, return 1.
     */
    final int numFieldsInUnion(int firstIndex)
    {
        VarDeclaration vd = fields[firstIndex];
        /* If it is a zero-length field, AND we can't find an earlier non-zero
         * sized field with the same offset, we assume it's not part of a union.
         */
        if (vd.size(loc) == 0 && !isUnionDeclaration() && firstFieldInUnion(firstIndex) == firstIndex)
            return 1;
        int count = 1;
        for (size_t i = firstIndex + 1; i < fields.dim; ++i)
        {
            VarDeclaration v = fields[i];
            // If offsets are different, they are not in the same union
            if (v.offset != vd.offset)
                break;
            ++count;
        }
        return count;
    }

    // is aggregate deprecated?
    final bool isDeprecated()
    {
        return isdeprecated;
    }

    // disable deprecation message on Dsymbol?
    final bool muteDeprecationMessage()
    {
        return mutedeprecation;
    }

    /****************************************
     * Returns true if there's an extra member which is the 'this'
     * pointer to the enclosing context (enclosing aggregate or function)
     */
    final bool isNested()
    {
        return enclosing !is null;
    }

    final void makeNested()
    {
        if (enclosing) // if already nested
            return;
        if (sizeok == SIZEOKdone)
            return;
        if (isUnionDeclaration() || isInterfaceDeclaration())
            return;
        if (storage_class & STCstatic)
            return;
        // If nested struct, add in hidden 'this' pointer to outer scope
        Dsymbol s = toParent2();
        if (!s)
            return;
        AggregateDeclaration ad = s.isAggregateDeclaration();
        FuncDeclaration fd = s.isFuncDeclaration();
        Type t = null;
        if (fd)
        {
            enclosing = fd;
            AggregateDeclaration agg = fd.isMember2();
            t = agg ? agg.handleType() : Type.tvoidptr;
        }
        else if (ad)
        {
            if (isClassDeclaration() && ad.isClassDeclaration())
            {
                enclosing = ad;
            }
            else if (isStructDeclaration())
            {
                if (TemplateInstance ti = ad.parent.isTemplateInstance())
                {
                    enclosing = ti.enclosing;
                }
            }
            t = ad.handleType();
        }
        if (enclosing)
        {
            //printf("makeNested %s, enclosing = %s\n", toChars(), enclosing->toChars());
            assert(t);
            if (t.ty == Tstruct)
                t = Type.tvoidptr; // t should not be a ref type
            assert(!vthis);
            vthis = new ThisDeclaration(loc, t);
            //vthis->storage_class |= STCref;
            members.push(vthis);
        }
    }

    final bool isExport()
    {
        return protection.kind == PROTexport;
    }

    /*******************************************
     * Look for constructor declaration.
     */
    final Dsymbol searchCtor()
    {
        Dsymbol s = search(Loc(), Id.ctor);
        if (s)
        {
            if (!(s.isCtorDeclaration() || s.isTemplateDeclaration() || s.isOverloadSet()))
            {
                error("%s %s is not a constructor; identifiers starting with __ are reserved for the implementation", s.kind(), s.toChars());
                errors = true;
                s = null;
            }
        }
        return s;
    }

    final Prot prot()
    {
        return protection;
    }

    final Type handleType()
    {
        return type;
    }

    // 'this' type
    // Back end
    Symbol* stag; // tag symbol for debug data
    Symbol* sinit;

    final AggregateDeclaration isAggregateDeclaration()
    {
        return this;
    }

    void accept(Visitor v)
    {
        v.visit(this);
    }
}
