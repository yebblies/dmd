

// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module root.root;

import core.stdc.stdarg;

import root._dchar;

extern(C++)
{
    char *wchar2ascii(wchar_t *);
    int wcharIsAscii(wchar_t *);
    char *wchar2ascii(wchar_t *, uint len);
    int wcharIsAscii(wchar_t *, uint len);

    int bstrcmp(ubyte *s1, ubyte *s2);
    char *bstr2str(ubyte *b);
    void error(const(char)* format, ...);
    void error(const wchar_t *format, ...);
    void warning(const(char)* format, ...);
    
    alias long longlong;
    alias ulong ulonglong;

    alias double d_time;
    alias wchar wchar_t;

    longlong randomx();
}


/*
 * Root of our class library.
 */

alias ArrayBase!(File*) Files;
//alias ArrayBase!(char*) Strings;

extern(C++)
class _Object
{
    this() { }
    ~this() { }

    int equals(_Object o);

    /**
     * Returns a hash code, useful for things like building hash tables of _Objects.
     */
    hash_t hashCode();

    /**
     * Return <0, ==0, or >0 if this is less than, equal to, or greater than obj.
     * Useful for sorting _Objects.
     */
    int compare(_Object obj);

    /**
     * Pretty-print an _Object. Useful for debugging the old-fashioned way.
     */
    void print();

    char *toChars();
    _dchar *toDchars();
    void toBuffer(OutBuffer buf);

    /**
     * Used as a replacement for dynamic_cast. Returns a unique number
     * defined by the library user. For _Object, the return value is 0.
     */
    int dyncast();

    /**
     * Marks pointers for garbage collector by calling mem.mark() for all pointers into heap.
     */
    /*virtual*/         // not used, disable for now
    final void mark();
};

extern(C++)
class String : _Object
{
    int _ref;                    // != 0 if this is a reference to someone else's string
    char *str;                  // the string itself

    this(char *str, int _ref = 1);

    ~this();

    static hash_t calcHash(const(char)* str, size_t len);
    static hash_t calcHash(const(char)* str);
    
    hash_t hashCode();
    int equals(_Object obj);
    int compare(_Object obj);
final:
    uint len();
    char *toChars();
    void print();
    void mark();
};

extern(C++)
class FileName : String
{
    this(char *str, int _ref);
    this(char *path, char *name);
    
final:
    hash_t hashCode();
    int equals(_Object obj);
    static int equals(const(char)* name1, const(char)* name2);
    int compare(_Object obj);
    static int compare(const(char)* name1, const(char)* name2);
    static int absolute(const(char)* name);
    static char *ext(const(char)* );
    char *ext();
    static char *removeExt(const(char)* str);
    static char *name(const(char)* );
    char *name();
    static char *path(const(char)* );
    static const(char)* replaceName(const(char)* path, const(char)* name);

    static char *combine(const(char)* path, const(char)* name);
    static ArrayBase!(char*) *splitPath(const(char)* path);
    static FileName defaultExt(const(char)* name, const(char)* ext);
    static FileName forceExt(const(char)* name, const(char)* ext);
    int equalsExt(const(char)* ext);

    void CopyTo(FileName to);
    static char *searchPath(ArrayBase!(char*) *path, const(char)* name, int cwd);
    static char *safeSearchPath(ArrayBase!(char*) *path, const(char)* name);
    static int exists(const(char)* name);
    static void ensurePathExists(const(char)* path);
    static char *canonicalName(const(char)* name);
};

extern(C++)
class File : _Object
{
    int _ref;                    // != 0 if this is a reference to someone else's buffer
    ubyte *buffer;      // data for our file
    uint len;               // amount of data in buffer[]
    void *touchtime;            // system time to use for file

    FileName name;             // name of our file

    this(char *);
    this(FileName);
    ~this();

final:
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
    static Files *match(FileName );

    // Compare file times.
    // Return   <0      this < f
    //          =0      this == f
    //          >0      this > f
    int compareTime(File *f);

    // Read system file statistics
    void stat();

    /* Set buffer
     */

    void setbuffer(void *buffer, uint len);

    void checkoffset(size_t offset, size_t nbytes);

    void remove();              // delete file
};

extern(C++)
class OutBuffer : _Object
{
    ubyte *data;
    uint offset;
    uint size;

    this();
    ~this();
final:
    char *extractData();
    void mark();

    void reserve(uint nbytes);
    void setsize(uint size);
    void reset();
    void write(const(void)* data, uint nbytes);
    void writebstring(ubyte *string);
    void writestring(const(char)* string);
    void writedstring(const(char)* string);
    void writedstring(const wchar_t *string);
    void prependstring(const(char)* string);
    void writenl();                     // write newline
    void writeByte(uint b);
    void writebyte(uint b);
    void writeUTF8(uint b);
    void write_dchar(uint b);
    void prependbyte(uint b);
    void writeword(uint w);
    void writewchar(uint w);
    void writeUTF16(uint w);
    void write4(uint w);
    void write(OutBuffer buf);
    void write(_Object obj);
    void fill0(uint nbytes);
    void _align(uint size);
    void vprintf(const(char)* format, va_list args);
    void printf(const(char)* format, ...);
    void bracket(char left, char right);
    uint bracket(uint i, const(char)* left, uint j, const(char)* right);
    void spread(uint offset, uint nbytes);
    uint insert(uint offset, const(void)* data, uint nbytes);
    void remove(uint offset, uint nbytes);
    char *toChars();
    char *extractString();
};

extern(C++)
class Array : _Object
{
    uint dim;
    void **data;

  private:
    uint allocdim;
    void *smallarray[1];    // inline storage for small arrays

  public:
    this();
    ~this();
    //this(const& Array);
final:
    void mark();
    char *toChars();

    void reserve(uint nentries);
    void setDim(uint newdim);
    void fixDim();
    void push(void *ptr);
    void *pop();
    void shift(void *ptr);
    void insert(uint index, void *ptr);
    void insert(uint index, Array a);
    void append(Array a);
    void remove(uint i);
    void zero();
    void *tos();
    void sort();
    Array copy();
};

extern(C++)
class ArrayBase(TYPE) : Array
{
final:
    TYPE *tdata()
    {
        return cast(TYPE *)data;
    }

    ref TYPE opIndex (size_t index)
    {
        debug {
            assert(index < dim);
        }

        return (cast(TYPE *)data)[index];
    }

    void insert(size_t index, TYPE v)
    {
        super.insert(index, cast(void *)v);
    }

    void insert(size_t index, ArrayBase a)
    {
        super.insert(index, cast(Array )a);
    }

    void append(ArrayBase a)
    {
        super.append(cast(Array )a);
    }

    void push(TYPE a)
    {
        super.push(cast(void *)a);
    }

    ArrayBase copy()
    {
        return cast(ArrayBase )super.copy();
    }
};

extern(C++)
class Bits : _Object
{
    uint bitdim;
    uint allocdim;
    uint *data;

    this();
    ~this();
final:
    void mark();

    void resize(uint bitdim);

    void set(uint bitnum);
    void clear(uint bitnum);
    int test(uint bitnum);

    void set();
    void clear();
    void copy(Bits from);
    Bits clone();

    void sub(Bits b);
};

