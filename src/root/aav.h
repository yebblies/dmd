
/* Copyright (c) 2010-2014 by Digital Mars
 * All Rights Reserved, written by Walter Bright
 * http://www.digitalmars.com
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE or copy at http://www.boost.org/LICENSE_1_0.txt)
 * https://github.com/D-Programming-Language/dmd/blob/master/src/root/aav.h
 */

struct AA;

size_t dmd_aaLen(AA* aa);
void **dmd_aaGet(AA** aa, void *key);
void *dmd_aaGetRvalue(AA* aa, void *key);
void dmd_aaRehash(AA** paa);

