
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef OBJECT_H
#define OBJECT_H

#define POSIX (linux || __APPLE__ || __FreeBSD__ || __OpenBSD__ || __sun)

#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include "port.h"
#include "rmem.h"

#if __DMC__
#pragma once
#endif

typedef size_t hash_t;

struct OutBuffer;

/*
 * Root of our class library.
 */
class RootObject
{
public:
    RootObject() { }
    virtual ~RootObject() { }

    virtual bool equals(RootObject *o);

    /**
     * Returns a hash code, useful for things like building hash tables of Objects.
     */
    virtual hash_t hashCode();

    /**
     * Return <0, ==0, or >0 if this is less than, equal to, or greater than obj.
     * Useful for sorting Objects.
     */
    virtual int compare(RootObject *obj);

    /**
     * Pretty-print an Object. Useful for debugging the old-fashioned way.
     */
    virtual void print();

    virtual char *toChars();
    virtual void toBuffer(OutBuffer *buf);

    /**
     * Used as a replacement for dynamic_cast. Returns a unique number
     * defined by the library user. For Object, the return value is 0.
     */
    virtual int dyncast();

    /**
     * Marks pointers for garbage collector by calling mem.mark() for all pointers into heap.
     */
    /*virtual*/         // not used, disable for now
        void mark();
};

#endif
