
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module mars;
extern(C++):

/*
It is very important to use version control macros correctly - the
idea is that host and target are independent. If these are done
correctly, cross compilers can be built.
The host compiler and host operating system are also different,
and are predefined by the host compiler. The ones used in
dmd are:

Macros defined by the compiler, not the code:

    Compiler:
        __DMC__         Digital Mars compiler
        _MSC_VER        Microsoft compiler
        __GNUC__        Gnu compiler
        __clang__       Clang compiler

    Host operating system:
        _WIN32          Microsoft NT, Windows 95, Windows 98, Win32s,
                        Windows 2000, Win XP, Vista
        _WIN64          Windows for AMD64
        linux           Linux
        __APPLE__       Mac OSX
        __FreeBSD__     FreeBSD
        __OpenBSD__     OpenBSD
        __sun&&__SVR4   Solaris, OpenSolaris (yes, both macros are necessary)

For the target systems, there are the target operating system and
the target object file format:

    Target operating system:
        TARGET_WINDOS   Covers 32 bit windows and 64 bit windows
        TARGET_LINUX    Covers 32 and 64 bit linux
        TARGET_OSX      Covers 32 and 64 bit Mac OSX
        TARGET_FREEBSD  Covers 32 and 64 bit FreeBSD
        TARGET_OPENBSD  Covers 32 and 64 bit OpenBSD
        TARGET_SOLARIS  Covers 32 and 64 bit Solaris
        TARGET_NET      Covers .Net

    It is expected that the compiler for each platform will be able
    to generate 32 and 64 bit code from the same compiler binary.

    Target object module format:
        OMFOBJ          Intel Object Module Format, used on Windows
        ELFOBJ          Elf Object Module Format, used on linux, FreeBSD, OpenBSD and Solaris
        MACHOBJ         Mach-O Object Module Format, used on Mac OSX

    There are currently no macros for byte endianness order.
 */


import core.stdc.stdio;
import core.stdc.stdint;
import core.stdc.stdarg;

import arraytypes;
import _module : Module;
import root.root;
import lib;
import dsymbol;

version (DigitalMars)
{
    enum __DMC__ = 1;
}
version (Win32)
{
    enum _WIN32 = 1;
}

debug {
    enum UNITTEST = 1;
}

void unittests();

enum DMDV1 = 0;
enum DMDV2 = 1;       // Version 2.0 features
enum BREAKABI = 1;      // 0 if not ready to break the ABI just yet
enum STRUCTTHISREF = DMDV2;     // if 'this' for struct is a reference, not a pointer
enum SNAN_DEFAULT_INIT = DMDV2; // if floats are default initialized to signalling NaN
enum SARRAYVALUE = DMDV2;       // static arrays are value types
enum MODULEINFO_IS_STRUCT = DMDV2;   // if ModuleInfo is a struct rather than a class

// Set if C++ mangling is done by the front end
enum CPP_MANGLE = (DMDV2 && (TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_OPENBSD || TARGET_SOLARIS));

/* Other targets are TARGET_LINUX, TARGET_OSX, TARGET_FREEBSD, TARGET_OPENBSD and
 * TARGET_SOLARIS, which are
 * set on the command line via the compiler makefile.
 */
 
enum TARGET_LINUX = 0;
enum TARGET_OSX = 0;
enum TARGET_FREEBSD = 0;
enum TARGET_SOLARIS = 0;
enum TARGET_NET = 0;
enum TARGET_OPENBSD = 0;

enum IN_GCC = 0;
enum GCC_SAFE_DMD = 1;

version (Win32) {
    enum TARGET_WINDOS = 1;
    enum OMFOBJ = TARGET_WINDOS;
} else {
    static assert(0, "Only windows supported");
}

static if (TARGET_LINUX || TARGET_FREEBSD || TARGET_OPENBSD || TARGET_SOLARIS) {
    enum ELFOBJ = 1;
}
    
static if (TARGET_OSX) {
    enum MACHOBJ = 1;
}


