
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef FILENAME_H
#define FILENAME_H

#if __DMC__
#pragma once
#endif

#include "object.h"

template <typename TYPE> struct Array;
typedef Array<const char> Strings;

struct String
{
    static hash_t calcHash(const char *str, size_t len);
    static hash_t calcHash(const char *str);
};

struct FileName
{
    const char *str;                  // the string itself
    FileName(const char *str);
    hash_t hashCode();
    bool equals(RootObject *obj);
    static int equals(const char *name1, const char *name2);
    int compare(RootObject *obj);
    static int compare(const char *name1, const char *name2);
    static int absolute(const char *name);
    static const char *ext(const char *);
    const char *ext();
    static const char *removeExt(const char *str);
    static const char *name(const char *);
    const char *name();
    static const char *path(const char *);
    static const char *replaceName(const char *path, const char *name);

    static const char *combine(const char *path, const char *name);
    static Strings *splitPath(const char *path);
    static const char *defaultExt(const char *name, const char *ext);
    static const char *forceExt(const char *name, const char *ext);
    static int equalsExt(const char *name, const char *ext);

    int equalsExt(const char *ext);
    char *toChars();

    void CopyTo(FileName *to);
    static const char *searchPath(Strings *path, const char *name, int cwd);
    static const char *safeSearchPath(Strings *path, const char *name);
    static int exists(const char *name);
    static void ensurePathExists(const char *path);
    static void ensurePathToNameExists(const char *name);
    static const char *canonicalName(const char *name);

    static void free(const char *str);
    static void error(const char *format, ...);
};

#endif
