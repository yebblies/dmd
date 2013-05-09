
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef ROOT_H
#define ROOT_H

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

/*
 * Root of our class library.
 */

struct OutBuffer;

// Can't include arraytypes.h here, need to declare these directly.
template <typename TYPE> struct Array;
typedef Array<class File> Files;
typedef Array<const char> Strings;

#include "object.h"

class String : public RootObject
{
public:
    const char *str;                  // the string itself

    String(const char *str);
    ~String();

    static hash_t calcHash(const char *str, size_t len);
    static hash_t calcHash(const char *str);
    hash_t hashCode();
    size_t len();
    bool equals(RootObject *obj);
    int compare(RootObject *obj);
    char *toChars();
    void print();
    void mark();
};

class FileName : public String
{
public:
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

    void CopyTo(FileName *to);
    static const char *searchPath(Strings *path, const char *name, int cwd);
    static const char *safeSearchPath(Strings *path, const char *name);
    static int exists(const char *name);
    static void ensurePathExists(const char *path);
    static void ensurePathToNameExists(const char *name);
    static const char *canonicalName(const char *name);

    static void free(const char *str);
};

class File : public RootObject
{
public:
    int ref;                    // != 0 if this is a reference to someone else's buffer
    unsigned char *buffer;      // data for our file
    size_t len;                 // amount of data in buffer[]
    void *touchtime;            // system time to use for file

    FileName *name;             // name of our file

    File(const char *);
    File(const FileName *);
    ~File();

    void mark();

    char *toChars();

    /* Read file, return !=0 if error
     */

    int read();

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void readv();

    /* Read file, return !=0 if error
     */

    int mmread();

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void mmreadv();

    /* Write file, return !=0 if error
     */

    int write();

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void writev();

    /* Return !=0 if file exists.
     *  0:      file doesn't exist
     *  1:      normal file
     *  2:      directory
     */

    /* Append to file, return !=0 if error
     */

    int append();

    /* Append to file, either succeed or fail
     * with error message & exit.
     */

    void appendv();

    /* Return !=0 if file exists.
     *  0:      file doesn't exist
     *  1:      normal file
     *  2:      directory
     */

    int exists();

    /* Given wildcard filespec, return an array of
     * matching File's.
     */

    static Files *match(char *);
    static Files *match(FileName *);

    // Compare file times.
    // Return   <0      this < f
    //          =0      this == f
    //          >0      this > f
    int compareTime(File *f);

    // Read system file statistics
    void stat();

    /* Set buffer
     */

    void setbuffer(void *buffer, size_t len)
    {
        this->buffer = (unsigned char *)buffer;
        this->len = len;
    }

    void checkoffset(size_t offset, size_t nbytes);

    void remove();              // delete file
};

struct OutBuffer
{
    unsigned char *data;
    size_t offset;
    size_t size;

    int doindent;
    int level;
    int notlinehead;

    OutBuffer();
    ~OutBuffer();
    char *extractData();
    void mark();

    void reserve(size_t nbytes);
    void setsize(size_t size);
    void reset();
    void write(const void *data, size_t nbytes);
    void writebstring(unsigned char *string);
    void writestring(const char *string);
    void prependstring(const char *string);
    void writenl();                     // write newline
    void writeByte(unsigned b);
    void writebyte(unsigned b) { writeByte(b); }
    void writeUTF8(unsigned b);
    void prependbyte(unsigned b);
    void writewchar(unsigned w);
    void writeword(unsigned w);
    void writeUTF16(unsigned w);
    void write4(unsigned w);
    void write(OutBuffer *buf);
    void write(RootObject *obj);
    void fill0(size_t nbytes);
    void align(size_t size);
    void vprintf(const char *format, va_list args);
    void printf(const char *format, ...);
    void bracket(char left, char right);
    size_t bracket(size_t i, const char *left, size_t j, const char *right);
    void spread(size_t offset, size_t nbytes);
    size_t insert(size_t offset, const void *data, size_t nbytes);
    void remove(size_t offset, size_t nbytes);
    char *toChars();
    char *extractString();
};

#include "array.h"

// TODO: Remove (only used by disabled GC)
class Bits : public RootObject
{
public:
    unsigned bitdim;
    unsigned allocdim;
    unsigned *data;

    Bits();
    ~Bits();
    void mark();

    void resize(unsigned bitdim);

    void set(unsigned bitnum);
    void clear(unsigned bitnum);
    int test(unsigned bitnum);

    void set();
    void clear();
    void copy(Bits *from);
    Bits *clone();

    void sub(Bits *b);
};

#endif