// Put command line switches in here
struct Param
{
    char obj;           // write object file
    char link;          // perform link
    char dll;           // generate shared dynamic library
    char lib;           // write library file instead of object file(s)
    char multiobj;      // break one object file into multiple ones
    char oneobj;        // write one object file instead of multiple ones
    char trace;         // insert profiling hooks
    char quiet;         // suppress non-error messages
    char verbose;       // verbose compile
    char vtls;          // identify thread local variables
    char symdebug;      // insert debug symbolic information
    char alwaysframe;   // always emit standard stack frame
    char optimize;      // run optimizer
    char map;           // generate linker .map file
    char cpu;           // target CPU
    char is64bit;       // generate 64 bit code
    char isLinux;       // generate code for linux
    char isOSX;         // generate code for Mac OSX
    char isWindows;     // generate code for Windows
    char isFreeBSD;     // generate code for FreeBSD
    char isOPenBSD;     // generate code for OpenBSD
    char isSolaris;     // generate code for Solaris
    char scheduler;     // which scheduler to use
    char useDeprecated; // allow use of deprecated features
    char useAssert;     // generate runtime code for assert()'s
    char useInvariants; // generate class invariant checks
    char useIn;         // generate precondition checks
    char useOut;        // generate postcondition checks
    char useArrayBounds; // 0: no array bounds checks
                         // 1: array bounds checks for safe functions only
                         // 2: array bounds checks for all functions
    char noboundscheck; // no array bounds checking at all
    char useSwitchError; // check for switches without a default
    char useUnitTests;  // generate unittest code
    char useInline;     // inline expand functions
    char release;       // build release version
    char preservePaths; // !=0 means don't strip path from source file
    char warnings;      // 0: enable warnings
                        // 1: warnings as errors
                        // 2: informational warnings (no errors)
    char pic;           // generate position-independent-code for shared libs
    char cov;           // generate code coverage data
    char nofloat;       // code should not pull in floating point support
    char Dversion;      // D version number
    char ignoreUnsupportedPragmas;      // rather than error on them
    char enforcePropertySyntax;

    char *argv0;        // program name
    Strings imppath;     // array of char*'s of where to look for import modules
    Strings fileImppath; // array of char*'s of where to look for file import modules
    char *objdir;       // .obj/.lib file output directory
    char *objname;      // .obj file output name
    char *libname;      // .lib file output name

    char doDocComments; // process embedded documentation comments
    char *docdir;       // write documentation file to docdir directory
    char *docname;      // write documentation file to docname
    Strings ddocfiles;   // macro include files for Ddoc

    char doHdrGeneration;       // process embedded documentation comments
    char *hdrdir;               // write 'header' file to docdir directory
    char *hdrname;              // write 'header' file to docname

    char doXGeneration;         // write JSON file
    char *xfilename;            // write JSON file to xfilename

    uint debuglevel;        // debug level
    Strings debugids;     // debug identifiers

    uint versionlevel;      // version level
    Strings versionids;   // version identifiers

    bool dump_source;

    const(char)* defaultlibname; // default library for non-debug builds
    const(char)* debuglibname;   // default library for debug builds

    char *moduleDepsFile;       // filename for deps output
    OutBuffer moduleDeps;      // contents to be written to deps file

    // Hidden debug switches
    char debuga;
    char debugb;
    char debugc;
    char debugf;
    char debugr;
    char debugw;
    char debugx;
    char debugy;

    char run;           // run resulting executable
    size_t runargs_length;
    char** runargs;     // arguments for executable

    // Linker stuff
    Strings objfiles;
    Strings linkswitches;
    Strings libfiles;
    char *deffile;
    char *resfile;
    char *exefile;
    char *mapfile;
};

