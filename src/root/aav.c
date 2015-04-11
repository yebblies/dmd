
/* Copyright (c) 2010-2014 by Digital Mars
 * All Rights Reserved, written by Walter Bright
 * http://www.digitalmars.com
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE or copy at http://www.boost.org/LICENSE_1_0.txt)
 * https://github.com/D-Programming-Language/dmd/blob/master/src/root/aav.c
 */

/**
 * Implementation of associative arrays.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#include "aav.h"
#include "rmem.h"


inline size_t hash(size_t a)
{
    a ^= (a >> 20) ^ (a >> 12);
    return a ^ (a >> 7) ^ (a >> 4);
}

struct Entry
{
    void *key;
    void *value;
};

struct AA
{
    Entry *buckets;
    size_t b_length;
    size_t nodes;       // total number of Entry nodes
    Entry binit[4];      // initial value of buckets[]
};

/****************************************************
 * Determine number of entries in associative array.
 */

size_t dmd_aaLen(AA *aa)
{
    return aa ? aa->nodes : 0;
}


/*************************************************
 * Get pointer to value in associative array indexed by key.
 * Add entry for key if it is not already there, returning a pointer to a null Value.
 * Create the associative array if it does not already exist.
 */

void **dmd_aaGet(AA **paa, void *key)
{
    //printf("paa = %p\n", paa);
    if (!*paa)
    {
        AA *a = (AA *)mem.xmalloc(sizeof(AA));
        a->buckets = (Entry *)a->binit;
        a->b_length = 4;
        a->nodes = 0;
        a->binit[0].key = NULL;
        a->binit[0].value = NULL;
        a->binit[1].key = NULL;
        a->binit[1].value = NULL;
        a->binit[2].key = NULL;
        a->binit[2].value = NULL;
        a->binit[3].key = NULL;
        a->binit[3].value = NULL;
        *paa = a;
        assert((*paa)->b_length == 4);
    }
    //printf("paa = %p, *paa = %p\n", paa, *paa);

lookup:
    AA *aa = *paa;
    assert(aa->b_length);
    size_t i = hash((size_t)key) & (aa->b_length - 1);
    while (aa->buckets[i].key != NULL)
    {
        Entry *e = &aa->buckets[i];
        if (key == e->key)
            return &e->value;
        i++;
        i &= aa->b_length - 1;
    }

    // Not found, create new elem
    //printf("create new one\n");

    size_t nodes = ++aa->nodes;
    Entry *e = &aa->buckets[i];
    e->key = key;
    e->value = NULL;

    //printf("length = %d, nodes = %d\n", aa->b_length, nodes);
    if (nodes * 2 > aa->b_length)
    {
        //printf("rehash\n");
        dmd_aaRehash(paa);
        goto lookup;
    }

    return &e->value;
}


/*************************************************
 * Get value in associative array indexed by key.
 * Returns NULL if it is not already there.
 */

void *dmd_aaGetRvalue(AA* aa, void *key)
{
    //printf("_aaGetRvalue(key = %p)\n", key);
    if (aa)
    {
        size_t len = aa->b_length;
        size_t i = hash((size_t)key) & (len - 1);
        while (aa->buckets[i].key != NULL)
        {
            Entry *e = &aa->buckets[i];
            if (key == e->key)
                return e->value;
            i++;
            i &= len - 1;
        }
    }
    return NULL;    // not found
}


/********************************************
 * Rehash an array.
 */

void dmd_aaRehash(AA** paa)
{
    //printf("Rehash\n");
    if (!*paa)
        return;

    AA *aa = *paa;
    if (aa)
    {
        // printf("======== before\n");
        // for (size_t ii = 0; ii < aa->b_length; ii++)
        // {
            // printf("%d: %p %p\n", ii, aa->buckets[ii].key, aa->buckets[ii].value);
        // }

        size_t len = aa->b_length;
        if (len == 4)
            len = 32;
        else
            len *= 4;
        Entry *newb = (Entry *)mem.xmalloc(sizeof(Entry) * len);
        memset(newb, 0, len * sizeof(Entry));

        for (size_t k = 0; k < aa->b_length; k++)
        {
            Entry *e = &aa->buckets[k];
            if (!e->key)
                continue;

            size_t i = hash((size_t)e->key) & (len - 1);
            while (newb[i].key != NULL)
            {
                i++;
                i &= len - 1;
            }
            newb[i].key = e->key;
            newb[i].value = e->value;
        }
        if (aa->buckets != (Entry *)aa->binit)
            mem.xfree(aa->buckets);

        aa->buckets = newb;
        aa->b_length = len;

        // printf("======== after\n");
        // for (size_t ii = 0; ii < aa->b_length; ii++)
        // {
            // printf("%d: %p %p\n", ii, aa->buckets[ii].key, aa->buckets[ii].value);
        // }
    }
}


#if UNITTEST

#include <stdlib.h>
#include <stdio.h>
#include "array.h"

void unittest_aa()
{
    AA *aa = NULL;
    Array<const char *> list;
    const char *q = new char[1];
    list.push(q);
    *dmd_aaGet(&aa, (void *)q) = (void *)q;
    for (size_t i = 0; i < 10000; i++)
    {
        if (rand() % 2)
        {
            const char *p = new char[1];
            // printf("insert %p\n", p);
            list.push(p);
            *dmd_aaGet(&aa, (void *)p) = (void *)p;
        }
        else
        {
            const char *p = list[rand() % list.dim];
            void *val = dmd_aaGetRvalue(aa, (void *)p);
            // printf("check %p (%p)\n", p, val);
            assert(val == (void *)p);
        }
    }
}

#endif