struct Global
{
    const(char)* mars_ext;
    const(char)* sym_ext;
    const(char)* obj_ext;
    const(char)* lib_ext;
    const(char)* dll_ext;
    const(char)* doc_ext;        // for Ddoc generated files
    const(char)* ddoc_ext;       // for Ddoc macro include files
    const(char)* hdr_ext;        // for D 'header' import files
    const(char)* json_ext;       // for JSON files
    const(char)* map_ext;        // for .map files
    const(char)* copyright;
    const(char)* written;
    Strings path;        // Array of char*'s which form the import lookup path
    Strings filePath;    // Array of char*'s which form the file import lookup path
    int structalign;
    const(char)* _version;

    Param params;
    uint errors;       // number of errors reported so far
    uint warnings;     // number of warnings reported so far
    uint gag;          // !=0 means gag reporting of errors & warnings
    uint gaggedErrors; // number of errors reported while gagged

    // Start gagging. Return the current number of gagged errors
    uint startGagging();

    /* End gagging, restoring the old gagged state.
     * Return true if errors occured while gagged.
     */
    bool endGagging(uint oldGagged);

    //@disable this();
};

extern Global global;

/* Set if Windows Structured Exception Handling C extensions are supported.
 * Apparently, VC has dropped support for these?
 */
enum WINDOWS_SEH = (_WIN32 && __DMC__);


//static if (__DMC__) {
    alias creal complex_t;
//} else {
//    static assert(0);
//}

// Be careful not to care about sign when using dinteger_t
//typedef uint64_t integer_t;
alias uint64_t dinteger_t;    // use this instead of integer_t to
                                // avoid conflicts with system #include's

// Signed and unsigned variants
alias int64_t sinteger_t;
alias uint64_t uinteger_t;

alias int8_t                  d_int8;
alias uint8_t                 d_uns8;
alias int16_t                 d_int16;
alias uint16_t                d_uns16;
alias int32_t                 d_int32;
alias uint32_t                d_uns32;
alias int64_t                 d_int64;
alias uint64_t                d_uns64;

alias float                   d_float32;
alias double                  d_float64;
alias real                    d_float80;

alias d_uns8                  d_char;
alias d_uns16                 d_wchar;
alias d_uns32                 d_dchar;

alias real real_t;

//typedef unsigned Loc;         // file location
struct Loc
{
    const(char)* filename = null;
    uint linnum = 0;

    this(int x)
    {
        linnum = x;
        filename = null;
    }

    //this(Module mod, uint linnum);

    char *toChars();
    bool equals(const ref Loc loc);
};

static if (GCC_SAFE_DMD) {
    enum TRUE  = 1;
    enum FALSE = 0;
}

enum INTERFACE_OFFSET = 0;       // if 1, put classinfo as first entry
                                        // in interface vtbl[]'s
enum INTERFACE_VIRTUAL = 0;       // 1 means if an interface appears
                                        // in the inheritance graph multiple
                                        // times, only one is used

alias uint LINK;
enum : LINK
{
    LINKdefault,
    LINKd,
    LINKc,
    LINKcpp,
    LINKwindows,
    LINKpascal,
};

alias uint DYNCAST;
enum : DYNCAST
{
    DYNCAST_OBJECT,
    DYNCAST_EXPRESSION,
    DYNCAST_DSYMBOL,
    DYNCAST_TYPE,
    DYNCAST_IDENTIFIER,
    DYNCAST_TUPLE,
};

enum MATCH
{
    MATCHnomatch,       // no match
    MATCHconvert,       // match with conversions
//#if DMDV2
    MATCHconst,         // match with conversion to const
//#endif
    MATCHexact          // exact match
};
alias MATCH.MATCHnomatch MATCHnomatch;
alias MATCH.MATCHconvert MATCHconvert;
alias MATCH.MATCHconst   MATCHconst;
alias MATCH.MATCHexact   MATCHexact;

static assert(DMDV2, "disabled preprocessor conditional");

alias uint64_t StorageClass;

void obj_start(char *srcfile);
void obj_end(Library library, File objfile);
void obj_append(Dsymbol s);
void obj_write_deferred(Library library);

const(char)* importHint(const(char)* s);
